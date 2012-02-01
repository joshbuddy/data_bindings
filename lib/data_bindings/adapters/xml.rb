module DataBindings
  module Adapters
    module XML
      include Ruby
      include DataBindings::GemRequirement

      # Constructs a wrapped object from a JSON string
      # @param [String] str The JSON object
      # @return [RubyObjectAdapter, RubyArrayAdapter] The wrapped object
      def from_xml(str)
        from_ruby(from_xml_obj(Nokogiri::XML(str)))
      end
      gentle_require_gem :from_xml, 'nokogiri'

      def from_xml_obj(o)
        case o.type
        when Nokogiri::XML::Node::DOCUMENT_NODE
          from_xml_obj(o.children[0])
        when Nokogiri::XML::Node::TEXT_NODE
          o.text
        when Nokogiri::XML::Node::ELEMENT_NODE
          if o.children.size == 1 and o.children[0].text?
            from_xml_obj(o.children[0])
          elsif o.children[0].name == '0'
            o.children.map{ |c| from_xml_obj(c) }
          else
            Hash[o.children.map { |n| [n.name, from_xml_obj(n)] }]
          end
        end
      end
      gentle_require_gem :from_xml_obj, 'nokogiri'

      # Creates a String repsentation of a Ruby Hash or Array.
      # @param [Generator] generator The generator that invokes this constructor
      # @param [Symbol] name The name of the binding used on this object
      # @param [Array, Hash] obj The object to be represented in JSON
      # @return [String] The JSON representation of this object

      module Convert
        include DataBindings::GemRequirement
        include ConverterHelper

        def force_convert_to_xml
          Convert.construct(@generator, @name, self, @binding_block)
        end
        gentle_require_gem :force_convert_to_xml, 'builder'
        standard_converter :convert_to_xml

        def self.construct(generator, name, obj, builder = nil)
          root = builder.nil?
          builder ||= Builder::XmlMarkup.new
          builder.instruct!(:xml, :encoding => "UTF-8") if root
          case obj
          when Array
            builder.__send__(name || "doc") do |b|
              obj.each_with_index(o, i)
              construct(generator, i.to_s, o, b)
            end
          when Hash
            builder.__send__(name || "doc") do |b|
              obj.each do |k, v|
                construct(generator, k, v, b)
              end
            end
          else
            builder.__send__(name, obj)
          end
          builder.target! if root
        end

      end
    end
  end
end
