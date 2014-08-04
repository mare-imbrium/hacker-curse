require 'hacker/curse/abstractsiteparser'

module HackerCurse

  class HackerNewsParser < AbstractSiteParser
    def initialize config={}
      @host = config[:host] || "https://news.ycombinator.com"
      subforum = config[:subforum] || "news"
      _url="#{@host}/#{subforum}"
      @subforum = subforum
      config[:url] ||= _url
      super config
    end
    def _retrieve_page url
      #puts "got url #{url} "
      raise "url should be string" unless url.is_a? String
      arr = to_hash url
      page = hash_to_class arr
      to_yml "#{@subforum}.yml", arr
      return page
    end
    # currently returns a Hash. containing various entries relating to the main article
    #  which can be avoiced.
    #  Contains an array :comments which contains hashes, :head contains text of head, :comment contains 
    #   text of comment, and then there are entries for submitter.
    #   hash[:comments].each do |e| e[:comment] ; end
    # @return Array of ForumComment objects.
    #    pages.each do |co| puts co.comment_text, co.head; end
    def _retrieve_comments url
      arr = to_hash_comment url
      # TODO break head into points age etc
      pages = hash_to_comment_class arr
      return pages
    end
    def hash_to_comment_class arr
      page = ForumArticle.new arr
      return page
    end
    def oldhash_to_comment_class arr
      co = arr[:comments]
      pages = Array.new
      co.each do |h|
        page = ForumComment.new h
        pages << page
      end
      return pages
    end
    def to_hash_comment url
      # for testing i may send in a saved file, so i don't keep hitting HN
      if !File.exists? url
        unless url.index("http")
          url = @host + "/" + url
        end
      end
      page = Nokogiri::HTML(open(url))
      h = {}
      title = page.css("td.title")
      article_url = title.css("a").first["href"]
      h[:title] = title.text
      h[:article_url] = article_url

      subtext = page.css("td.subtext")
      h[:byline] = subtext.text
      # TODO extract age_text
      h[:age_text] = subtext.text.scan(/\d+ \w+ ago/).first
      score = subtext.css("span").text
      h[:points] = score
      subtext.css("a").each_with_index do |e, i|
        link = e["href"]
        text = e.text
        if link.index("user") == 0
          h[:submitter] = text
          h[:submitter_url] = link
        elsif link.index("item") == 0
          h[:comment_count] = text
          h[:comments_url] = link
        end
      end

      # need to get points
      comheads = page.css("span.comhead") # .collect do |e| e.text ; end
      comments = page.css("span.comment").collect do |e| e.text ; end
      comheads.delete(comheads.first)
      # array of comments
      carr = Array.new
      comheads.zip(comments) do |head,c| 
        hh={}; hh[:head] = head.text; 
        #$stderr.puts "head:: #{head.text}"
        m = head.text.scan(/\d+ \w+ ago/)
        if !m.empty?
          hh[:age_text] = m.first.scan(/\d+ \w/).first.rjust(4)
          hh[:age] = human_age_to_unix(m.first)
          head.css("a").each_with_index do |e, i|
            link = e["href"]
            text = e.text
            if link.index("user") == 0
              hh[:submitter] = text
              hh[:submitter_url] = link
            elsif link.index("item") == 0
              hh[:text] = text
              hh[:comment_url] = link
            end
          end
        end
        hh[:comment_text]=c; 
        carr << hh 
      end

      h[:comments] = carr
      return h
    end
    def hash_to_class h
      p = ForumPage.new
      p.url = h[:url]
      p.next_url = h[:next_url]
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
    # convert the front page to a hash
    def to_hash url
      doc  = get_doc_for_url url
      count = 0
      page = {}
      page[:url] = url

      arr = Array.new
      h = {}
      links = doc.xpath("//table/tr/td/table/tr")
      links.each_with_index do |li, i|
        x = li.css("td.title")
        if !x.empty?
          #puts "   ---- title ----- #{x.count} "
          count = x[0].text
          #puts count
          if x.count < 2
            # this block is for the next_url
            article_url = x[0].css("a")[0]["href"]   # link url
            #puts article_url
            h = {}
            h[:title] = count
            h[:article_url] = article_url
            more = count
            more_url = "#{@host}/#{article_url}"
            #arr << h
            page[:next_url] = more_url
            #puts li
          end
          break if x.count < 2

          # actual article url
          title = x[1].css("a")[0].text   # title
          article_url = x[1].css("a")[0]["href"]   # link url
          #puts article_url
          #puts title
          h = {}
          #h[:number] = count
          h[:title] = title
          # ask option does not have hostname since it is relative to HN
          if article_url.index("http") != 0
            article_url = "#{@host}/#{article_url}"
          end

          h[:article_url] = article_url
          arr << h
        else 
          x = li.css("td.subtext")
          if !x.empty?
            fulltext = x.text
            #puts "   ---- subtext ----- (#{fulltext})"
            submitter = nil
            submitter_url = nil
            comment = nil
            comments_url = nil
            t = x.css("a")
            t.each_with_index do |tt, ii|
              case ii
              when 0
                submitter = tt.text
                submitter_url = tt["href"]
              when 1
                comment = tt.text
                comments_url = tt["href"]
                comments_url = "#{@host}/#{comments_url}"
              end
            end
            points = x.css("span").text rescue ""
            #puts submitter
            #puts submitter_url
            #puts comment
            #puts comments_url
            #puts points
            h[:submitter] = submitter
            h[:submitter_url] = submitter_url
            h[:comment_count] = comment.to_i.to_s.rjust(4)
            h[:comments_url] = comments_url
            h[:points] = points.to_i.to_s.rjust(4)
            m = fulltext.scan(/\d+ \w+ ago/)
            if m
              #h[:age_text] = m.first
              h[:age_text] = m.first.scan(/\d+ \w/).first.rjust(4)
              h[:age] = human_age_to_unix(m.first)
            end
            #puts "fulltext: #{fulltext} "
            h[:byline] = fulltext
          end
        end
      end
      #return arr
      page[:articles] = arr
      return page
    end
  end # class
end # module
