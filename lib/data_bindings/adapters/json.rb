module DataBindings
  module Adapters
    module JSON
      include Ruby
      include DataBindings::GemRequirement

      # Constructs a wrapped object from a JSON string
      # @param [String] str The JSON object
      # @return [RubyObjectAdapter, RubyArrayAdapter] The wrapped object
      def from_json(str)
        from_ruby(MultiJson.decode(str))
      end
      gentle_require_gem :from_json, 'multi_json'

      module Convert
        include ConverterHelper
        include DataBindings::GemRequirement

        # Creates a String repsentation of a Ruby Hash or Array.
        # @param [Generator] generator The generator that invokes this constructor
        # @param [Symbol] name The name of the binding used on this object
        # @param [Array, Hash] obj The object to be represented in JSON
        # @return [String] The JSON representation of this object
        def force_convert_to_json
          MultiJson.encode(self)
        end
        gentle_require_gem :force_convert_to_json, 'multi_json'
        standard_converter :convert_to_json
      end
    end
  end
end