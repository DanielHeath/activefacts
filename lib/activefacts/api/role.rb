## The ActiveFacts Runtime API Concept class
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module API

    class Role
      attr_accessor :name
      attr_accessor :counterpart      # All roles except unaries have a binary counterpart
      attr_accessor :player           # May be a Symbol, which will be converted to a Class/Concept
      attr_accessor :mandatory
      attr_accessor :value_restriction

      def initialize(player, counterpart, name, mandatory = false)
        @player = player
        @counterpart = counterpart
        @name = name
        @mandatory = mandatory
      end

      def unary?
        # N.B. A role with a forward reference looks unary until it is resolved.
        counterpart == nil
      end

      def resolve_player(vocabulary)
        return @player if Class === @player   # Done already
        klass = vocabulary.concept(@player)   # Trigger the binding
        raise "Cannot resolve role player #{@player.inspect} for role #{name} in vocabulary #{vocabulary.basename}; still forward-declared?" unless klass
        @player = klass                       # Memoize a successful result
      end
    end

    # Every Concept has a Role collection
    # REVISIT: You can enumerate the concept's own roles, or inherited roles as well.
    class RoleCollection < Hash
      def verbalise
        keys.sort_by(&:to_s).inspect
      end
    end

    # REVISIT: Perhaps I should use an enumerator here instead,
    # and just find a way to handle replace and delete?
    #
    # A RoleValueArray is an array with all mutating methods hidden.
    # We use these for the "many" side of a 1:many relationship.
    # Only "replace" and "delete" are actually used (so far!).
    # Perhaps sort! is innocuous and can remain?
    class RoleValueArray < Array
      [ :"<<", :"[]=", :clear, :collect!, :compact!, :concat, :delete,
        :delete_at, :delete_if, :fill, :flatten!, :insert, :map!, :pop,
        :push, :reject!, :replace, :reverse!, :shift, :shuffle!, :slice!,
        :sort!, :uniq!, :unshift
      ].each{|s|
          begin
            alias_method("__#{s}", s)
          rescue NameError  # shuffle! is in 1.9 only
          end
        }
    end

  end
end