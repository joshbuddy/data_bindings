module DataBindings
  module Adapters
    autoload :BSON,       'data_bindings/adapters/bson'
    autoload :JSON,       'data_bindings/adapters/json'
    autoload :Native,     'data_bindings/adapters/native'
    autoload :Ruby,       'data_bindings/adapters/ruby'
    autoload :YAML,       'data_bindings/adapters/yaml'
    autoload :Params,     'data_bindings/adapters/params'
    autoload :XML,        'data_bindings/adapters/xml'
    autoload :TNetstring, 'data_bindings/adapters/tnetstring'
  end
end