require "BCA/version"
require "curb"
require "nokogiri"

module BCA
  BASE_URL = "https://www.pancasila.co".freeze

  class Client

    def initialize(username, password)
      @username = username
      @password = password
    end

    def hi
      curl = Curl::Easy.new("#{BASE_URL}/adminlogin/")

      cookies = []
      curl.on_header { |header|
        cookies << "#{$1}=#{$2}" if header =~ /^Set-Cookie: ([^=]+)=([^;]+)/
        header.length
      }

      curl.perform
      p curl.body_str
      p cookies

      html_doc = Nokogiri::HTML(curl.body_str)
      csrfmiddlewaretoken_element = html_doc.xpath("//*[@name='csrfmiddlewaretoken']")
      csrfmiddlewaretoken = csrfmiddlewaretoken_element.attr("value").value

      curl.cookies = cookies.join(";")
      cookies = []

      curl.http_post(
        Curl::PostField.content("username", @username),
        Curl::PostField.content("password", @password),
        Curl::PostField.content("csrfmiddlewaretoken", csrfmiddlewaretoken)
      )

      p curl.body_str
      p cookies

      curl.url = "#{BASE_URL}/admin"
      curl.cookies = cookies.join(";")
      curl.http_get

      p curl.body_str
      p cookies
     end
  end
end
