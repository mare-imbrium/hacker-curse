# ----------------------------------------------------------------------------- #
#         File: hacker-yml.rb
#  Description: saves hacker or reddit output as a YML file
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-08-05 - 01:08 
#      License: MIT
#  Last update: 2014-08-05 01:21
# ----------------------------------------------------------------------------- #
#  hacker-yml.rb  Copyright (C) 2012-2014 j kepler
#!/usr/bin/env ruby

require 'hacker/curse/hackernewsparser.rb'
require 'hacker/curse/redditnewsparser.rb'

if true
  begin
    url = nil
    host = nil
    outputfile = nil
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    options[:num_pages] = 1
    OptionParser.new do |opts|
      opts.banner = %Q{
 Usage: #{$0} [options]
 Outputs stories from Hacker News front page or Reddit.com to a YML file

 Examples:


 Retrieves one page of articles from reddit.com/r/ruby and save yml output in a file (default is
 <subforum>.yml).

     hacker-yml.rb -H rn -s ruby 

     hacker-yml.rb -H rn -s ruby -y ~/tmp/ruby.yml

 Retrieves two pages of stories from Hacker News and save the retrieved HTML file to news.html,
 and redirect YML output to news.yml (default).

     hacker-yml.rb -H hn -p 2 -s news -w news.html 
    }

      opts.separator ""
      opts.separator "Common Options:"

      opts.on("-s subforum", String,"--subforum", "Get articles from subforum such as newest") do |v|
        options[:subforum] = v
      end
      opts.on("-H (rn|hn)", String,"--hostname", "Get articles from HOST") do |v|
        host = v
      end
      opts.on("-p N", Integer,"--pages", "Retrieve N number of pages") do |v|
        options[:num_pages] = v
      end
      opts.separator ""
      opts.separator "Specific Options:"
      opts.on("-n N", "--limit", Integer, "limit to N stories") do |v|
        options[:number] = v
      end
      opts.on("-t", "print only titles") do |v|
        options[:titles] = true
      end
      opts.on("-d SEP", String,"--delimiter", "Delimit columns with SEP") do |v|
        options[:delimiter] = v
      end
      opts.on("-u URL", String,"--url", "Get articles from URL/file") do |v|
        options[:url] = v
      end
      opts.on("-w PATH", String,"--save-html-path", "Save html to file PATH") do |v|
        options[:htmloutfile] = v
        options[:save_html] = true
      end
      opts.on("-y PATH", String,"--save-yml-path", "Save YML to file PATH") do |v|
        outputfile = v
      end
      opts.on("-v", "--[no-]verbose", "Print description also") do |v|
        options[:verbose] = v
      end
    end.parse!

    hn = nil
    case host
    when "reddit", "rn"
      hn = RedditNewsParser.new options
    else
      hn = HackerNewsParser.new options
    end

    outputfile ||= options[:subforum].gsub("/","__")
    arr = hn.get_next_page
    hn.save_page_as_yml outputfile, arr
    if arr.articles.nil? or arr.articles.empty?
      $stderr.puts "No articles"
    end
  ensure
  end
end
