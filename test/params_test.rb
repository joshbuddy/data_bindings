require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings params" do
  
  describe "params parsing" do
    it "should parse params" do
      a = DataBindings.from_params("author=josh&title=great+expectations").bind { property :author; property :title }
      assert a.valid?
      assert_equal "josh", a[:author]
    end
    
    it "should parse a nested hash" do
      a = DataBindings.from_params("name[first_name][short]=ben&name[first_name][long]=benjamin&name[last_name]=coe").bind { property :name }
      assert a.valid?
      assert_equal "ben", a[:name][:first_name][:short]
      assert_equal "benjamin", a[:name][:first_name][:long]
      assert_equal "coe", a[:name][:last_name]
    end
    
    it "should parse an array" do
      a = DataBindings.from_params("name[0][last_name]=coe&name[0][first_name]=ben&name[1][first_name]=josh").bind { property :name }
      assert a.valid?
      assert_equal "ben", a[:name][0][:first_name]
      assert_equal "coe", a[:name][0][:last_name]
      assert_equal "josh", a[:name][1][:first_name]
    end
  end
  
  describe "params generation" do
    
    it "should generate params" do
      a = DataBindings.from_ruby('author' => 'siggy',"title" => 'koran').bind { property :author; property :title }
      assert a.valid?
      assert_match "author=siggy", a.convert_to_params
    end
    
    it "should generate params for nested hash" do
      a = DataBindings.from_ruby('author' => {'name' => {'first_name' => 'bill'}}, 'title' => 'koran', 'meta' => {'isbn' => 9999} ).bind do
          property :author
          property :title
          property :meta
      end
      assert a.valid?
      assert_match "author[name][first_name]=bill", a.convert_to_params
      assert_match "meta[isbn]=9999", a.convert_to_params
      assert_match "title=koran", a.convert_to_params
    end
    
    it "should generate params for nested array" do
      a = DataBindings.from_ruby('authors' => ['josh', 'ben'], 'title' => 'koran' ).bind do
          property :authors
          property :title
      end
      assert a.valid?
      assert_match "authors[0]=josh", a.convert_to_params
      assert_match "title=koran", a.convert_to_params
    end
    
  end
end
