#
#       ActiveFacts Generators.
#       Generate CQL from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/ordered'

module ActiveFacts
  module Generate #:nodoc:
    # Generate CQL for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --cql <file>.cql
    class CQL < OrderedDumper
    private
      def vocabulary_start(vocabulary)
        puts "vocabulary #{vocabulary.name};\n\n"
      end

      def vocabulary_end
      end

      def value_type_banner
        puts "/*\n * Value Types\n */"
      end

      def value_type_end
        puts "\n"
      end

      def value_type_dump(o)
        return unless o.supertype    # An imported type
        if o.name == o.supertype.name
            # In ActiveFacts, parameterising a ValueType will create a new ValueType
            # throw Can't handle parameterized value type of same name as its ValueType" if ...
        end

        parameters =
          [ o.length != 0 || o.scale != 0 ? o.length : nil,
            o.scale != 0 ? o.scale : nil
          ].compact
        parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : ""

                  #" restricted to {#{(allowed_values.map{|r| r.inspect}*", ").gsub('"',"'")}}")

        puts "#{o.name} is written as #{o.supertype.name}#{ parameters }#{
            o.value_restriction && " "+o.value_restriction.describe
          };"
      end

      def append_ring_to_reading(reading, ring)
        reading << " [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]"
      end

      def identified_by_roles_and_facts(entity_type, identifying_roles, identifying_facts, preferred_readings)
        identifying_role_names = identifying_roles.map{|role|
            preferred_role_ref = preferred_readings[role.fact_type].role_sequence.all_role_ref.detect{|reading_rr|
                reading_rr.role == role
              }
            role_words = []
            # REVISIT: Consider whether NOT to use the adjective if it's a prefix of the role_name

            role_name = role.role_name
            role_name = nil if role_name == ""
            # debug "concept.name=#{preferred_role_ref.role.concept.name}, role_name=#{role_name.inspect}, preferred_role_name=#{preferred_role_ref.role.role_name.inspect}"

            if (role.fact_type.all_role.size == 1)
              # REVISIT: Guard against unary reading containing the illegal words "and" and "where".
              role.fact_type.default_reading    # Need whole reading for a unary.
            elsif (role_name)
              role_name
            else
              role_words << preferred_role_ref.leading_adjective if preferred_role_ref.leading_adjective != ""
              role_words << preferred_role_ref.role.concept.name
              role_words << preferred_role_ref.trailing_adjective if preferred_role_ref.trailing_adjective != ""
              role_words.compact*"-"
            end
          }

        # REVISIT: Consider emitting extra fact types here, instead of in entity_type_dump?
        # Just beware that readings having the same players will be considered to be of the same fact type, even if they're not.

        # Detect standard reference-mode scenarios
        external_identifying_facts = identifying_facts - [entity_type.fact_type]
        ft = external_identifying_facts[0]
        fact_constraints = nil
        ftr = ft && ft.all_role.sort_by{|role| role.ordinal}
        if external_identifying_facts.size == 1 and
          entity_role = ftr[n = (ftr[0].concept == entity_type ? 0 : 1)] and
          value_role = ftr[1-n] and
          value_name = value_role.concept.name and
          residual = value_name.gsub(%r{#{entity_role.concept.name}},'') and
          residual != '' and
          residual != value_name

          # The EntityType is identified by its association with a single ValueType
          # whose name is an extension (the residual) of the EntityType's name.

          # Detect standard reference-mode readings:
          forward_reading = reverse_reading = nil
          ft.all_reading.each do |reading|
            if reading.text =~ /^\{(\d)\} has \{\d\}$/
              if reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}.role == entity_role
                forward_reading = reading
              else
                reverse_reading = reading
              end
            elsif reading.text =~ /^\{(\d)\} is of \{\d\}$/
              if reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}.role == value_role
                reverse_reading = reading
              else
                forward_reading = reading
              end
            end
          end

          debug :mode, "------------------- Didn't find standard forward reading" unless forward_reading
          debug :mode, "------------------- Didn't find standard reverse reading" unless reverse_reading

          # If we didn't find at least one of the standard readings, don't use a refmode:
          if (forward_reading || reverse_reading)
            # Elide the constraints that would have been emitted on those readings.
            # If there is a UC that's not in the standard form for a reference mode,
            # we have to emit the standard reading anyhow.
            fact_constraints = @presence_constraints_by_fact[ft]
            fact_constraints.each do |pc|
              if (pc.role_sequence.all_role_ref.size == 1 and pc.max_frequency == 1)
                # It's a uniqueness constraint, and will be regenerated
                @constraints_used[pc] = true
              end
            end
            fact_constraints += Array(@presence_constraints_by_fact[entity_type.fact_type])

            @fact_types_dumped[ft] = true

            # Figure out whether any non-standard readings exist:
            other_readings = ft.all_reading - [forward_reading] - [reverse_reading]
            debug :mode, "--- other_readings.size now = #{other_readings.size}" if other_readings.size > 0

            fact_text = (
              other_readings.map do |reading|
                expanded_reading(reading, fact_constraints, true)
              end +
              (entity_type.fact_type ?
                fact_readings_with_constraints(entity_type.fact_type, fact_constraints) : []
              )
            )*",\n\t"

            return " identified by its #{residual}" +
              (fact_text != "" ? " where\n\t" + fact_text : "")
          end
        end

        identifying_facts.each{|f| @fact_types_dumped[f] = true }
        @identifying_fact_text = 
            identifying_facts.map{|f|
                fact_readings_with_constraints(f, fact_constraints)
            }.flatten*",\n\t"

        " identified by #{ identifying_role_names*" and " }" +
          " where\n\t"+@identifying_fact_text
      end

      def entity_type_banner
        puts "/*\n * Entity Types\n */"
      end

      def entity_type_group_end
        puts "\n"
      end

      def fact_readings(fact_type)
        constrained_fact_readings = fact_readings_with_constraints(fact_type)
        constrained_fact_readings*",\n\t"
      end

      def subtype_dump(o, supertypes, pi)
        print "#{o.name} is a kind of #{ o.supertypes.map(&:name)*", " }"
        if pi
          print identified_by(o, pi)
        end
        # If there's a preferred_identifier for this subtype, identifying readings were emitted
        print((pi ? "," : " where") + "\n\t" + fact_readings(o.fact_type)) if o.fact_type
        puts ";\n"
      end

      def non_subtype_dump(o, pi)
        print "#{o.name} is" + identified_by(o, pi)
#        print(" where\n\t"+ fact_readings(o.fact_type)) if o.fact_type
        puts ";\n"
      end

      def fact_type_dump(fact_type, name)

        @identifying_fact_text = nil
        if (o = fact_type.entity_type)
          print "#{o.name} is"
          if !o.all_type_inheritance_as_subtype.empty?
            print " a kind of #{ o.supertypes.map(&:name)*", " }"
          end

          # Alternate identification of objectified fact type?
          primary_supertype = o.supertypes[0]
          pi = fact_type.entity_type.preferred_identifier
          if pi && primary_supertype && primary_supertype.preferred_identifier != pi
            print identified_by(o, pi)
            print ";\n"
          end
        end

        unless @identifying_fact_text
          print " where\n\t" if o
          puts(fact_readings(fact_type)+";")
        end
      end

      def fact_type_banner
        puts "/*\n * Fact Types\n */"
      end

      def fact_type_end
        puts "\n"
      end

      def constraint_banner
        puts "/*\n * Constraints:"
        puts " */"
      end

      def constraint_end
      end

      # Of the players of a set of roles, return the one that's a subclass of (or same as) all others, else nil
      def roleplayer_subclass(roles)
        roles[1..-1].inject(roles[0].concept){|subclass, role|
          next nil unless subclass and EntityType === role.concept
          role.concept.supertypes_transitive.include?(subclass) ? role.concept : nil
        }
      end

      def dump_presence_constraint(c)
        roles = c.role_sequence.all_role_ref.map{|rr| rr.role }

        # REVISIT: If only one role is covered and it's mandatory >=1 constraint, use SOME/THAT form:
        # for each Bug SOME Tester logged THAT Bug;
        players = c.role_sequence.all_role_ref.map{|rr| rr.role.concept.name}.uniq

        fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
        puts \
          "each #{players.size > 1 ? "combination " : ""}#{players*", "} occurs #{c.frequency} time in\n\t"+
          "#{fact_types.map{|ft| ft.default_reading([], nil)}*",\n\t"}" +
            ";"

=begin
          # More than one fact type involved, an external constraint.
            fact_type = rr.role.fact_type
          # or all facts are binary and the counterparts of the roles are.
          puts "// REVISIT: " +
          if (player = roleplayer_subclass(roles))
            "#{player.name} must play #{c.frequency} of "
          else
            counterparts = roles.map{|r|
                r.fact_type.all_role[r.fact_type.all_role[0] != r ? 0 : -1]
              }
            player = roleplayer_subclass(counterparts)
            "#{c.frequency} #{player ? player.name : "UNKNOWN" } exists for each "
          end +
          "#{
              c.role_sequence.all_role_ref.map{|rr|
                "'#{rr.role.fact_type.default_reading([], nil)}'"
              }*", "
            }"
=end

=begin
        puts \
          "FOR each #{players*", "}" +
          (c.role_sequence.all_role_ref.size > 1 ? " "+c.frequency+" of these holds" : "") + "\n\t"+
          "#{c.role_sequence.all_role_ref.map{|rr|
            role = rr.role
            fact_type = role.fact_type
            some_that = Array.new(fact_type.all_role.size, "some")
            c.role_sequence.all_role_ref.each{|rr2|
              next if rr2.role.fact_type != fact_type
              some_that[fact_type.all_role.index(role)] = "that"
            }
            rr.role.fact_type.default_reading(some_that, nil)
          }*",\n\t"}" +
          ";"
=end
      end

      # Find the common supertype of these concepts.
      # N.B. This will only work if all concepts are on the direct path to the deepest.
      def common_supertype(concepts)
        players_differ = false
        common =
          concepts[1..-1].inject(concepts[0]) do |supertype, concept|
            if !supertype || concept == supertype
              concept   # Most common case
            elsif concept.supertypes_transitive.include?(supertype)
              players_differ = true
              supertype
            elsif supertype.supertypes_transitive.include?(concept)
              players_differ = true
              concept
            else
              return nil  # No common supertype
            end
          end
        return common, players_differ
      end

      def dump_set_constraint(c)
        # REVISIT exclusion: every <player-list> must<?> either reading1, reading2, ...

        # Each constraint involves two or more occurrences of one or more players.
        # For each player, a subtype may be involved in the occurrences.
        # Find the common supertype of each player.
        scrs = c.all_set_comparison_roles.sort_by{|scr| scr.ordinal}
        player_count = scrs[0].role_sequence.all_role_ref.size
        role_seq_count = scrs.size

        #raise "Can't verbalise constraint over many players and facts" if player_count > 1 and role_seq_count > 1

        # puts "#{c.class.basename} has #{role_seq_count} scr's: #{scrs.map{|scr| "("+scr.role_sequence.all_role_ref.map{|rr| rr.role.concept.name}*", "+")"}*", "}"

        players_differ = []   # Record which players are also played by subclasses
        players = (0...player_count).map do |pi|
          # Find the common supertype of the players of the pi'th role in each sequence
          concepts = scrs.map{|r| r.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}[pi].role.concept }
          player, players_differ[pi] = common_supertype(concepts)
          raise "Role sequences of #{c.class.basename} must have concepts matching #{concepts.map(&:name)*","} in position #{pi}" unless player
          player
        end
        #puts "#{c.class.basename} has players #{players.map{|p| p.name}*", "}"

        if c.is_a?(ActiveFacts::Metamodel::SetEqualityConstraint)
          # REVISIT: Need a proper approach to some/that and adjective disambiguation:
          puts \
            scrs.map{|scr|
              scr.role_sequence.all_role_ref.map{|rr| rr.role.fact_type.default_reading([], nil) }*" and "
            } * "\n\tif and only if\n\t" + ";"
          return
        end

        mode = c.is_mandatory ? "exactly one" : "at most one"
        puts "for each #{players.map{|p| p.name}*", "} #{mode} of these holds:\n\t" +
          (scrs.map do |scr|
            constrained_roles = scr.role_sequence.all_role_ref.map{|rr| rr.role }
            fact_types = constrained_roles.map{|r| r.fact_type }.uniq

            fact_types.map do |fact_type|
              # REVISIT: future: Use "THAT" and "SOME" only when:
              # - the role player occurs twice in the reading, or
              # - is a subclass of the constrained concept, or
              reading = fact_type.preferred_reading
              expand_constrained(reading, constrained_roles, players, players_differ)
            end * " and "

          end*",\n\t"
          )+';'
      end

      # Expand this reading using (in)definite articles where needed
      # Handle any roles in constrained_roles specially.
      def expand_constrained(reading, constrained_roles, players, players_differ)
        frequency_constraints = reading.role_sequence.all_role_ref.map {|role_ref|
            i = constrained_roles.index(role_ref.role)
            if !i
              [ "some", role_ref.role.concept.name]
            elsif players_differ[i]
              [ "that", players[i].name ]   # Make sure to use the superclass name
            else
              if reading.fact_type.all_role.select{|r| r.concept == role_ref.role.concept }.size > 1
                [ "that", role_ref.role.concept.name ]
              else
                [ "some", role_ref.role.concept.name ]
              end
            end
          }
        frequency_constraints = [] unless frequency_constraints.detect{|fc| fc[0] != "some" }

        #$stderr.puts "fact_type roles (#{fact_type.all_role.map{|r| r.concept.name}*","}) default_reading '#{fact_type.preferred_reading.text}' roles (#{fact_type.preferred_reading.role_sequence.all_role_ref.map{|rr| rr.role.concept.name}*","}) #{frequency_constraints.inspect}"

        # REVISIT: Make sure that we refer to the constrained players by their common supertype

        reading.expand(frequency_constraints, nil)
      end

      def dump_subset_constraint(c)
        # If the role players are identical and not duplicated, we can simply say "reading1 only if reading2"
        subset_roles, subset_fact_types =
          c.subset_role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| [rr.role, rr.role.fact_type]}.transpose
        superset_roles, superset_fact_types =
          c.superset_role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| [rr.role, rr.role.fact_type]}.transpose

        subset_fact_types.uniq!
        superset_fact_types.uniq!

        subset_players = subset_roles.map(&:concept)
        superset_players = superset_roles.map(&:concept)

        # We need to ensure that if the player of any constrained role also exists
        # as the player of a role that's not a constrained role, there are different
        # adjectives or other qualifiers qualifier applied to distinguish that role.
        fact_type_roles = (subset_fact_types+superset_fact_types).map{|ft| ft.all_role }.flatten
        non_constrained_roles = fact_type_roles - subset_roles - superset_roles
        if (r = non_constrained_roles.detect{|r| (subset_roles+superset_roles).include?(r) })
          # REVISIT: Find a way to deal with this problem, should it arise.

          # It would help, but not entirely fix it, to use SOME/THAT to identify the constrained roles.
          # See ServiceDirector's DataStore<->Client fact types for example
          # Use SOME on the subset, THAT on the superset.
          raise "Critical ambiguity, #{r.concept.name} occurs both constrained and unconstrained in #{c.name}"
        end

        puts \
          "#{subset_fact_types.map{|ft| ft.default_reading([], nil)}*" and "}" +
          "\n\tonly if " +
          "#{superset_fact_types.map{|ft| ft.default_reading([], nil)}*" and "}" +
          ";"
      end

      def dump_ring_constraint(c)
        # At present, no ring constraint can be missed to be handled in this pass
        puts "// #{c.ring_type} ring over #{c.role.fact_type.default_reading([], nil)}"
      end

      def constraint_dump(c)
          case c
          when ActiveFacts::Metamodel::PresenceConstraint
            dump_presence_constraint(c)
          when ActiveFacts::Metamodel::RingConstraint
            dump_ring_constraint(c)
          when ActiveFacts::Metamodel::SetComparisonConstraint # includes SetExclusionConstraint, SetEqualityConstraint
            dump_set_constraint(c)
          when ActiveFacts::Metamodel::SubsetConstraint
            dump_subset_constraint(c)
          else
            "#{c.class.basename} #{c.name}: unhandled constraint type"
          end
      end
    end
  end
end
