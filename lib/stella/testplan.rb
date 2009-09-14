require 'stella/testplan/usecase'
require 'stella/testplan/stats'

module Stella
class Testplan
  include Gibbler::Complex
  
  class WackyRatio < Stella::Error
    def message; "Usecase ratio cannot be higher than 100 (#{@obj})"; end
  end

  
  attr_accessor :usecases
  attr_accessor :base_path
  attr_accessor :desc
  attr_reader :stats
  
  def initialize
    @desc, @usecases = "Stella's plan", []
    @testplan_current_ratio = 0
    @stats = Stella::Testplan::Stats.new
  end
  
  def self.load_file(path)
    conf = File.read path
    plan = Stella::Testplan.new
    plan.base_path = File.dirname path
    # eval so the DSL code can be executed in this namespace.
    plan.instance_eval conf
    plan
  end
  
  def check!
    # Adjust ratios if necessary
    needy = @usecases.select { |u| u.ratio < 0 }
    needy.each do |u|
      u.ratio = (remaining_ratio / needy.size).to_i
    end
    # Give usecases a name if necessary
    @usecases.each_with_index { |uc,i| uc.desc ||= "Usecase ##{i+1}" }
    raise WackyRatio, @testplan_current_ratio if @testplan_current_ratio > 100 
  end
    
  def usecase(*args, &blk)
    return @usecases if args.empty?
    ration, name = nil,nil
    ratio, name = args[0], args[1] if args[0].is_a?(Fixnum)
    ratio, name = args[1], args[0] if args[0].is_a?(String)
    uc = Stella::Testplan::Usecase.new
    uc.base_path = @base_path
    uc.instance_eval &blk
    uc.ratio, uc.desc = (ratio || -1).to_i, name
    @testplan_current_ratio += uc.ratio if uc.ratio > 0
    add_usecase uc
  end
  def xusecase(*args, &blk); Stella.ld "Skipping usecase"; end
  
  def add_usecase(uc)
    Stella.ld "Usecase: #{uc.desc}"
    @usecases << uc
    uc
  end
  
  def desc(*args)
    @desc = args.first unless args.empty?
    @desc
  end

  def pretty
    str = []
    str << " %-50s ".att(:reverse) % [@desc]
    @usecases.each_with_index do |uc,i| 
      description = uc.desc || "Usecase ##{i+1}"
      str << "  %s (%s)".bright % [description, uc.ratio]
      requests = uc.requests.each do |r| 
        str << "    %-35s %s" % ["#{r.desc}:", r]
        if Stella.loglev > 2
          [:wait].each { |i| str << "      %s: %s" % [i, r.send(i)] }
        end
      end
    end
    str.join($/)
  end
  
  private
  def remaining_ratio
    100 - @testplan_current_ratio
  end
  
end
end

__END__
# instance_exec for Ruby 1.8 written by Mauricio Fernandez
# http://eigenclass.org/hiki/instance_exec
if RUBY_VERSION =~ /1.8/
  module InstanceExecHelper; end
  include InstanceExecHelper
  def instance_exec(*args, &block) # !> method redefined; discarding old instance_exec
    mname = "__instance_exec_#{Thread.current.object_id.abs}_#{object_id.abs}"
    InstanceExecHelper.module_eval{ define_method(mname, &block) }
    begin
      ret = send(mname, *args)
    ensure
      InstanceExecHelper.module_eval{ undef_method(mname) } rescue nil
    end
    ret
  end
end
