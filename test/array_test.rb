require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings array" do
  before do
    DataBindings.reset!
  end

  describe "from bind" do
    it "should validate a list of integers" do
      a = DataBindings.from_json("[1,2,3]").bind([Integer])
      assert a.valid?
      assert a.errors.empty?
      assert_equal [1, 2, 3], [a[0], a[1], a[2]]
      a.unshift 'asd'
      refute a.valid?
      refute a.errors.empty?
    end

    it "should bind a list of complex things" do
      DataBindings.type(:person) { property :name, String }
      a = DataBindings.from_json('[{"name":"a"},{"name":"b"},{"name":"c"}]').bind([:person])
      assert a.valid?
      assert a.errors.empty?
      assert_equal 3, a.size
      assert_equal 'c', a[2][:name]
      a.unshift 'asd'
      refute a.valid?
      refute a.errors.empty?
    end

    it "should validate a list" do
      assert DataBindings.from_json("[1,2,3]").bind([]).valid?
      refute DataBindings.from_json("[1,2,3]").bind([], :length => 2).valid?
      assert_raises(DataBindings::BindingMismatch) { DataBindings.from_json("{}").bind([]) }
    end
  end

  describe "from within a bind" do
    it "should validate a list of integers" do
      a = DataBindings.from_json('{"a":[1,2,3]}').bind { property :a, [Integer] }
      assert a.valid?
      assert a.errors.empty?
      assert_equal [1, 2, 3], [a[:a][0], a[:a][1], a[:a][2]]
      a[:a].unshift 'asd'
      refute a.valid?
      refute a.errors.empty?
    end

    it "should validate a list" do
      assert DataBindings.from_json('{"a":[1,2,3]}').bind { property :a, [Integer], :length => 3 }.valid?
      refute DataBindings.from_json('{"a":[1,2,3,4]}').bind { property :a, [Integer], :length => 3 }.valid?
    end
    
  end
end
