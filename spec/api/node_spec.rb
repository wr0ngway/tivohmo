require_relative "../spec_helper"

describe TivoHMO::API::Node do


  describe "#initialize" do

    it "should raise if parent not a node" do
      expect { described_class.new('r', parent: 'foo') }.to raise_error(ArgumentError)
    end

    it "should set root to self when parent is nil" do
      node = described_class.new('r', parent: nil)
      expect(node.root).to eq(node)
    end

    it "should add self to children of parent" do
      root = described_class.new('r', parent: nil)
      child = described_class.new('c', parent: root)
      expect(root.children).to eq([child])
    end

    it "should set root for heirarchy" do
      root = described_class.new('r', parent: nil)
      child1 = described_class.new('c1', parent: root)
      child11 = described_class.new('c11', parent: child1)
      child111 = described_class.new('c111', parent: child11)
      expect(child1.root).to eq(root)
      expect(child11.root).to eq(root)
      expect(child111.root).to eq(root)
    end

  end

  describe "#add_child" do

    it "should raise if parent not a node" do
      root = described_class.new('r')
      expect { root.add_child('foo') }.to raise_error(ArgumentError)
    end

    it "should setup parent/child relationship" do
      root = described_class.new('r', parent: nil)
      child = described_class.new('c')
      root.add_child(child)
      expect(root.children).to eq([child])
      expect(child.parent).to eq(root)
    end

  end

  describe "#title_path" do

    before(:each) do
      @root = described_class.new('r', parent: nil)
      @child1 = described_class.new('c1', parent: @root)
      @child11 = described_class.new('c11', parent: @child1)
      @child111 = described_class.new('c111', parent: @child11)
      @child2 = described_class.new('c2', parent: @root)
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
      @root = described_class.new('r', parent: nil)
      @child1 = described_class.new('c1', parent: @root)
      @child11 = described_class.new('c11', parent: @child1)
      @child111 = described_class.new('c111', parent: @child11)
      @child2 = described_class.new('c2', parent: @root)
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
    end

  end

end
