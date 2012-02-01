module DataBindings
  # Module that handles unbound objects
  module Unbound

    attr_reader :binding, :binding_name

    def bind!(name = nil, &blk)
      bind(name, &blk).valid!
    end

    def convert_target
      bind { copy_source }
    end

    def bind(name = nil, opts = nil, &blk)
      if name.is_a?(Unbound)
        update_binding(name.binding_name, &name.binding)
      else
        name, opts = nil, name if name.is_a?(Hash) && opts.nil?
        raise if name.nil? && blk.nil?
        update_binding(name, &blk)
      end
      binding_class.new(@generator, @array, self, name, opts, &@binding)
    end

    def bind_array(type = nil, opts = nil, &blk)
      type, opts = nil, type if type.is_a?(Hash) && opts.nil?
      update_binding([], &blk)
      binding_class.new(@generator, @array, self, nil, opts, &blk)
    end

    def type
      if self.is_a?(Array)
        :array
      elsif self.is_a?(Hash)
        :hash
      else
        raise
      end
    end

    def hash?
      type == :hash
    end

    def array?
      type == :array
    end

    def to_native
      array? ?
        map{ |m| m.respond_to?(:to_native) ? m.to_native : m } :
        OpenStruct.new(inject({}) {|h, (k, v)| v = @generator.from_ruby(v); h[k] = (v.respond_to?(:to_native) ? v.to_native : v); h})
    end

    def update_binding(name, &blk)
      if name.is_a?(Array)
        n = name.at(0)
        @array = true
        blk = proc { all_elements n }
        name = nil
      else
        @array = false
      end
      @binding = @generator.get_type(name) || blk || raise(UnknownBindingError, "Unknown binding #{name.inspect}")
      @name = name
    end

    def binding_class
      case type
      when :array then @generator.binding_class(Bound::BoundArray)
      when :hash  then @generator.binding_class(Bound::BoundObject)
      end
    end
  end
end
