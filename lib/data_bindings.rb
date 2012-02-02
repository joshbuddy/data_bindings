require 'ext/hashie'

require 'data_bindings/util'
require 'data_bindings/generator'
require 'data_bindings/version'
require 'data_bindings/converters'
require 'data_bindings/bound'
require 'data_bindings/unbound'
require 'data_bindings/adapters'

# From https://github.com/marcandre/backports
module Kernel
  # Standard in ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Object.html]
  def define_singleton_method(*args, &block)
    class << self
      self
    end.send(:define_method, *args, &block)
  end unless method_defined? :define_singleton_method
end

# Top-level constant for DataBindings
module DataBindings

  class << self
    # Sends all methods calls to DefaultGenerator
    def method_missing(m, *args, &blk)
      DefaultGeneratorInstance.send(m, *args, &blk)
    end

    def type(name, &blk)
      DefaultGeneratorInstance.type(name, &blk)
    end

    def true_boolean?(el)
      el == true or el == 'true' or el == 1 or el == '1' or el == 'yes'
    end

    def primitive_value?(val)
      case val
      when Integer, Float, true, false, String, Symbol, nil
        true
      else
        false
      end
    end
  end

  # Generator instance used by default when you make a call to DataBindings. This can act as a singleton, so, if you want your own
  # generator, create an instance of it
  DefaultGeneratorInstance = DefaultGenerator.new
end
