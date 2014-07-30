#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: hacker-comments.rb
#  Description: view comments on terminal or save to file and view
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-07-16 - 13:10
#      License: MIT
#  Last update: 2014-07-30 01:19
# ----------------------------------------------------------------------------- #
#  hacker-comments.rb  Copyright (C) 2012-2014 j kepler

## NOTE: This uses a comments page from ycombinator.com and from the reddit MOBILE page.
#  If you give a comment url from the normal reddit.com page, it will NOT work as all.
#
#  The comment URL is what is given out by the hacker-tsv.rb program, and can be taken
#   from reddit.com/programming/.mobile
#
# This is a sample front-end to the hacker-curse and prints out
#  comments given a comment url. 
#  It the comment url is given it determines the host from the URL.
#
# Two formats are provided:
#   - line : each item is in a separate line, which can be used for further processing
#   - compact : some fields clubbed together on a line, to make viewing easier
# One may have the output save to a YML file using '-y' and further use that by loading it into a hash.
#
# In case, the comments page is saved to disk, you may provide the file name, but then you must give
#  the host name also, so we know which parser to use.
#
require 'hacker/curse/hackernewsparser.rb'
require 'hacker/curse/redditnewsparser.rb'

def format_line article
  puts "# #{article.title}"
  puts " "
  puts article.article_url
  puts "By:         #{article.submitter}"
  puts "Points:     #{article.points}"
  puts "Age:        #{article.age_text}"
  puts "Comments:   #{article.comment_count}"
  comments = article.comments
  unless comments
    $stderr.puts "No comments found for #{url} " 
    exit(2)
  end
  puts " "
  comments.each_with_index do |e, i|
    ctr = i+1
    puts "## : #{ctr}"
    # #{e.head} "
    #puts " #{e.age_text} | #{e.age} | #{e.points} | #{e.submitter} | #{e.submitter_url} "
    puts "By:        #{e.submitter} (#{e.submitter_url}) "
    puts "Age:       #{e.age_text}" 
    puts "Seconds:   #{e.age} " 
    puts "Points:    #{e.points} " if e.points and e.points != ""
    puts "Text:"
    puts e.comment_text
    puts " "
  end
end
def format_compact article
  puts "# #{HEADER_START} #{article.title}#{HEADER_END}"
  puts " "
  puts "(#{ULINE}#{article.article_url}#{CLEAR}) "
  puts "#{article.points} | #{BOLD} by #{article.submitter} #{BOLDOFF} | #{article.age_text} | #{article.comment_count} "
  comments = article.comments
  unless comments
    $stderr.puts "No comments found for #{url} " 
    exit(2)
  end
  puts " "
  comments.each_with_index do |e, i|
    ctr = i+1
    puts "## :#{HEADER_START} #{ctr} #{HEADER_END}"
    # #{e.head} "
    #puts " #{e.age_text} | #{e.age} | #{e.points} | #{e.submitter} | #{e.submitter_url} "
    print "#{BOLD} #{e.submitter} #{BOLDOFF} | #{e.age_text} ago"
    print "| #{e.points} points " if e.points and e.points != ""
    print "\n"
    puts e.comment_text
    puts " "
  end
end
CLEAR      = "\e[0m"
COLOR_BOLD       = "\e[1m"
COLOR_BOLD_OFF       = "\e[22m"
RED        = "\e[31m"
ON_RED        = "\e[41m"
GREEN      = "\e[32m"
YELLOW     = "\e[33m"
BLUE       = "\e[1;34m"

ON_BLUE    = "\e[44m"
REVERSE    = "\e[7m"
UNDERLINE    = "\e[4m"
if $stdout.tty?
  BOLD=COLOR_BOLD
  BOLDOFF=COLOR_BOLD_OFF
  HEADER_START=ON_BLUE
  HEADER_END=CLEAR
  ULINE=UNDERLINE
else
  BOLD="**"
  BOLDOFF="**"
  HEADER_START=""
  HEADER_END=""
  ULINE=""
end

url = nil
host = nil
format = "line"
ymlfile = nil
# http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
require 'optparse'
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-d SEP", String,"--delimiter", "Delimit columns with SEP") do |v|
    options[:delimiter] = v
  end
  opts.on("-H HOST", String,"--hostname", "hostname rn/hn") do |v|
    # this is only required if you pass in a saved file, so we need to know which parser to use
    host = v
  end
  #opts.on("-H (reddit|hn)", String,"--hostname", "Get articles from HOST") do |v|
    #host = v
  #end
  opts.on("-f FORMAT", String,"--format", "write in format: compact, line") do |v|
    format = v
  end
  opts.on("-w PATH", String,"--save-html-path", "Save html to file PATH") do |v|
    options[:htmloutfile] = v
    options[:save_html] = true
  end
  opts.on("-y PATH", String,"--save-yml-path", "Save yml to file PATH") do |v|
    ymlfile = v
  end
end.parse!

#p options
#p ARGV

url=ARGV[0];
unless url
  $stderr.puts "URL of comment expected"
  exit(1)
end
# this is only required if you pass in a saved file, so we need to know which parser to use
if host
  case host
  when "hn"
    hn = HackerNewsParser.new options
  when "rn"
    hn = RedditNewsParser.new options
  end
end

unless hn
  if url.index("reddit.com")
    hn = RedditNewsParser.new options
  elsif url.index("ycombinator.com")
    hn = HackerNewsParser.new options
  else
    $stderr.puts "Unknown host. Expecting reddit.com or ycombinator.com"
    exit(1)
  end
end
if ymlfile
  hn.save_comments_as_yml ymlfile, url
  exit
end
#comments = hn._retrieve_comments url
article = hn._retrieve_comments url
#hn.to_yml "comments.yml", article.hash
case format
when "compact"
  format_compact article
else
  format_line article
end
