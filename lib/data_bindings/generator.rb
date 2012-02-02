module DataBindings
  # This is the class the handles registering readers, writers, adapters and types.
  class Generator
    # Enable/disable strict mode
    attr_accessor :strict
    alias_method :strict?, :strict

    def initialize
      reset!
    end

    # Defines an object type
    # @param [Symbol] name The name of the type
    # @see https://github.com/joshbuddy/data_bindings/wiki/Types
    def type(name, &blk)
      @types[name] = blk
    end

    # Retrieves an object type
    # @param [Symbol] name The name of the type
    # @return [Proc] The body of the type
    def get_type(name)
      @types[name]
    end

    def binding_class(cls)
      mod = @writer_module
      @binding_classes[cls] ||= begin
        Class.new(cls) do
          include mod
        end
      end
    end

    # Retrieves an adapter
    # @param [Symbol] name The name of the adapter
    # @return [Object] The adapter
    def get_adapter(name)
      @adapter_classes[name] or raise UnknownAdapterError, "Could not find adapter #{name.inspect}"
    end

    # Defines a reader
    # @param [Symbol] name The name of the reader
    # @yield [*Object] All arguments passed to the method used to invoke this reader
    def reader(name, &blk)
      @reader_module.define_singleton_method(name, &blk)
      build!
    end

    # Defines a writer
    # @param [Symbol] name The name of the writer
    # @yield [*Object] All arguments passed to the method used to invoke this writer
    def writer(name, &blk)
      @writer_module.define_singleton_method(name, &blk)
    end

    # Passes off writing of an object through a specific writer.
    # @param [Symbol] method_name The method name to be invoked on the writer
    # @param [String] data The data to be written
    def write(method_name, obj, *args, &blk)
      @writer_module.send(method_name, obj, *args, &blk)
    end

    # Tests if a specific type of writer is supported
    # @param [Symbol] name The name of the writer to test
    # @return [Boolean]
    def write_targets(name)
      target, format = name.to_s.split(/_/, 2)
    end

    # Registers an adapter
    # @param [Symbol] name The name of the adapter
    # @param [Object] The adapter
    def register(name, cls)
      @adapters[name] = cls
      build!
    end

    # Resets the generator to a blank state
    def reset!
      @reader_module = Module.new { extend Readers }
      @writer_module = Module.new { extend Writers; include WritingInterceptor }
      @strict = false
      @types = {}
      @adapters = {}
      @adapter_classes = {}
      @binding_classes = {}
    end

    # Defines a native constructor
    # @param [Symbol] name The name of the type to create a constructor for
    def for_native(name, &blk)
      native_constructors[name] = blk
    end

    def native_constructors
      @native_constructors ||= {}
    end

    private
    # @api private
    def build!
      @adapters.each do |name, cls|
        unless @adapter_classes[name]
          @adapter_classes[name] = cls.to_s.split('::').inject(Object) {|const, n| const.const_get(n)}
          extend @adapter_classes[name]
          @writer_module.send(:include, @adapter_classes[name]::Convert) if @adapter_classes[name].const_defined?(:Convert)
        end
        converter_methods = @reader_module.methods - Module.methods
        converter_methods.each do |m|
          method_name = :"from_#{name}_#{m}"
          unless singleton_methods.include?(method_name)
            define_singleton_method method_name do |*args|
              out = @reader_module.send(m, *args)
              send(:"from_#{name}", out)
            end
          end
        end
      end
    end
  end

  class DefaultGenerator < Generator
    # Resets the generator to a blank state and installs the json, yaml, ruby and native
    # adpaters
    def reset!
      super
      register(:json,       'DataBindings::Adapters::JSON')
      register(:yaml,       'DataBindings::Adapters::YAML')
      register(:ruby,       'DataBindings::Adapters::Ruby')
      register(:native,     'DataBindings::Adapters::Native')
      register(:bson,       'DataBindings::Adapters::BSON')
      register(:params,     'DataBindings::Adapters::Params')
      register(:xml,        'DataBindings::Adapters::XML')
      register(:tnetstring, 'DataBindings::Adapters::TNetstring')
    end
  end
end