#!/usr/bin/env ruby -w
#
# This is just a wrapper over hacker-tsv.rb
# If called with news or newest it calls hacker news, otherwise by default it will call
#  reddit.com for other args. Use -H to specify host if it is hacker news.
# It also puts the output in a TSV file.
# Currently, corvus is calling this.

if true
  begin
    pages = 1
    outputfile = nil
    hostname = nil
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    #options = {}
    prog = File.basename $0
    OptionParser.new do |opts|
      opts.banner  = %Q{ 
      Usage: #{prog} [options] subforum
      Examples:
             #{prog} --pages 2 news
             #{prog} programming
             #{prog} programming/new

        subforum can be news / newest (Hacker News)
        or any subforum from reddit such as programming, ruby, vim, zsh, commandline, etc.

        This program is a wrapper over hacker-tsv.rb and writes the output into a tab separated file
        of the same name as the subforum, with a ".tsv" extension, such as news.tsv or ruby.tsv.
        }

      opts.on("-H HN", String, "--hostname", "hostname [hn|rn]") do |v|
        hostname = v
      end
      opts.on("-p pages", Integer, "--pages", "pages to retrieve ") do |v|
        pages = v
      end
      opts.on("-o outputfile", String, "--outputfile", "name of TSV file to create ") do |v|
        outputfile = v
      end
    end.parse!

    subr=ARGV[0] || "news"
    subr2 = subr.gsub("/", "__")
    outputfile ||= "#{subr2}.tsv"
    outputhtml ||= "#{subr2}.html"

    puts "subreddit is: #{subr} "
    exec_str = nil
    case subr
    when "news", "newest"
      exec_str = "hacker-tsv.rb -H hn -p #{pages} -s #{subr} -w #{outputhtml} > #{outputfile}"
    else
      hostname ||= "rn"
      exec_str = "hacker-tsv.rb -H #{hostname} -p #{pages} -s #{subr} -w #{outputhtml} > #{outputfile}"
      #hacker-tsv.rb -H "$hostname" -p $pages -s "$subr" -w $outputhtml > $outputfile
    end
    ret = system( exec_str )
    status = $?
    unless ret
      $stderr.puts exec_str
      $stderr.puts "hacker-tsv returned with error/s #{ret}, #{status}"
      exit(status)
    end
  ensure
  end
end
