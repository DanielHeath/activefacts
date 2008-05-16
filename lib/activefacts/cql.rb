#
# ActiveFacts CQL loader.
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'polyglot'
require 'activefacts/cql/parser'
require 'activefacts/generate/ruby'

module ActiveFacts
  # Extend the generated parser:
  class CQLLoader
    # The load method required by Polyglot.
    # The meaning of load will probably be to parse the file, and
    # generate and eval Ruby source code for the implied modules.
    def self.load(file)
      debug "Loading #{file}" do
        parser = ActiveFacts::CQLParser.new

        result = nil
        File.open(file) do |f|
          result = parser.parse_all(input = f.read, :definition) { |node|
              parser.definition(node)
              nil
            }
          raise parser.failure_reason unless result
        end

        # REVISIT: Nothing is done with results (the loaded parse tree) yet
        # The parser will produce a vocabulary, which will be generated into
        # Ruby code and eval'ed.
      end
    end
  end

  Polyglot.register('cql', CQLLoader)
end
