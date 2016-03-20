#!/usr/bin/env ruby -w
#
# Fetch hacker news front page entries into a hash.
# TODO : get next page. Nexts is /news2 but after that it changes
# TODO : 2014-07-27 - 12:42 put items in hash in an order, so printers can use first 4 cols for long listing
#       title, age_text, comment_count, points, article_url, comments_url, age, submitter, submitter_url
#
require 'open-uri'
require 'nokogiri'

# this is from hacker news itself
#file = "news.html"

module HackerCurse
  class ForumPage
    include Enumerable
    # new newest hot rising etc
    attr_accessor :url
    attr_accessor :next_url
    attr_accessor :create_date
    attr_accessor :subforum
    # array of article objects
    attr_accessor :articles
    def each
      @articles.each do |e| yield(e) ; end
    end 
    alias :each_article :each
    def merge_page page
      self.next_url = page.next_url
      self.articles.push(*page.articles)
      self
    end
  end
  class ForumArticle
    attr_accessor :title
    attr_accessor :article_url
    attr_accessor :points
    attr_accessor :comment_count
    attr_accessor :comments_url
    attr_accessor :age_text
    attr_accessor :age
    attr_accessor :submitter
    attr_accessor :submitter_url
    attr_accessor :domain
    attr_accessor :domain_url
    # byline is dump of text on top containing all the info on points, # of comments, nn hours aga
    attr_accessor :byline
    attr_accessor :parent
    attr_writer :comments
    attr_reader :hash
    def initialize h
      @comments = nil
      @hash = h
      [:title, :article_url, :points, :comment_count, :comments_url, :age_text, :age,
       :submitter, :submitter_url, :domain, :domain_url, :byline].each do |sym|
        instance_variable_set("@#{sym.to_s}", h[sym]) if h.key? sym
      end
      if h.key? :comments
        c = h[:comments]
        @comments = Array.new
        c.each do |h|
          fc = ForumComment.new h
          @comments << fc
        end
      end
    end

    def comments
      @comments || retrieve_comments(@comments_url)
    end
    def each
      comments.each do |e| yield(e) ; end
    end 
    def retrieve_comments url
      raise "Parent must be set in order to retrieve comments " unless @parent
      @parent._retrieve_comments url
    end
    alias :each_comment :each
    def [](sym)
      @hash[sym]
    end
    def keys
      @hash.keys
    end
    def values
      @hash.values
    end
  end
  class ForumComment
    attr_accessor :submitter, :submitter_url
    attr_accessor :age, :age_text, :points, :head
    attr_accessor :comment_text
    attr_accessor :comment_url
    attr_reader :hash
    def initialize h

      @hash = h
    [:points, :comment_url, :age_text, :age,
    :submitter, :submitter_url, :comment_text, :head].each do |sym|
      instance_variable_set("@#{sym.to_s}", h[sym])
    end
    end
    def [](sym)
      @hash[sym]
    end
    def keys
      @hash.keys
    end
    def values
      @hash.values
    end
  end

  # 
  # rn = RNParser.new [url]
  # rn.subreddit = "ruby"
  # resultset = rn.get_next_page :page => prevresultset, :number => 5
  # resultset.each do |art|
  #    art.title, art.points
  #    art.comments
  # end
  #
  # hn = HNewsParser @options
  # hn.subxxx = "news" / "newest"
  #
  # redditnews.rb -s ruby --pages 2
  # hackernews.rb -s newest --pages 2 -d '|'
  #

  class AbstractSiteParser
    attr_reader :more_url
    attr_accessor :host
    attr_accessor :num_pages
    attr_accessor :subforum
    # should the html be saved
    attr_accessor :save_html
    attr_accessor :htmloutfile
    #HOST = "https://news.ycombinator.com"
    def initialize options={}
      @options = options
      @url = @options[:url]
      @save_html = @options[:save_html]
      @htmloutfile = @options[:htmloutfile]
      @num_pages = @options[:num_pages] || 1
      @more_url = nil
      #puts "initialize: url is #{@url} "
    end
    def get_first_page
      #@arr = to_hash @url
      # 2016-03-20 - 23:45 page can be nil if HTTPError
      page = _retrieve_page @url
    end
    def get_next_page opts={}
      page = opts[:page]
      num_pages = opts[:num_pages] || @num_pages
      num_pages ||= 1
      u = @more_url || @url
      if page 
        u = page.next_url
      end
      pages = nil
      num_pages.times do |i|
        page = _retrieve_page u
        if pages.nil?
          pages = page
        else
          pages.merge_page page
        end
        u = page.next_url
        break unless u  # sometimes there is no next
        @more_url = u
      end
      return pages
    end
    alias :get_next :get_next_page
    def _retrieve_page url
      raise "must be implemented by concrete class"
    end
    # write as yml, this doesn't work if multiple pages since we call x times
    #  so previous is overwritten
    #  This should be called with final class
    def to_yml outfile, arr = @arr
      require 'yaml'
      # cannot just convert / to __ in filename since path gets converted too
      #if outfile.index("/")
        #outfile = outfile.gsub("/","__")
      #end
      File.open(outfile, 'w' ) do |f|
        f << YAML::dump(arr)
      end
    end
    # after called get_next_page, one may pass its return value 
    # to this method to convert it into an array of hashes and store it as a yml file
    # It's a bit silly, first we break the hash down into this structure
    #  and then deconstruct the whole thing. 
    def save_page_as_yml outputfile, page
      h = {}
      h[:url] = page.url
      h[:next_url] = page.next_url
      h[:subforum] = page.subforum
      h[:create_date] = page.create_date
      articles = []
      page.each do |a| articles << a.hash; end

      h[:articles] = articles

      to_yml outputfile, h
    end
    # retrieves the comments for a url and stores in outputfile in YML format
    def save_comments_as_yml outputfile, url
      pages = _retrieve_comments url
      if pages 
        to_yml outputfile, pages.hash
      end
    end
    # returns nokogiri html doc and writes html is required.
    # returns nil if HTTPError
    def get_doc_for_url url
      $stderr.puts "get_doc #{url} "
      doc = nil
      # 2016-03-20 - added check since sometimes server error was coming
      begin
        out = open(url)
      rescue StandardError=>e
        $stderr.puts "\tError: #{e}"
        # 2016-03-20 - adding exit since it will go to client that shelled this command.
        exit 1
      else
        doc  = Nokogiri::HTML(out)
        if @save_html
          subforum = @subforum || "unknown"
          outfile = @htmloutfile || "#{subforum}.html"
          #if !File.exists? url
          out.rewind
          File.open(outfile, 'w') {|f| f.write(out.read) }
          #end
        end
      end
      return doc
    end
    # this is a test method so we don't keep hitting HN while testing out and getting IP blocked.
    def load_from_yml filename="hn.yml"
      @arr = YAML::load( File.open( filename ) )
      next_url = @arr.last[:article_url]
      unless next_url.index("http")
        next_url = @host + "/" + next_url
      end
      @more_url = next_url
    end
    def _retrieve_comments url
      raise "Must be implemented by concrete class "
    end
    public
    def get_comments_url index
      arr = @arr
      entry = arr[index]
      if entry
        if entry.key? :comments_url
          return entry[:comments_url]
        end
      end
      return nil
    end
    public
    def get_comments index
      url = get_comments_url index
      if url
        #puts url
        comments = convert_comment_url url
        return comments
      #else
        #puts "Sorry no url for #{index} "
      end
      return []
    end
    alias :get_comments_for_link :get_comments
    def human_age_to_unix age_text
      i = age_text.to_i
      ff=1
      if age_text.index("hour")
        i *= ff*60*60
      elsif age_text.index("second")
        i *= ff
      elsif age_text.index("minute")
        i *= ff*60
      elsif age_text.index("day")
        i *= ff*60*60*24
      elsif age_text.index("month")
        i *= ff*60*60*24*30
      elsif age_text.index("week")
        i *= ff*60*60*24*7
      elsif age_text.index("year")
        i *= ff*60*60*24*365
      else
        #raise "don't know how to convert #{age_text} "
        return 0
      end
      return (Time.now.to_i - i)
    end
  end
end
include HackerCurse


if __FILE__ == $0
  #rn = HackerNewsParser.new :url => "hackernews.html"
  rn = RedditNewsParser.new :url => "reddit-prog.html"

  page = rn.get_next_page  # [page if supplied, take page.next_url, otherwise store??]
  puts "For each article :::"
  page.each do |art|
    puts art.title, art.points, art.age_text, art.age, Time.at(art.age)
  end # each_article
  art = page.articles.first
  puts "PRINTING comments "
  art.each_comment do |c|
    puts 
    puts " ======"
    puts c.head
    s = nil
    if c.age
      s = Time.at(c.age)
    end
    puts " #{c.age_text} | #{c.submitter} | #{c.age} . #{s} "
    puts c.comment_text
  end

  exit
  articles = page.articles
  co = articles.first.comments
  puts "PRINTING comments "
  puts co[:title], co[:subtext]
  comments = co[:comments]
  comments.each_with_index do |c,i|
    puts "=======  #{c[:head]} : " 
    puts " - #{c[:head]} : " 
    puts " #{c[:comment]} "
    puts " "
  end

  #comments.each_with_index do |c,i|
    #puts " #{i}:  #{c} "
  #end
  exit
  art.each_comment do |cc|
  end
  #rn.next_url = page.next_url
  rn.set_next_url(page)
  #arr = rn.convert_comment_url "hn_comments.html"
  #rn.to_yml "hn_comments.yml", arr


  arr = rn.get_next_page
  rn.to_yml "hn.yml"
  puts "getting comments for link 1"
  comments = rn.get_comments_for_link 1
  if comments.empty?
    comments = rn.get_comments_for_link 9
  end
  rn.to_yml "hn-comments.yml", comments
  puts "getting next page"
  arr1 = rn.get_next_page
  rn.to_yml "hn-1.yml", arr1
end
