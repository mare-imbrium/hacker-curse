#!/usr/bin/env ruby -w

if true
  begin
    pages = 1
    outputfile = nil
    hostname = nil
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    #options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

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
