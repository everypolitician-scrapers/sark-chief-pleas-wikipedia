#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end


def scrape_2008(url)
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[contains(.,"Candidate")]]//tr[td]')
  raise "No rows" if rows.count.zero?
  rows.map do |tr|
    td = tr.css('td')
    next if td[1].css('b').empty?
    data = { 
      name: td[1].text.tidy,
      source: url,
    }
    if td[3].text.tidy.to_i == 2
      data.merge({ term: 2009 })
    elsif td[3].text.tidy.to_i == 4
      [2009, 2011].map { |t| data.merge({ term: t }) }
    else 
      abort "odd term in #{td}"
    end
  end
end

def scrape_2010(url)
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[contains(.,"Candidate")]]//tr[td]')
  raise "No rows" if rows.count.zero?
  rows.map do |tr|
    td = tr.css('td')
    next if td[1].css('b').empty?
    data = { 
      name: td[1].text.tidy,
      source: url,
    }
    [2011, 2013].map { |t| data.merge({ term: t }) }
  end
end

def scrape_2012(url)
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[contains(.,"Candidate")]]//tr[td]')
  raise "No rows" if rows.count.zero?
  rows.map do |tr|
    td = tr.css('td')
    next unless td[3] && td[3].text.downcase.include?('elected')
    data = { 
      name: td[0].text.tidy,
      source: url,
    }
    [2013, 2015].map { |t| data.merge({ term: t }) }
  end
end

def scrape_2014(url)
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[contains(.,"Candidate")]]//tr[td]')
  raise "No rows" if rows.count.zero?
  rows.map do |tr|
    td = tr.css('td')
    next unless td[2] && td[2].text.downcase.include?('elected')
    data = { 
      name: td[0].text.tidy,
      source: url,
    }
    if td[1].text.tidy.to_i == 2
      data.merge({ term: 2015 })
    elsif td[1].text.tidy.to_i == 4
      [2015, 2017].map { |t| data.merge({ term: t }) }
    else 
      abort "odd term in #{td}"
    end
  end
end

mems = (
  scrape_2008("https://en.wikipedia.org/wiki/Sark_general_election,_2008") +
  scrape_2010("https://en.wikipedia.org/wiki/Sark_general_election,_2010") +
  scrape_2012("https://en.wikipedia.org/wiki/Sark_general_election,_2012") + 
  scrape_2014("https://en.wikipedia.org/wiki/Sark_general_election,_2014")
).flatten.compact.sort_by { |m| [m[:name], m[:term]] }.reject { |m| m[:term] == 2017 }

puts mems
ScraperWiki.save_sqlite([:name, :term], mems)

