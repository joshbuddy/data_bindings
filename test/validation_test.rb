describe "Data Bindings validation" do
  before do
    DataBindings.reset!
  end

  it "should revalidate" do
    a = DataBindings.from_json("[1,2,3]").bind([Integer])
    assert a.valid?
    assert a.errors.empty?
    assert_equal [1, 2, 3], [a[0], a[1], a[2]]
    a.unshift 'asd'
    refute a.valid?
    refute a.errors.empty?
  end

  it "should allow for a property to have a Boolean type" do
    DataBindings.type(:person) do
      property :name, String
      property :awesome, :boolean
    end
    a = DataBindings.from_json('{"name":"Andrew","awesome":"true"}').bind(:person)
    assert a.errors.empty?
    assert a.valid?
    assert_equal true, a[:awesome]
  end

  it "should allow for a property to have a default value set" do
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer, :default => 25
    end
    a = DataBindings.from_json('{"name":"Andrew"}').bind(:person)
    assert a.errors.empty?
    assert a.valid?
    assert_equal 25, a[:age]
  end

  it "should allow the default value to be overridden with another value." do
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer, :default => 25
    end
    a = DataBindings.from_json('{"name":"Andrew", "age":26}').bind(:person)
    assert a.errors.empty?
    assert a.valid?
    assert_equal 26, a[:age]
  end
  
  it "should allow for an alias property name to be set for a property" do
    DataBindings.type(:file) do
      property :size, Integer
      property :filename, String, :alias => :file_name
    end
    a = DataBindings.from_json('{"size":925, "file_name":"foo.txt"}').bind(:file)
    assert a.errors.empty?
    assert a.valid?
    assert_equal "foo.txt", a[:filename]
  end
  
  it "should allow an array of aliases to be provided for a property" do
    DataBindings.type(:file) do
      property :size, Integer
      property :filename, String, :alias => [:filenames, :file_name]
    end
    a = DataBindings.from_json('{"size":925, "file_name":"foo.txt"}').bind(:file)
    assert a.errors.empty?
    assert a.valid?
    assert_equal "foo.txt", a[:filename]    
  end

  it "should raise when using bind! with invalid data" do
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer
    end
    assert_raises DataBindings::FailedValidation do
      DataBindings.from_json('{"name":"Andrew","age":"asd"}').bind!(:person)
    end
  end

  it "should give back the original object with errors with invalid data" do
    DataBindings.type(:person) do
      property :name, String
      property :age, Integer
    end
    a = DataBindings.from_json('{"name":"Andrew","age":"asd"}').bind(:person)
    assert_equal "Andrew", a[:name] 
    assert_equal "asd", a[:age] 
    refute a.valid?
  end

  describe "nested DataBindings::FailedValidation" do
    before do
      DataBindings.for_native(:person) { |obj| person.new(obj[:name], obj[:age]) }
      DataBindings.type(:person) do
        property :name, String
        property :age, Integer
        property :books, Array(:book)
      end

      DataBindings.type(:book) do
        property :author, String
        property :title, String
      end
    end

    it "should bind to ruby" do
      a = DataBindings.from_json('{"name":"Andrew","age":32,"books":[{"author":"Siggy","title":"Help Me"},{"author":"Samsum","title":"SC2 and you"}]}').bind(:person)
      assert a.valid?
      assert a.errors.empty?
      assert_equal "Andrew", a[:name]
      assert_equal "Help Me", a[:books][0][:title]
    end

    it "should be invalid if a nested object is invalid" do
      a = DataBindings.from_json('{"name":"Andrew","age":32,"books":[{"author":"Siggy"},{"author":"Samsum","title":"SC2 and you"}]}').bind(:person)
      refute a.valid?
      refute a.errors.empty?
      assert_equal "Andrew", a[:name]
      assert_equal nil, a[:books][0][:title]
    end
  end

  describe "nested validation" do
    it "should bind to ruby" do
      a = DataBindings.from_json('{"name":"Andrew","age":32,"book":{"author":"Siggy","title":"Help Me"}}').to_native
      assert_equal OpenStruct, a.class
      assert_equal "Siggy", a.book.author
    end
  end

  describe "in clause" do
    before do
      DataBindings.type(:person) do
        property :name, String, :in => %w(Steve John Andrew)
      end
    end

    it "should have vaild data" do
      a = DataBindings.from_json('{"name":"Andrew"}').bind(:person)
      assert_equal "Andrew", a[:name] 
      assert a.valid?
    end

    it "should handle invaild data" do
      a = DataBindings.from_json('{"name":"Josh"}').bind(:person)
      assert_equal "Josh", a[:name] 
      refute a.valid?
    end
  end

  describe "inline data type" do
    before do
      DataBindings.type(:person) do
        property :books, [] do
          property :author
          property :title
        end
      end
    end

    it "should have vaild data" do
      a = DataBindings.from_json('{"books":[{"author":"siggy","title":"bible"},{"author":"josh","title":"koran"}]}').bind(:person)
      assert_equal "josh", a[:books][1][:author] 
      assert a.valid?
    end

    it "should handle invaild data" do
      a = DataBindings.from_json('{"books":[{"author":"siggy"},{"author":"josh","title":"koran"}]}').bind(:person)
      assert_equal "josh", a[:books][1][:author] 
      refute a.valid?
    end

    it "should allow binding to the data in a non-named way" do
      a = DataBindings.from_json('{"books":[{"author":"siggy","title":"bible"},{"author":"josh","title":"koran"}]}').bind {
        property :books, [] do
          property :author
          property :title
        end
      }
      assert_equal "josh", a[:books][1][:author] 
      assert a.valid?
    end
  end

  describe "ad-hoc data type" do
    it "should allow binding to the data in a non-named way" do
      a = DataBindings.from_json('{"books":[{"author":"siggy","title":"bible"},{"author":"josh","title":"koran"}]}').bind {
        property :books, [] do
          property :author
          property :title
        end
      }
      assert_equal "josh", a[:books][1][:author] 
      assert a.valid?
    end

    it "should handle invaild data" do
      a = DataBindings.from_json('{"books":[{"author":"siggy"},{"author":"josh","title":"koran"}]}').bind {
        property :books, [] do
          property :author
          property :title
        end
      }
      assert_equal "josh", a[:books][1][:author]
      refute a.valid?
    end

    describe "strictness" do
      it "should reject extra properties" do
        a = DataBindings.from_json('{"author":"siggy","title":"bible"}').bind(:strict => true) { property :author }
        assert_equal "siggy", a[:author]
        refute a.valid?
      end
    end
  end
end