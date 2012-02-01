require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings xml" do
  describe "xml parsing" do
    it "should parse xml" do
      a = DataBindings.from_xml("<?xml version=\"1.0\" encoding=\"UTF-8\"?><doc><author>siggy</author><title>koran</title></doc>").bind { property :author; property :title }
      assert a.valid?
      assert_equal "siggy", a[:author]
    end
  end

  describe "yaml generation" do
    it "should generate yaml" do
      a = DataBindings.from_ruby('author' => 'siggy',"title" => 'koran').bind { property :author; property :title }
      assert a.valid?
      assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?><doc><author>siggy</author><title>koran</title></doc>", a.convert_to_xml
    end
  end
end
