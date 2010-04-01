require "spec"
require File.dirname(__FILE__) + '/../lib/foreign_model'

describe "belongs_to_foreign_model" do
  class Parent
    attr_accessor :id
    def initialize(id="some_id")
      @id = id
    end
    
    def self.find(id)
      new(id)
    end
    
    def ==(other)
      self.class == other.class && self.id == other.id
    end
  end
  
  class Child
    attr_reader :parent_id
    include ForeignModel
    belongs_to_foreign_model :parent
  end
  
  describe Child do
    describe "#parent=" do
      before :each do
        @parent = Parent.new
        @child = Child.new
      end
      it "should accept nil" do
        @child.parent = nil
        @child.parent.should be_nil
      end
      it "should set parent" do
        @child.parent = @parent
        @child.parent.should == @parent
      end
      it "should set parent id" do
        @child.parent = @parent
        @child.parent_id.should == @parent.id
      end
    end
  end

  describe "#parent_type_id=" do
    before :each do
      @parent = Parent.new
      @child  = Child.new
      @child.parent_id = @parent.id
    end
    it "should set the parent" do
     @child.parent.should == @parent
   end
    it "should set the parent_id" do
      @child.parent_id.should == @parent.id
    end
  end

  describe "with :scope => proc{...}" do
    class ChildWithScope
      attr_reader :parent_id
      include ForeignModel
      belongs_to_foreign_model :parent, :scope => proc{ Scope }
    end
    
    class Scope
    end
    
    it "should find by scope" do
      @child = ChildWithScope.new
      @child.parent_id = "another id"
      
      @parent = mock("parent found by scope")
      Scope.should_receive(:find).with("another id").and_return(@parent)
      
      @child.parent.should == @parent
    end
  end
  
  describe "with :class_name option" do
    class ChildWithClassName
      attr_reader :parent_id
      include ForeignModel
      belongs_to_foreign_model :parent, :class_name => "SomeModule::OtherParent"
    end
    
    module SomeModule
      class OtherParent < ::Parent
        def self.find(id)
          new(id)
        end
      end
    end
    
    it "should find by scope" do
      @child = ChildWithClassName.new
      @child.parent_id = "another id"
      
      @child.parent.id.should == "another id"
      @child.parent.should be_a(SomeModule::OtherParent)
    end
  end

  describe "with :polymorphic => true" do
    class FosterParent
      attr_accessor :id
      def initialize(id="some_id")
        @id = id
      end

      def self.find(id)
        new(id)
      end

      def ==(other)
        self.class == other.class && self.id == other.id
      end
    end
    
    class ChildWithPolymorphicParents
      attr_reader :parent_id
      attr_reader :parent_type
      include ForeignModel
      belongs_to_foreign_model :parent, :polymorphic => true
    end
    
    before :each do
      @parent        = Parent.new
      @foster_parent = FosterParent.new
      @child         = ChildWithPolymorphicParents.new
    end
    
    it "should set the parent to a Parent" do
      @child.parent = @parent
      
      @child.parent.should      == @parent
      @child.parent_id.should   == @parent.id
      @child.parent_type.should == "Parent"
    end
    
    it "should set the parent to a FosterParent" do
      @child.parent = @foster_parent
      
      @child.parent.should      == @foster_parent
      @child.parent_id.should   == @foster_parent.id
      @child.parent_type.should == "FosterParent"
    end
    
    it "should set the parent by id and type" do
      @child.parent_id   = @foster_parent.id
      @child.parent_type = "FosterParent"
      
      @child.parent.should == @foster_parent
    end
  end
end

describe "has_many_foreign_models" do
  class HmfParent
    attr_accessor :id
    def initialize(id="some_id")
      @id = id
    end
    has_many_foreign_models :hmf_children
  end
  
  class HmfChild
    attr_accessor :id
    attr_accessor :parent_id
    def initialize(id="some_id", parent_id="parent_id")
      @id        = id
      @parent_id = parent_id
    end
    
    def self.find_many(parent_id)
      [HmfChild.new("id1", parent_id), HmfChild("id2", parent_id)]
    end
  end
end