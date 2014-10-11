require_relative "../spec_helper"

describe TivoHMO::API::Node do

  class TestNode
    include TivoHMO::API::Node
  end

  def test_class
    TestNode
  end

  describe "#initialize" do

    it "should initialize" do
      node = test_class.new('n')
      expect(node).to be_a(TivoHMO::API::Node)
      expect(node.identifier).to eq('n')
      expect(node.title).to eq('n')
      expect(node.children).to eq([])
    end

    it "force title to string" do
      node = test_class.new(:n)
      expect(node).to be_a(TivoHMO::API::Node)
      expect(node.identifier).to eq(:n)
      expect(node.title).to eq('n')
    end

  end

  describe "root?" do

    it "should be false if not root" do
      node = test_class.new('r')
      expect(node.root?).to be(false)
    end

    it "should be true if root" do
      node = test_class.new('r')
      node.root = node
      expect(node.root?).to be(true)
    end

  end

  describe "app?" do

    it "should be false if not app" do
      node = test_class.new('a')
      expect(node.app?).to be(false)
    end

    it "should be true if root" do
      node = test_class.new('a')
      node.app = node
      expect(node.app?).to be(true)
    end

  end

  describe "#add_child" do

    before(:each) do
      @root = test_class.new('r')
      @root.root = @root
    end

    it "should setup parent/child relationship" do
      child = test_class.new('c')
      @root.add_child(child)
      expect(@root.children).to eq([child])
      expect(child.parent).to eq(@root)
    end

    it "should preserve root for children" do
      app1 = test_class.new('a1')
      app1.app = app1
      app2 = test_class.new('a2')
      app2.app = app2

      @root.add_child(app1)
      @root.add_child(app2)

      child1 = test_class.new('c1')
      app1.add_child(child1)

      child2 = test_class.new('c2')
      app2.add_child(child2)

      expect(@root.root).to eq(@root)
      expect(app1.root).to eq(@root)
      expect(app2.root).to eq(@root)
      expect(child1.root).to eq(@root)
      expect(child2.root).to eq(@root)
    end

    it "should preserve app for children" do
      app1 = test_class.new('a1')
      app1.app = app1
      app2 = test_class.new('a2')
      app2.app = app2

      @root.add_child(app1)
      @root.add_child(app2)

      child1 = test_class.new('c1')
      app1.add_child(child1)

      child2 = test_class.new('c2')
      app2.add_child(child2)

      expect(app1.app).to eq(app1)
      expect(child1.app).to eq(app1)

      expect(app2.app).to eq(app2)
      expect(child2.app).to eq(app2)
    end

  end

  describe "#title_path" do

    before(:each) do
      @root = test_class.new('r')
      @root.root = @root
      @child1 = @root.add_child(test_class.new('c1'))
      @child11 = @child1.add_child(test_class.new('c11'))
      @child111 = @child11.add_child(test_class.new('c111'))
      @child2 = @root.add_child(test_class.new('c2'))
    end

    it "should be '/' for root" do
      expect(@root.title_path).to eq('/')
    end

    it "should reflect the heirarchy" do
      expect(@child111.title_path).to eq('/c1/c11/c111')
      expect(@child2.title_path).to eq('/c2')
    end

  end

  describe "#find" do

    before(:each) do
      @root = test_class.new('r')
      @root.root = @root
      @child1 = @root.add_child(test_class.new('c1'))
      @child11 = @child1.add_child(test_class.new('c11'))
      @child111 = @child11.add_child(test_class.new('c111'))
      @child2 = @root.add_child(test_class.new('c2'))
    end

    it "should find '/' for root" do
      expect(@root.find('/')).to eq(@root)
      expect(@child111.find('/')).to eq(@root)
    end

    it "should find relative path" do
      expect(@child1.find('c11')).to eq(@child11)
    end

    it "should find deep full path" do
      expect(@root.find('/c1/c11/c111')).to eq(@child111)
      expect(@child11.find('/c1/c11/c111')).to eq(@child111)
    end

    it "should find deep relative path" do
      expect(@root.find('c1/c11/c111')).to eq(@child111)
      expect(@child1.find('c11/c111')).to eq(@child111)
      expect(@root.find('c11/c111')).to eq(nil)
      expect(@child1.find('c1/c11/c111')).to eq(nil)
    end

  end

end
