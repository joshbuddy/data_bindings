module DataBindings
  module Adapters
    module BSON
      include Ruby
      include DataBindings::GemRequirement
      
      # Constructs a wrapped object from a JSON string
      # @param [String] str The JSON object
      # @return [RubyObjectAdapter, RubyArrayAdapter] The wrapped object
      def from_bson(str)
        from_ruby(::BSON.deserialize(str.unpack("C*")))
      end
      gentle_require_gem :from_bson, 'bson'

      module Convert
        include ConverterHelper
        include DataBindings::GemRequirement

        # Creates a String repsentation of a Ruby Hash or Array.
        # @param [Generator] generator The generator that invokes this constructor
        # @param [Symbol] name The name of the binding used on this object
        # @param [Array, Hash] obj The object to be represented in JSON
        # @return [String] The JSON representation of this object
        def force_convert_to_bson
          ::BSON.serialize(self).to_s
        end
        gentle_require_gem :force_convert_to_bson, 'bson'
        standard_converter :convert_to_bson
      end
    end
  end
end
