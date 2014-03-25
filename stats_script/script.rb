#!/usr/bin/ruby
load "stats_script/base.rb"

def main
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

  filter = select_data(nil,3,10,nil,nil) { |p,r|  [p.n,r.result.timers["Time (s)"]/r.count]}
  names = {:title => "Titre", :xlabel=>"Axe x", :ylabel => "Axe y"}

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  db.to_gnuplot filter,"stats_script/skel.p",names
end


def populate name
  db = Database::new

  algos = Algos
  h = Heuristics
  n = (1..100).map {|x| 100*x}
  l = [3]
  k = (1..100).map {|x| 100*x}
  sample = 5

  Threads.times do 
    Thread::new do
      run_tests(n,l,k,algos,h,sample) { |problem, report| db.record(problem, report) }  
    end
  end

  while Thread::list.length != 1 do
    puts "Saving"
    db.save name
    sleep 600    
  end

  db.to_gnuplot filter,"stats_script/skel.p",names
end

if __FILE__ == $0
  main
end
