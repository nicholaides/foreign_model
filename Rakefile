require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "foreign_model"
    gem.summary = %Q{ActiveRecord-like associations that work between models of different databases and database types.}
    gem.description = %Q{Works for ActiveRecord and Mongoid}
    gem.email = "mike@ablegray.com"
    gem.homepage = "http://github.com/nicholaides/foreign_model"
    gem.authors = ["Mike Nicholaides"]
    gem.add_development_dependency "spec", ">= 1.3.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "foreign_model #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
