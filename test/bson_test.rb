require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings bson" do
  describe "bson parsing" do
    it "should parse bson" do
      a = DataBindings.from_bson(BSON.serialize(:author => 'siggy', :title => 'bible')).bind { property :author; property :title }
      assert a.valid?
      assert_equal "siggy", a[:author]
    end
  end

  describe "bson generation" do
    it "should generate bson" do
      a = DataBindings.from_ruby('author' => 'siggy',"title" => 'koran').bind { property :author; property :title }
      assert a.valid?
      valid_bson_representations = [
        "(\x00\x00\x00\x02author\x00\x06\x00\x00\x00siggy\x00\x02title\x00\x06\x00\x00\x00koran\x00\x00",
        "(\x00\x00\x00\x02title\x00\x06\x00\x00\x00koran\x00\x02author\x00\x06\x00\x00\x00siggy\x00\x00"
      ]
      assert valid_bson_representations.include?( a.convert_to_bson )
    end
  end
end
