require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings json" do
  before do
    DataBindings.reset!
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer
    end
  end

  it "should create a JSON object" do
    a = DataBindings.from_json('{"name":"Andrew","age":32}').bind(:person)
    assert a.errors.empty?
    assert a.valid?
    assert_equal "Andrew", a[:name]
    assert_equal MultiJson.decode("{\"name\":\"Andrew\",\"age\":32}"), MultiJson.decode(a.convert_to_json)
  end

  it "should refuse to create a JSON object when the data is invalid" do
    a = DataBindings.from_json('{"name":"Andrew","age":"asd"}').bind(:person)
    refute a.errors.empty?
    refute a.valid?
    assert_raises(DataBindings::FailedValidation) { a.convert_to_json }
  end

  it "should create a JSON object when the data is invalid and is forced" do
    a = DataBindings.from_json('{"name":"Andrew","age":"asd"}').bind(:person)
    refute a.errors.empty?
    refute a.valid?
    assert_equal MultiJson.decode("{\"name\":\"Andrew\",\"age\":\"asd\"}"), MultiJson.decode(a.force_convert_to_json)
  end

  it "should parse JSON" do
    a = DataBindings.from_json("[1,2,3]").bind([Integer])
    assert a.valid?
    assert a.errors.empty?
    assert_equal [1, 2, 3], [a[0], a[1], a[2]]
  end
end
