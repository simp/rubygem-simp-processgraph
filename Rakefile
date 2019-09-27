# -*- ruby -*-

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

desc 'help'
task :help do
  sh 'rake -T'
end

RSpec::Core::RakeTask.new(:spec)

#desc 'Ensure gemspec-safe permissions on all files'
#task :chmod do
#  gemspec = File.expand_path( "#{@package}.gemspec", @rakefile_dir ).strip
#  spec = Gem::Specification::load( gemspec )
#  spec.files.each do |file|
#    FileUtils.chmod 'go=r', file
#  end
#end

namespace :pkg do
  desc "build rubygem package for #{@package}"
  task :gem do
    Dir.chdir @rakefile_dir
    Dir['*.gemspec'].each do |spec_file|
      cmd = %Q{SIMP_RPM_BUILD=1 gem build "#{spec_file}"}
      sh cmd
      FileUtils.mkdir_p 'dist'
      FileUtils.mv Dir.glob("#{@package}*.gem"), 'dist/'
    end
  end

  desc "build and install rubygem package for #{@package}"
  task :install_gem => [:clean, :gem] do
    Dir.chdir @rakefile_dir
    Dir.glob("dist/#{@package}*.gem") do |pkg|
      sh %Q{gem install #{pkg}}
    end
  end
end

# vim: syntax=ruby
