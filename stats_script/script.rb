#!/usr/bin/ruby
load "stats_script/base.rb"


def main
  puts "Hello World"
  db = Database::new
  algos = ["dpll","wl"]
  h = ["rand_rand","rand_mf"]
  n = (1..5).map {|x| 10*x}
  l = [3]
  k = (1..5).map {|x| 10*x}
  sample = 5
  Threads.times do 
    Thread::new do
      run_tests(n,l,k,algos,h,sample) { |problem, report| db.record(problem, report) }  
    end
  end
  db
end

if __FILE__ == $0
  p main
end
