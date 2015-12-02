# -*- ruby -*-

require "rubygems"
require 'rake/clean'
require 'fileutils'
require 'find'
require 'rspec/core/rake_task'

@package='simp-processgraph'
@rakefile_dir=File.dirname(__FILE__)

CLEAN.include "#{@package}-*.gem"
CLEAN.include 'pkg'
CLEAN.include 'dist'
Find.find( @rakefile_dir ) do |path|
  if File.directory? path
    CLEAN.include path if File.basename(path) == 'tmp'
  else
    Find.prune
  end
end

desc 'default - help'
task :default => [:help]
 
task :test => [:spec]
 
desc 'List all rake tasks'
task :help do
  system('rake -sT')
end


desc 'Ensure gemspec-safe permissions on all files'
task :chmod do
  gemspec = File.expand_path( "#{@package}.gemspec", @rakefile_dir ).strip
  spec = Gem::Specification::load( gemspec )
  FileUtils.chmod 'go=r', spec.files, :verbose => true
end

# From https://www.relishapp.com/rspec/rspec-core/docs/command-line/rake-task
begin
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # no rspec available
end

namespace :pkg do
  desc "build rubygem package for #{@package}"
  task :gem => :chmod do
    Dir.chdir @rakefile_dir
    Dir['*.gemspec'].each do |spec_file|
      cmd = %Q{SIMP_RPM_BUILD=1 bundle exec gem build "#{spec_file}"}
      sh cmd
      FileUtils.mkdir_p 'dist'
      FileUtils.mv Dir.glob("#{@package}*.gem"), 'dist/'
    end
  end

  desc "build and install rubygem package for #{@package}"
  task :install_gem => [:clean, :gem] do
    Dir.chdir @rakefile_dir
    Dir.glob("dist/#{@package}*.gem") do |pkg|
      sh %Q{bundle exec gem install #{pkg}}
    end
  end
end

# vim: syntax=ruby
