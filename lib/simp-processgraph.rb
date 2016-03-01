#!/usr/bin/env ruby
require 'optparse'
require 'gv'
require 'socket'

@@sites
@@owners
@@hosts
@@ips
@@processes

class ProcessList
  def initialize(owner)
    @owner = owner
    @mySiteList = []
 end

  def addSite(newSite)
    found = false
    if (@mySiteList.size > 0) then
      @mySiteList.each do |sitenm|
        thisSite = sitenm.getSiteName
#        puts "site name is #{thisSite}"
        if thisSite == newSite then
          found = true
#          puts "found #{newSite}"
          return sitenm
        end # match
      end #each site
    else
#       puts "first site name is #{newSite}"     
    end # more than one site

    if (!found) then 
      addSite = SiteName.new(newSite)
      @mySiteList << addSite
#      puts "added site #{newSite} to site list - count is #{@mySiteList.size}"
      return addSite       
    else
#      puts "site #{newSite} is a repeat"
    end
  end
 
  def printSites
    puts "printSites -- printing list of #{@mySiteList.size}"
    @mySiteList.each do |sitenm|
      puts "site name is #{sitenm.getSiteName}"
      sitenm.printHosts
    end # site
  end #printSites

  def graphProcesses
#   init graph
    $gv = Gv.digraph("ProcessGraph")
    puts"ouputting graph"
    # rank TB makes the graph go from top to bottom - works better right now with the CentOS version
    # rank LR draws left to right which is easier to read
    Gv.layout($gv, 'dot')
    Gv.setv($gv, 'rankdir', 'LR')
    puts "graphProcesses -- printing list of #{@mySiteList.size}"
    $upno = 0
    $sitecount = 0
    $hostcount = 0
    $ipcount = 0
    $proccount = 0
    $portcount = 0
#   progress through the sites
    @mySiteList.each do |sitenm|
      $sitecount += 1
      puts "site name is #{sitenm.getSiteName}"
      sg = Gv.graph($gv, "cluster#{$upno}")
      Gv.setv(sg, 'color', 'black')
      Gv.setv(sg, 'label', "#{sitenm.getSiteName}")
      Gv.setv(sg, 'shape', 'box')
      $upno += 1
#     the hosts 
      hostList = sitenm.getHostList
      hostList.each do |host|
        $hostcount += 1
        sgb = Gv.graph(sg, "cluster#{$upno}")
        Gv.setv(sgb, 'color', 'red')
        Gv.setv(sgb, 'label', "#{host.getHostName}")
        Gv.setv(sgb, 'shape', 'box')
        $upno +=1
        puts "host name is #{host.getHostName}"
        ipList = host.getIPList       
        ipList.each do |myIP|
          $ipcount += 1
          puts "ip is #{myIP.getIP}"
          sgc = Gv.graph(sgb, "cluster#{$upno}")
          Gv.setv(sgc, 'color', 'blue')
          Gv.setv(sgc, 'label', "#{myIP.getIP}")
          Gv.setv(sgc, 'shape', 'box')
          $upno +=1
          procs = myIP.getProcs
          procs.each do |myproc|
            $proccount += 1
            puts "proc name is #{myproc.getProc}"
            sgd = Gv.graph(sgc, "cluster#{$upno}")
            Gv.setv(sgd, 'color', 'green')
            Gv.setv(sgd, 'label', "#{myproc.getProc}")
            Gv.setv(sgd, 'shape', 'box')
#            ng = Gv.node(sgd,"p#{$portcount}")  
#            Gv.setv(ng, 'label', "p#{myproc.getProc}")
#            Gv.setv(ng, 'style', 'filled')
#            Gv.setv(ng, 'shape', 'point')
            $upno +=1
            portList = myproc.getPorts
            portList.each do |portno|
              $portcount += 1
              puts "port name is #{portno.getPort}"
              sge = Gv.graph(sgd, "cluster#{$upno}")
              Gv.setv(sge, 'color', 'black')
              Gv.setv(sge, 'label', "#{portno.getPort}")
              Gv.setv(sge, 'shape', 'box')
              ng = Gv.node(sge,"k#{$portcount}")  
              Gv.setv(ng, 'label', "#{portno.getPort}")
              Gv.setv(ng, 'style', 'filled')
              Gv.setv(ng, 'shape', 'point')
              portno.setGraphNode("k#{$portcount}")
              $upno +=1
            end #ports
          end #procs
        end #ipList
      end #hostList
    end # site
  $outputfile = "test"
  puts "starting -- dot -Tpng #{$outputfile}.dot -o #{$outputfile}.png"
  success = Gv.write($gv, "#{$outputfile}.dot")
  system "dot -Tpng #{$outputfile}.dot -o #{$outputfile}.png"
# for now, create the dot this way, see if we can find correction
  puts "done -- dot -Tpng #{$outputfile}.dot -o #{$outputfile}.png"
  end #graphProcesses

  def graphConnections  
  puts "outputting connections"
#   progress through the sites
    @mySiteList.each do |sitenm|
      hostList = sitenm.getHostList
      hostList.each do |host|
        ipList = host.getIPList       
        ipList.each do |myIP|
          procs = myIP.getProcs
          procs.each do |myproc|
            portList = myproc.getPorts
            portList.each do |portnum|
              puts "port name is #{portnum.getPort}"
#             once more to get connections
puts "checking connections for port #{portnum.getPort}"
              myConns = portnum.getConnections
puts "port #{portnum.getPort}, connections #{myConns}"    
              myConns.each do |conn|
                startNode = portnum.getGraphNode
                endNode = conn.getGraphNode
puts "CONNECTING portno #{portnum.getPort} start #{startNode} , end #{endNode}"
                if (endNode != nil && startNode != nil) then
                  eg = Gv.edge($gv, startNode, endNode)
                  Gv.setv(eg, 'color', 'black')
puts "CONNECTING start #{startNode} , end #{endNode} for real"
                end  # not nil
              end #connections
            end #ports
          end #procs
        end #ipList
      end #hostList
    end # site
  $outputfile = "pretest"
  success = Gv.write($gv, "#{$outputfile}.dot")
# for now, create the dot this way, see if we can find correction
  system "dot -Tpng #{$outputfile}.dot -o #{$outputfile}.png"
  end #graphConnections
end #ProcessList

### Site
class SiteName   
  attr_accessor :mySiteName

  def initialize(mySiteName)
    @mySiteName = mySiteName
    @myHostList = []
  end #initialize

  def addHost(newHost)
    found = false
    if (@myHostList.size > 0) then
      @myHostList.each do |hostnm|
        if newHost == hostnm.getHostName then
          found = true
#          puts "found #{newHost}"
          return hostnm
        end # match
      end #each site
    else
#       puts "first host name is #{newHost}"     
    end # more than one

    if (!found) then 
      thisHost = HostName.new(newHost)
      @myHostList << thisHost
#      puts "added #{newHost} to site list - count is #{@myHostList.size}"
      return thisHost       
    else
#      puts "site #{thisHost.getHostName} is a repeat"
    end
  end

  def getSiteName
     return @mySiteName
  end

  def getHostList
    return @myHostList
  end

  def printHosts
    puts "host list size is #{@myHostList.size}"
    @myHostList.each do |hostnm|
      puts "hostlist -- host name is #{hostnm.getHostName}"
      hostnm.printIPs
    end # site
  end #printHosts

end #SiteName

### Host
class HostName    
  attr_accessor :myHostName

  def initialize(myHostName)
    @myHostName = myHostName
    @myIPList = []
  end #initialize

  def addIP(myIP)
    found = false
    if (@myIPList.size > 0) then
      @myIPList.each do |ipnm|
        thisIP = ipnm.getIP
#        puts "comparing #{thisIP} with #{myIP}"
        if (thisIP == myIP) then
          found = true
#          puts "found #{myIP}"
          return ipnm
        end # match
      end #each site
    else
#       puts "first IP name is #{myIP}"     
    end # more than one

    if (!found) then 
      newIP = IPAddr.new(myIP)
      @myIPList << newIP
#      puts "added #{myIP} to site list - count is #{@myIPList.size}"
      return newIP       
    else
#      puts "site #{myIP} is a repeat"
    end # found
  end # addIP

  def getHostName
    return @myHostName
  end

  def getIPList
    return @myIPList
  end

  def printIPs
    puts "IP list size is #{@myIPList.size}"
    @myIPList.each do |ipnm|
      puts "iplist -- name is #{ipnm.getIP}"
      ipnm.printProcs
    end # IP    
  end #printIPs

end #HostName



### IP
class IPAddr    
  attr_accessor :myIP

  def initialize(myIP)
    @myIP = myIP
    @myProcList = []
  end #initialize

  def getIP
    return @myIP
  end

  def getProcs
    return @myProcList
  end

  def addProc(myProc)
    found = false
    if (@myProcList.size > 0) then
      @myProcList.each do |proc|
        thisProc = proc.getProc
#        puts "comparing #{thisProc} with #{myProc}"
        if (thisProc == myProc) then
          found = true
#          puts "found #{myProc}"
          return proc
        end # match
      end #each site
    else
#      puts "first Proc name is #{myProc}"     
    end # more than one

    if (!found) then 
      newPL = ProcessName.new(myProc)
      @myProcList << newPL
#      puts "added #{myProc} to site list - count is #{@myProcList.size}"
      return newPL       
    else
#      puts "site #{myPort} is a repeat"
    end # found
  end # addProc

  def printProcs
    puts "Proc list size is #{@myProcList.size}"
    @myProcList.each do |procnm|
      puts "proc list -- name is #{procnm.getProc}"
      procnm.printPorts
    end # Proc
  end #printProcs

end #IPAddr

### Process
class ProcessName
  attr_accessor :procname

  def initialize(procname)
    @procname = procname
    @myPortList = []
  end #initialize

  def getProc
    return(@procname)
  end

  def getPorts
    return(@myPortList)
  end

  def addPort(myPort)
    found = false
    if (@myPortList.size > 0) then
      @myPortList.each do |port|
        thisPort = port.getPort
#        puts "comparing #{thisPort} with #{myPort}"
        if (thisPort == myPort) then
          found = true
#          puts "found #{myPort}"
          return port
        end # match
      end #each site
    else
#      puts "first Port name is #{myPort}"     
    end # more than one

    if (!found) then 
      newPort = PortNum.new(myPort)
      @myPortList << newPort
#      puts "added #{myPort} to site list - count is #{@myPortList.size}"
      return newPort 
    else
#      puts "site #{myPort} is a repeat"
    end # found
  end # addPort

  def printPorts
    puts "Port list size is #{@myPortList.size}"
    @myPortList.each do |portno|
      puts "port list -- name is #{portno.getPort}"
#      puts "port connections #{portno.getConnections.inspect}."
    end # Ports
  end #printPorts

end #ProcessName

### PortNum
class PortNum
  attr_accessor :port

  def initialize(port)
    @port = port
    @myConnects = []
    @graphNode 
  end #initialize

  def getPort
    return(@port)
  end

  def addConnection(outPort)
    puts "added connection from #{self.getPort} to  #{outPort.getPort} outport is #{outPort}"
    @myConnects << outPort
#    puts "inspect connections is #{@myConnects.inspect} - size is #{@myConnects.size}"
  end

  def setGraphNode(inNode)
    @graphNode = inNode
  end

  def getGraphNode
    return @graphNode
  end

  def getConnections
    return @myConnects
  end

end #PortNum

def FileInput(infile, outfile)
  @allComms = Array.new {Hash.new}
  $infiles = Array.new

  # get the list of processes to a file
  infile = 'process_list'
  $filetype = 'none'

  # check to see if we input a file
  if @inputfile == nil 
    @inputfile = infile
  end
  if File.directory?@inputfile then
    $filetype = 'dir'
  elsif File.file?@inputfile
    $filetype = 'file'
  else
   infile = @inputfile
   $filetype = 'none'
  end

  # output file
  if @outputfile == nil then
    @outputfile = @inputfile
  end

  # this ss command lists processes to a file
  # comment out for a test file
  if $filetype == 'none'
#    system ("ss -npa > #{infile}")
    system ("ss -npat > #{infile}")
    $filetype = 'file'
  end

  if $filetype == 'dir' then
    Dir.foreach(@inputfile) do |infile|
#      next if infile == '.' or infile == '..'
      if infile.end_with?('lsof') then
        $infiles << @inputfile+'/'+infile
      end
    end
#   got through - check to ensure we got a file
    if $infiles.size == 0
       puts "no files found"
    end
    @inputfile = infile+"_dir"
    if @outputfile == nil then
      @outputfile = @inputfile
    end
  else
    $infiles << @inputfile
  end
  # get rid of any far away directories for our output files
  @outputfile = File.basename(@outputfile)    

  # read each input file in the directory
  $infiles.each do |infile|
    $numProcs = 0
    counter = 0
#   read the file, one line at a time
    IO.foreach(infile) do |line|
#     create a hash for all the significant info
#      puts "line: #{line}"
      counter += 1
      sitename = ''
      domainname = ''
      hostname = ''
      localIP = ''
      localProc = ''
      peerIP = ''
      peerProc = ''
      proto = ''
      portName = ''

#     break out the fields  
      begin
#       Netid  State      Recv-Q Send-Q     Local Address:Proc       Peer Address:Proc 
#       State      Recv-Q Send-Q        Local Address:Proc          Peer Address:Proc  
        f1 = line.split(' ')
#        netid = f1[0]
#        state = f1[1]
#        recQ = f1[2]
#        sendQ = f1[3]
#        localAdd = f1[4]
#        peerAdd = f1[5]
#        socketUsers = f1[6]
#        peerAdd = f1[7]
#        socketUsers = f1[8]
#        netid = f1[0]
        state = f1[0]
        recQ = f1[1]
        sendQ = f1[2]
        localAdd = f1[3]
        peerAdd = f1[4]
        socketUsers = f1[5]
#       for the local address split address and proc via colon
        f2 = localAdd.split(':')
        localIP = f2[0]
        localPort = f2[1]
#       for the dest address split address and proc via colon
        f3 = peerAdd.split(':')
        peerIP = f3[0]
        peerPort = f3[1]
#       create peer record and local record and associate the numbers
        f4 = socketUsers.split(':')
        proto = f4[1]
        f5 = proto.split('"')
        procName = f5[1]
#        puts "procname is #{procName}"
      rescue
#       ignore everything else
      end
#     current domain and host
      sitename = "judys site"
      hostname = "#{Socket.gethostname}"
      domainname = "dot.com"
  
#     write both sets to hashes 
      if (recQ != "recQ" && peerPort != '' && peerPort != nil) then
        $datarow = Hash.new
        $datarow["sitename"] = sitename
        $datarow["hostname"] = hostname
        $datarow["domainname"] = domainname
        $datarow["localIP"] = localIP
        $datarow["localPort"] = localPort
        $datarow["proto"] = proto
        $datarow["procname"] = procName
        $datarow["peerIP"] = peerIP
        $datarow["peerPort"] = peerPort
        $datarow["socketUsers"] = socketUsers
        @allComms << $datarow
#        @allComms.push($datarow)
      end # recQ (not header)
    end   # end reading file
    puts "done reading"
#    printArray(@allComms)
  end # end array of files
  return @allComms
end #FileInput

# Print array from file
def printArray(allComms)
  puts "listing my file contents"
  allComms.each do |record|
#    puts "---- sitename #{record["sitename"]}, hostname #{record["hostname"]}, domainname #{record["domainname"]}" 
#    puts "local IP #{record["localIP"]},lproc #{record["localProc"]},remote IP #{record["peerIP"]},rproc #{record["peerProc"]},socket users #{record["socketUsers"]}" 
# 
  end
end #printList


# Process array from file
def processData(infile, outfile)
  puts "starting List"
  theStart = ProcessList.new("judy")

# read from file
  dataRead = FileInput(infile, outfile)
  printArray(dataRead)

# set up objects based on the record you just read
  dataRead.each do |record|
    newSite = theStart.addSite(record["sitename"])
    newHost = newSite.addHost(record["hostname"])
    newIP = newHost.addIP(record["localIP"])
    newProc = newIP.addProc(record["procname"])
    newPort = newProc.addPort(record["localPort"])

# destinations
    destSite = theStart.addSite(record["sitename"])
    destHost = destSite.addHost(record["hostname"])
    destIP = destHost.addIP(record["peerIP"])
    destProc = destIP.addProc(record[""])
    destPort = destProc.addPort(record["peerPort"])
    newPort.addConnection(destPort)

# connection

  end
#  puts "inspect -- #{theStart.inspect}"
#  puts "************************************"
#  theStart.printSites
  theStart.graphProcesses
  theStart.graphConnections

end #processData

# test
if __FILE__ == $0
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

processData($inpfile, $outfile)

end # running this file or just required

