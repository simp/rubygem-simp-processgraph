# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

  home_dir = File.expand_path('~')
  # puts "home dir is #{home_dir}"
  $test_dir = home_dir+'/lsoffiles'
  $sample_file = 'spec/fixtures/sample.lsof'
  # puts "test dir is #{$test_dir}"
  if File.directory?($test_dir) then
    if !File.exist?($test_dir+'/*.lsof')
       FileUtils.cp($sample_file, $test_dir)
    end
  else
    puts "created directory, copied in #{$sample_file}"
    FileUtils.mkdir($test_dir)
    FileUtils.cp($sample_file, $test_dir) 
  end


describe "testing input directory to process graph" do
# create a temp dir for output
  testclass = SimpProcessGraph_i4.new($test_dir, "new_testout")
  testclass.create_dot
  
  it "created dot file from input directory name" do
     expect(File).to exist("new_testout.dot")
  end

  it "created png file from input directory name" do
     expect(File).to exist("new_testout.png")
  end

end


