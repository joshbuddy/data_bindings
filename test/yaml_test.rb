require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings yaml" do
  describe "yaml parsing" do
    it "should parse yaml" do
      a = DataBindings.from_yaml('{author: siggy, title: bible}').bind { property :author; property :title }
      assert a.valid?
      assert_equal "siggy", a[:author]
    end
  end

  describe "yaml generation" do
    it "should generate yaml" do
      a = DataBindings.from_ruby('author' => 'siggy',"title" => 'koran').bind { property :author; property :title }
      assert a.valid?
      assert_match /--- ?\nauthor: siggy\ntitle: koran\n|--- ?\ntitle: koran\nauthor: siggy\n/, a.convert_to_yaml
    end
  end
end