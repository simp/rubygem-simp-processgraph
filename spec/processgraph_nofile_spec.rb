# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

describe "testing process graph with no parms" do

  testclass = SimpProcessGraph_i4.new()
  testclass.create_dot

  it "created input file based on default" do
     expect(File).to exist("i4_processes")
  end

  it "created sorted file based on default" do
     expect(File).to exist("i4_processes.sorted")
  end

  it "created dot file based on default" do
     expect(File).to exist("i4_processes.dot")
  end

  it "created png file based on default" do
     expect(File).to exist("i4_processes.png")
  end

end


