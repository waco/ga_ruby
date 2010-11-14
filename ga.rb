#!/usr/bin/ruby

# Copyright 2009 Google Inc. All Rights Reserved.

require 'cgi'
require 'digest/md5'
require 'open-uri'

$cgi = CGI.new

#Tracker version.
GA_VERSION = "4.4sh"
COOKIE_NAME = "__utmmobile"

#The path the cookie will be available to, edit this to use a different
#cookie path.
COOKIE_PATH = "/"

#Two years in seconds.
COOKIE_USER_PERSISTENCE = 63072000

#1x1 transparent GIF
GIF_DATA = [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
  0x01, 0x00, 0x01, 0x00, 0x80, 0xff,
  0x00, 0xff, 0xff, 0xff, 0x00, 0x00,
  0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02,
  0x02, 0x44, 0x01, 0x00, 0x3b
]

#The last octect of the IP address is removed to anonymize the user.
def get_ip(remote_address)
  return "" unless remote_address

  #Capture the first three octects of the IP address and replace the forth
  #with 0, e.g. 124.455.3.123 becomes 124.455.3.0
  regex = /^([^.]+\.[^.]+\.[^.]+\.).*/
  if matches = remote_address.scan(regex)
    return matches[0][0] + "0"
  else
    return ""
  end
end

#Generate a visitor id for this hit.
#If there is a visitor id in the cookie, use that, otherwise
#use the guid if we have one, otherwise use a random number.
def get_visitor_id(guid, account, user_agent, cookie)

  #If there is a value in the cookie, don't change it.
  return cookie unless cookie

  message = ""
  if guid && guid != ""
    #Create the visitor id using the guid.
    message = guid + account
  else
    #otherwise this is a new user, create a new random id.
    message = user_agent + Digest::MD5.hexdigest(get_random_number)
  end

  md5_string = Digest::MD5.hexdigest(message)

  return "0x" + md5_string
end

#Get a random number string.
def get_random_number()
  rand(0x7fffffff).to_s
end


#Writes the bytes of a 1x1 transparent gif into the response.
def write_gif_data(utm_url, time_stamp, visitor_id)
  header = {}

  header["Content-Type"] = "image/gif"
  header["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
  header["Pragma"] = "no-cache"
  header["Expires"] = "Wed, 17 Sep 1975 21:32:10 GMT"

  #If the debug parameter is on, add a header to the response that contains
  #the url that was used to contact Google Analytics.
  header["X-GA-MOBILE-URL"] = utm_url if $cgi["utmdebug"] != ""

  #Always try and add the cookie to the response.
  header["cookie"] = CGI::Cookie.new({
    "name" => COOKIE_NAME,
    "value" => visitor_id,
    "expire" => time_stamp + COOKIE_USER_PERSISTENCE.to_s,
    'path' => COOKIE_PATH
  })

  $cgi.out(header){GIF_DATA.pack("C35")}
end

#Make a tracking request to Google Analytics from this server.
#Copies the headers from the original request to the new one.
#If request containg utmdebug parameter, exceptions encountered
#communicating with Google Analytics are thown.
def send_request_to_google_analytics(utm_url)
  options = {
    "method" => "GET",
    "user_agent" => ENV["HTTP_USER_AGENT"],
    "header" => "Accepts-Language: #{ENV["HTTP_ACCEPT_LANGUAGE"]}"
  }
  if $cgi["utmdebug"] == ""
    OpenURI::open_uri(utm_url, options)
  else
    OpenURI::open_uri(utm_url, options) {|f| warn f.read }
  end
end

#Track a page view, updates all the cookies and campaign tracker,
#makes a server side request to Google Analytics and writes the transparent
#gif byte data to the response.
def track_page_view()
  time_stamp = Time.now.to_s
  domain_name = ENV["SERVER_NAME"]
  domain_name ||= ""

  #Get the referrer from the utmr parameter, this is the referrer to the
  #page that contains the tracking pixel, not the referrer for tracking
  #pixel.
  document_referer = $cgi["utmr"]
  if document_referer != "" && document_referer != "0"
    document_referer = "-"
  else
    document_referer = CGI.unescape(document_referer)
  end

  document_path = $cgi["utmp"]
  document_path ||= ""
  document_path = CGI.unescape(document_path)

  account = $cgi["utmac"]
  user_agent = ENV["HTTP_USER_AGENT"]
  user_agent ||= ""

  #Try and get visitor cookie from the request.
  cookie = $cgi.cookies[COOKIE_NAME]

  guid_header = ENV["HTTP_X_DCMGUID"]
  guid_header ||= ENV["HTTP_X_UP_SUBNO"]
  guid_header ||= ENV["HTTP_X_JPHONE_UID"]
  guid_header ||= ENV["HTTP_X_EM_UID"]

  visitor_id = get_visitor_id(guid_header, account, user_agent, cookie)

  utm_gif_location = "http://www.google-analytics.com/__utm.gif"

  #Construct the gif hit url.
  utm_url = utm_gif_location + "?" +
    "utmwv=" + GA_VERSION +
    "&utmn=" + get_random_number +
    "&utmhn=" + CGI::escape(domain_name) +
    "&utmr=" + CGI::escape(document_referer) +
    "&utmp=" + CGI::escape(document_path) +
    "&utmac=" + account +
    "&utmcc=__utma%3D999.999.999.999.999.1%3B" +
    "&utmvid=" + visitor_id +
    "&utmip=" + get_ip(ENV["REMOTE_ADDR"])

  send_request_to_google_analytics(utm_url)

  #Finally write the gif data to the response.
  write_gif_data(utm_url, time_stamp, visitor_id)
end

track_page_view
