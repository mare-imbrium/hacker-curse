# ----------------------------------------------------------------------------- #
#         File: hacker-curse.rb
#  Description: view hacker news on terminal
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-07-16 - 13:10
#      License: MIT
#  Last update: 2014-08-01 18:07
# ----------------------------------------------------------------------------- #
#  hacker-curse.rb  Copyright (C) 2012-2014 j kepler
#!/usr/bin/env ruby

require 'hacker/curse/hackernewsparser.rb'
require 'hacker/curse/redditnewsparser.rb'

if true
  begin
    url = nil
    host = nil
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    options[:num_pages] = 1
    OptionParser.new do |opts|
      opts.banner = %Q{
 Usage: #{$0} [options]
 Outputs stories from Hacker News front page or Reddit.com as tab separated values

 Examples:

 Retrieves two pages of stories from Hacker News and save the retrieved HTML file
 and redirect output to a file.

     hacker-tsv.rb -H hn -p 2 -s news -w news.html > news.tsv

 Retrieves one page of articles from reddit.com/r/ruby and save output in a file.

     hacker-tsv.rb -H rn -s ruby > ruby.tsv
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
      opts.on("-v", "--[no-]verbose", "Print description also") do |v|
        options[:verbose] = v
      end
    end.parse!

    #p options
    #p ARGV

    #filename=ARGV[0];
    #url ||= "https://news.ycombinator.com/news"
    hn = nil
    case host
    when "reddit", "rn"
      hn = RedditNewsParser.new options
    else
      hn = HackerNewsParser.new options
    end

    arr = hn.get_next_page
    titles_only = options[:titles]
    sep = options[:delimiter] || "\t"
    limit = options[:number] || arr.count
    headings = %w[ title age_text comment_count points article_url comments_url age submitter submitter_url ]
    arr.first.keys.each do |k|
      unless headings.include? k.to_s
        headings << k.to_s
      end
    end
    headings.delete("byline")
    headings << "byline"
    # this yields a ForumArticle not a hash.
    arr.each_with_index do |e, i|
      break if i >= limit
      h = e.hash
      if titles_only
        puts "#{e[:title]}"
      else
        unless options[:verbose]
          #e.delete(:description)
        end
        if i == 0
          #s = e.keys.join(sep)
          s = headings.join(sep)
          puts s
        end
        # if missing value then we get one column missing !!! FIXME
        s = ""
        # insert into s in the right order, so all outputs are standard in terms of columns
        headings.each do |h|
          s << "#{e[h.to_sym]}#{sep}"
        end
        #s = e.values.join(sep)
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
