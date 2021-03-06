begin
  require 'pismo'
rescue LoadError
end

class Stella
  class Log
    class HTTP < Storable
      include Gibbler::Complex
      include Selectable::Object
      field :stamp
      field :httpmethod
      field :uri     
      field :request_params
      field :request_headers
      field :request_body
      field :response_status
      field :response_headers
      field :response_body
      field :msg
    end
  end
  class Report < Storable
    include Gibbler::Complex
    CRLF = "\r\n" unless defined?(Report::CRLF)
    @plugins, @plugin_order = {}, []
    class << self
      attr_reader :plugins, :plugin_order
      def plugin?(name)
        @plugins.has_key? name
      end
      def load(name)
        @plugins[name]
      end
    end
    module Plugin
      def self.included(obj)
        obj.extend ClassMethods
        obj.field :processed => Boolean
      end
      def processed!
        @processed = true
      end
      def processed?
        @processed == true
      end
      attr_reader :report
      def initialize(report=nil)
        @report = report
      end
      module ClassMethods
        attr_reader :plugin
        def register(plugin)
          @plugin = plugin
          extra_methods = eval "#{self}::ReportMethods" rescue nil
          Stella::Report.send(:include, extra_methods) if extra_methods
          Stella::Report.field plugin => self
          Stella::Report.plugins[plugin] = self
          Stella::Report.plugin_order << plugin
        end
        def process *args
          raise StellaError, "Must override run"
        end
      end
    end

    class Errors < Storable
      include Gibbler::Complex
      include Report::Plugin
      field :exceptions
      field :timeouts
      field :fubars
      def process(filter={})
        @exceptions = report.timeline.messages.filter(:kind => :http_log, :state => :exception)
        @timeouts = report.timeline.messages.filter(:kind => :http_log, :state => :timeout)
        @fubars = report.timeline.messages.filter(:kind => :http_log, :state => :fubar)
        processed!
      end
      def exceptions?
        !@exceptions.nil? && !@exceptions.empty?
      end
      def timeouts?
        !@timeouts.nil? && !@timeouts.empty?
      end
      def fubars?
        !@fubars.nil? && !@fubars.empty?
      end
      def all 
        [@exceptions, @timeouts, @fubars].flatten
      end
      module ReportMethods
        # expects Statuses plugin is loaded
        def errors?
          exceptions? || timeouts? || fubars? || (statuses && !statuses.nonsuccessful.empty?)
        end
        def exceptions?
          return false unless processed? && errors
          errors.exceptions?
        end
        def timeouts?
          return false unless processed? && errors
          errors.timeouts?
        end
        def error_count
          errors.all.size
        end
        def fubars?
          return false unless processed? && errors
          errors.fubars?
        end
      end
      register :errors
    end
    
    class Content < Storable
      include Gibbler::Complex
      include Report::Plugin
      field :request_body
      field :response_body
      field :request_body_digest
      field :response_body_digest
      field :keywords => Array
      field :title
      field :favicon
      field :author
      field :lede
      field :description
      field :is_binary => Boolean
      field :is_image => Boolean
      field :log => Array
      def binary?
        @is_binary == true
      end
      def image?
        @is_image == true
      end
      def process(filter={})
        if report.errors.exceptions?
          @log = report.errors.exceptions
        elsif report.errors.fubars?
          @log = report.errors.fubars
        elsif report.errors.timeouts?
          @log = report.errors.timeouts
        else
          @log = report.timeline.messages.filter(:kind => :http_log, :state => :nominal)
        end
        
        return if @log.empty?
        
        unless Stella::Utils.binary?(@log.first.request_body) || Stella::Utils.image?(@log.first.request_body)
          @request_body = @log.first.request_body 
        end
        
        @request_body_digest = @log.first.request_body.digest
        @is_binary = Stella::Utils.binary?(@log.first.response_body)
        @is_image = Stella::Utils.image?(@log.first.response_body)
        unless binary? || image?
          @response_body = @log.first.response_body.to_s
          if @response_body.size >= 250_000
            @response_body = @response_body.slice 0, 249_999
            @response_body << ' [truncated]'
          end
          @response_body.force_encoding("UTF-8") if RUBY_VERSION >= "1.9.0"
          begin 
            if defined?(Pismo) && @response_body
              doc = Pismo::Document.new @response_body
              @keywords = doc.keywords rescue nil  # BUG: undefined method `downcase' for nil:NilClass
              @title = doc.title
              @favicon = doc.favicon
              @author = doc.author
              @lede = doc.lede
              @description = doc.description
            end
          rescue => ex
            Stella.li ex.message
            # /Library/Ruby/Gems/1.8/gems/nokogiri-1.4.1/lib/nokogiri/xml/fragment_handler.rb:37: [BUG] Segmentation fault
            #  ruby 1.8.7 (2008-08-11 patchlevel 72) [universal-darwin10.0]
          end
        end
        @response_body_digest = @log.first.response_body.digest
        @log.each { |entry| entry.response_body = ''; entry.request_body = '' }
        processed!
      end
      module ReportMethods
        def log
          content.log
        end
      end
      register :content
    end
    
    class Statuses < Storable
      include Gibbler::Complex
      include Report::Plugin
      field :values => Array
      def process(filter={})
        @values = report.content.log.collect { |entry| entry.tag_values(:status) }.flatten
        processed!
      end
      def nonsuccessful
        @values.select { |status| status.to_i >= 400 }
      end
      def successful
        @values.select { |status| status.to_i < 400 }
      end
      def redirected
        @values.select { |status| (300..399).member?(status.to_i) }
      end
      def success?
        nonsuccessful.empty?
      end
      def redirect?
        @values.size == redirected.size
      end
      module ReportMethods
        def redirect?
          statuses.redirect?
        end
        def success?
          statuses.success?
        end
        def statuses_pretty
          pretty = ["Statuses"]
          if statuses.successful.size > 0
            pretty << '%20s: %s' % ['successful', statuses.successful.join(', ')] 
          end
          if statuses.nonsuccessful.size > 0
            pretty << '%20s: %s' % ['nonsuccessful', statuses.nonsuccessful.join(', ')] 
          end
          pretty.join $/
        end
      end
      register :statuses
    end
    
    class Headers < Storable
      include Gibbler::Complex
      include Report::Plugin
      field :request_headers
      field :response_headers
      field :request_headers_digest
      field :response_headers_digest
      def init *args
        # TODO: This doesn't seem to be called anymore.
        @request_headers_hash = {}
        @response_headers_hash = {}
      end
      def process(filter={})
        return if report.content.log.empty?
        @request_headers = report.content.log.first.request_headers
        @response_headers = report.content.log.first.response_headers
        @request_headers_digest = report.content.log.first.request_headers.digest
        @response_headers_digest = report.content.log.first.response_headers.digest
        processed!
      end
      def request_header name=nil
        @request_headers_hash ||= {}
        if @request_headers_hash.empty? && @request_headers
          @request_headers_hash = parse(@request_headers)
        end
        name.nil? ? @request_headers_hash : @request_headers_hash[name.to_s.upcase]
      end
      def response_header name=nil
        @response_headers_hash ||= {}
        if @response_headers_hash.empty? && @response_headers
          @response_headers_hash = parse(@response_headers)
        end
        name.nil? ? @response_headers_hash : @response_headers_hash[name.to_s.upcase]
      end
      def empty?
        @response_headers.to_s.empty?
      end
      private 
      def parse str
        headers = {}
        str.split(CRLF).each do|line|
          key, value = line.split(/\s*:\s*/, 2)
          headers[key.upcase] = value
        end
        headers
      end
      register :headers
    end

    class Metrics < Storable
      include Gibbler::Complex
      include Report::Plugin
      field :response_time            => Benelux::Stats::Calculator
      field :socket_connect           => Benelux::Stats::Calculator
      field :first_byte               => Benelux::Stats::Calculator
      field :last_byte                => Benelux::Stats::Calculator
      field :send_request             => Benelux::Stats::Calculator
      field :request_headers_size     => Benelux::Stats::Calculator
      field :request_content_size     => Benelux::Stats::Calculator
      field :response_headers_size    => Benelux::Stats::Calculator
      field :response_content_size    => Benelux::Stats::Calculator
      field :requests                 => Integer
      def process(filter={})
        return if processed?
        @response_time = report.timeline.stats.group(:response_time).merge
        @socket_connect = report.timeline.stats.group(:socket_connect).merge
        @first_byte = report.timeline.stats.group(:first_byte).merge
        @send_request = report.timeline.stats.group(:send_request).merge
        @last_byte = report.timeline.stats.group(:last_byte).merge
        #@response_time2 = Benelux::Stats::Calculator.new 
        #@response_time2.sample @socket_connect.mean + @send_request.mean + @first_byte.mean + @last_byte.mean
        @requests = report.timeline.stats.group(:requests).merge.n
        @request_headers_size = Benelux::Stats::Calculator.new 
        @request_content_size = Benelux::Stats::Calculator.new 
        @response_headers_size = Benelux::Stats::Calculator.new 
        @response_content_size = Benelux::Stats::Calculator.new 

        @request_content_size.sample report.content.request_body.size unless report.content.request_body.to_s.empty?
        @response_content_size.sample report.content.response_body.size unless report.content.response_body.to_s.empty?

        @request_headers_size.sample report.headers.request_headers.size unless report.headers.request_headers.to_s.empty?
        @response_headers_size.sample report.headers.response_headers.size unless report.headers.response_headers.to_s.empty?

        # unless report.content.log.empty?
        #   report.content.log.each do |entry|
        #     @request_headers_size.sample entry.request_headers.size if entry.request_headers
        #     @request_content_size.sample entry.request_body.size if entry.request_body
        #     @response_headers_size.sample entry.response_headers.size if entry.response_headers
        #     @response_content_size.sample entry.response_body.size if entry.response_body
        #   end
        # end
        processed!
      end
      def postprocess
        self.class.field_names.each do |fname|
          next unless self.class.field_types[fname] == Benelux::Stats::Calculator
          hash = send(fname)
          val = Benelux::Stats::Calculator.from_hash hash
          send("#{fname}=", val)
        end
      end
      module ReportMethods
        def metrics_pack
          return unless metrics
          pack = ::MetricsPack.new
          pack.update Stella.now, runid.shorten, metrics.requests, metrics.response_time, metrics.socket_connect, metrics.send_request.to_f.to_s,
                      metrics.first_byte, metrics.last_byte, metrics.request_headers_size, metrics.request_content_size,
                      metrics.response_headers_size, metrics.response_content_size, 0, error_count
          pack
        end
        def metrics_pretty
          return unless metrics
          pretty = ['Metrics   (across %d requests)' % metrics.requests]
          [:socket_connect, :send_request, :first_byte, :last_byte, :response_time].each do |fname|
            val = metrics.send(fname)
            pretty << ('%20s: %8sms' % [fname.to_s.tr('_', ' '), val.mean.to_ms])
          end
          pretty << ''
          [:request_headers_size, :response_content_size].each do |fname|
            val = metrics.send(fname)
            pretty << ('%20s: %8s' % [fname.to_s.tr('_', ' '), val.mean.to_bytes])
          end
          pretty.join $/
        end
      end
      register :metrics
    end
    
    field :processed => Boolean
    field :runid
    
    attr_reader :timeline, :filter
    def initialize(timeline=nil, runid=nil)
      @timeline, @runid = timeline, runid
      @processed = false
    end
    def postprocess
      self.class.plugins.each_pair do |name,klass|
        val = klass.from_hash(self.send(name))
        self.send("#{name}=", val)
      end
      # When we load a report from a hash, some plugin
      # attributes need to be recontituted from a hash as well. 
      (self.content.log || []).collect! { |v| Stella::Log::HTTP.from_hash(v) }
    end
    def process
      self.class.plugin_order.each do |name|
        klass = self.class.plugins[name]
        Stella.ld "processing #{name}"
        plugin = klass.new self
        plugin.process(filter)
        self.send("#{name}=", plugin)
      end
      @processed = true
    end
    def processed?
      @processed == true
    end
  end
end