require File.expand_path("../lib/archiver/version", __FILE__)
require "rubygems"
::Gem::Specification.new do |s|
  s.name                      = "ruby-archiver"
  s.version                   = Archiver::VERSION
  s.platform                  = ::Gem::Platform::RUBY
  s.authors                   = ['Caleb Crane']
  s.email                     = ['ruby-archiver@simulacre.org']
  s.homepage                  = "http://github.com/simulacre/ruby-archiver"
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
