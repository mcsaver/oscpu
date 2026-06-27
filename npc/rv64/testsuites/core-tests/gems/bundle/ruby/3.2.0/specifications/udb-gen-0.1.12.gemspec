# -*- encoding: utf-8 -*-
# stub: udb-gen 0.1.12 ruby lib

Gem::Specification.new do |s|
  s.name = "udb-gen".freeze
  s.version = "0.1.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/riscv/riscv-unified-db/issues", "homepage_uri" => "https://github.com/riscv/riscv-unified-db", "mailing_list_uri" => "https://lists.riscv.org/g/tech-unifieddb" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Derek Hower".freeze]
  s.date = "2026-05-19"
  s.description = "A tool to generate artifacts using UDB data\n".freeze
  s.email = ["dhower@qti.qualcomm.com".freeze]
  s.executables = ["udb-gen".freeze]
  s.files = ["bin/udb-gen".freeze]
  s.homepage = "https://github.com/riscv/riscv-unified-db".freeze
  s.licenses = ["BSD-3-Clause-Clear".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 3.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Command line interface for UDB-based generators".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<asciidoctor>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<asciidoctor-diagram>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<asciidoctor-pdf>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<sorbet-runtime>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tty-exit>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tty-option>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tty-progressbar>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tty-table>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<udb>.freeze, ["= 0.1.13"])
  s.add_runtime_dependency(%q<write_xlsx>.freeze, [">= 0"])
  s.add_development_dependency(%q<sorbet>.freeze, [">= 0"])
  s.add_development_dependency(%q<tapioca>.freeze, [">= 0.17.10"])
end
