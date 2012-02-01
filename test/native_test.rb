require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings native" do
  before do
    DataBindings.reset!
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer
    end
    @person = Class.new { attr_accessor :name, :age; def initialize(name, age); @name, @age = name, age; end }
    DataBindings.for_native(:person) { |props| @person.new(props[:name], props[:age]) }
  end

  it "should parse a Native object" do
    p = @person.new("ben", 23)
    a = DataBindings.from_native(p)
    assert_equal "ben", a['name']
  end

  it "should transform into json without a binding (roughly)" do
    p = @person.new("ben", 23)
    assert_raises(DataBindings::UnboundError) { DataBindings.from_native(p).convert_to_json }
  end

  it "should not transform into json without a binding" do
    p = @person.new("ben", 23)
    a = DataBindings.from_native(p).bind(:person).convert_to_json
    assert_equal({"name" => "ben", "age" => 23}, MultiJson.decode(a))
  end

  it "should transform into a native object" do
    a = DataBindings.from_json('{"name":"Andrew","age":32}').bind(:person)
    assert a.errors.empty?
    assert a.valid?
    assert_equal "Andrew", a[:name]
    assert_equal "Andrew", a.to_native.name
  end

  it "should create a hash when there is no binding" do
    a = DataBindings.from_json('{"name":"Andrew","age":32}').to_native
    assert_equal "Andrew", a.name
  end

  it "should be able to create nested objets" do
    DataBindings.type(:address_book) do
      property :owner, :person
      property :friends, [:person]
    end
    address_book = Class.new {
      attr_accessor :owner, :friends
      def initialize(owner, friends)
        @owner, @friends = owner, friends
      end

      def find(name)
        idx = @friends.find_index{|f| f.name == name }
        idx && @friends[idx]
      end
    }
    DataBindings.for_native(:address_book) { |props| address_book.new(props[:owner], props[:friends]) }
    book = DataBindings.from_json('{"owner":{"name":"josh","age":34},"friends":[{"name":"grinch","age":123},{"name":"steve","age":23}]}').bind(:address_book).to_native
    assert_equal 'steve', book.find('steve').name
  end
end
