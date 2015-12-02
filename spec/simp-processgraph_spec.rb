# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

describe "testing process graph with two inputs" do
  if (!Dir.exists?("tmp")) then
    FileUtils.mkdir("tmp")
  end
  testclass = SimpProcessGraph_i4.new("testin", "temp_testout")
  testclass.create_dot

  it "created input file  given in and out names" do
     expect(File).to exist("testin")
  end

  it "created sorted file  given in and out names" do
     expect(File).to exist("testin.sorted")
  end

  it "created dot file given in and out names" do
     expect(File).to exist("temp_testout.dot")
  end

  it "created png file given in and out names" do
     expect(File).to exist("temp_testout.png")
  end

end


