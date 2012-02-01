require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings" do
  before do
    DataBindings.reset!
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer
    end
  end

  it "should raise a validation error if neither the key or alias key exist on an object" do
    DataBindings.type(:file) do
      property :size, Integer
      property :filename, String, :alias => [:filenames, :file_name]
    end
    a = DataBindings.from_json('{"size":925, "fn":"foo.txt"}').bind(:file)
    assert_equal({'filename' => "not found"}, a.errors)
    refute a.errors.empty?
    refute a.valid?
  end

  describe "from_*_file" do
    it "should load from a file" do
      a = DataBindings.from_json_file(File.expand_path("../fixtures/1.json", __FILE__)).bind_array {
        all_elements :person
      }
      assert a.valid?
      assert_equal "josh", a[1][:name]
    end
  end

  describe "from_*_net" do
    it "should load from the net" do
      a = DataBindings.from_json_http("http://localhost/1.json").bind_array {
        all_elements :person
      }
      assert a.valid?
      assert_equal "josh", a[1][:name]
    end

    it "should fail to load without auth" do
      assert_raises DataBindings::HttpError do
        a = DataBindings.from_json_http("http://secret/1.json").bind_array {
          all_elements :person
        }
      end
    end

    it "should load with the right auth" do
      a = DataBindings.from_json_http("http://secret/1.json", :basic_auth => {:username => 'test', :password => 'user'}).bind_array {
        all_elements :person
      }
      assert a.valid?
      assert_equal "josh", a[1][:name]
    end
  end

  describe "strictness via the generator's default" do
    it "should reject extra properties" do
      DataBindings.strict = true
      a = DataBindings.from_json('{"author":"siggy","title":"bible"}').bind { property :author }
      assert_equal "siggy", a[:author]
      refute a.valid?
    end
  end
end
