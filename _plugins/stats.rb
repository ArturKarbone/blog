require 'fileutils'

module Jekyll
  class StatsGenerator < Generator
    priority :low
    safe true
    def generate(site)
      dat = File.join(site.config['source'], '_temp/stats/stats.dat')
      FileUtils.mkdir_p File.dirname(dat)
      months = {}
      min = Time.parse('2014-04-01')
      site.posts.docs.each do |doc|
        next if doc.date < min
        m = doc.date.strftime("%Y-%m")
        months[m] = 0 if !months.key?(m)
        months[m] += doc.content.split(/\s+/).length
      end
      open(dat, 'w') do |f|
        for m, c in months
          f.puts "#{m}-01T00:00 #{c}"
        end
      end
      puts %x[
        set -e
        src=#{site.config['source']}
        tmp=#{File.dirname(dat)}
        cp ${src}/_stats/stats.gpi ${tmp}/stats.gpi
        cd ${tmp}
        gnuplot stats.gpi
        cp ${tmp}/stats.svg ${src}/_site/stats.svg
      ]
      raise 'failed to build gnuplot stats image' if !$?.exitstatus
      site.static_files << Jekyll::StaticFile.new(site, site.dest, '', 'stats.svg')
      puts "stats.svg created: #{File.size(File.join(site.dest, 'stats.svg'))} bytes"
      exit
    end
  end
end