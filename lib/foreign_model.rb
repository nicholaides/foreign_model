module ForeignModel
  SCOPE_PROCS = {}
  
  def self.included(base)
    SCOPE_PROCS[base] ||= {}
    
    base.class_eval do
      extend ClassMethods
    end
  end
  
  def self.camelize(str)
    str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end
  
  module ClassMethods
    def belongs_to_foreign_model(name, options={})
      options[:class_name] ||= ForeignModel.camelize(name.to_s)
      if options[:scope]
        ForeignModel::SCOPE_PROCS[self][name.to_s] = options[:scope]
        
        class_eval %`
          def parent_proc_for_#{name}
            @parent_proc_for_#{name} ||= begin
              ForeignModel::SCOPE_PROCS[self.class]["#{name}"].call(self)
            end
          end
        `
        
      else
        class_eval %`
          def parent_proc_for_#{name}
            #{options[:class_name]}
          end
        `
      end
      
      class_eval %`
        def #{name}
          @#{name} ||= parent_proc_for_#{name}.find(#{name}_id) if parent_proc_for_#{name} && #{name}_id 
        end

        def #{name}=(foreign_model)
          @#{name} = foreign_model
          send('#{name}_id=', foreign_model.id) if foreign_model
        end

        def #{name}_id=(foreign_model_id)
          if #{name}_id != foreign_model_id
            write_raw_attribute("#{name}_id", foreign_model_id)
            @#{name} = nil
          end
        end
      `
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