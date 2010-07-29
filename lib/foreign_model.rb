module ForeignModel
  SCOPE_PROCS = {}
  
  def self.included(base)
    SCOPE_PROCS[base] ||= {}
    base.extend ClassMethods
  end
  
  def self.camelize(str)
    str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end
  
  module ClassMethods
    def belongs_to_foreign_model(name, options={})
      options[:class_name] ||= ForeignModel.camelize(name)
      
      ForeignModel::SCOPE_PROCS[self][name] = begin
        if options[:scope]
          options[:scope]
        elsif options[:polymorphic]
          proc do |r|
            type = r.send("#{name}_type")
            type and eval(type)
          end
        else
          #TODO: this is a hack
          proc{ eval(options[:class_name]) }
        end
      end
      
      define_method "parent_proc_for_#{name}" do
        unless instance_variable_get "@parent_proc_for_#{name}"
          instance_variable_set "@parent_proc_for_#{name}", ForeignModel::SCOPE_PROCS[self.class][name].call(self)
        end
        instance_variable_get "@parent_proc_for_#{name}"
      end
      
      define_method name do
        if send("parent_proc_for_#{name}") && send("#{name}_id") && send("#{name}_id") != ""
          unless instance_variable_get "@#{name}"
            instance_variable_set "@#{name}", send("parent_proc_for_#{name}").find(send("#{name}_id"))
          end
        end
        instance_variable_get "@#{name}"
      end
      
      define_method "#{name}=" do |foreign_model|
        instance_variable_set "@#{name}", foreign_model
        if foreign_model
          send("#{name}_id=",   foreign_model.id)
          send("#{name}_type=", foreign_model.class.name) if respond_to? "#{name}_type="
        end
      end
      
      define_method "#{name}_id=" do |foreign_model_id|
        if send("#{name}_id") != foreign_model_id
          write_raw_attribute("#{name}_id", foreign_model_id)
          instance_variable_set "@#{name}", nil
        end
      end
      
      if options[:polymorphic]
        define_method "#{name}_type=" do |foreign_model_type|
          if send("#{name}_type") != foreign_model_type
            write_raw_attribute("#{name}_type", foreign_model_type)
            instance_variable_set "@#{name}", nil
          end
        end
      end
    end
  end
end

class Object
  def write_raw_attribute(name, value)
    instance_variable_set "@#{name}".to_sym, value
  end
end

module ActiveRecord
  class Base
    def write_raw_attribute(name, value)
      write_attribute name.to_sym, value
    end
  end
end

module Mongoid
  module Document
    def write_raw_attribute(name, value)
      raw_attributes[name.to_s] = value
    end
  end
end