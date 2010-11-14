#!/usr/bin/ruby

require 'cgi'

$cgi = CGI.new

GA_ACCOUNT = "YOUR ACCOUNT HERE"
GA_PIXEL = "/ga.rb"

def google_analytics_get_image_url
  url = ""
  url << GA_PIXEL + "?"
  url << "utmac=" + GA_ACCOUNT
  url << "&utmn=" + rand(0x7fffffff).to_s
  referer = ENV["HTTP_REFERER"]
  query = ENV["QUERY_STRING"]
  path = ENV["REQUEST_URI"]
  unless referer
    referer = "-"
  end
  url << "&utmr=" + CGI.escape(referer)
  if path
    url << "&utmp=" + CGI.escape(path)
  end
  url << "&guid=ON"

  url.gsub "&", "&amp"
end

$cgi.out(){%{<img src="#{google_analytics_get_image_url}" />}}
