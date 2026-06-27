# -*- encoding: utf-8 -*-
# stub: idlc 0.1.5 ruby lib

Gem::Specification.new do |s|
  s.name = "idlc".freeze
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/riscv/riscv-unified-db/issues", "homepage_uri" => "https://github.com/riscv/riscv-unified-db", "mailing_list_uri" => "https://lists.riscv.org/g/tech-unifieddb" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Derek Hower".freeze]
  s.date = "2026-05-19"
  s.description = "Compiler binary and Ruby libraries for compiling IDL code.\n\nPart of the RISC-V Unified Database project\n".freeze
  s.email = ["dhower@qti.qualcomm.com".freeze]
  s.executables = ["idlc".freeze]
  s.files = ["bin/idlc".freeze]
  s.homepage = "https://github.com/riscv/riscv-unified-db".freeze
  s.licenses = ["BSD-3-Clause-Clear".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 3.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "ISA Description Language Compiler".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<commander>.freeze, ["~> 5"])
  s.add_runtime_dependency(%q<pp>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<sorbet-runtime>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<treetop>.freeze, ["= 1.6.12"])
  s.add_runtime_dependency(%q<tty-progressbar>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rdbg>.freeze, [">= 0"])
  s.add_development_dependency(%q<rouge>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-github>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-sorbet>.freeze, [">= 0"])
  s.add_development_dependency(%q<ruby-lsp>.freeze, [">= 0"])
  s.add_development_dependency(%q<ruby-prof>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov-cobertura>.freeze, [">= 0"])
  s.add_development_dependency(%q<sorbet>.freeze, [">= 0"])
  s.add_development_dependency(%q<spoom>.freeze, [">= 0"])
  s.add_development_dependency(%q<tapioca>.freeze, [">= 0.17.10"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard-sorbet>.freeze, [">= 0"])
end
