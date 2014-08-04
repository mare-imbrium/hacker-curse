# Hacker  Curse

View Hacker News and Reddit.com pages from within your terminal.

## Installation

    $ gem install hacker-curse

## Usage

The basic library uses nokogiri to parse hacker news and reddit.com subforums into a similar 
structure so that a single program can render output from both sources.

      hn = RedditNewsParser.new :subforum => 'ruby'
      or 
      hn = HackerNewsParser.new :subforum => 'news'

      page = hn.get_next_page
      page.each_article do |a|
          print a.title, a.age_text, a.points, a.comment_count, a.article_url, "\n"
      end
      art = page.first
      art.each_comment do |c|
         print c.age_text, c.points, c.submitter, "\n"
         print c.comment_text
      end





This program comes with several wrappers which display how to use the library and the wrappers may
themselves be used as-is.

For example, `hacker-tsv.rb` prints the articles and its details such as age, points and number of comments, 
url, comments url, submitter etc in a tab delimited format. This may further be used be filtered or sorted
by other programs.

As an example, the following retrieves two pages of stories from Hacker News and save the retrieved HTML file, 
the output goes to the terminal/screen.

     hacker-tsv.rb -H hn -p 2 -s news -w news.html 

Retrieve one page of articles from reddit.com/r/ruby printing the tab delimited rows to the screen.

     hacker-tsv.rb -H rn -s ruby 

`hacker.rb` is a wrapper over `hacker-tsv.rb` that saves the output of the above into tab delimited files.
It can guess the host based on the argument.

     hacker.rb news
     hacker.rb newest
     hacker.rb programming
     hacker.rb --pages 2 ruby

`corvus` is an interactive program (non-ncurses) that uses the above generated TSV files, and displays a selectable list
of stories which a user may navigate, select and launch the article (or comments) in a gui or text browser.
User may switch between forums, reload the file, view the articles in a long list or short list, single or
multiple columns etc. `corvus` requires at least ruby 1.9.3 in order to get single characters.

Finally, the curses-based program is to be written. I am currently working on `corvus` which allows me
to get the functionality down, and firm up the API. Once this is over, I can start working on a ncurses
version.

p.s. I am moving corvus to use the YML output rather than the TSV files for two reasons:
- the tab separated values file does not keep a link to next_url whereas the YML does.
- THe YML can contain the date of retrieval of data, whereas currentl we need to check the
modified date of the TSV file to find out how old the data is.
- If there is any error, such as no rows, the YML file has a blank/empty articles array
whereas the TSV file may be zero bytes and give errors which need to be trapped in various places.

The TSV file should be used as a command-line filter, and not in applications or front-ends.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hacker-curse/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
