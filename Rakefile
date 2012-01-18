require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "centroider"
  gem.homepage = "http://github.com/princelab/centroider"
  gem.license = "MIT"
  gem.summary = %Q{centroids profile spectra (typically for mass spectrometry data)}
  gem.description = %Q{centroids profile spectra (typically for mass spectrometry data). }
  gem.email = "jtprince@gmail.com"
  gem.authors = ["Jamison Dance, John T. Prince"]
  gem.add_development_dependency "gsl", "~> 1"
  gem.add_development_dependency "rspec", "~> 2.6"
  gem.add_development_dependency "jeweler", "~> 1.5.2"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |spec|
  spec.libs << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "msplat #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
