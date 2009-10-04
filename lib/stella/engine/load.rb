
module Stella::Engine
  module Load
    extend Stella::Engine::Base
    extend self
      
    def run(plan, opts={})
      opts = {
        :hosts        => [],
        :clients        => 1,
        :time         => nil,
        :nowait    => false,
        :repetitions  => 1
      }.merge! opts
      opts[:clients] = plan.usecases.size if opts[:clients] < plan.usecases.size
      opts[:clients] = 1000 if opts[:clients] > 1000
      
      Stella.ld "OPTIONS: #{opts.inspect}"
      Stella.li3 "Hosts: " << opts[:hosts].join(', ') 
      
      counts = calculate_usecase_clients plan, opts
      
      Stella.li $/, "Preparing #{counts[:total]} virtual clients...", $/
      Stella.lflush
      packages = build_thread_package plan, opts, counts
      
      Stella.li "Generating load...", $/
      Stella.lflush
      
      begin
        execute_test_plan packages, opts[:repetitions]
      rescue Interrupt
        Stella.li "Stopping test...", $/
        Stella.abort!
      ensure
        Stella.li "Processing statistics...", $/
        Stella.lflush
        generate_report plan

        rep_stats = self.timeline.ranges(:build_thread_package).first    
        Stella.li "%20s %0.4f" % ['Prep time:', rep_stats.duration]

        rep_stats = self.timeline.ranges(:execute_test_plan).first    
        Stella.li "%20s %0.4f" % ['Test time:', rep_stats.duration]

        rep_stats = self.timeline.ranges(:generate_report).first    
        Stella.li "%20s %0.4f" % ['Reporting time:', rep_stats.duration]
        Stella.li $/
      end
      
      !plan.errors?
    end
    

  protected
    class ThreadPackage
      attr_accessor :index
      attr_accessor :client
      attr_accessor :usecase
      def initialize(i, c, u)
        @index, @client, @usecase = i, c, u
      end
    end
    
    def calculate_usecase_clients(plan, opts)
      counts = { :total => 0 }
      plan.usecases.each_with_index do |usecase,i|
        count = case opts[:clients]
        when 0..9
          if (opts[:clients] % plan.usecases.size > 0) 
            msg = "Client count does not evenly match usecase count"
            raise Stella::Testplan::WackyRatio, msg
          else
            (opts[:clients] / plan.usecases.size)
          end
        else
          (opts[:clients] * usecase.ratio).to_i
        end
        counts[usecase.gibbler_cache] = count
        counts[:total] += count
      end
      counts
    end
    
    def build_thread_package(plan, opts, counts)
      packages, pointer = Array.new(counts[:total]), 0
      plan.usecases.each do |usecase|
        count = counts[usecase.gibbler_cache]
        Stella.ld "THREAD PACKAGE: #{usecase.desc} (#{pointer} + #{count})"
        # Fill the thread_package with the contents of the block
        packages.fill(pointer, count) do |index|
          Stella.li3 "Creating client ##{index+1} "
          client = Stella::Client.new opts[:hosts].first, index+1
          client.add_observer(self)
          client.enable_nowait_mode if opts[:nowait]
          ThreadPackage.new(index+1, client, usecase)
        end
        pointer += count
      end
      packages.compact # TODO: Why one nil element sometimes?
    end
    
    def execute_test_plan(packages, reps=1)
      Thread.ify packages, :threads => packages.size do |package|
        
        # This thread will stay on this one track. 
        Benelux.current_track package.client.gibbler
        Benelux.add_thread_tags :usecase => package.usecase.gibbler_cache
        
        (1..reps).to_a.each do |rep|
          Benelux.add_thread_tags :rep =>  rep
          Stella::Engine::Load.rescue(package.client.gibbler_cache) {
            break if Stella.abort?
            print '.' if Stella.loglev == 1
            stats = package.client.execute package.usecase
          }
          Benelux.remove_thread_tags :rep
        end
        
        Benelux.remove_thread_tags :usecase
      end
      Stella.li $/, $/
    end
      
    def generate_report(plan)
      Benelux.update_all_track_timelines
      global_timeline = Benelux.timeline
      
      p global_timeline.counts
      
      Stella.li $/, " %-72s  ".att(:reverse) % ["#{plan.desc}  (#{plan.gibbler_cache.shorter})"]
      plan.usecases.uniq.each_with_index do |uc,i| 
        
        # TODO: Create Ranges object, like Stats object
        # global_timeline.ranges(:do_request)[:usecase => '1111']
        # The following returns globl do_request ranges. 
        requests = 0 #global_timeline.ranges(:do_request).size
        
        desc = uc.desc || "Usecase ##{i+1} "
        desc << "  (#{uc.gibbler_cache.shorter}) "
        str = ' ' << " %-66s %s   %d%% ".bright.att(:reverse)
        Stella.li str % [desc, '', uc.ratio_pretty]
        
        uc.requests.each do |req| 
          desc = req.desc 
          Stella.li "   %-72s ".bright % ["#{req.desc}  (#{req.gibbler_cache.shorter})"]
          Stella.li "    %s" % [req.to_s]
          global_timeline.stats.each_pair do |n,stat|
            filter = {
              :usecase => uc.gibbler_cache,
              :request => req.gibbler_cache
            }
            stats = stat[filter]
            Stella.li '      %-30s %.3f <= %.3f >= %.3f; %.3f(SD) %d(N)' % [n, stats.min, stats.mean, stats.max, stats.sd, stats.n]
            Stella.lflush
          end
          Stella.li $/
        end
      end
    end
    
    
    def update_prepare_request(client_id, usecase, req, counter)
      
    end
      
    def update_receive_response(client_id, usecase, uri, req, counter, container)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.li2 '  Client-%s %3d %-6s %-45s' % [client_id.shorter, container.status, req.http_method, uri]
    end
    
    def update_execute_response_handler(client_id, req, container)
    end
    
    def update_error_execute_response_handler(client_id, ex, req, container)
      desc = "#{container.usecase.desc} > #{req.desc}"
      Stella.li $/ if Stella.loglev == 1
      Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
      Stella.ld ex.backtrace
    end
    
    def update_request_error(client_id, usecase, uri, req, params, ex)
      desc = "#{usecase.desc} > #{req.desc}"
      Stella.li $/ if Stella.loglev == 1
      Stella.le '  Client-%s %-45s %s' % [client_id.shorter, desc, ex.message]
      Stella.ld ex.backtrace
    end

    def update_quit_usecase client_id, msg
      Stella.li2 "  Client-%s     QUIT   %s" % [client_id.shorter, msg]
    end
    
    
    def update_repeat_request client_id, counter, total
      Stella.li3 "  Client-%s     REPEAT   %d of %d" % [client_id.shorter, counter, total]
    end
    
    def self.rescue(client_id, &blk)
      blk.call
    rescue => ex
      Stella.le '  Error in Client-%s: %s' % [client_id.shorter, ex.message]
      Stella.ld ex.backtrace
    end
    
    
    Benelux.add_timer Stella::Engine::Load, :generate_report
    Benelux.add_timer Stella::Engine::Load, :build_thread_package
    Benelux.add_timer Stella::Engine::Load, :execute_test_plan
    
  end
end

