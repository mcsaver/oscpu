# -*- encoding: utf-8 -*-
# stub: udb 0.1.13 ruby lib
# stub: ext/udb_download/extconf.rb

Gem::Specification.new do |s|
  s.name = "udb".freeze
  s.version = "0.1.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/riscv/riscv-unified-db/issues", "homepage_uri" => "https://github.com/riscv/riscv-unified-db", "mailing_list_uri" => "https://lists.riscv.org/g/tech-unifieddb" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Derek Hower".freeze, "James Ball".freeze]
  s.date = "2026-05-19"
  s.description = "A Ruby interface to the data in the RISC-V Unified Database.\nContains object models for the data and common functions to\nextract information.\n".freeze
  s.email = ["dhower@qti.qualcomm.com".freeze, "jamesball@qti.qualcomm.com".freeze]
  s.executables = ["udb".freeze]
  s.extensions = ["ext/udb_download/extconf.rb".freeze]
  s.files = ["bin/udb".freeze, "ext/udb_download/extconf.rb".freeze]
  s.homepage = "https://github.com/riscv/riscv-unified-db".freeze
  s.licenses = ["BSD-3-Clause-Clear".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 3.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Interface to the RISC-V Unified Database".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<asciidoctor>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<awesome_print>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<idlc>.freeze, ["= 0.1.5"])
  s.add_runtime_dependency(%q<json_schemer>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<numbers_and_words>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<ostruct>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<pastel>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<sorbet-runtime>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<terminal-table>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<thor>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tilt>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tty-command>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tty-logger>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tty-progressbar>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<udb_helpers>.freeze, ["= 0.1.3"])
  s.add_runtime_dependency(%q<z3>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-github>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-sorbet>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov-cobertura>.freeze, [">= 0"])
  s.add_development_dependency(%q<sorbet>.freeze, [">= 0"])
  s.add_development_dependency(%q<tapioca>.freeze, [">= 0.17.10"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard-sorbet>.freeze, [">= 0"])
end
