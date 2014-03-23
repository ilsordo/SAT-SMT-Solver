#!/usr/bin/ruby
require 'tempfile'

Heuristics = ["rand_rand","rand_mf","next_rand","next_mf","moms","dlis"]
Algos = ["wl","dpll"]

class Result
  attr_accessor :timers, :stats, :sat

  def initialize
    @timers = {}
    @stats = {}
    @sat = nil
  end

  def is_compatible? r
    raise ArgumentError unless r == nil or r.is_a? Result
    r == nil or (@timers.keys.sort == r.timers.keys.sort and @stats.keys.sort == r.stats.keys.sort)
  end 

  def add r
    raise ArgumentError unless r == nil or r.is_a? Result
    if r then
      @timers.keys.each { |key| @timers[key] += r.timers[key] }
      @stats.keys.each { |key| @stats[key] += r.stats[key] }
      @sat += r.sat
    end
    self
  end
end

class Report
  attr_reader :count, :result
  
  def initialize
    @count = 0
    @result = nil
  end

  def << result
    raise ArgumentError unless result.is_compatible? @result
    @result = result.add @result
    @count += 1
    self
  end

  def merge! report
    raise ArgumentError unless report.is_a? Report
    @count += report.count - 1
    self << report.result
  end
end


class Database
  attr_reader :data

  def initialize (source = nil)
    @data = {}
    @data.default = nil
    raise ArgumentError if source and not source.is_a? IO
    if source
      merge! Marshal.load(source)
    end
  end

  def save
    Marshal.dump(self)
  end

  def record problem, report
    repr = @data[@data.keys[0]]
    raise ArgumentError unless problem.is_a? Problem 
    raise ArgumentError unless report.is_a? Report 
    raise ArgumentError unless report.result.is_compatible? repr.result
    if @data.key? problem then
      @data[problem].merge! report
    else
      @data[problem] = report
    end
  end

  def merge! o
    raise ArgumentError unless o.is_a? Database
    o.data.each { |problem,report| self.record problem,report }
    self
  end
end

class Problem

  attr_reader :n, :l, :k, :algo, :heuristic

  def initialize(n = 10, l = 3, k = 10, algo = "dpll", heuristic = "rand_rand")
    @temp = nil
    @n = n
    @l = l
    @k = k
    @algo = if Algos.include? algo
              algo 
            else
              raise ArgumentError 
            end
    @heuristic = if Heuristics.include? heuristic 
                   heuristic
                 else
                   raise ArgumentError
                 end
  end
  
  def to_s
    "<Problem : n=#{@n}, l=#{@l}, k=#{@k}, algo=#{@algo}, heuristic=#{@heuristic}>"
  end

  alias inspect to_s
  
  def hash
    to_s.hash
  end
  
  def eql? o
    to_s.eql? o.to_s
  end
  
  def gen
    temp = Tempfile.open("sat")
    system "./gen #{@n} #{@l} #{@k} > #{temp.path}"
    Proc::new {
      result = Result::new
      puts "./main -algo #{@algo} -h #{@heuristic} #{temp.path} 2>&1"
      IO::popen "./main -algo #{@algo} -h #{@heuristic} #{temp.path} 2>&1" do |io|
        io.each do |line|
          case line
          when /\[stats\] (?<stat>\w+) = (?<value>\d+)/
            result.stats[$~[:stat]] = $~[:value].to_i
          when /\[timer\] (?<timer>\w+) : (?<value>\d+(\.\d+)?) s/
            result.timers[$~[:timer]] = $~[:value].to_f
          when /s SATISFIABLE/
            result.sat = 1.0
          when /s UNSATISFIABLE/
            result.sat = 0.0
          end
        end
      end
      result
    }
  end
end


def main
  puts "Hello World"
  report = Report::new
  p = Problem::new
  proc = p.gen
  report << proc.call << proc.call
  db = Database::new
  db.data[p] = report
  db
end

if __FILE__ == $0
  main
end
