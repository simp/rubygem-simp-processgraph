# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

describe "testing input only to process graph" do

  testclass = SimpProcessGraph_i4.new("testinput")
  testclass.create_dot
  
  it "created given input file" do
     expect(File).to exist("testinput")
  end
  it "created given sorted file" do
     expect(File).to exist("testinput.sorted")
  end
  it "created dot file from input name" do
     expect(File).to exist("testinput.dot")
  end

  it "created png file from input name" do
     expect(File).to exist("testinput.png")
  end

end


