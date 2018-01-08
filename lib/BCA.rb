require 'BCA/version'
require 'curb'
require 'nokogiri'

module BCA
  USER_AGENT = "BCA-#{VERSION}.gem".freeze
  BASE_URL = 'https://ibank.klikbca.com'.freeze

  class Client
    def initialize(username, password)
      @username = username
      @password = password
    end

    def login
      curl = Curl::Easy.new("#{BASE_URL}/authentication.do")
      curl.headers['User-Agent'] = USER_AGENT
      # curl.verbose = true

      @cookies = []
      curl.on_header do |header|
        @cookies << "#{Regexp.last_match(1)}=#{Regexp.last_match(2)}" if
        header =~ /^Set-Cookie: ([^=]+)=([^;]+)/
        header.length
      end

      curl.http_post(
        Curl::PostField.content('value(actions)', 'login'),
        Curl::PostField.content('value(user_id)', @username),
        Curl::PostField.content('value(pswd)', @password),
        # Curl::PostField.content("value(user_ip)", "111.94.26.135"),
        # Curl::PostField.content("value(mobile)", "false"),
        Curl::PostField.content('value(Submit)', 'LOGIN')
      )

      # rubocop:disable Style/IfInsideElse
      if curl.response_code != 200
        message = Regexp.last_match(1).to_s if
          curl.body_str =~ %r{<title>(.+?)<\/title>}
      else
        message = Regexp.last_match(1).to_s if
          curl.body_str =~ /var err=\s*'([^';]*)/
      end
      # rubocop:enable Style/IfInsideElse

      if message
        @cookies = nil
        [false, message]
      else
        [true, 'Successfully logged in']
      end
    end

    def welcome
      return nil if @cookies.nil?

      url = "#{BASE_URL}/authentication.do?value(actions)=welcome"
      curl = Curl::Easy.new(url)
      curl.headers['User-Agent'] = USER_AGENT
      curl.cookies = @cookies.join(';')
      curl.http_get
      curl.body_str[/[^>]*(?<=\, Selamat Datang Di Internet Banking BCA)/]
    end

    def balance_inquiry
      return nil if @cookies.nil?

      curl = Curl::Easy.new("#{BASE_URL}/balanceinquiry.do")
      curl.headers['User-Agent'] = USER_AGENT
      curl.cookies = @cookies.join(';')
      curl.http_post
      html = Nokogiri::HTML(curl.body_str)
      lines = []
      html.xpath('//table/tr').each do |tr|
        lines << tr.text.gsub(/[\n]+/, '').strip.tr(',', '.')
                   .gsub(/[ ]{2,}/, ',')
      end
      lines.join("\n")
    end

    def statement_download
      return nil if @cookies.nil?

      url = "#{BASE_URL}/stmtdownload.do?value(actions)=account_statement"
      curl = Curl::Easy.new(url)
      curl.headers['User-Agent'] = USER_AGENT
      curl.cookies = @cookies.join(';')
      curl.http_post(
        Curl::PostField.content('value(r1)', '2'),
        Curl::PostField.content('value(x)', '1')
      )
      curl.body_str
    end

    def logout
      return nil if @cookies.nil?

      url = "#{BASE_URL}/authentication.do?value(actions)=logout"
      curl = Curl::Easy.new(url)
      curl.headers['User-Agent'] = USER_AGENT
      curl.cookies = @cookies.join(';')
      curl.http_get
      @cookies = nil
      # p curl.body_str
    end
  end
end
