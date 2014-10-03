module TivoHMO
  module API

    # A tree node.  Nodes have a parent, children and a root, with the tree
    # itself representing the app/container/items heirarchy
    class Node
      # We could have used https://github.com/evolve75/RubyTree here instead of
      # hand coding a tree, but since this is part of the 'api' I figured it
      # was better not to have any external dependencies

      include GemLogger::LoggerSupport

      attr_accessor :identifier,
                    :parent,
                    :children,
                    :root,
                    :title,
                    :content_type,
                    :source_format,
                    :modified_at,
                    :created_at

      alias app root

      def initialize(identifier, parent: nil)
        raise ArgumentError, "Not a node: #{parent}" unless parent.nil? || parent.is_a?(Node)

        self.identifier = identifier
        self.title = identifier
        self.parent = parent
        @children = []
        if parent.nil?
          self.root = self
        else
          parent.add_child(self)
        end
      end

      def add_child(child)
        raise ArgumentError, "Not a node: #{child}" unless child.is_a?(Node)
        child.parent = self
        child.root = self.root
        @children << child
        child
      end

      def find(title_path)

        unless title_path.is_a?(Array)
          title_path = title_path.split('/')
          return root if title_path.blank?
          if title_path.first == ""
            return root.find(title_path[1..-1])
          end
        end

        next_title, rest = title_path[0], title_path[1..-1]

        self.children.find do |c|
          if c.title == next_title
            if rest.blank?
              return c
            else
              return c.find(rest)
            end
          end
        end

        return nil
      end

      def title_path
        if self == root
          "/"
        else
          if parent == root
            "#{parent.title_path}#{self.title}"
          else
            "#{parent.title_path}/#{self.title}"
          end
        end
      end

      def to_s
        "<#{self.class.name}: #{self.identifier}>"
      end

    end

  end
end
