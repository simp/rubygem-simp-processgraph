!#/usr/bin/env ruby
require 'optparse'
require 'gv'
require 'socket'

#######################
#
# simp-processgraph.rb 
#
# This requires 
# $sudo yum install ruby 
# $sudo yum install 'graphviz*'
# $sudo yum install 'graphviz-ruby'
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

# this lsof command lists files using ipv4 to a file
# comment out for a test file
if $filetype == 'none'
  system ("lsof -i -n > #{infile}")
  $filetype = 'file'
end

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

# read each input file in the directory
$infiles.each do |infile|

# read the file, one line at a time
IO.foreach(infile) do |line|
  # create a hash for all the significant info
  $procrow = Hash.new
  f1 = line.split(' ')
  # now get process, owner and name
  proc_id = f1[1]
  owner = f1[2]
  procname = f1[0]   # process name 
  type = f1[4]
  node1 = f1[7]
  protocol = "#{type}:#{node1}"
  outproto = "#{type}:#{node1}"

  $sourcedest = f1[8]  # source->destination
   begin
     f2 = $sourcedest.split('->')
     from = f2[0]
     to = f2[1]
     f3 = from.split(':')
     hoststring = f3[0]
     port = f3[1]
     f4 = to.split(':')
     file1 = f4[0]
     outport = f4[1]
        
   rescue
     if (f1[0] != "COMMAND")
       puts "unable to parse #{line}"
     else
#       reading header line
     end
     port = 0
     file1 = 0
     hoststring = "NOHOSTNAME"
   end

   $procrow["proc_id"] = proc_id
   $procrow["owner"] = owner
   $procrow["procname"] = procname   # process name 
   $procrow["type"] = type
   $procrow["node1"] = node1
   $procrow["protocol"] = protocol
   $procrow["portno"] = port
   $procrow["outhostname"] = file1
   $procrow["hostname"] = hoststring
   $procrow["outportno"] = outport
   $procrow["inlabels"] = "PROCESS: #{procname}\nUSER: #{owner}\nPROTOCOL: #{protocol}"
   $procrow["outlabels"] = ""
#   $procrow["outlabels"] = "PROCESS: #{procname}\nUSER: #{owner}\nPROTOCOL: #{outproto}"

# write to array (but blow off the headers)
   if (hoststring != "NOHOSTNAME" &&  $procrow["proc_id"] != "PID") then
     $boxes << $procrow
   end
end                       # end reading file

end # end array of files

# prepare an output file to save the hashes for now (this file is a just-in-case)
# get the outhostname in present working dir
tempfile = File.basename($inputfile)+".sorted"  # write to a file
outfile = File.open(tempfile, 'w')

# write it out to file
$boxes.each do |hash|
  outfile.puts hash
end                             # each row of array
outfile.close

# make hash of user/process combos and of files (which is really just destination IPs when you run -i) and of hosts (source IP)
$userprocess = Array.new
$outuserprocess = Array.new
$inlabels = Array.new
$outlabels = Array.new
$dests = Array.new
$hosts = Array.new
$owners = Array.new
$counter = 0

# for each box (row in the output)
$boxes.each do |row|
  # create entry to ensure we have a distinct host/row/process combination - those will be the smallest boxes
  $entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
  $outentry = "#{row["outhostname"]}-#{row["owner"]}-#{row["procname"]}"
    # if the other fields are not yet in the arrays, add them -- each array should contain one copy of each 
    if (!$userprocess.include?$entry) then
      $userprocess <<  $entry
      $inlabels << row["inlabels"]
    end
    if (!$userprocess.include?$outentry) then
      $userprocess <<  $outentry
      $inlabels << row["outlabels"]
    end
    if (!$hosts.include?(row["hostname"])) then
      $hosts << row["hostname"]
    end
    if (!$hosts.include?(row["outhostname"])) then
      $hosts << row["outhostname"]
    end
    if (!$owners.include?(row["owner"])) then
      $owners << row["owner"]
    end
  $counter += 1

end  #each box


# do graph
gv = Gv.digraph("ProcessGraph")
# rank TB makes the graph go from top to bottom - works better right now with the CentOS version
# rank LR draws left to right which is easier to read
Gv.layout(gv, 'dot')
Gv.setv(gv, 'rankdir', 'LR')

# now set up subgraphs for the sources
$uprows = Array.new($boxes.size)
$filerows = Array.new($boxes.size)
$upno = 0
$hostcount = 0
$hosts.each do |ho|
  $thishost = ho.to_s
  # the source ip
  sg = Gv.graph(gv, "cluster#{$upno}")
  Gv.setv(sg, 'color', 'black')
  Gv.setv(sg, 'label', "#{ho}")
  Gv.setv(sg, 'shape', 'box')
  $upno += 1
# for each distinct user/process combo add a subgraph, then for matching rows add a node in that subgraph
  $procno = 0
  $userprocess.each do |up|
      # subgraphs inside of source for the source/user/process
      sgb = Gv.graph(sg, "cluster#{$upno}")
      Gv.setv(sgb, 'color', 'red')
      $thislabel = $inlabels[$procno]
      Gv.setv(sgb, 'label', "#{$thislabel}")
      # Gv.setv(sgb, 'label', "#{up}")
      Gv.setv(sgb, 'shape', 'box')
      $upno +=1
      $rowno = 0
      $boxes.each do |row|
        # check for matching box in in array
        $entry = "#{row["hostname"]}-#{row["owner"]}-#{row["procname"]}"
        $myhost = row["hostname"].to_s
        if ($entry == up) && ($myhost == $thishost) then
            # this is the node that actually contains the 'from' port
            ng2 = Gv.node(sgb, "#{$upno}")
            Gv.setv(ng2, 'label', "#{row["portno"]}")
            Gv.setv(ng2, 'style', 'filled')
            Gv.setv(ng2, 'shape', 'box')
            $uprows[$rowno] = $upno
            $upno += 1
        end  # if  it is a match for its big box
        # then do the same for out array   
        $outentry = "#{row["outhostname"]}-#{row["owner"]}-#{row["procname"]}"
        $myhost = row["outhostname"].to_s
        if ($outentry == up) && ($myhost == $thishost) then
            # this is the node that actually contains the 'to' port
            ng3 = Gv.node(sgb, "#{$upno}")
            Gv.setv(ng3, 'label', "#{row["outportno"]}")
            Gv.setv(ng3, 'style', 'filled')
            Gv.setv(ng3, 'shape', 'box')
            $filerows[$rowno] = $upno
             $upno += 1
        end  # if  it is a match for its big box   
        $rowno += 1
      end  # each row in array of all comms
      $procno += 1
  end # userprocs
  $hostcount += 1
end  # end of host loop

# for each row, link the process to the file
# alternate colors among the ones we named up top -- we can experiment with this scheme
if ($boxes.count > 0) then
  for count in 0 .. $boxes.count-1
     if ($uprows[count] != nil && $filerows[count] != nil) then
       colorcode =  count.modulo($colors.size)
       # connect the dots
       eg = Gv.edge(gv, "#{$uprows[count]}","#{$filerows[count]}")
       Gv.setv(eg, 'color', $colors[colorcode])
     end    # if neither end is nil
  end       # for each line
end         #if there is data


# is there any data in here?
if ($boxes.count <= 0) then
  puts "No processes to plot. Graph will be empty"
end
success = Gv.write(gv, "#{$outputfile}.dot")
# for now, create the dot this way, see if we can find correction
exec "dot -Tpng #{$outputfile}.dot -o #{$outputfile}.png"

end #create_dot
end # class

#####
# only make this call if you are running this file, not just requiring it
if __FILE__ == $0
class SimpProcessGraph
# instantiate
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
  opts.on('-i', '--input outhostname NAME', 'Input file or directory name') do
    |s| puts "input outhostname is #{s}"
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

end
# YAY

