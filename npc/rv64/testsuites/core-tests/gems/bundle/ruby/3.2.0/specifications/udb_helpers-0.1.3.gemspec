# -*- encoding: utf-8 -*-
# stub: udb_helpers 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "udb_helpers".freeze
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/riscv/riscv-unified-db/issues", "homepage_uri" => "https://github.com/riscv/riscv-unified-db", "mailing_list_uri" => "https://lists.riscv.org/g/tech-unifieddb" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Derek Hower".freeze, "James Ball".freeze, "Afonso Olivera".freeze]
  s.date = "2026-04-13"
  s.description = "Various utilities to help with generating artifacts from UDB.\n".freeze
  s.email = ["dhower@qti.qualcomm.com".freeze, "jamesball@qti.qualcomm.com".freeze, "Afonso.Oliveira@synopsys.com".freeze]
  s.homepage = "https://github.com/riscv/riscv-unified-db".freeze
  s.licenses = ["BSD-3-Clause-Clear".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 3.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Misc helpers for UDB generators".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
