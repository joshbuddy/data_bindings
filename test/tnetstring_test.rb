require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings tnetstring" do
  describe "tnetstring parsing" do
    it "should parse tnetstring" do
      a = DataBindings.from_tnetstring(TNetstring.dump(:author => 'siggy', :title => 'bible')).bind { property :author; property :title }
      assert a.valid?
      assert_equal "siggy", a[:author]
    end
  end

  describe "tnetstring generation" do
    it "should generate tnetstring" do
      a = DataBindings.from_ruby('author' => 'siggy',"title" => 'koran').bind { property :author; property :title }
      assert a.valid?
      valid_tnetstring_representations = [
        "33:6:author,5:siggy,5:title,5:koran,}",
        "33:5:title,5:koran,6:author,5:siggy,}"
      ]
      assert valid_tnetstring_representations.include?( a.convert_to_tnetstring )
    end
  end
end
