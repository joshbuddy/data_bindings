module DataBindings
  module Adapters
    module Ruby

      # Constructs a wrapped object from an Array or Hash
      # @param [Array, Hash] obj The Ruby array or hash
      # @return [RubyObjectAdapter, RubyArrayAdapter] The wrapped object
      def from_ruby(obj)
        case obj
        when Array then from_ruby_array(obj)
        when Hash  then from_ruby_hash(obj)
        else            obj
        end
      end

      def from_ruby_hash(h)
        binding_class(RubyObjectAdapter).new(self, h)
      end
      alias_method :from_ruby_object, :from_ruby_hash

      def from_ruby_array(a)
        binding_class(RubyArrayAdapter).new(self, a)
      end

      class RubyArrayAdapter < Array
        include Unbound

        def initialize(generator, o)
          @generator = generator
          super o
        end
      end

      class RubyObjectAdapter < IndifferentHash
        include Unbound

        def initialize(generator, o)
          @generator = generator
          replace o
        end
      end
    end
  end
end