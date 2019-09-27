# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

describe 'testing process graph with no parms' do
  site_name = 'test_domain'
  # create a temp dir for output
  outdir = File.join('processgraph_output', site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)
  # call with nothing
  Dir.chdir(outdir) do
    the_graph = ProcessList.new
    the_graph.process_data(site_name, 0)
  end
  # ensure rawfile is created
  it 'created input file based on default [process_list]' do
    expect(File).to exist("#{outdir}/process_list.raw")
  end
  # ensure dot file is created
  it 'created dot file based on default' do
    expect(File).to exist("#{outdir}/process_list.dot")
  end
  # ensure png file created
  it 'created png file based on default' do
    expect(File).to exist("#{outdir}/process_list.png")
  end
end
