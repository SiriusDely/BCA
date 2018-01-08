require "BCA/version"
require "curb"
require "nokogiri"

module BCA

  USER_AGENT = "BCA-#{VERSION}.gem"
  # BASE_URL = "https://www.pancasila.co".freeze
  BASE_URL = "https://ibank.klikbca.com".freeze

  class Client

    def initialize(username, password)
      @username = username
      @password = password
    end

    def login
      curl = Curl::Easy.new("#{BASE_URL}/authentication.do")
      curl.headers["User-Agent"] = USER_AGENT
      # curl.verbose = true

      @cookies = []
      curl.on_header { |header|
        # p header
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

      if curl.response_code != 200
        message = "#{$1}" if curl.body_str =~ /<title>(.+?)<\/title>/
      else
        message = "#{$1}" if curl.body_str =~  /var err=\s*'([^';]*)/
      end

      if message
        @cookies = nil
        [false, message]
      else
        [true, "Successfully logged in"]
      end
    end

    def welcome
      if @coookies.nil?
        return nil
      end

      curl = Curl::Easy.new("#{BASE_URL}/authentication.do?value(actions)=welcome")
      curl.headers["User-Agent"] = USER_AGENT
      curl.cookies = @cookies.join(";")
      curl.http_get
      curl.body_str[/[^>]*(?<=\, Selamat Datang Di Internet Banking BCA)/]
    end

    def balance_inquiry
      if @coookies.nil?
        return nil
      end

      curl = Curl::Easy.new("#{BASE_URL}/balanceinquiry.do")
      curl.headers["User-Agent"] = USER_AGENT
      curl.cookies = @cookies.join(";")
      curl.http_post
      html = Nokogiri::HTML(curl.body_str)
      lines = []
      html.xpath("//table/tr").each do |tr|
        lines << tr.text.gsub(/[\n]+/, "").strip.gsub(",", ".").gsub(/[ ]{2,}/, ",")
      end
      lines.join("\n")
    end

    def statement_download
      if @coookies.nil?
        return nil
      end

      curl = Curl::Easy.new("#{BASE_URL}/stmtdownload.do?value(actions)=account_statement")
      curl.headers["User-Agent"] = USER_AGENT
      curl.cookies = @cookies.join(";")
      curl.http_post(
        Curl::PostField.content("value(r1)", "2"),
        Curl::PostField.content("value(x)", "1")
      )
      curl.body_str
    end

    def logout
      if @coookies.nil?
        return nil
      end

      curl = Curl::Easy.new("#{BASE_URL}/authentication.do?value(actions)=logout")
      curl.headers["User-Agent"] = USER_AGENT
      curl.cookies = @cookies.join(";")
      curl.http_get
      @cookies = nil
      # p curl.body_str
    end
  end
end
