module DataBindings
  class FailedValidation < RuntimeError
    attr_reader :errors, :original
    def initialize(message, errors, original)
      @errors, @original = errors, original
      super message
    end
  end

  UnboundError = Class.new(RuntimeError)
  UnknownAdapterError = Class.new(RuntimeError)
  UnknownBindingError = Class.new(RuntimeError)
  BindingMismatch = Class.new(RuntimeError)

  class IndifferentHash < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  module ConverterHelper
    def self.included(m)
      m.class_eval <<-EOT, __FILE__, __LINE__ +1
      def self.standard_converter(m)
        define_method(m) do
          pre_convert if respond_to?(:pre_convert)
          send(:"force_\#{m}")
        end
      end
      EOT
    end
  end

  module WritingInterceptor
    def method_missing(m, *args, &blk)
      if match = m.to_s.match(/^((?:force_)?convert_to_(?:[^_]+))_(.*)/)
        self.class.class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{m}(*args, &blk)
          @generator.write(#{match[2].inspect}, send(#{match[1].inspect}, *args, &blk), *args, &blk)
        end
        EOT
        send(m, *args, &blk)
      else
        super
      end
    end
  end

  module GemRequirement
    def self.included(o)
      o.extend ClassMethods
    end

    module ClassMethods
      def gentle_require_gem(method, gem)
        class_eval <<-EOT, __FILE__, __LINE__ + 1
          alias_method :#{method}_without_gem, :#{method}
          def #{method}(*args, &blk)
            DataBindings::GemRequirement.gentle_require_gem #{gem.to_s.inspect}
            class << self
              self
            end.instance_eval do
              alias_method :#{method}, :#{method}_without_gem
            end
            #{method}(*args, &blk)
          end
        EOT
      end
    end

    def self.gentle_require_gem(gem)
      begin
        require gem
      rescue LoadError
        warn "The `#{gem}' gem must be loadable"
        exit 1
      end
    end
  end
end