require "BCA/version"
require "curb"
require "nokogiri"

module BCA

  USER_AGENT = "BCA-#{VERSION}"
  # BASE_URL = "https://www.pancasila.co".freeze
  BASE_URL = "https://ibank.klikbca.com".freeze

  class Client

    def initialize(username, password)
      @username = username
      @password = password
      @cookies = []
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

    def login
      curl = Curl::Easy.new("#{BASE_URL}/authentication.do")
      curl.headers["User-Agent"] = USER_AGENT
      # curl.verbose = true

      @cookies = []
      curl.on_header { |header|
        p header
        @cookies << "#{$1}=#{$2}" if header =~ /^Set-Cookie: ([^=]+)=([^;]+)/
        header.length
      }

      curl.http_post(
        Curl::PostField.content("value(actions)", "login"),
        Curl::PostField.content("value(user_id)", @username),
        Curl::PostField.content("value(pswd)", @password),
        # Curl::PostField.content("value(user_ip)", "111.94.26.135"),
        # Curl::PostField.content("value(mobile)", "false"),
        Curl::PostField.content("value(Submit)", "LOGIN")
      )

      # p curl.body_str
      p @cookies
    end

    def welcome
      curl = Curl::Easy.new("#{BASE_URL}/authentication.do?value(actions)=welcome")
      curl.headers["User-Agent"] = USER_AGENT
      curl.cookies = @cookies.join(";")
      curl.http_get
      p curl.body_str
    end

    def logout
      curl = Curl::Easy.new("#{BASE_URL}/authentication.do?value(actions)=logout")
      curl.headers["User-Agent"] = USER_AGENT
      curl.cookies = @cookies.join(";")
      curl.http_get
      # p curl.body_str
    end
  end
end
