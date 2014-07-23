# ----------------------------------------------------------------------------- #
#         File: hacker-curse.rb
#  Description: view hacker news on terminal
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-07-16 - 13:10
#      License: MIT
#  Last update: 2014-07-23 19:21
# ----------------------------------------------------------------------------- #
#  hacker-curse.rb  Copyright (C) 2012-2014 j kepler
!/usr/bin/env ruby

require 'lib/hacker/curse/hackernewsparser.rb'

if true
  begin
    url = nil
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Print description also") do |v|
        options[:verbose] = v
      end
      opts.on("-n N", "--limit", Integer, "limit to N stories") do |v|
        options[:number] = v
      end
      opts.on("-t", "print only titles") do |v|
        options[:titles] = true
      end
      opts.on("-d SEP", String,"--delimiter", "Delimit columns with SEP") do |v|
        options[:delimiter] = v
      end
      opts.on("-s subforum", String,"--subforum", "Get articles from subforum such as newest") do |v|
        options[:subreddit] = v
        url = "https://news.ycombinator.com/#{v}"
        #url = "http://www.reddit.com/r/#{v}/.rss"
      end
      opts.on("-u URL", String,"--url", "Get articles from URL/file") do |v|
        url = v
      end
      opts.on("--save-html", "Save html to file?") do |v|
        options[:save_html] = true
      end
      opts.on("-w PATH", String,"--save-html-path", "Save html to file PATH") do |v|
        options[:htmloutfile] = v
      end
    end.parse!

    #p options
    #p ARGV

    #filename=ARGV[0];
    url ||= "https://news.ycombinator.com/news"
    options[:url] = url
    hn = HackerNewsParser.new options
    arr = hn.next_page
    titles_only = options[:titles]
    sep = options[:delimiter] || "\t"
    limit = options[:number] || arr.count
    arr.each_with_index do |e, i|
      break if i >= limit
      if titles_only
        puts "#{e[:title]}"
      else
        unless options[:verbose]
          e.delete(:description)
        end
        if i == 0
          s = e.keys.join(sep)
          puts s
        end
        s = e.values.join(sep)
        puts s
        #puts "#{e[:title]}#{sep}#{e[:url]}#{sep}#{e[:comments_url]}"
      end
    end
    #puts " testing block "
    #klass.run do | t,u,c|
      #puts t
    #end
  ensure
  end
end
exit
hn = HackerNewsParser.new
page = hn.get_next_page
sep = "\t"
page.each do |art|
  puts "#{art.title}#{sep}#{art.points}#{sep}#{art.age_text}"
end
