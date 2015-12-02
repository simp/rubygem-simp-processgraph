#!/usr/bin/env ruby
require 'optparse'
require 'gviz'
require 'socket'

#######################
#
# simp-processgraph.rb
#
# This requires
# $yum install ruby
# $yum install 'graphviz*'
# $gem install gviz
#
#######################
class SimpProcessGraph_i4
  attr_accessor :infile, :outfile

  def initialize(infile = nil,outfile = nil)
    @infile  = infile
    @outfile = outfile
  end

  def create_dot
    @input_file  = @infile
    @output_file = @outfile
    boxes        = []
    colors       = ['yellow','green','orange','violet', 'turquoise', 'gray','brown']
    @in_files    = []

    # get the list of processes to a file
    infile    = 'i4_processes'
    file_type = 'none'

    # check to see if we input a file
    if @input_file == nil
      @input_file = infile
    end
    if File.directory?@input_file then
      file_type = 'dir'
    elsif File.file?@input_file
      file_type = 'file'
    else
     infile = @input_file
     file_type = 'none'
    end

    # output file
    if @output_file == nil then
      @output_file = @input_file
    end
    # puts "inputfile #{@input_file}, outputfile #{@output_file}"

    # this lsof command lists files using ipv4 to a file
    # comment out for a test file
    if file_type == 'none'
      system ("lsof -i4 -n > #{infile}")
      file_type = 'file'
    end

    # puts "input file type is #{file_type} and name is #{@input_file}"
    # puts "output file is #{@output_file}"
    if file_type == 'dir' then
      Dir.foreach(@input_file) do |infile|
        #    next if infile == '.' or infile == '..'
        if infile.end_with?('lsof') then
          @in_files << @input_file+'/'+infile
        end
      end
      # got through - check to ensure we got a file
      if @in_files.size == 0
         puts "no files found"
      end
      @input_file = infile+"_dir"
      if @output_file == nil then
        @output_file = @input_file
      end
    else
      @in_files << @input_file
    end
    # get rid of any far away directories for our output files
    @output_file = File.basename(@output_file)

    # read each input file in the directory
    @in_files.each do |infile|
      IO.foreach(infile) do |line|
        # create a hash for all the significant info
        proc_row = {}
        f1 = line.split(' ')

        # now get process, owner and name
        proc_row["proc_id"]  = f1[1]
        proc_row["owner"]    = f1[2]
        proc_row["procname"] = f1[0] # process name
        wholefilename        = f1[8] # file
         begin
           f2 = wholefilename.split(':')
           hoststring = f2[0]
           f3 = f2[1].split("->")
           file = f3[1]
           if (file == nil)
             file = f1[9]
           end
           port = f3[0]
         rescue
           if (f1[0] != "COMMAND")
             puts "unable to parse #{line}"
           else
            # reading header line
           end
           port = 0
           file = 0
           hoststring = "NOHOSTNAME"
         end
         proc_row["portno"] = port
         proc_row["filename"] = file
         proc_row["hostname"] = hoststring

         # write to array (but blow off the headers)
         if (hoststring != "NOHOSTNAME") then
           boxes << proc_row
         end
      end # end reading file
    end   # end array of files

    # prepare an output file to save the hashes for now (this file is a just-in-case)
    # get the filename in present working dir
    outfilename = File.basename(@input_file)+".sorted"  # write to a file
    outfile = File.open(outfilename, 'w')

    # write it out to file
    boxes.each do |hash|
      outfile.puts hash
    end                             # each row of array
    outfile.close

    # make hash of user/process combos and of files (which is really just destination IPs when you run -i4) and of hosts (source IP)
    userprocess = []
    files       = []
    hosts       = []
    owners      = []
    counter = 0

    # for each box (row in the output)
    boxes.each do |row|
      # create entry to ensure we have a distinct host/row/process combination - those will be the smallest boxes
      entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
      # first entry is always
      if (counter == 0) then
        userprocess << entry
        hosts << row["hostname"]
        owners << row["owner"]
        files << row["filename"]
      else
        # if the other fields are not yet in the arrays, add them -- each array should contain one copy of each
        if (!userprocess.include?entry) then
          userprocess <<  entry
        end
        if (!hosts.include?(row["hostname"])) then
          hosts << row["hostname"]
        end
        if (!files.include?(row["filename"])) then
          files << row["filename"]
        end
        if (!owners.include?(row["owner"])) then
          owners << row["owner"]
        end
      end   # if first entry
      counter += 1
    end  #each box

    # do graph
    gv = Gviz.new
    gv.graph do
      # rankdir TB makes the graph go from top to bottom - works better right now with the CentOS version
      # rankdir LR draws left to right which is easier to read
        global :rankdir => 'LR'
      # global :rankdir => 'TB'

      # now set up subgraphs for the sources
        uprows = Array.new(boxes.size)
        upno = 0
        host_count = 0
        hosts.each do |ho|
        thishost = ho.to_s
        subgraph do  # big - for each host
          global :color => 'black', :label => "#{ho}"
          nodes :style => 'filled', :shape => 'point'
          upno += 1
          node :"p#{host_count}"

          # for each distinct user/process combo add a subgraph, then for
          # matching rows add a node in that subgraph
          userprocess.each do |up|
            subgraph do
              nodes :style => 'filled', :shape => 'box'
              global :color => 'red', :label => "#{up}"
              upno +=1
              rowno = 0
              boxes.each do |row|
                entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
                myhost = row["hostname"].to_s
                if (entry == up) && (myhost == thishost) then
                  node :"#{upno}", label:"#{row["portno"]}"
                  uprows[rowno] = upno
                  upno += 1
                end  # if  it is a match for its big box
                rowno += 1
              end  # each row in array of all comms
            end #subgraph for up
          end # userprocs
        end # end of big subgraph
        host_count += 1
      end  # end of host loop

      @@file_rows = Array.new(boxes.size)
      # now the filenames on the other side
      files.each do |file|
        subgraph do
          nodes  :style => 'filled', :shape => 'point'
          global :color => 'blue', :label => "#{file}"
          upno += 1
          rowno = 0
          boxes.each do |row|
           if (row["filename"] == file) && (hosts.include?(file)) then
              hostindex = hosts.index(file)
              @@file_rows[rowno] = "p#{hostindex}"
           elsif (row["filename"] == file) then
              node :"#{upno}", label:"#{row["filename"]}"
              @@file_rows[rowno] = upno
              upno += 1
            end # if match

            # for each row, link the process to the file
            # alternate colors among the ones we named up top -- we can
            # experiment with this scheme
            if (uprows[rowno] != nil && @@file_rows[rowno] != nil) then
              colorcode = rowno.modulo(colors.size)
              edge :"#{uprows[rowno]}_#{@@file_rows[rowno]}", :color => colors[colorcode]
            end    # if neither end is nil

            rowno += 1
          end # each row in array of all comms
        end # filename
      end  # each file
    end #gv

    # is there any data in here?
    if (boxes.count <= 0) then
      puts "No processes to plot. Graph will be empty"
    end
    gv.save(:"#{@output_file}", :png)

  end #create_dot
end # class

#####
# only make this call if you are running this file, not just requiring it
if __FILE__ == $0
  class SimpProcessGraph
    # instantiate
    # get the command line parameters
    options = {}
    inpfile = nil
    outfile = nil
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby simp_processgraph.rb [options]"
      opts.on('-h', '--help', 'Help') do
        puts opts
        exit
      end
      opts.on('-i', '--input filename NAME', 'Input file or directory name') do
        |s| puts "input filename is #{s}"
        inpfile = s
      end

      out_msg =  'Output file or directory name (will look for files in the directory named *.lsof'
      opts.on('-o', '--output file NAME', out_msg) do
        |s| puts "outfile is #{s}"
        outfile = s
      end
    end.parse!
    mygraph = SimpProcessGraph_i4.new(inpfile, outfile)
    mygraph.create_dot
  end
end
# YAY
