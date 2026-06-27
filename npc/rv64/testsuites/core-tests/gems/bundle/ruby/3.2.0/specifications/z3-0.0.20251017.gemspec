# -*- encoding: utf-8 -*-
# stub: z3 0.0.20251017 ruby lib

Gem::Specification.new do |s|
  s.name = "z3".freeze
  s.version = "0.0.20251017"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "msys2_mingw_dependencies" => "z3" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tomasz Wegrzanowski".freeze]
  s.date = "2025-10-17"
  s.description = "Ruby bindings for Z3 Constraint Solver".freeze
  s.email = "Tomasz.Wegrzanowski@gmail.com".freeze
  s.homepage = "https://github.com/taw/z3".freeze
  s.licenses = ["MIT".freeze]
  s.requirements = ["z3 library (4.8+)".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Z3 Constraint Solver".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 13"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.13"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22"])
  s.add_development_dependency(%q<regexp_parser>.freeze, ["~> 1.8"])
  s.add_development_dependency(%q<paint>.freeze, [">= 2.3.0"])
  s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.17"])
end
