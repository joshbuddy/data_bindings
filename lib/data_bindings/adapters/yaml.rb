require 'yaml'

module DataBindings
  module Adapters
    module YAML
      include Ruby
    
      def from_yaml(str)
        from_ruby(::YAML::load(str))
      end

      def from_yaml_file(f)
        from_ruby(::YAML::load_file(f))
      end

      module Convert
        include ConverterHelper

        def force_convert_to_yaml
          ::YAML::dump(self.to_nonindifferent_hash)
        end
        standard_converter :convert_to_yaml
      end
    end
  end
end