# Data bindings

There are many ways to represent data. For instance, XML, JSON and YAML are all very similar while having different representations.
Data bindings attempts to unify these various representations by allowing the creation of representation-free schemas which can be used to valiate a document. As well,
it provides adapters to normalize access across these various types.

Data bindings has four central concepts. *Adapters* provide normal access independent of representation. *Readers* allow you to define adapter-independent ways of reading data. *Writers* allows you define adapter-independent ways of writing data.*Validations* allow you to define a schema for your document.

## 5 minute demo

Start by loading from a JSON object

    a = DataBindings.from_json('{"name":"Proust","books":[{"published":1913,"title":"Swan\'s Way"},{"published":1923,"title":"The Prisoner"}]}')

(You could also load from YAML, XML BSON, etc by using `#from_yaml`, `#from_xml`, `#from_bson` and so forth)

We can go ahead and access that like we nomrally would

    a[:name]
    # "proust"
    a[:name][0][:title]
    # "Swan's Way"

Great, now let's get a validated copy of that object

    b = a.bind {
      property :name, String
      property :books, [] {
        property :published, Integer
        property :title, String
      }
    }

Is it okay?

    b.valid?
    # => true

How about we represent it in YAML!

    b.convert_to_yaml
    # => "---\nname: Proust\nbooks:\n- published: 1913\n  title: Swan's Way\n- published: 1923\n  title: The Prisoner\n" 

Or, right out to a YAML file

    b.convert_to_yaml_file("/tmp/proust.yaml")

And load it back

    from_file = DataBindings.from_yaml_file("/tmp/proust.yaml")
    from_file.bind(a) # Use the binding from above

We can also define the types independently so that we can associate them with Ruby constructors later.

    DataBindings.type(:book) {
      property :published, Integer
      property :title, String
    }

    DataBindings.type(:person) {
      property :name
      property :books, [:book]
    }

    proust = DataBindings.from_yaml_file('/tmp/proust.yaml').bind(:person)
    p proust[:name]
    # => "Proust" 
    p proust[:books][1]
    # => {"published"=>1923, "title"=>"The Prisoner"}

Maybe we also want to create a Ruby object out of person, let's do that.

    class Person
      attr_reader :name, :books

      def initialize(name, books)
        @name = name
        @books = books
      end

      def proust?
        name.downcase == 'proust'
      end
    end

    class Book
      attr_reader :published, :title

      def initialize(published, title)
        @published, @title = published, title
      end

      def published_before?(year)
        published < year
      end
    end

    DataBindings.for_native(:person) { |attrs| Person.new(attrs[:name], attrs[:books]) }
    DataBindings.for_native(:book) { |attrs| Book.new(attrs[:published], attrs[:title]) }

    proust = DataBindings.from_yaml_file('/tmp/proust.yaml').bind!(:person).to_native
    proust.proust?
    # => true
    proust.books[0].published_before?(2011)
    # => true
	proust.books[0].published_before?(1800)
	# => false

## Adapters

Adapters have a simple contract. They must be a module. They must define a method #from_* where * is a type. For example, the JSONAdapter provides `#from_json`. They must also provide a singleton method #construct that can serialize an object into it's target representation. They may provide other methods to your base generator; they are included into it and thus can access any of it's internals. They are typically expected to return a ruby hash or array. For instance:

    a = DataBindings.from_json('{"Hello":"World"}')
	# => {"Hello"=>"World"} 
	a.class
    # => DataBindings::Adapters::Ruby::RubyObjectAdapter 

## Binding

Bindings provide a mechanism to validate certain properties of a Hash.

To create a type, define it from your generator. For example:

	DataBindings.type(:person) do
	  property :name, String
	  property :age, Integer
	end

Would define a type for `:person`. This object would have two properties `name` and `age`. The types available are String, Integer, Float, DataBindings::Boolean. As well, you can refer to any of the types you've defined previously. You can refer to an implicit array of values by putting the type in `[]`. For example, you could have

	DataBindings.type(:person) do
	  property :name, String
	  property :age, Integer
	  property :lottery_numbers, [Integer]
	end

## Readers

Readers provide an adapter-indepedent way of reading data from other sources. By default, we are also dealing with a String representation of the data. For instance:

    DataBindings.from_json('{"Hello":"World"}')

would create a JSON representation. You could provide file access by adding a `file` reader.

	DataBindings.reader(:file) { |f| File.read(f) }

Now, we could load the above JSON from disk by using

    DataBindings.from_json_file('/tmp/file.json')

The `#from_json_file` method is synthesized into your generator by adding a `:file` reader. By default, there are readers for files, io, and http.

## Writers

Writers provide an adapter-indepedent way of writing data to other sources. By default, we emit our representation of the data as a String. For instance:

    DataBindings.from_ruby({"Hello" => "World"}).convert_to_yaml

would create a YAML representation. You could provide file writing by adding a `file` writer.

	DataBindings.reader(:file) { |obj, f| File.open(f, 'w') { |h| h << obj } }

Now, if you wanted to write the above JSON to disk as YAML, you could do the following:

	DataBindings.from_ruby({"Hello" => "World"}).convert_to_file(:yaml, "/tmp/out.yaml")

The `#convert_to_file` method that would be synthesized into your generator. By default, there are writers for files, io, and http.
