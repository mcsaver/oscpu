# -*- encoding: utf-8 -*-
# stub: write_xlsx 1.15.0 ruby lib

Gem::Specification.new do |s|
  s.name = "write_xlsx".freeze
  s.version = "1.15.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hideo NAKAMURA".freeze]
  s.date = "1980-01-02"
  s.description = "write_xlsx is a gem to create a new file in the Excel 2007+ XLSX format.".freeze
  s.email = ["nakamura.hideo@gmail.com".freeze]
  s.extra_rdoc_files = ["Changes".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["Changes".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/cxn03651/write_xlsx#readme".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "write_xlsx is a gem to create a new file in the Excel 2007+ XLSX format.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<nkf>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 2.4.0", "< 4.0"])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<mutex_m>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rake>.freeze, [">= 0"])
end
