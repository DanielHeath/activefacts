module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Fact < Definition
        def initialize readings, population_name = ''
          @readings = readings
          @population_name = population_name
        end

        def compile
          @population = @constellation.Population(@vocabulary, @population_name)

          @context = CompilationContext.new(@vocabulary)
          @readings.each{ |reading| reading.identify_players_with_role_name(@context) }
          @readings.each{ |reading| reading.identify_other_players(@context) }
          @readings.each{ |reading| reading.bind_roles @context }

          # Figure out the simple existential facts and find fact types:
          @bound_instances = {}  # Instances indexed by binding
          @bound_fact_types = []
          @unbound_readings = @readings.
            map do |reading|
              bind_literal_or_fact_type reading
            end.
            compact

          # Because the fact types may include forward references, we must
          # process the list repeatedly until we make no further progress.
          @pass = 0 # Repeat until we make no more progress:
          true while bind_more_facts

          # Any remaining unbound facts are a problem we can bitch about:
          complain_incomplete unless @unbound_readings.empty?
        end

        def bind_literal_or_fact_type reading
          # Every bound word (term) in the phrases must have a literal
          # OR be bound to an entity type identified by the phrases

          # Any clause that has one binding and no other word is
          # either a value instance or a simply-identified entity.
          reading.role_refs.map do |role_ref|
            next role_ref unless l = role_ref.literal
            player = role_ref.binding.player
            debug :instance, "Making #{player.class.basename} #{player.name} using #{l.inspect}" do
              @bound_instances[role_ref.binding] =
                instance_identified_by_literal player, l
            end
            role_ref
          end

          if reading.phrases.size == 1 && (role_ref = reading.phrases[0]).is_a?(Compiler::RoleRef)
            # This is an existential fact (like "Name 'foo'", or "Company 'Microsoft'")
            # @bound_instances[role_ref.binding]
            nil # Nothing to see here, move along
          else
            @bound_fact_types << reading.match_existing_fact_type(@context)
            reading
          end
        end

        def bind_more_facts
          @pass += 1

          progress = false
          debug :instance, "Pass #{@pass}" do
            @unbound_readings.map! do |reading|
              # See if we can create the fact instance yet

              bare_roles = reading.role_refs.
                select do |role_ref|
                  !role_ref.literal && !@bound_instances[role_ref.binding]
                end
              # REVISIT: Bare bindings might be bound to instances we created

              debug :instance, "Considering '#{reading.fact_type.preferred_reading.expand}' with bare roles: #{bare_roles.map{|role_ref| role_ref.player.name}*", "} "

              case
              when bare_roles.size == 0
                debug :instance, "All bindings in '#{reading.fact_type.preferred_reading.expand}' contain instances; create the fact type"
                instances = reading.role_refs.map{|rr| @bound_instances[rr.binding]}
                debug :instance, "Instances are #{instances.map{|i| "#{i.concept.name} #{i.value.inspect}"}*", "}"

                # Check that this fact doesn't already exist
                fact = reading.fact_type.all_fact.detect{|f|
                  # Get the role values of this fact in the order of the reading we just bound
                  role_values_in_reading_order = f.all_role_value.sort_by do |rv|
                    reading.reading.role_sequence.all_role_ref.detect{|rr| rr.role == rv.role}.ordinal
                  end
                  # If all this fact's role values are played by the bound instances, it's the same fact
                  !role_values_in_reading_order.zip(instances).detect{|rv, i| rv.instance != i }
                }
                unless fact
                  fact = @constellation.Fact(:new, :fact_type => reading.fact_type, :population => @population)
                  @constellation.Instance(:new, :concept => reading.fact_type.entity_type, :fact => fact, :population => @population)
                  reading.reading.role_sequence.all_role_ref.zip(instances).each do |rr, instance|
                    debug :instance, "New fact has #{instance.concept.name} role #{instance.value.inspect}"
                    @constellation.RoleValue(:fact => fact, :instance => instance, :role => rr.role, :population => @population)
                  end
                else
                  debug :instance, "Found existing fact type instance"
                end
                progress = true
                next  # Done with this reading

              # If we have one bare role (no literal or instance) played by an entity type,
              # and the bound fact type participates in the identifier, we might now be able
              # to create the entity instance.
              when bare_roles.size == 1 &&
                (binding = bare_roles[0].binding) &&
                (e = binding.player).is_a?(ActiveFacts::Metamodel::EntityType) &&
                e.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type == reading.fact_type}

                # Check this instance doesn't already exist already:
                identifying_binding = (reading.role_refs.map{|rr| rr.binding}-[binding])[0]
                identifying_instance = @bound_instances[identifying_binding]

                debug :instance, "This clause associates a new #{binding.player.name} with a #{identifying_binding.player.name}#{identifying_instance ? " which exists" : ""}"

                identifying_role_ref = e.preferred_identifier.role_sequence.all_role_ref.detect { |rr|
                    rr.role.fact_type == reading.fact_type && rr.role.concept == identifying_binding.player
                  }
                unless identifying_role_ref
                  debug :instance, "Failed to find a #{identifying_instance.concept.name}"
                  next reading # We can't do this yet
                end
                role_value = identifying_instance.all_role_value.detect do |rv|
                  rv.fact.fact_type == identifying_role_ref.role.fact_type
                end
                if role_value
                  instance = (role_value.fact.all_role_value.to_a-[role_value])[0].instance
                  debug :instance, "Found existing instance (of #{instance.concept.name}) from a previous definition"
                  @bound_instances[binding] = instance
                  next  # Done with this reading
                end

                pi_role_refs = e.preferred_identifier.role_sequence.all_role_ref
                # For each pi role, we have to find the fact clause, which contains the binding we need.
                # Then we have to create an instance of each fact
                identifiers =
                  pi_role_refs.map do |rr|
                    fact_a = @readings.detect{|reading| rr.role.fact_type == reading.fact_type}
                    identifying_role_ref = fact_a.role_refs.select{|role_ref| role_ref.binding != binding}[0]
                    identifying_binding = identifying_role_ref ? identifying_role_ref.binding : nil
                    identifying_instance = @bound_instances[identifying_binding]

                    [rr, fact_a, identifying_binding, identifying_instance]
                  end
                if identifiers.detect{ |i| !i[3] }  # Not all required facts are bound yet
                  debug :instance, "Can't go through with creating #{binding.player.name}; not all the facts are in"
                  next reading
                end

                debug :instance, "Going ahead with creating #{binding.player.name} using #{identifiers.size} roles"
                instance = @constellation.Instance(:new, :concept => e, :population => @population)
                @bound_instances[binding] = instance
                identifiers.each do |rr, fact_a, identifying_binding, identifying_instance|
                  # This reading provides the identifying literal for the EntityType e
                  id_fact = @constellation.Fact(:new, :fact_type => rr.role.fact_type, :population => @population)
                  role = (rr.role.fact_type.all_role.to_a-[rr.role])[0]
                  @constellation.RoleValue(:instance => instance, :fact => id_fact, :population => @population, :role => role)
                  @constellation.RoleValue(:instance => identifying_instance, :fact => id_fact, :role => rr.role, :population => @population)
                  true
                end

                next  # Done with this reading
              end
              reading
            end # each unbound reading
            @unbound_readings.compact!
          end # debug
          progress
        end

        def instance_identified_by_literal concept, literal
          if concept.is_a?(ActiveFacts::Metamodel::EntityType)
            entity_identified_by_literal concept, literal
          else
            debug :instance, "Making ValueType #{concept.name} #{literal.inspect} #{@population.name.size>0 ? " in "+@population.name.inspect : ''}" do

              is_a_string = String === literal
              instance = @constellation.Instance.detect do |key, i|
                  # REVISIT: And same unit
                  i.population == @population &&
                    i.value &&
                    i.value.literal == literal &&
                    i.value.is_a_string == is_a_string
                end
              #instance = concept.all_instance.detect { |instance|
              #  instance.population == @population && instance.value == literal
              #}
              debug :instance, "This #{concept.name} value already exists" if instance
              unless instance
                instance = @constellation.Instance(
                    :new,
                    :concept => concept,
                    :population => @population,
                    :value => [literal.to_s, is_a_string, nil]
                  )
              end
              instance
            end
          end
        end

        def entity_identified_by_literal concept, literal
          # A literal that identifies an entity type means the entity type has only one identifying role
          # That role is played either by a value type, or by another similarly single-identified entity type
          debug "Making EntityType #{concept.name} identified by '#{literal}' #{@population.name.size>0 ? " in "+@population.name.inspect : ''}" do
            identifying_role_refs = concept.preferred_identifier.role_sequence.all_role_ref
            raise "Single literal cannot satisfy multiple identifying roles for #{concept.name}" if identifying_role_refs.size > 1
            role = identifying_role_refs.single.role
            identifying_instance = instance_identified_by_literal role.concept, literal
            existing_instance = nil
            instance_rv = identifying_instance.all_role_value.detect { |rv|
              next false unless rv.population == @population         # Not this population
              next false unless rv.fact.fact_type == role.fact_type # Not this fact type
              other_role_value = (rv.fact.all_role_value-[rv])[0]
              existing_instance = other_role_value.instance
              other_role_value.instance.concept == concept          # Is it this concept?
            }
            if instance_rv
              instance = existing_instance
              debug :instance, "This #{concept.name} entity already exists"
            else
              fact = @constellation.Fact(:new, :fact_type => role.fact_type, :population => @population)
              instance = @constellation.Instance(:new, :concept => concept, :population => @population)
              # The identifying fact type has two roles; create both role instances:
              @constellation.RoleValue(:instance => identifying_instance, :fact => fact, :population => @population, :role => role)
              @constellation.RoleValue(:instance => instance, :fact => fact, :population => @population, :role => (role.fact_type.all_role-[role])[0])
            end
            instance
          end
        end

        def complain_incomplete
          return
          raise "REVISIT: old code, not fixed"
          incomplete = @bound_fact_types.select{|ft| !ft.is_a?(ActiveFacts::Metamodel::Instance) && !ft.is_a?(ActiveFacts::Metamodel::Fact)}
          if incomplete.size > 0
            # Provide a readable description of the problem here, by showing each binding with no instance
            missing_bindings = incomplete.map do |f|
              phrases = f[0]
              phrases.select{|p|
                p.is_a?(Hash) and binding = p[:binding] and !@bound_instances[binding]
              }.map{|phrase| phrase[:binding]}
            end.flatten.uniq
            raise "Not enough facts are given to identify #{
                missing_bindings.map do |b|
                  [ b.leading_adjective, b.concept.name, b.trailing_adjective ].compact*" " +
                  " (need #{b.concept.preferred_identifier.role_sequence.all_role_ref.map do |rr|
                      [ rr.leading_adjective, rr.role.role_name || rr.role.concept.name, rr.trailing_adjective ].compact*" "
                    end*", "
                  })"
                end*", "
              }"
          end
        end

      end
    end
  end
end