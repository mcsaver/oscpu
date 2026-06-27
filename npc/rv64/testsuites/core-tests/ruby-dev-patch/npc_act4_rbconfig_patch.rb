require "rbconfig"

root = ENV["NPC_ACT4_RUBY_DEV_ROOT"]
if root && !root.empty?
  include_base = File.join(root, "usr/include/ruby-3.2.0")
  include_arch = File.join(root, "usr/include/x86_64-linux-gnu/ruby-3.2.0")
  libdir = File.join(root, "usr/lib/x86_64-linux-gnu")
  ruby_so_name = RbConfig::CONFIG["RUBY_SO_NAME"] || "ruby-3.2"

  {
    "rubyhdrdir" => include_base,
    "rubyarchhdrdir" => include_arch,
    "libdir" => libdir,
    "topdir" => libdir,
    "LIBRUBYARG" => "-L#{libdir} -l#{ruby_so_name}",
    "LIBRUBYARG_SHARED" => "-L#{libdir} -l#{ruby_so_name}",
  }.each do |key, value|
    RbConfig::CONFIG[key] = value
    RbConfig::MAKEFILE_CONFIG[key] = value
  end
end
