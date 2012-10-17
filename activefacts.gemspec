# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "activefacts"
  s.version = "0.8.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Clifford Heath"]
  s.date = "2012-10-17"
  s.description = "\nActiveFacts provides a semantic modeling language, the Constellation\nQuery Language (CQL).  CQL combines natural language verbalisation and\nformal logic, producing a formal language that reads like plain\nEnglish. ActiveFacts converts semantic models from CQL to relational\nand object models in SQL, Ruby and other languages.\n"
  s.email = "cjh@dataconstellation.com"
  s.executables = ["afgen", "cql"]
  s.extensions = ["lib/activefacts/cql/Rakefile"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc",
    "TODO"
  ]
  s.files = [
    "History.txt",
    "LICENSE",
    "Manifest.txt",
    "README.rdoc",
    "Rakefile",
    "bin/afgen",
    "bin/cql",
    "css/offline.css",
    "css/orm2.css",
    "css/print.css",
    "css/style-print.css",
    "css/style.css",
    "download.html",
    "examples/CQL/Address.cql",
    "examples/CQL/Blog.cql",
    "examples/CQL/CompanyDirectorEmployee.cql",
    "examples/CQL/Death.cql",
    "examples/CQL/Diplomacy.cql",
    "examples/CQL/Genealogy.cql",
    "examples/CQL/Insurance.cql",
    "examples/CQL/JoinEquality.cql",
    "examples/CQL/Marriage.cql",
    "examples/CQL/Metamodel.cql",
    "examples/CQL/Monogamy.cql",
    "examples/CQL/MonthInSeason.cql",
    "examples/CQL/Moon.cql",
    "examples/CQL/MultiInheritance.cql",
    "examples/CQL/NonRoleId.cql",
    "examples/CQL/OddIdentifier.cql",
    "examples/CQL/OilSupply.cql",
    "examples/CQL/OneToOnes.cql",
    "examples/CQL/Orienteering.cql",
    "examples/CQL/PersonPlaysGame.cql",
    "examples/CQL/RedundantDependency.cql",
    "examples/CQL/SchoolActivities.cql",
    "examples/CQL/SeparateSubtype.cql",
    "examples/CQL/ServiceDirector.cql",
    "examples/CQL/SimplestUnary.cql",
    "examples/CQL/SubtypePI.cql",
    "examples/CQL/Supervision.cql",
    "examples/CQL/Tests.Test5.Load.cql",
    "examples/CQL/WaiterTips.cql",
    "examples/CQL/Warehousing.cql",
    "examples/CQL/WindowInRoomInBldg.cql",
    "examples/CQL/unit.cql",
    "examples/index.html",
    "examples/intro.html",
    "examples/local.css",
    "index.html",
    "lib/activefacts.rb",
    "lib/activefacts/cql.rb",
    "lib/activefacts/cql/CQLParser.treetop",
    "lib/activefacts/cql/Context.treetop",
    "lib/activefacts/cql/Expressions.treetop",
    "lib/activefacts/cql/FactTypes.treetop",
    "lib/activefacts/cql/Language/English.treetop",
    "lib/activefacts/cql/LexicalRules.treetop",
    "lib/activefacts/cql/ObjectTypes.treetop",
    "lib/activefacts/cql/Rakefile",
    "lib/activefacts/cql/Terms.treetop",
    "lib/activefacts/cql/ValueTypes.treetop",
    "lib/activefacts/cql/compiler.rb",
    "lib/activefacts/cql/compiler/clause.rb",
    "lib/activefacts/cql/compiler/constraint.rb",
    "lib/activefacts/cql/compiler/entity_type.rb",
    "lib/activefacts/cql/compiler/expression.rb",
    "lib/activefacts/cql/compiler/fact.rb",
    "lib/activefacts/cql/compiler/fact_type.rb",
    "lib/activefacts/cql/compiler/join.rb",
    "lib/activefacts/cql/compiler/shared.rb",
    "lib/activefacts/cql/compiler/value_type.rb",
    "lib/activefacts/cql/nodes.rb",
    "lib/activefacts/cql/parser.rb",
    "lib/activefacts/generate/absorption.rb",
    "lib/activefacts/generate/cql.rb",
    "lib/activefacts/generate/dm.rb",
    "lib/activefacts/generate/help.rb",
    "lib/activefacts/generate/html/glossary.rb",
    "lib/activefacts/generate/json.rb",
    "lib/activefacts/generate/null.rb",
    "lib/activefacts/generate/oo.rb",
    "lib/activefacts/generate/ordered.rb",
    "lib/activefacts/generate/records.rb",
    "lib/activefacts/generate/ruby.rb",
    "lib/activefacts/generate/sql/mysql.rb",
    "lib/activefacts/generate/sql/server.rb",
    "lib/activefacts/generate/text.rb",
    "lib/activefacts/generate/version.rb",
    "lib/activefacts/input/cql.rb",
    "lib/activefacts/input/orm.rb",
    "lib/activefacts/persistence.rb",
    "lib/activefacts/persistence/columns.rb",
    "lib/activefacts/persistence/foreignkey.rb",
    "lib/activefacts/persistence/index.rb",
    "lib/activefacts/persistence/object_type.rb",
    "lib/activefacts/persistence/reference.rb",
    "lib/activefacts/persistence/tables.rb",
    "lib/activefacts/support.rb",
    "lib/activefacts/version.rb",
    "lib/activefacts/vocabulary.rb",
    "lib/activefacts/vocabulary/extensions.rb",
    "lib/activefacts/vocabulary/metamodel.rb",
    "lib/activefacts/vocabulary/verbaliser.rb",
    "script/txt2html",
    "spec/absorption_spec.rb",
    "spec/cql/comparison_spec.rb",
    "spec/cql/context_spec.rb",
    "spec/cql/contractions_spec.rb",
    "spec/cql/deontic_spec.rb",
    "spec/cql/entity_type_spec.rb",
    "spec/cql/expressions_spec.rb",
    "spec/cql/fact_type_matching_spec.rb",
    "spec/cql/french_spec.rb",
    "spec/cql/parser/bad_literals_spec.rb",
    "spec/cql/parser/constraints_spec.rb",
    "spec/cql/parser/entity_types_spec.rb",
    "spec/cql/parser/expressions_spec.rb",
    "spec/cql/parser/fact_types_spec.rb",
    "spec/cql/parser/literals_spec.rb",
    "spec/cql/parser/pragmas_spec.rb",
    "spec/cql/parser/value_types_spec.rb",
    "spec/cql/role_matching_spec.rb",
    "spec/cql/samples_spec.rb",
    "spec/cql_cql_spec.rb",
    "spec/cql_dm_spec.rb",
    "spec/cql_mysql_spec.rb",
    "spec/cql_parse_spec.rb",
    "spec/cql_ruby_spec.rb",
    "spec/cql_sql_spec.rb",
    "spec/cql_symbol_tables_spec.rb",
    "spec/cqldump_spec.rb",
    "spec/helpers/array_matcher.rb",
    "spec/helpers/ctrl_c_support.rb",
    "spec/helpers/diff_matcher.rb",
    "spec/helpers/file_matcher.rb",
    "spec/helpers/parse_to_ast_matcher.rb",
    "spec/helpers/string_matcher.rb",
    "spec/helpers/test_parser.rb",
    "spec/norma_cql_spec.rb",
    "spec/norma_ruby_spec.rb",
    "spec/norma_ruby_sql_spec.rb",
    "spec/norma_sql_spec.rb",
    "spec/norma_tables_spec.rb",
    "spec/ruby_api_spec.rb",
    "spec/spec_helper.rb",
    "status.html",
    "why.html"
  ]
  s.homepage = "http://github.com/cjheath/activefacts"
  s.licenses = ["MIT"]
  s.post_install_message = "For more information on ActiveFacts, see http://dataconstellation.com/ActiveFacts"
  s.rdoc_options = ["-S", "-x", "lib/activefacts/cql/.*.rb", "-x", "lib/activefacts/vocabulary/.*.rb"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "A semantic modeling and query language (CQL) and application runtime (the Constellation API)"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activefacts-api>, ["~> 0.9.1"])
      s.add_runtime_dependency(%q<treetop>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<activefacts-api>, ["~> 0.9.1"])
      s.add_runtime_dependency(%q<treetop>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rdoc>, [">= 2.4.2"])
    else
      s.add_dependency(%q<activefacts-api>, ["~> 0.9.1"])
      s.add_dependency(%q<treetop>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<activefacts-api>, ["~> 0.9.1"])
      s.add_dependency(%q<treetop>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rdoc>, [">= 2.4.2"])
    end
  else
    s.add_dependency(%q<activefacts-api>, ["~> 0.9.1"])
    s.add_dependency(%q<treetop>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<activefacts-api>, ["~> 0.9.1"])
    s.add_dependency(%q<treetop>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rdoc>, [">= 2.4.2"])
  end
end

