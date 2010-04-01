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
      options[:class_name] ||= ForeignModel.camelize(name.to_s)
      
      ForeignModel::SCOPE_PROCS[self][name.to_s] = begin
        if options[:scope]
          options[:scope]
        elsif options[:polymorphic]
          proc{|r| eval( r.send("#{name}_type") ) }
        else
          #TODO: this is a hack
          proc{ eval(options[:class_name]) }
        end
      end
        
      class_eval %`
        def parent_proc_for_#{name}
          @parent_proc_for_#{name} ||= begin
            ForeignModel::SCOPE_PROCS[self.class]["#{name}"].call(self)
          end
        end
        
        def #{name}
          @#{name} ||= parent_proc_for_#{name}.find(#{name}_id) if parent_proc_for_#{name} && #{name}_id 
        end

        def #{name}=(foreign_model)
          @#{name} = foreign_model
          if foreign_model
            send('#{name}_id=', foreign_model.id)
            send('#{name}_type=', foreign_model.class.name) if respond_to? '#{name}_type='
          end
        end

        def #{name}_id=(foreign_model_id)
          if #{name}_id != foreign_model_id
            write_raw_attribute("#{name}_id", foreign_model_id)
            @#{name} = nil
          end
        end
      `
      
      if options[:polymorphic]
        class_eval %`  
          def #{name}_type=(foreign_model_type)
            if #{name}_type != foreign_model_type
              write_raw_attribute("#{name}_type", foreign_model_type)
              @#{name} = nil
            end
          end
        `
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