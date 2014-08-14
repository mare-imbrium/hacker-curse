require 'hacker/curse/abstractsiteparser'

module HackerCurse

  class RedditNewsParser < AbstractSiteParser
    def initialize config={}
      @host = config[:host] || "http://www.reddit.com/"
      subforum = config[:subforum] || "unknown"
      _url="#{@host}/r/#{subforum}/.mobile"
      config[:url] ||= _url
      @subforum = subforum
      super config
    end
    def _retrieve_page url
      $stderr.puts "_retrieve_page got url #{url} "
      raise "url should be string" unless url.is_a? String
      arr = to_hash url
      page = hash_to_class arr
      #to_yml "#{@subforum}OLD.yml", arr
      return page
    end
    # reddit
    # @return array of ForumComment objects
    #  For each, you may retrieve +hash+ or individual items such as comment_text, points, age, age_text, submitter, head
    def _retrieve_comments url
      arr = to_hash_comment url
      pages = hash_to_comment_class arr
      return pages
    end
    # reddit parse to hash containing :url, :mext_url and :articles (an array of hashes for each article)
    def to_hash url
      page = {}
      arr = Array.new
      doc  = get_doc_for_url url
      page[:url] = url
      now = Time.now
      page[:create_date_seconds] = now.to_i
      page[:create_date] = now
      page[:subforum] = @subforum
      #filename = "r.#{subr}.yml"
      links = doc.css("li div.link")
      links.each do |li|
        h = {}
        e = li.css("a.title")
        if !e.empty?
          e = e.first
          h[:title] = e.text
          h[:article_url] = e["href"]
        end
        e = li.css("a.domain")
        if !e.empty?
          e = e.first
          h[:domain] = e.text
          h[:domain_url] = e["href"]
        end
        e = li.css("a.author")
        if !e.empty?
          e = e.first
          h[:submitter] = e.text
          h[:submitter_url] = e["href"]
        end
        e = li.css("span.buttons > a")
        if !e.empty?
          e = e.first
          #h[:comment_count] = e.text.to_i
          h[:comment_count] = e.text.to_i.to_s.rjust(4)
          h[:comments_url] = e["href"]
        else
          h[:comment_count] = "   0"
          h[:comments_url] = ""
        end
        byline =  li.css("p.byline").text
        h[:byline] = byline
        # 2014-08-14 - 13:34 in some cases the byline just says "17 minutes ago" with no BAR or "by"
        parts = byline.split("|")
        points = parts[0].strip
        age = parts.last.split("by").first.strip
        h[:age_text]= age.scan(/\d+ \w/).first.rjust(4) if age
        #h[:age_text]= age
        h[:age] = human_age_to_unix(age) if age
        #h[:points]= points.to_i
        h[:points]= points.to_i.to_s.rjust(4)
        #puts points
        #puts age
        arr << h
      end
      # some cases like rising do not have next prev
      #next_prev_url= doc.css("p.nextprev").first.css("a").first["href"]
      next_prev_url= doc.css("p.nextprev").first
      if next_prev_url #&& !next_prev_url.empty?
        next_prev_url = next_prev_url.css("a").first["href"]
        page[:next_url] = next_prev_url
      end
      page[:articles] = arr
      #arr << { :next_prev_url => next_prev_url }
      #@more_url = next_prev_url
      return page
    end
    # reddit
    def hash_to_class h
      p = ForumPage.new
      p.url = h[:url]
      p.next_url = h[:next_url]
      p.create_date = h[:create_date]
      p.subforum = h[:subforum]
      #p.create_date_seconds = h[:create_date_seconds]
      art = h[:articles]
      arts = []
      art.each do |a|
        fa = ForumArticle.new a
        fa.parent = self
        arts << fa
      end
      p.articles = arts
      return p
    end
    # #child_t1_cixd8gn > ul:nth-child(1) > li:nth-child(2) > div:nth-child(1) > div:nth-child(2) > p:nth-child(1)
    # If you want to get the heirarchy, of comments within comments.
    # toplevelcomments = page.css("body > ul > li > div.comment")
    # go for body > ul
    # then get the li 
    # within the li look for levels using
    # > div > ul > li
    # to get the next level of entries
    # This will require recursive going down levels
    # NOTE: currently this returns a flat list of comments. Actually they are nested
    #  and contain block-quotes, so ideally user to check the actual page on the browser
    #private
    public
    # returns a hash. hash[:comments] returns an array of hashes containing comment details
    def to_hash_comment url
      # for testing i may send in a saved file, so i don't keep hitting HN
      if !File.exists? url
        unless url.index("http")
          url = @host + "/" + url
        end
      end
      # comments are nested and there is a div for that,
      # Also blockquotes for when commenter quotes another.
      doc = Nokogiri::HTML(open(url))
      h = {}
      main = doc.css("li div.link")
      maintext = main.text
      #puts maintext
      #puts main.css("a").count
      #puts main.css("a").first
      # this dumps the whole line
      h[:main_text] = maintext
      main.css("a").each_with_index do |l, i|
        # this breaks the main line into text and links
        case i
        when 0
          h[:title] = l.text
          h[:article_url] = l["href"]
        when 1
          h[:comment_count] = l.text
          h[:comments_url] = l["href"]
        when 2
          h[:submitter] = l.text
          h[:submitter_url] = l["href"]
        when 3
          h[:domain] = l.text
          h[:domain_url] = l["href"]
        end
      end
      byline = main.css("p.byline").text
      h[:byline] = byline
      points = byline.scan(/\d+ point/).first
      age_text = byline.scan(/\d+ \w+ ago/).first
      h[:points] = points
      h[:age_text] = age_text

      arr = []
      comments = doc.css("li div.comment")
      comments.each_with_index do |co, ix|
        #puts  ix
        hh = {}
        arr << hh
        comment = co.css("div.md").text
        hh[:comment_text] = comment
        byline = co.css("p.byline")
        #puts "byline:"
        #puts byline
        bytext = byline.text
        hh[:head] = bytext
        #puts "bytext:"
        #puts bytext
        m = bytext.scan(/\d+ \w+ ago/)
        hh[:age_text] = m.first.sub(/ago/,"")
        hh[:age] = human_age_to_unix(m.first)
        link = byline.css("a").first
        if link
          commenter = link.text
          hh[:submitter] = commenter
          submitter_url = link["href"]
          hh[:submitter_url] = submitter_url
        end
        points = byline.css("span.score").text rescue ""
        hh[:points] = points.sub(/points?/,"")
      end
      h[:comments] = arr
      return h
    end
    # reddit
    def hash_to_comment_class arr
      page = ForumArticle.new arr
      return page
    end
    # this returns an array of Forumcomments but that means the article title
    #  etc is not there, and if the output is saved, then that info may be required.
    def old_hash_to_comment_class arr
      co = arr[:comments]
      pages = Array.new
      co.each do |h|
        page = ForumComment.new h
        pages << page
      end
      return pages
    end
  end # class
end # module
