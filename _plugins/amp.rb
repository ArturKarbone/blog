# Copyright (c) 2014-2017 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so. The Software doesn't include files with .md extension.
# That files you are not allowed to copy, distribute, modify, publish, or sell.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'liquid'
require 'redcarpet'
require 'nokogiri'

module Jekyll
  class AmpPage < Page
    def initialize(site, doc)
      super(site, site.source, File.dirname(doc.relative_path), doc.basename)
    end
  end
  class AmpFile < StaticFile
    def initialize(site, path, html)
      super(site, site.dest, '', path)
      @path = path
      xml = Nokogiri::HTML(html)
      xml.xpath('//comment()').remove
      xml.xpath('//@style').remove
      xml.xpath('//body//iframe').remove
      xml.xpath('//body//script').remove
      xml.xpath('//body//form').remove
      xml.xpath('//body//figure[@class="highlight"]').each do |f|
        f.before('<pre>' + f.xpath('pre//text()').to_s + '</pre>')
      end
      xml.xpath('//body//figure').remove
      xml.xpath('//body//figcaption').remove
      xml.xpath('//body//img').remove
      xml.xpath('//body//svg').remove
      xml.xpath('//body//aside').remove
      @html = xml.to_html
        .gsub(/<meta http-equiv="Content-Type" content="text\/html; charset=UTF-8">/, '')
      write(site.dest)
    end
    def write(dest)
      target = File.join(dest, @path)
      FileUtils.mkdir_p File.dirname(target)
      File.write(target, @html)
      true
    end
  end
  class AmpGenerator < Generator
    priority :low
    def generate(site)
      start = Time.now
      total = 0
      site.posts.docs.each do |doc|
        page = AmpPage.new(site, doc)
        payload = site.site_payload
        payload['page'] = page
        payload['doc'] = doc
        page.render(
          { 'post' => Layout.new(site, site.source, '_layouts/amp.html') },
          payload
        )
        site.static_files << Jekyll::AmpFile.new(
          site, doc.url.gsub(/\.html$/, '.amp.html'), page.output
        )
        total += 1
      end
      puts "#{total} AMP pages generated in #{(Time.now - start).round(2)}s"
    end
  end
end
