# simp-processgraph
This holds the tool we are using to draw the process graphs

This code allows you to plot the communications between your host and others.
It uses the lsof (list open files) command with the -i4 (using ipv4 protocol) with the and -n option (converts hostnames to ip addresses),
creates an array of hashes of (process id, process name, port, filename, hostname, owner),
writes the interim data to a file,
and creates a graph, boxing up where the user and process are the same, and at the other end where destinations are the same.
Lines are color-alternated to keep them distinct.

Files included

In order to run, you must

Set up your environment as described here:
https://simp-project.atlassian.net/wiki/display/SD/Setting+up+your+build+environment
(until you install bundler)
then
$bundle

In order to create the .png files, you must have graphviz installed
$yum install graphviz

You may need to install lsof in various versions of Linux
$yum install lsof

Below are the functions available under rake:
rake chmod            # Ensure gemspec-safe permissions on all files
rake clean            # Remove any temporary products
rake clobber          # Remove any generated file
rake default          # default - help
rake help             # help
rake pkg:gem          # build rubygem package for simp-processgraph
rake pkg:install_gem  # build and install rubygem package for simp-processgraph
rake spec             # run all RSpec tests

To run, type in the command below:
$ ruby simp-processgraph.rb

The parameters are:
Usage: ruby simp_processgraph.rb [options]
    -h, --help                       Help
    -i, --input filename NAME        Input file or directory name
    -o, --output file NAME           Output file or directory name (will look for files in the directory named *.lsof


or call the two lines below within your ruby
mygraph = SimpProcessGraph_i4.new($inpfile, $outfile)
mygraph.create_dot


