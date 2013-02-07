require File.expand_path("../lib/archiverb/version", __FILE__)
require "rubygems"
::Gem::Specification.new do |s|
  s.name                      = "archiverb"
  s.version                   = Archiverb::VERSION
  s.platform                  = ::Gem::Platform::RUBY
  s.authors                   = ['Caleb Crane']
  s.email                     = ['ruby-archiver@simulacre.org']
  s.homepage                  = "http://github.com/simulacre/archiverb"
  s.summary                   = 'Ruby implementations of various archivers'
  s.description               = ''
  s.required_rubygems_version = ">= 1.3.6"
  s.files                     = Dir["lib/**/*.rb", "bin/*", "*.md"]
  s.require_paths             = ['lib']
  s.executables               = Dir["bin/*"].map{|f| f.split("/")[-1] }
  s.license                   = 'MIT'

  # If you have C extensions, uncomment this line
  # s.extensions = "ext/extconf.rb"
  s.add_development_dependency 'rspec'
end
