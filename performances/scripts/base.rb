#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'tempfile'
require 'timeout'

Heuristics = ["rand_rand","rand_mf","next_rand","next_mf","moms","dlis","dlcs","jewa"]
Algos = ["wl","dpll"]
Skeleton = "performances/scripts/skel.p"

class Result < Hash

end

class Report

  def [] x
    @data[x]
  end

  def []=(x, a)
    @data[x] = a
  end

  def keys
    @data.keys
  end

  def initialize
    @data = {"count" => 0}
    @data.default = 0
  end

  def count
    @data["count"]
  end
  
  def add_count count
    @data["count"] += count
  end
  
  def << result
    raise ArgumentError unless result.is_a? Result
    result.keys.each do |key|
      @data[key] += result[key]
    end
    add_count 1
    self
  end

  def merge! report
    raise ArgumentError unless report.is_a? Report
    report.keys.each do |key|
      @data[key] += report[key]
    end
  end
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

  def record entry, report
    raise ArgumentError unless entry and report and report.is_a? Report
    if report.count > 0
      @mutex.lock
      if @data.key? entry then
        @data[entry].merge! report
      else
        @data[entry] = report.dup
      end
      @mutex.unlock
    end
    self
  end

  def merge! o
    raise ArgumentError unless o.is_a? Database
    o.data.each { |entry,report| self.record entry,report }
    self
  end

  # On accède aux données par h[valeur][série]
  # names : { :title => "titre", :xlabel => "x label", :ylabel => ylabel }
  def to_gnuplot (filter,names)
    if data.empty?
      puts "Empty database"
      return
    end

    names = names.dup
    h = Hash::new { |hash,key| hash[key] = Hash::new 0 }
    count = Hash::new { |hash,key| hash[key] = Hash::new 0 }
    data.each do |entry, report|
      serie, param, valeur = filter.call(entry, report)
      if serie
        p [serie, param, valeur]
        h[param][serie] += valeur
        count[param][serie] += report.count
      end
    end
    h.each do |param, serie|
      serie.each do |key, value|
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

    series = {}
    h1.values.each { |x| x.keys.each { |serie| series[serie] = true } }
    series = series.keys
    p series
    
    names[:ncols] = series.length + 1
    data = Tempfile::new "data"
    names[:data] = data.path
    
    data.write "PARAM"
    series.each { |serie| data.write (" "+serie.to_s.upcase) }
    data.write "\n"
    h1.each do |param, cols|
      data.write param
      series.each do |serie|
        if cols[serie]
          data.write (" "+cols[serie].to_s)
        else
          data.write " ?0"
        end
      end
      data.write "\n"
    end
    data.flush
    
    script = Tempfile::new "script"
    script.write (open Skeleton).read.gsub(/#\{(\w*)\}/) { |match| names[$1.to_sym] }
    script.flush

    system "gnuplot -persist #{script.path}"
  end
end

#"#{problem.algo}+#{problem.heuristic}"

class Problem

  attr_reader :params

  def [] x
    @params[x]
  end

  def []=(x,a)
    @params[x] = a
  end

  def initialize(params,gen_string,run_options)
    raise ArgumentError unless params[:type]
    @params = params
    @gen_string = gen_string
    @run_options = run_options
  end
  
  def to_s
    "<Problem : #{@params}>"
  end

  alias inspect to_s
  
  def hash
    @params.hash
  end
  
  def eql? o
    @params.eql? o.params
  end

  def gen
    temp = Tempfile.open("sat")
    system ("./gen " + (@gen_string.gsub(/#\{(\w*)\}/) { |match| @params[$1.to_sym] }) + " > #{temp.path}")
    Proc::new { |algo,heuristic,timeout = 0|
      timeout ||= 0
      raise ArgumentError unless Algos.include? algo and Heuristics.include? heuristic
      result = Result::new
      IO::popen "if ! timeout #{timeout} ./main -algo #{algo} -h #{heuristic} #{@run_options.gsub(/#\{(\w*)\}/) { |match| @params[$1.to_sym] }} #{temp.path} 2>&1; then echo \"Timeout\"; fi" do |io|
        io.each do |line|
          case line
          when /\[stats\] (?<stat>.+) = (?<value>\d+)/
            result[$~[:stat]] = $~[:value].to_i
          when /\[timer\] (?<timer>.+) : (?<value>\d+(\.\d+)?)/
            result[$~[:timer]] = $~[:value].to_f
          when /s SATISFIABLE/
            result["sat"] = 1.0
          when /s UNSATISFIABLE/
            result["sat"] = 0.0
          when /Timeout/
            raise Timeout::Error
          end
        end
      end
      [({:algo => algo, :heuristic => heuristic}.merge @params) , result]
    }
  end
end

class ProblemCnf < Problem
  def initialize(n = 10, l = 3, k = 10)
    super({:type => :cnf, :n => n, :l => l, :k => k}, '#{n} #{l} #{k}', "")  
  end
end

class ProblemColor < Problem
  def initialize(vertices = 10, p = 0.5, k = 3)
    super({:type => :color, :vertices => vertices, :p => p, :k => k}, '-color #{vertices} #{p}', '-color #{k}')  
  end
  
  def dicho(algo, heuristic) # Ne fonctionne pas :(
    raise ArgumentError unless Algos.include? algo and Heuristics.include? heuristic
    min = 0
    max = @params[:vertices]
    p = gen
    entry = nil
    report = Report::new
    while min != max do
      p min
      p max
      target = (min+max)/2
      @params[:k] = target
      entry, result = p.call(algo, heuristic)
      p entry, result
      report << result
      if result["sat"] == 1
        min, max = min, target
      else
        min, max = (target + 1), max
      end
    end
    [entry,report]
  end
end

class ProblemTseitin < Problem
  def initialize(n_vars = 3, size = 10)
    super({:type => :tseitin, :n_vars => n_vars, :size => size}, '-tseitin #{n_vars} #{size}', "-tseitin")  
  end
end


def run_tests_cnf(n,l,k,algos,heuristics,sample=1, limit = nil,&block)
  limit ||= 0
  n.each do |n_|
    l.each do |l_|
      k.each do |k_|
        sample.times do
          p = ProblemCnf::new(n_,l_,k_)
          puts p
          proc = p.gen
          algos.each do |a_|
            heuristics.each do |h_|
              report = Report::new
              begin
                entry,result = proc.call(a_,h_,limit)
                report << result
                yield(entry,report) if result
              rescue Timeout::Error
                puts "Timeout : #{p}, #{a_}, #{h_}"
              end 
            end
          end
        end
      end
    end
  end
  true
end




# Sélectionne les données selon constraints et passe les données acceptées à une fonction qui calcule la valeur mesurée
# Le traitement du yield doit renvoyer [série,paramètre,valeur] 
def select_data(constraints,min_count = 0, &block)
  lambda { |entry,report|
    if report.count >= min_count and (constraints.all? do |param,range| (range.respond_to? "include?" and range.include? entry[param]) or range === entry[param] end)
      yield(entry,report)
    else
      nil
    end
  }
end
