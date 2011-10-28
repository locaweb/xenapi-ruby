# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "xenapi/version"

Gem::Specification.new do |s|
  s.name        = "xenapi-ruby"
  s.version     = XenAPI::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["fabiokung"]
  s.email       = ["fabio.kung@gmail.com"]
  s.homepage    = "http://www.locaweb.com.br"
  s.description = %Q{A simple gem to deal with Xen API}
  s.summary     = s.description

  s.files         = Dir["./**/*"].reject {|file| file =~ /\.git|pkg/}
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "ruby-debug19"
end
