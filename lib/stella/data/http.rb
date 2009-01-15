
require 'utils/httputil'
require 'base64'

module Stella::Data
  
  # TODO: Implement HTTPHeaders. We should be printing untouched headers. 
  # HTTPUtil should split the HTTP event lines and that's it. Replace 
  # parse_header_body with split_header_body
  class HTTPHeaders < Stella::Storable
    attr_reader :raw_data
    
    def to_s
      @raw_data
    end
    
  end
  
  class HTTPRequest < Stella::Storable
    attr_reader :raw_data
    
    field :time => DateTime
    field :client_ip 
    field :server_ip 
    field :header 
    field :uri
    field :body 
    field :http_method
    field :http_version
    
    def has_body?
      @body && !@body.nil & !@body.empty?
    end
    def has_request?
      false
    end
    def has_response?
      (@response && @response.status && !@response.status.nil?)
    end
    
    def initialize(raw_data=nil)
      @raw_data = raw_data
      if @raw_data
        @http_method, @http_version, @uri, @header, @body = HTTPUtil::parse_http_request(raw_data) 
      end
      @response = Stella::Data::HTTPResponse.new
    end
    
    def uri
      @uri.host = @server_ip.to_s if @uri && (@uri.host == 'unknown' || @uri.host.empty?)
      @uri
    end
    
    def body
      return nil unless @body
      @body
      #(!header || header[:Content_Type] || header[:Content_Type] !~ /text/) ? Base64.encode64(@body) : @body
    end
    

    
    def inspect
      headers = []
      header.each_pair do |n,v|
        headers << "#{n.to_s.gsub('_', '-')}: #{v[0]}"
      end
      str = "%s %s HTTP/%s" % [http_method, uri.to_s, http_version]
      str << $/ + headers.join($/)
      str << $/ + $/ + body if body
      str
    end
    
    def to_s
      str = "%s: %s %s HTTP/%s" % [time.strftime(NICE_TIME_FORMAT), http_method, uri.to_s, http_version]
      str
    end
    
  end
  
  class HTTPResponse < Stella::Storable
    attr_reader :raw_data
    
    field :time => DateTime
    field :client_ip => String
    field :server_ip => String
    field :header => String
    field :body => String
    field :status => String
    field :message => String
    field :http_version => String
    
    def initialize(raw_data=nil)
      @raw_data = raw_data
      if @raw_data
        @status, @http_version, @message, @header, @body = HTTPUtil::parse_http_response(@raw_data)
      end
    end
    
    def has_body?
      @body && !@body.nil? & !@body.empty?
    end
    def has_request?
      false
    end
    def has_response?
      false
    end
    
    def body
      return nil unless @body
      #Base64.encode64(@body)
      (!header || !header[:Content_Type] || header[:Content_Type] !~ /text/) ? '' : @body
    end
    
    def inspect
      headers = []
      header.each_pair do |n,v|
        headers << "#{n.to_s.gsub('_', '-')}: #{v[0]}"
      end
      str = "HTTP/%s %s (%s)" % [@http_version, @status, @message]
      str << $/ + headers.join($/)
      str << $/ + $/ + body if body
      str
    end
    
    def to_s
      str = "%s: HTTP/%s %s (%s)" % [time.strftime(NICE_TIME_FORMAT), @http_version, @status, @message]
      str 
    end
  end
end 