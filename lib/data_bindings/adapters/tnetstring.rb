module DataBindings
  module Adapters
    module TNetstring
      include Ruby
      include DataBindings::GemRequirement

      # Constructs a wrapped object from a Tnetstring
      # @param [String] str The Tnetstring object
      # @return [RubyObjectAdapter, RubyArrayAdapter] The wrapped object
      def from_tnetstring(str)
        from_ruby(::TNetstring.parse(str)[0])
      end
      gentle_require_gem :from_tnetstring, 'tnetstring'

      module Convert
        include ConverterHelper
        include DataBindings::GemRequirement

        # Creates a String repsentation of a Ruby Hash or Array.
        # @param [Generator] generator The generator that invokes this constructor
        # @param [Symbol] name The name of the binding used on this object
        # @param [Array, Hash] obj The object to be represented in JSON
        # @return [String] The Tnetstring representation of this object
        def force_convert_to_tnetstring
          ::TNetstring.dump(self)
        end
        gentle_require_gem :force_convert_to_tnetstring, 'tnetstring'
        standard_converter :convert_to_tnetstring
      end
    end
  end
end
