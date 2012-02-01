module DataBindings
  module Bound
    ValidationError = Class.new(RuntimeError)
    NoBindingName = Class.new(RuntimeError)

    class Errors < DataBindings::IndifferentHash
      attr_accessor :base

      def join(st = nil)
        (base ? [base].concat(values) : values).join(st)
      end

      def valid?
        base.nil? && empty?
      end

      def clear
        super
        @base = nil
      end
    end

    #include DataBindings::WriterInterceptor

    attr_reader :errors, :source, :name, :generator

    def valid?
      calculate_validness
      errors.valid?
    end

    def calculate_validness
      if @last_hash.nil? || @last_hash != hash
        @from = self if @last_hash
        errors.clear
        validate
        @last_hash = hash
      end
    end

    def valid!
      valid? or raise FailedValidation.new("Object was invalid with the following errors: #{errors.join(", ")}", errors, source)
      self
    end

    def pre_convert
      valid!
    end

    def cast_element(lookup_name, source, type, opts = nil, &blk)
      name = get_parameter_name(lookup_name, source, opts)
      el = name && source[name]
      raise_on_error = opts && opts.key?(:raise_on_error) ? opts[:raise_on_error] : false
      allow_nil = opts && opts.key?(:allow_nil) ? opts[:allow_nil] : false
      el ||= opts[:default] if opts && opts.key?(:default)

      if el.nil? && name.nil?
        @errors[lookup_name] = generate_error("not found", raise_on_error)
        nil
      else
        new_el = if type.nil?
          # anything goes
          case el
          when Array, Hash
            blk ? register_sub(name, @generator.from_ruby(el).bind(&blk), raise_on_error) : el
          else
            el
          end
        elsif type == String
          @errors[lookup_name] = generate_error("was not a String", raise_on_error) unless el.is_a?(String)
          el
        elsif type == Integer
          begin
            Integer(el)
          rescue ArgumentError, TypeError
            @errors[lookup_name] = generate_error("was not an Integer", raise_on_error)
            el
          end
        elsif type == Float
          begin
            Float(el)
          rescue ArgumentError, TypeError
            @errors[lookup_name] = generate_error("was not a Float", raise_on_error)
            el
          end
        elsif Array === type
          if el.is_a?(Array)
            @errors[lookup_name] = generate_error("did not match the length", raise_on_error) if opts && opts[:length] && !(opts[:length] === el.size)
            if type.first
              register_sub(name, @generator.from_ruby(el).bind_array { all_elements type.first }, raise_on_error)
            elsif blk
              register_sub(name, @generator.from_ruby(el).bind_array { all_elements &blk }, raise_on_error)
            else
              el
            end
          else
            @errors[lookup_name] = generate_error("was not an Array", raise_on_error)
            el
          end
        elsif  type == :boolean
          if allow_nil
            el.nil? ? nil : DataBindings.true_boolean?(el)
          else
            DataBindings.true_boolean?(el)
          end
        elsif Symbol === type
          if el.is_a?(Hash)
            register_sub(name, @generator.from_ruby(el).bind(type), raise_on_error)
          else
            @errors[lookup_name] = generate_error("was not a Hash", raise_on_error)
            el
          end
        else
          raise "Unknown type #{type.inspect}"
        end
        if inclusion = opts && opts[:in]
          @errors[lookup_name] = generate_error("was not included in #{inclusion.inspect}", raise_on_error) unless inclusion.include?(new_el)
        end
        @errors[lookup_name] = generate_error("was nil", raise_on_error) if new_el.nil? && !allow_nil
        new_el
      end
    end

    private

    def dump_val(val)
      if val.respond_to?(:to_hash)
        val.to_hash
      elsif val.respond_to?(:to_ary)
        val.to_ary
      else
        val
      end
    end

    def convert_target
      self
    end

    def generate_error(str, raise_on_error)
      raise_on_error ? raise(ValidationError, str) : str
    end

    def register_sub(name, sub, raise_on_error)
      unless sub.valid?
        @errors[name] = generate_error(sub.errors.to_s, raise_on_error)
      end
      sub
    end

    def validate
      reset_validation_state
      run_validation
      enforce_strictness if @strict
    end

    def init_bound(generator, source, name, opts, validator)
      @errors, @generator, @source, @name, @opts, @validator = Errors.new, generator, source, name, opts, validator
      @from = @source
      @strict = opts && opts.key?(:strict) ? opts[:strict] : generator.strict?
      reset_validation_state
      valid?
    end

    class BoundObject < DataBindings::IndifferentHash
      include Bound

      def initialize(generator, array_expected, source, name, opts, &blk)
        raise BindingMismatch if array_expected
        init_bound(generator, source, name, opts, blk)
      end

      def to_hash
        keys.inject(DataBindings::IndifferentHash.new) { |h, k|
          val = self[k]
          h[k] = dump_val(val)
          h
        }
      end

      def to_native
        valid!
        data = inject(IndifferentHash.new) { |h, (k, v)|
          h[k] = v.respond_to?(:to_native) ? v.to_native : v
          h
        }
        if constructor = generator.native_constructors[name]
          o = constructor[data.to_hash]
        else
          OpenStruct.new(data)
        end
      end

      def property(name, type = nil, opts = nil, &blk)
        type, opts = nil, type if type.is_a?(Hash)
        self[name] = cast_element(name, @from, type, opts, &blk)
      end

      def required(name, type = nil, opts = nil, &blk)
        type, opts = nil, type if type.is_a?(Hash)
        opts ||= {}
        opts[:allow_nil] = false
        property(name, type, opts, &blk)
      end

      def optional(name, type = nil, opts = nil, &blk)
        type, opts = nil, type if type.is_a?(Hash)
        opts ||= {}
        opts[:allow_nil] = true
        property(name, type, opts, &blk)
      end

      def all_properties(type = nil, opts = nil)
        type, opts = nil, type if type.is_a?(Hash)
        @from.keys.each do |key|
          property key, type, opts
        end
      end

      def enforce_strictness
        @errors.base = "hasn't been fully matched" unless size == @from.size
      end

      def copy_source
        replace @source
      end

      private

      def get_parameter_name(name, source, opts)
        name = if opts && opts[:alias]
          aliases = Array(opts[:alias])
          index = aliases.index {|k| source.key?(k) }
          index ? aliases[index] : name
        else
          name
        end
        source.key?(name) ? name : nil
      end
      
      def reset_validation_state
        errors.clear
      end

      def run_validation
        instance_eval(&@validator)
      end
    end

    class BoundArray < Array
      include Bound

      def initialize(generator, array_expected, source, name, opts, &blk)
        raise BindingMismatch unless array_expected
        init_bound(generator, source, name, opts, blk)
      end

      def to_ary
        self.inject([]) { |a, v|
          a << dump_val(v)
        }
      end

      def to_native
        valid!
        inject([]) {|a, el| a << (el.respond_to?(:to_native) ? el.to_native : el); a}
      end

	    def elements(size = nil, type = nil, opts = nil, &blk)
        if size.nil? || size.respond_to?(:to_int)
          size ||= source.size
          # consume all
          (@pos...(@pos+size)).each do |i|
            self[@pos] = cast_element(@pos, @from, type, opts, &blk)
            @pos += 1
          end
        elsif size.respond_to?(:min) && size.respond_to?(:max)
          original_pos = @pos
          while (@pos - original_pos) <= size.max
            begin
              opts ||= {}
              opts[:raise_on_error] = @pos >= size.min
              self[@pos] = cast_element(@pos, @from, type, opts, &blk)
            rescue ValidationError
              break
            end
            @pos += 1
          end
        else
          raise "Size isn't understood: #{size.inspect}"
        end
      end

      def copy_source
        replace @source
      end

      def enforce_strictness
        @errors.base = "hasn't been fully matched" unless @pos.succ == source.size
      end

	    def all_elements(type = nil, &blk)
        elements(nil, type, &blk)
      end

      private
      
      def get_parameter_name(name, source, opts)
        source.at(name) ? name : nil
      end
      
      def reset_validation_state
        @pos = 0
        errors.clear
      end

      def run_validation
        errors.base = "didn't match legnth #{@opts[:length]}" if @opts && @opts[:length] && !(@opts[:length] === size)
        instance_eval(&@validator)
      end
	  end
  end
end
