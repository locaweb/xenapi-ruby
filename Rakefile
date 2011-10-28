require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "xenapi-ruby"
    gem.summary = %Q{Ruby API to control XenServers}
    gem.description = %Q{This API enables programatic management of XenServer pools for Ruby code. Commands are sended through the XML-RPC API provided by XenServer pools.}
    gem.email = "fabio.kung@gmail.com"
    gem.homepage = "http://github.com/fabiokung/xenapi-ruby"
    gem.authors = ["fabiokung"]
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "cucumber"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_opts = %w[--options spec/spec.opts]
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_opts = %w[--color --format specdoc]
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov_opts = %w[--exclude spec,lib\/spec,bin\/spec,config\/boot.rb,rcov]
  spec.rcov = true
end

task :spec => :check_dependencies

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :features => :check_dependencies
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "xenapi-ruby #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
