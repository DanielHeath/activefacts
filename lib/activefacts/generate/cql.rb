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

      def units_banner
        puts "/*\n * Units\n */"
      end

      def unit_dump unit
        if !unit.ephemera_url
          if unit.coefficient
            # REVISIT: Use a smarter algorithm to switch to exponential form when there'd be lots of zeroes.
            print unit.coefficient.numerator.to_s('F')
            if d = unit.coefficient.denominator and d != 1
              print "/#{d}"
            end
            print ' '
          else
            print '1 '
          end
        end

        print(unit.
          all_derivation_as_derived_unit.
          # REVISIT: Sort base units
          # REVISIT: convert negative powers to division?
          map do |der|
            base = der.base_unit
            "#{base.name}#{der.exponent and der.exponent != 1 ? "^#{der.exponent}" : ''} "
          end*''
        )
        if o = unit.offset and o != 0
          print "+ #{o.to_s('F')} "
        end
        print "converts to #{unit.name}#{unit.plural_name ? '/'+unit.plural_name : ''}"
        print " approximately" if unit.coefficient and !unit.coefficient.is_precise
        print " ephemera #{unit.ephemera_url}" if unit.ephemera_url
        puts ";"
      end

      def value_type_banner
        puts "/*\n * Value Types\n */"
      end

      def value_type_end
        puts "\n"
      end

      def value_type_dump(o)
        # Ignore Value Types that don't do anything:
        return if
          !o.supertype &&
          o.all_role.size == 0 &&
          !o.is_independent &&
          !o.value_constraint &&
          o.all_context_note.size == 0 &&
          o.all_instance.size == 0
        # No need to dump it if the only thing it does is be a supertype; it'll be created automatically
        # return if o.all_value_type_as_supertype.size == 0

=begin
        # Leave this out, pending a proper on-demand system for dumping VT's
        # A ValueType that is only used as a reference mode need not be emitted here.
        if o.all_value_type_as_supertype.size == 0 &&
          !o.all_role.
            detect do |role|
              (other_roles = role.fact_type.all_role.to_a-[role]).size != 1 ||      # Not a role in a binary FT
              !(concept = other_roles[0].concept).is_a?(ActiveFacts::Metamodel::EntityType) ||  # Counterpart is not an ET
              (pi = concept.preferred_identifier).role_sequence.all_role_ref.size != 1 ||   # Entity PI has > 1 roles
              pi.role_sequence.all_role_ref.single.role != role                     # This isn't the identifying role
            end
          puts "About to skip #{o.name}"
          debugger
          return
        end

        # We'll dump the subtypes before any roles, so we don't need to dump this here.
        # ... except that isn't true, we won't do that so we can't skip it now
        #return if
        #  o.all_value_type_as_supertype.size != 0 &&    # We have subtypes
        #  o.all_role.size != 0
=end

        parameters =
          [ o.length != 0 || o.scale != 0 ? o.length : nil,
            o.scale != 0 ? o.scale : nil
          ].compact
        parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : ""

        puts "#{o.name} is written as #{(o.supertype || o).name}#{ parameters }#{
            o.value_constraint && " "+o.value_constraint.describe
          }#{o.is_independent ? ' [independent]' : ''
          };"
      end

      def append_ring_to_reading(reading, ring)
        reading << " [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]"
      end

      def mapping_pragma(entity_type)
        ti = entity_type.all_type_inheritance_as_subtype
        assimilation = ti.map{|t| t.assimilation }.compact[0]
        return "" unless entity_type.is_independent || assimilation
        " [" +
          [
            entity_type.is_independent ? "independent" : nil,
            assimilation || nil
          ].compact*", " +
        "]"
      end

      def identifying_role_names identifying_roles
        identifying_roles.map do |role|
          preferred_role_ref = role.fact_type.preferred_reading.role_sequence.all_role_ref.detect{|reading_rr|
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
        end
      end

      def value_role_identification(entity_type, identifying_facts)
        external_identifying_facts = identifying_facts - [entity_type.fact_type]
        fact_type = external_identifying_facts[0]
        ftr = fact_type && fact_type.all_role.sort_by{|role| role.ordinal}
        if external_identifying_facts.size == 1 and
            entity_role = ftr[n = (ftr[0].concept == entity_type ? 0 : 1)] and
            value_role = ftr[1-n] and
            value_player = value_role.concept and
            value_player.is_a?(ActiveFacts::Metamodel::ValueType) and
            value_name = value_player.name and
            value_residual = value_name.sub(%r{^#{entity_role.concept.name} ?},'') and
            value_residual != '' and
            value_residual != value_name
          [fact_type, entity_role, value_role, value_residual]
        else
          []
        end
      end

      # This entity is identified by a single value, so find whether standard refmode readings were used
      def detect_standard_refmode_readings fact_type, entity_role, value_role
        forward_reading = reverse_reading = nil
        fact_type.all_reading.each do |reading|
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
        debug :mode, "Didn't find standard forward reading" unless forward_reading
        debug :mode, "Didn't find standard reverse reading" unless reverse_reading
        [forward_reading, reverse_reading]
      end

      # This entity is identified by a refmode. Generate the identification and fact reading text.
      def identified_by_refmode(entity_type, value_residual, fact_type, value_role, nonstandard_readings)
        # Elide the constraints that would have been emitted on those readings.
        # If there is a UC that's not in the standard form for a reference mode,
        # we have to emit the standard reading anyhow.
        fact_constraints = @presence_constraints_by_fact[fact_type]
        fact_constraints.each do |pc|
          if (pc.role_sequence.all_role_ref.size == 1 and pc.max_frequency == 1)
            # It's a uniqueness constraint, and will be regenerated
            @constraints_used[pc] = true
          end
        end
        fact_constraints += Array(@presence_constraints_by_fact[entity_type.fact_type])

        @fact_types_dumped[fact_type] = true

        # Figure out whether any non-standard readings exist:
        debug :mode, "--- nonstandard_readings.size now = #{nonstandard_readings.size}" if nonstandard_readings.size > 0

        fact_text = (
          nonstandard_readings.map do |reading|
            expanded_reading(reading, fact_constraints, true)
          end +
          (entity_type.fact_type ?
            fact_readings_with_constraints(entity_type.fact_type, fact_constraints) : []
          )
        )*",\n\t"

        # If we emitted a reading, it'll include the role_value_constraint already
        value_constraint = fact_text.empty? && value_role.role_value_constraint
        constraint_text = value_constraint ? " "+value_constraint.describe : ""
        return " identified by its #{value_residual}#{constraint_text}#{mapping_pragma(entity_type)}" +
          (fact_text != "" ? " where\n\t" + fact_text : "")
      end

      def identified_by_roles_and_facts(entity_type, identifying_roles, identifying_facts)
        irn = identifying_role_names identifying_roles

        # Detect standard reference-mode scenarios
        fact_constraints = nil

        fact_type, entity_role, value_role, value_residual =
          *value_role_identification(entity_type, identifying_facts)
        if fact_type
          # The EntityType is identified by its association with a single ValueType
          # whose name is an extension (the value_residual) of the EntityType's name.
          # If we have at least one of the standard refmode readings, dump it that way.

          forward_reading, reverse_reading =
            *detect_standard_refmode_readings(fact_type, entity_role, value_role)

          if (forward_reading || reverse_reading)
            nonstandard_readings = fact_type.all_reading - [forward_reading, reverse_reading]

            return identified_by_refmode(entity_type, value_residual, fact_type, value_role, nonstandard_readings)
          end
        end

#        fact_constraints = @presence_constraints_by_fact[fact_type] +
#                     Array(@presence_constraints_by_fact[entity_type.fact_type])
        identifying_facts.each{|f| @fact_types_dumped[f] = true }
        @identifying_fact_text = 
            identifying_facts.map{|f|
                fact_readings_with_constraints(f, fact_constraints)
            }.flatten*",\n\t"

        " identified by #{ irn*" and " }" +
          mapping_pragma(entity_type) +
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
          puts identified_by(o, pi)+';'
          return
        end

        print mapping_pragma(o)

        print " where\n\t" + fact_readings(o.fact_type) if o.fact_type
        puts ";\n"
      end

      def non_subtype_dump(o, pi)
        puts "#{o.name} is" + identified_by(o, pi) + ';'
      end

      def fact_type_dump(fact_type, name)

        @identifying_fact_text = nil
        if (o = fact_type.entity_type)
          print "#{o.name} is"
          supertypes = o.supertypes
          print " a kind of #{ supertypes.map(&:name)*", " }" if !supertypes.empty?

          # Alternate identification of objectified fact type?
          primary_supertype = supertypes[0]
          pi = fact_type.entity_type.preferred_identifier
          if pi && primary_supertype && primary_supertype.preferred_identifier != pi
            puts identified_by(o, pi) + ';'
            return
          end
        end

        print " where\n\t" if o
        puts(fact_readings(fact_type)+";")
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
        if c.min_frequency == 1 && c.max_frequency == nil and c.role_sequence.all_role_ref.size == 2
          # REVISIT: Implement the "either... or" syntax for a simple external mandatory constraint
          puts \
            "either #{
              c.role_sequence.all_role_ref.map { |rr|
                rr.role.fact_type.default_reading
              }*" or "
            };"
        else
          # REVISIT: If only one role is covered and it's mandatory >=1 constraint, use SOME/THAT form:
          # for each Bug SOME Tester logged THAT Bug;
          roles = c.role_sequence.all_role_ref.map{|rr| rr.role }
          players = c.role_sequence.all_role_ref.map{|rr| rr.role.concept.name}.uniq
          fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
          min, max = c.min_frequency, c.max_frequency
          pl = (min&&min>1)||(max&&max>1) ? 's' : ''
          puts \
            "each #{players.size > 1 ? "combination " : ""}#{players*", "} occurs #{c.frequency} time#{pl} in\n\t"+
            "#{fact_types.map{|ft| ft.default_reading}*",\n\t"}" +
              ";"
        end
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

      def verbalise_over_role_sequence(role_sequences)
        if role_sequences.all_role_ref.detect{|rr| rr.join_node}
          join = role_sequences.all_role_ref.detect{|rr| rr.join_node}.join_node.join
          join.verbalise_over_role_refs(role_sequences.all_role_ref.to_a)
        else
          fact_types = role_sequences.all_role_ref_in_order.map{|rr| rr.role.fact_type}
          fact_types.uniq!

          # This doesn't use the name of the common supertype of constrained roles

          fact_types.map{|ft| ft.default_reading}*' and '
        end
      end

      def dump_set_comparison_constraint(c)
        scrs = c.all_set_comparison_roles.sort_by{|scr| scr.ordinal}
        role_sequences = scrs.map{|scr|scr.role_sequence}

        if role_sequences.detect{|scr| scr.all_role_ref.detect{|rr| rr.join_node}}
          # The argument to this constructor needs to be a transposed 2D array of the role_refs in these sequences.
          # ActiveFacts::Metamodel::Verbaliser.new(role_refs)

          # This set constraint has an explicit join. Verbalise it.
          readings_list = role_sequences.
            map do |rs|
              verbalise_over_role_sequence(rs) 
            end
          if c.is_a?(ActiveFacts::Metamodel::SetEqualityConstraint)
            puts readings_list.join("\n\tif and only if\n\t") + ';'
            return
          end
          if readings_list.size == 2 && c.is_mandatory  # XOR constraint
            puts "either " + readings_list.join(" or ") + " but not both;"
            return
          end
          mode = c.is_mandatory ? "exactly one" : "at most one"
          puts "for each #{players.map{|p| p.name}*", "} #{mode} of these holds:\n\t" +
            readings_list.join(",\n\t") +
            ';'
          return
        end

        # Each constraint involves two or more occurrences of one or more players.
        #
        # The constrained roles will usually be in fact types which also have unconstrained roles.
        # It's possible that unconstrained roles are played by a concept that plays a constrained role.
        # (an unconstrained role may form joins; not handled here yet)
        #
        # The readings chosen may apply non-matching adjectives to the occurrences of the constrained roles.
        # REVISIT: These constraints will not compile! - subscripts must be added.
        #
        # It's not clear when (if ever) the usage some/that (some X.... that X...) is useful.
        #
        # Each role reference must have an unambiguous identification (role reference) within the constraint.
        # This is achieved when each occurrence of a role reference:
        # * is played by a concept that appears nowhere else
        # * is played by a concept and distinguished by a local adjective (outside any adjectives in its readings)
        # * is played by a concept, perhaps with different adjectives, but with the same subscript.

        # For each player, a subtype may be involved in the occurrences.
        # Find the common supertype of each player.
        player_count = scrs[0].role_sequence.all_role_ref.size  # Must be the same in the other role_sequences
        role_seq_count = scrs.size

        #raise "Can't verbalise constraint over many players and facts" if player_count > 1 and role_seq_count > 1

        # debug :constraint, "#{c.class.basename} has #{role_seq_count} scr's: #{scrs.map{|scr| "("+scr.role_sequence.all_role_ref.map{|rr| rr.role.concept.name}*", "+")"}*", "}"

        players_differ = []   # Record which players are also played by subclasses
        players = (0...player_count).map do |pindex|
          # Find the common supertype of the players of the pindex'th role in each sequence
          concepts = scrs.map do |r|
            r.role_sequence.all_role_ref_in_order[pindex].role.concept
          end
          # Here, "concepts" is an array of the object types that all play the same role position "pindex"
          player, players_differ[pindex] = common_supertype(concepts)
          raise "Role sequences of #{c.class.basename} must have concepts matching #{concepts.map(&:name)*","} in position #{pindex}" unless player
          player
        end
        #debug :constraint, "#{c.class.basename} has players #{players.map{|p| p.name}*", "}"

        if c.is_a?(ActiveFacts::Metamodel::SetEqualityConstraint)
          # REVISIT: Need a proper approach to some/that and adjective disambiguation:
          puts \
            scrs.map{|scr|
              scr.role_sequence.all_role_ref.map{|rr| rr.role.fact_type.default_reading }*" and "
            } * "\n\tif and only if\n\t" + ";"
          return
        end

        if scrs.size == 2 && c.is_mandatory
          introduced = {}
          puts "either " +
            ( scrs.map do |scr|
                constrained_roles = scr.role_sequence.all_role_ref.map{|rr| rr.role }
                fact_types = constrained_roles.map{|r| r.fact_type }.uniq

                fact_types.map do |fact_type|
                  # Choose a reading that starts with the input role (constrained role if none)
                  reading = fact_type.all_reading.sort_by{|r| r.ordinal}.detect do |r|
                      first_reading_role = r.role_sequence.all_role_ref.detect{|rr| rr.ordinal == 0}.role
                      constrained_roles.include?(first_reading_role)
                    end
                  reading ||= fact_type.preferred_reading
                  expand_constrained(reading, constrained_roles, players, players_differ, introduced)
                end * " and "
              end*" or "
            ) +
            " but not both;"
        else
          mode = c.is_mandatory ? "exactly one" : "at most one"
          introduced = {}
          puts "for each #{players.map{|p| p.name}*", "} #{mode} of these holds:\n\t" +
            (scrs.map do |scr|
              constrained_roles = scr.role_sequence.all_role_ref.map{|rr| rr.role }
              fact_types = constrained_roles.map{|r| r.fact_type }.uniq

              fact_types.map do |fact_type|
                # REVISIT: future: Use "THAT" and "SOME" only when:
                # - the role player occurs twice in the reading, or
                # - is a subclass of the constrained concept, or
                reading = fact_type.preferred_reading
                expand_constrained(reading, constrained_roles, players, players_differ, introduced)
              end * " and "

            end*",\n\t"
            )+';'
        end
      end

      # Expand this reading using (in)definite articles where needed
      # Handle any roles in constrained_roles specially.
      def expand_constrained(reading, constrained_roles, players, players_differ, introduced)
        frequency_constraints = reading.role_sequence.all_role_ref.map {|role_ref|
            i = constrained_roles.index(role_ref.role)
            if !i   # Not a constrained role
              # REVISIT: If this is a join role, we need some/that, not just "some"
              # REVISIT: Deactivated this code since it does the wrong thing in either/or, and CQL doesn't use it anyhow
              [
                nil, # "some",
                role_ref.role.concept.name
              ]
            elsif players_differ[i]
              [
                nil, # "that",
                players[i].name
              ]   # Make sure to use the superclass name
            else
              if reading.fact_type.all_role.select{|r| r.concept == role_ref.role.concept }.size > 1
                # This fact type has more than one role played by the same concept
                [
                  nil, # "that",
                  role_ref.role.concept.name
                ]
              else
                [
                  nil, # "some",
                  role_ref.role.concept.name
                ]
              end
            end
          }
        frequency_constraints = [] unless frequency_constraints.detect{|fc| fc[0] != "some" }

        #debug :constraint, "fact_type roles (#{fact_type.all_role.map{|r| r.concept.name}*","}) default_reading '#{fact_type.preferred_reading.text}' roles (#{fact_type.preferred_reading.role_sequence.all_role_ref.map{|rr| rr.role.concept.name}*","}) #{frequency_constraints.inspect}"

        # REVISIT: Make sure that we refer to the constrained players by their common supertype

        reading.expand(frequency_constraints, nil)
      end

      def dump_subset_constraint(c)
        # If the role players are identical and not duplicated, we can simply say "reading1 only if reading2"
        subset_roles, subset_fact_types =
          c.subset_role_sequence.all_role_ref_in_order.map{|rr| [rr.role, rr.role.fact_type]}.transpose
        superset_roles, superset_fact_types =
          c.superset_role_sequence.all_role_ref_in_order.map{|rr| [rr.role, rr.role.fact_type]}.transpose

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
          verbalise_over_role_sequence(c.subset_role_sequence) +
          "\n\tonly if " +
          verbalise_over_role_sequence(c.superset_role_sequence) +
          ";"
      end

      def dump_ring_constraint(c)
        # At present, no ring constraint can be missed to be handled in this pass
        puts "// #{c.ring_type} ring over #{c.role.fact_type.default_reading}"
      end

      def constraint_dump(c)
          case c
          when ActiveFacts::Metamodel::PresenceConstraint
            dump_presence_constraint(c)
          when ActiveFacts::Metamodel::RingConstraint
            dump_ring_constraint(c)
          when ActiveFacts::Metamodel::SetComparisonConstraint # includes SetExclusionConstraint, SetEqualityConstraint
            dump_set_comparison_constraint(c)
          when ActiveFacts::Metamodel::SubsetConstraint
            dump_subset_constraint(c)
          else
            "#{c.class.basename} #{c.name}: unhandled constraint type"
          end
      end
    end
  end
end
