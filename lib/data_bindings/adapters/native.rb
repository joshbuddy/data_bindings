module DataBindings
  module Adapters
    module Native
      # Constructs a wrapped object from a native Ruby object. This object is expected
      # to respond to calls similar to those defined by #attr_accessor
      # @param [Object] obj The object to be wrapped
      # @return [NativeArrayAdapter, NativeObjectAdapter] The wrapped object
      def from_native(obj)
        binding_class(NativeAdapter).new(self, obj)
      end

      class NativeAdapter
        include Unbound

        def initialize(generator, object)
          @generator, @object = generator, object
        end

        def pre_convert
          raise DataBindings::UnboundError unless @name
        end

        def type
          @object.is_a?(Array) ? :array : :hash
        end

        def [](idx)
          val = @object.respond_to?(:[]) ? @object[idx] : @object.send(idx)
          if DataBindings.primitive_value?(val)
            val
          else
            binding_class(NativeAdapter).new(@generator, val)
          end
        end

        def []=(idx, value)
          @object.respond_to?(:[]=) ? @object[idx] = value : @object.send("#{idx}=", value)
        end

        def key?(name)
          @object.respond_to?(name)
        end

        def to_hash
          raise UnboundError
        end
      end
    end
  end
end