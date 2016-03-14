# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

home_dir = File.expand_path('~')
$test_dir = home_dir+'/ssfiles'
$sample_file = 'spec/fixtures/sample.ss'
if File.directory?($test_dir) then
  if !File.exist?($test_dir+'/*.ss')
     FileUtils.cp($sample_file, $test_dir)
  end
else
  puts "created directory, copied in #{$sample_file}"
  FileUtils.mkdir($test_dir)
  FileUtils.cp($sample_file, $test_dir)
end


describe "testing input directory to process graph" do
# create a temp dir for output
  theGraph = ProcessList.new($test_dir, "testdir")
  theGraph.processData($test_dir, "testdir", "test domain")

  it "created dot file from input directory name [testdir]" do
    expect(File).to exist("testdir.dot")
  end

  it "created png file from input directory name[testdir]" do
   expect(File).to exist("testdir.png")
  end

end

