#
# Dump to CQL module for ActiveFacts vocabularies.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
require 'activefacts/generate/ordered'

module ActiveFacts
  class Constellation; end

  class CQLDumper < OrderedDumper
    include Metamodel

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
	  # In ActiveFacts, parameterising a ValueType will create a new datatype
	  # throw Can't handle parameterized value type of same name as its datatype" if ...
      end

      parameters =
	[ o.length != 0 || o.scale != 0 ? o.length : nil,
	  o.scale != 0 ? o.scale : nil
	].compact
      parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : "()"

		#" restricted to {#{(allowed_values.map{|r| r.inspect}*", ").gsub('"',"'")}}")

      puts "#{o.name} = #{o.supertype.name}#{ parameters }#{
	  o.value_restriction ? " restricted to {#{
	    o.value_restriction.all_allowed_range.map{|ar|
		# REVISIT: Need to display as string or numeric according to type here...
		min = ar.value_range.minimum_bound
		max = ar.value_range.maximum_bound
		(min ? min.value : "") +
		(min.value != max.value ? (".." + (max ? max.value : "")) : "")
	      }*", "
	  }}" : ""
	};"
    end

    def expand_reading(reading, frequency_constraints, define_role_names)
      expanded = "#{reading.reading_text}"
      role_refs = reading.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
      (0...role_refs.size).each{|i|
	  role_ref = role_refs[i]
	  role = role_ref.role
	  la = "#{role_ref.leading_adjective}"
	  la.sub!(/(.\b|.\Z)/, '\1-')
	  la = nil if la == ""
	  ta = "#{role_ref.trailing_adjective}"
	  ta.sub!(/(\b.|\A.)/, '-\1')
	  ta = nil if ta == ""

	  expanded.gsub!(/\{#{i}\}/) {
	      player = role_refs[i].role.concept
	      role_name = role.role_name
	      role_name = nil if role_name == ""
	      [
		presence_constraint_frequency(frequency_constraints[i]),
		la,
		!define_role_names && role_name ? role_name : player.name,
		ta,
		define_role_names && role_name && player.name != role_name ? "(as #{role_name})" : nil
	      ].compact*" "
	  }
      }
      expanded.gsub!(/ *- */, '-')	# Remove spaces around adjectives
      expanded
    end

    def presence_constraint_frequency(constraint)
      return nil unless constraint
      min = constraint.min_frequency
      max = constraint.max_frequency
      [
	  ((min && min > 0 && min != max) ? "at least #{min == 1 ? "one" : min.to_s}" : nil),
	  ((max && min != max) ? "at most #{max == 1 ? "one" : max.to_s}" : nil),
	  ((max && min == max) ? "exactly #{max == 1 ? "one" : max.to_s}" : nil)
      ].compact * " and"
    end

    def append_ring_to_reading(reading, ring)
      reading << " [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]"
    end

    def identified_by_roles_and_facts(identifying_roles, identifying_facts, preferred_readings)
      identifying_role_names = identifying_roles.map{|role|
	  preferred_role_ref = preferred_readings[role.fact_type].role_sequence.all_role_ref.detect{|reading_rr|
	      reading_rr.role == role
	    }
	  role_words = []
	  # REVISIT: Consider whether NOT to use the adjective if it's a prefix of the role_name
	  role_words << preferred_role_ref.leading_adjective if preferred_role_ref.leading_adjective != ""

	  role_name = role.role_name
	  role_name = nil if role_name == ""
	  # debug "concept.name=#{preferred_role_ref.role.concept.name}, role_name=#{role_name.inspect}, preferred_role_name=#{preferred_role_ref.role.role_name.inspect}"

	  role_words << (role_name || preferred_role_ref.role.concept.name)
	  role_words << preferred_role_ref.trailing_adjective if preferred_role_ref.trailing_adjective != ""
	  role_words.compact*"-"
	}

      # REVISIT: Consider emitting extra fact types here, instead of in entity_type_dump?
      # Just beware that readings having the same players will be considered to be of the same fact type, even if they're not.

      " identified by #{ identifying_role_names*" and " }:\n\t" +
	  identifying_facts.map{|f|
	      fact_readings_with_constraints(f)
	  }.flatten*",\n\t"
    end

    def entity_type_banner
      puts "/*\n * Entity Types\n */"
    end

    def entity_type_group_end
      puts "\n"
    end

    def subtype_dump(o, supertypes, pi)
      puts "#{o.name} = subtype of #{ o.supertypes.map(&:name)*", " }" +
	(pi ? identified_by(o, pi) : "") +
	";\n"
    end

    def non_subtype_dump(o, pi)
      puts "#{o.name} = entity" +
	identified_by(o, pi) +
	";\n"
    end

    # Dump all fact types for which all precursors (of which "o" is one) have been emitted:
    def released_fact_types_dump(o)
      roles = o.all_role
      begin
	progress = false
	roles.map(&:fact_type).uniq.select{|fact_type|
	    # The fact type hasn't already been dumped but all its role players have
	    !@fact_types_dumped[fact_type] &&
	      !fact_type.all_role.detect{|r| !@concept_types_dumped[r.concept] }
	  }.each{|fact_type|
	      fact_type_dump_with_dependents(fact_type)
	      # Objectified Fact Types may release additional fact types
	      roles += fact_type.entity_type.all_role if fact_type.entity_type
	      progress = true
	    }
      end while progress
    end

    def skip_fact_type(f)
      # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
      # These will come up as un-handled constraints:
      @fact_set_constraints_exhausted[f] ||
	TypeInheritance === f
    end

    def fact_type_dump(fact_type, name, constrained_fact_readings)
      puts((name ? name+" = " : "") +
	  constrained_fact_readings*",\n\t" +
	  ";"
	)
    end

    def fact_type_banner
      puts "/*\n * Fact Types\n */"
    end

    def fact_type_end
      puts "\n"
    end

    def constraint_banner
      puts "/*\nConstraints:"
    end

    def constraint_end
      puts " */"
    end

    def constraint_dump(c)
      puts "\tREVISIT: Verbalise #{c.class.basename} #{c.name}: " # +c.to_s
    end
  end

  def dump(vocabulary, out = $>)
    CQLDumper.new(vocabulary).dump(out)
    #out << vocabulary.constellation.verbalise + "\n"
  end
end

