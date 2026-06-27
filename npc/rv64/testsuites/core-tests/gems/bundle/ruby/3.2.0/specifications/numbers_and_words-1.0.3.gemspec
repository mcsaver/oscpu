# -*- encoding: utf-8 -*-
# stub: numbers_and_words 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "numbers_and_words".freeze
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kirill Lazarev".freeze]
  s.date = "1980-01-02"
  s.description = "This gem spells out numbers in several languages using the I18n gem.".freeze
  s.email = "k.s.lazarev@gmail.com".freeze
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.rdoc".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/kslazarev/numbers_and_words".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Spell out numbers in several languages".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<i18n>.freeze, ["<= 2"])
  s.add_development_dependency(%q<jeweler>.freeze, ["~> 2"])
  s.add_development_dependency(%q<ostruct>.freeze, ["~> 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12"])
end
