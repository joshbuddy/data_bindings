require 'cgi'

module DataBindings
  module Adapters
    module Params
      include Ruby
      
      def from_params(str)
        from_ruby( parse_nested_query(str) )
      end
      
      
      def parse_nested_query(qs, d = nil)
        params = {}
        
        (qs || '').split(d ? /[#{d}] */n : /[&;] */n).each do |p|
          k, v = p.split('=', 2).map { |s| CGI::unescape(s) }
          normalize_params(params, k, v)
        end
        
        return params
      end
      
      private
      def normalize_params(params, name, v = nil)
        name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
        k = $1 || ''
        after = $' || ''
        
        return if k.empty?
        
        if after == ""
          params[k] = v
        elsif after == "[]"
          params[k] ||= []
          raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
          params[k] << v
        elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
          child_key = $1
          params[k] ||= []
          raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
          if params[k].last.is_a?(Hash) && !params[k].last.key?(child_key)
            normalize_params(params[k].last, child_key, v)
          else
            params[k] << normalize_params({}, child_key, v)
          end
        else
          params[k] ||= {}
          raise TypeError, "expected Hash (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Hash)
          params[k] = normalize_params(params[k], after, v)
        end
        
        return params
      end
      
      module Convert
        include ConverterHelper

        # Creates a String repsentation of a Ruby Hash or Array.
        # @param [Generator] generator The generator that invokes this constructor
        # @param [Symbol] name The name of the binding used on this object
        # @param [Array, Hash] obj The object to be represented in JSON
        # @return [String] The JSON representation of this object
        def force_convert_to_params
          build_nested_query(to_hash)
        end
        standard_converter :convert_to_params

        private
      
        def build_nested_query(value, prefix = nil)
          case value
          when Array
            index = 0
            value.map { |v|
              query_string = build_nested_query(v, prefix ? "#{prefix}[#{index}]" : index)
              index += 1
              query_string
            }.join("&")
          when Hash
            value.map { |k, v|
              build_nested_query(v, prefix ? "#{prefix}[#{CGI::escape(k)}]" : CGI::escape(k))
            }.join("&")
          else
            "#{prefix}=#{CGI::escape(value.to_s)}"
          end
        end
      end
    end
  end
end