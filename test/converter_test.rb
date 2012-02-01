require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings" do
  before do
    DataBindings.reset!
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer
    end
  end

  describe "custom readers" do
    it "should allow adding a custom converter" do
      DataBindings.reader(:kolob) { '{"name":"god","age":123}' }
      a = DataBindings.from_json_kolob.bind(:person)
      assert_equal "god", a[:name]
      assert a.valid?
    end
  end

  describe "custom writers" do
    it "should allow adding a custom converter" do
      data = ''
      DataBindings.writer(:kolob) { |o| data = o }
      a = DataBindings.from_json('{"author":"siggy","title":"bible"}').convert_to_json_kolob
      assert_equal MultiJson.decode('{"author":"siggy","title":"bible"}'), MultiJson.decode(data)
    end

    it "should allow adding a custom converter for a bound object" do
      data = ''
      DataBindings.writer(:kolob) { |o| data = o }
      a = DataBindings.from_json('{"name":"siggy","age":32}').bind(:person).convert_to_json_kolob
      assert_equal MultiJson.decode('{"name":"siggy","age":32}'), MultiJson.decode(data)
    end
  end
end
