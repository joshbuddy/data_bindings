require File.expand_path("../test_helper", __FILE__)

describe "Data Bindings classes" do
  before do
    @generator = DataBindings::DefaultGenerator.new
  end

  describe "class generation" do
    it "should create a basic class" do
      @generator.type(:person) do
        property :name
        property :favorite_food
      end
      @generator.class_for(:person) do
        def to_s
          "#{@name} likes to eat #{@favorite_food}"
        end
      end

      josh = @generator.from_ruby('name' => 'josh', 'favorite_food' => 'lasagna').bind(:person).to_native
      assert_equal "josh likes to eat lasagna", josh.to_s
    end
  end

end
