!#/usr/bin/env ruby
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
    @infile = infile 
    @outfile = outfile 
end

def create_dot

$inputfile = @infile
$outputfile = @outfile

$boxes = Array.new {Hash.new}
$colors = Array['yellow','green','orange','violet', 'turquoise', 'gray','brown']
$infiles = Array.new

# get the list of processes to a file
infile = 'i4_processes'
$filetype = 'none'

# check to see if we input a file
if $inputfile == nil 
  $inputfile = infile
end
if File.directory?$inputfile then
  $filetype = 'dir'
elsif File.file?$inputfile
  $filetype = 'file'
else
 infile = $inputfile
 $filetype = 'none'
end

# output file
if $outputfile == nil then
  $outputfile = $inputfile
end
# puts "inputfile #{$inputfile}, outputfile #{$outputfile}"

# this lsof command lists files using ipv4 to a file
# comment out for a test file
if $filetype == 'none'
  system ("lsof -i4 -n > #{infile}")
  $filetype = 'file'
end

# puts "input file type is #{$filetype} and name is #{$inputfile}"
# puts "output file is #{$outputfile}"
if $filetype == 'dir' then
  Dir.foreach($inputfile) do |infile|
#    next if infile == '.' or infile == '..'
    if infile.end_with?('lsof') then
      $infiles << $inputfile+'/'+infile
    end
  end
# got through - check to ensure we got a file
  if $infiles.size == 0
     puts "no files found"
  end
  $inputfile = infile+"_dir"
  if $outputfile == nil then
    $outputfile = $inputfile
  end
else
  $infiles << $inputfile
end
# get rid of any far away directories for our output files
$outputfile = File.basename($outputfile)    

# puts "list of files we are treating:  #{$infiles}"
# puts "inputfile #{$inputfile}, outputfile #{$outputfile}"

# read each input file in the directory
$infiles.each do |infile|
# puts "processing #{infile}"

# read the file, one line at a time
IO.foreach(infile) do |line|
  # create a hash for all the significant info 
  $procrow = Hash.new
  f1 = line.split(' ')
  # now get process, owner and name
  $procrow["proc_id"] = f1[1]
  $procrow["owner"] = f1[2]
  $procrow["procname"] = f1[0]   # process name   
  $wholefilename = f1[8]  # file
   begin
   f2 = $wholefilename.split(':')
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
#       puts "reading header line"
     end
     port = 0
     file = 0
     hoststring = "NOHOSTNAME" 
   end
   $procrow["portno"] = port
   $procrow["filename"] = file
   $procrow["hostname"] = hoststring

# puts "port #{port}, file #{file}, hoststring #{hoststring}"
# write to array (but blow off the headers)
   if (hoststring != "NOHOSTNAME") then
     $boxes << $procrow
   end
end                       # end reading file

end # end array of files

# prepare an output file to save the hashes for now (this file is a just-in-case)
# outfilename = $inputfile+".sorted"  # write to a file
# get the filename in present working dir
outfilename = File.basename($inputfile)+".sorted"  # write to a file
outfile = File.open(outfilename, 'w')

# write it out to file
$boxes.each do |hash|
  outfile.puts hash
end                             # each row of array
outfile.close

# make hash of user/process combos and of files (which is really just destination IPs when you run -i4) and of hosts (source IP)
$userprocess = Array.new
$files = Array.new
$hosts = Array.new
$owners = Array.new
$counter = 0

# for each box (row in the output)
$boxes.each do |row|
  # create entry to ensure we have a distinct host/row/process combination - those will be the smallest boxes
  $entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
  # first entry is always 
  if ($counter == 0) then
    $userprocess << $entry
    $hosts << row["hostname"]
    $owners << row["owner"]
    $files << row["filename"]
  else
    # if the other fields are not yet in the arrays, add them -- each array should contain one copy of each 
    if (!$userprocess.include?$entry) then
      $userprocess <<  $entry
    end
    if (!$hosts.include?(row["hostname"])) then
      $hosts << row["hostname"]
    end
    if (!$files.include?(row["filename"])) then
      $files << row["filename"]
    end
    if (!$owners.include?(row["owner"])) then
      $owners << row["owner"]
    end
  end   # if first entry
  $counter += 1
end  #each box

# do graph
gv = Gviz.new 
gv.graph do
# rank TB makes the graph go from top to bottom - works better right now with the CentOS version
# rank LR draws left to right which is easier to read
  global :rankdir => 'LR'
# global :rankdir => 'TB'

# now set up subgraphs for the sources
  $uprows = Array.new($boxes.size) 
  $upno = 0
  $hostcount = 0
  $hosts.each do |ho|
  $thishost = ho.to_s
  subgraph do  # big - for each host
    global :color => 'black', :label => "#{ho}"
    nodes :style => 'filled', :shape => 'point'
    $upno += 1
    node :"p#{$hostcount}"

#   for each distinct user/process combo add a subgraph, then for matching rows add a node in that subgraph
    $filerows = Array.new($boxes.size)
    $userprocess.each do |up|
      subgraph do
        nodes :style => 'filled', :shape => 'box'
        global :color => 'red', :label => "#{up}"
        $upno +=1
        $rowno = 0
        $boxes.each do |row|
          $entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
          $myhost = row["hostname"].to_s
          if ($entry == up) && ($myhost == $thishost) then
            node :"#{$upno}", label:"#{row["portno"]}"
            $uprows[$rowno] = $upno
            $upno += 1
          end  # if  it is a match for its big box   
          $rowno += 1
        end  # each row in array of all comms
      end #subgraph for up
    end # userprocs
  end # end of big subgraph
$hostcount += 1
end  # end of host loop

# now the filenames on the other side 
$files.each do |fi|
subgraph do
  nodes :style => 'filled', :shape => 'point'
  global :color => 'blue', :label => "#{fi}"
  $upno += 1
  $rowno = 0
  $boxes.each do |row| 
   if (row["filename"] == fi) && ($hosts.include?(fi)) then
      hostindex = $hosts.index(fi)
      $filerows[$rowno] = "p#{hostindex}"
   elsif (row["filename"] == fi) then
      node :"#{$upno}", label:"#{row["filename"]}"
      $filerows[$rowno] = $upno
      $upno += 1
    end # if match
    $rowno += 1
  end # each row in array of all comms
end # filename
end  # each file


# for each row, link the process to the file
# alternate colors among the ones we named up top -- we can experiment with this scheme
if ($boxes.count > 0) then
  for count in 0 .. $boxes.count-1
     if ($uprows[count] != nil && $filerows[count] != nil) then
       colorcode =  count.modulo($colors.size)
       edge :"#{$uprows[count]}_#{$filerows[count]}", :color => $colors[colorcode]
     end    # if neither end is nil
  end       # for each line
end         #if there is data

end #gv

# is there any data in here?
if ($boxes.count <= 0) then 
  puts "No processes to plot. Graph will be empty"
end
gv.save(:"#{$outputfile}", :png)

end #create_dot
end # class

class SimpProcessGraph
##### instantiate
# get the command line parameters
options = {}
$inpfile = nil
$outfile = nil
OptionParser.new do |opts|
  opts.banner = "Usage: ruby simp_processgraph.rb [options]" 
  opts.on('-h', '--help', 'Help') do
    puts opts
    exit
  end
  opts.on('-i', '--input filename NAME', 'Input file or directory name') do
    |s| puts "input filename is #{s}"
    $inpfile = s
  end

  out_msg =  'Output file or directory name (will look for files in the directory named *.lsof'
  opts.on('-o', '--output file NAME', out_msg) do
    |s| puts "outfile is #{s}"
    $outfile = s
  end
end.parse!
mygraph = SimpProcessGraph_i4.new($inpfile, $outfile)
mygraph.create_dot
end



# YAY


