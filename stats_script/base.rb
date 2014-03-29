#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'tempfile'
require 'timeout'

Heuristics = ["rand_rand","rand_mf","next_rand","next_mf","moms","dlis"]
Algos = ["wl","dpll"]
Db_store = "data.db"
Skeleton = "skel.p"
Threads = 4

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

  def to_s
    "<sat=#{@sat}, timers=#{@timers}, stats=#{@stats}>"
  end

  alias inspect to_s
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
    @count += report.count
    self << report.result
  end

  def to_s
    "<Report : count=#{@count}, #{@result}>"
  end

  alias inspect to_s
end


class Database
  attr :data

  def initialize (source = nil)
    if source
      @data = Marshal.load(open source)
    else
      @data = {}
    end
    @mutex = Mutex::new
  end

  def save dest
    @mutex.lock
    open(dest, "w") do |out| out.write Marshal.dump(data); out.flush end
    @mutex.unlock
  end

  def record problem, report
    raise ArgumentError unless problem and report
    @mutex.lock
    repr = @data[@data.keys[0]]
    if @data.key? problem then
      @data[problem].merge! report
    else
      @data[problem] = report
    end
    @mutex.unlock
  end

  def merge! o
    raise ArgumentError unless o.is_a? Database
    o.data.each { |problem,report| self.record problem,report }
    self
  end

  # On accède aux données par h[valeur][algo]
  # names : { :title => "titre", :xlabel => "x label", :ylabel => ylabel }
  def to_gnuplot (filter,skel,names)
    if data.empty?
      puts "Empty database"
      return
    end

    names = names.dup
    h = Hash::new { |hash,key| hash[key] = Hash::new 0 }
    count = Hash::new { |hash,key| hash[key] = Hash::new 0 }
    data.each do |problem, report|
      x = filter.call(problem, report)
      if x
        h[x[0]]["#{problem.algo}+#{problem.heuristic}"] += x[1]
        count[x[0]]["#{problem.algo}+#{problem.heuristic}"] += report.count
      end
    end
    h.each do |param, algos|
      algos.each do |key, value|
        h[param][key] /= count [param][key]
      end
    end

    if h.empty?
      puts "No results available"
      return
    end

    h1 = {}
    h.sort_by{ |key,value| key }.each{ |key,value| h1[key] = value}
    
    # p h1

    algos = h1.values.max { |x| x.length }.keys
    names[:ncols] = algos.length + 1
    data = Tempfile::new "data"
    names[:data] = data.path
    
    data.write "PARAM"
    algos.each { |algo| data.write (" "+algo.upcase) }
    data.write "\n"
    h1.each do |param, cols|
      data.write param
      algos.each do |algo|
        if cols[algo]
          data.write (" "+cols[algo].to_s)
        else
          data.write " ?0"
        end
      end
      data.write "\n"
    end
    data.flush
    
    script = Tempfile::new "script"
    script.write (open skel).read.gsub(/#\{(\w*)\}/) { |match| names[$1.to_sym] }
    script.flush

    system "gnuplot -persist #{script.path}"
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
      #puts "./main -algo #{@algo} -h #{@heuristic} #{temp.path} 2>&1"
      IO::popen "./main -algo #{@algo} -h #{@heuristic} #{temp.path} 2>&1" do |io|
        io.each do |line|
          case line
          when /\[stats\] (?<stat>.+) = (?<value>\d+)/
            result.stats[$~[:stat]] = $~[:value].to_i
          when /\[timer\] (?<timer>.+) : (?<value>\d+(\.\d+)?)/
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

def run_test(n,l,k,a,h,sample = 1, limit = nil)
  report = Report::new
  p = Problem::new(n,l,k,a,h)
  sample.times do
    Timeout::timeout(limit,Timeout::Error) do
      begin
        report << p.gen.call
      rescue Timeout::Error
        puts "Timeout : #{p}"
      end
    end
  end
  [p,report]
end

def run_tests(n,l,k,algos,heuristics,sample=1, limit = nil,&block)
  n.each do |n_|
    l.each do |l_|
      k.each do |k_|
        algos.each do |a_|
          heuristics.each do |h_|
            yield run_test(n_,l_,k_,a_,h_,sample)
          end
        end
      end
    end
  end
  true
end



# Sélectionne les données selon nlk et passe les données acceptées à une fonction qui calcule la valeur mesurée
# Le traitement du yield doit renvoyer [paramètre,valeur] 
def select_data(n,l,k,algos,h,min_count = nil, &block)
  lambda { |p,r|
    if (n==nil or n===p.n) and (l==nil or l===p.l) and (k==nil or k===p.k)
      if (algos == nil or algos === p.algo) and (h==nil or h===p.heuristic)
        if min_count and r.count >= min_count
          yield(p, r)
        end
      end
    end
  }
end

  

