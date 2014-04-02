#!/usr/bin/ruby
# -*- coding: utf-8 -*-

load "stats_script/base.rb"

def main
  db = Database::new

  algos = ["dpll"]
  h = ["next_rand"]
  n = (1..1).map {|x| 100*x}
  l = [3]
  k = (1..1).map {|x| 100*x}
  sample = 2                    # nombres de passages (*nb de proc)

  Threads.times do 
    Thread::new do
      run_tests(n,l,k,algos,h,sample,0) { |problem, report| db.record(problem, report) if problem and report}  
    end
  end



  filter = select_data(100,3,nil,nil,nil) { |p,r| [p.k,r.result.timers["Time (s)"]/r.count]}
  names = {:title => "Titre", :xlabel=>"Axe x", :ylabel => "Axe y"}

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  db.to_gnuplot filter,"stats_script/skel.p",names
end



def debug
  db = Database::new

  algos = ["dpll","wl"]
  h = ["rand_rand","rand_mf"]
  n = (1..5).map {|x| 10*x}
  l = [3]
  k = (1..5).map {|x| 10*x}
  sample = 5                    # nombres de passages (*nb de proc)

  Threads.times do 
    Thread::new do
      run_tests(n,l,k,algos,h,sample) { |problem, report| db.record(problem, report) if problem and report}  
    end
  end

  filter = select_data(nil,3,10,nil,nil) { |p,r| [p.n,r.result.timers["Time (s)"]/r.count]}
  names = {:title => "Titre", :xlabel=>"Axe x", :ylabel => "Axe y"}

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  # puts db.data

  db.to_gnuplot filter,"stats_script/skel.p",names
end


def populate name
  db = Database::new

  algos = ["dpll"]
  h = ["next_rand"]
  n = (1..1).map {|x| 1000*x}
  l = [3]
  k = (1..1).map {|x| 4300*x}
  sample = 1                    # nombres de passages (*nb de proc)

  Threads.times do 
    Thread::new do
      run_tests(n,l,k,algos,h,sample,2) { |problem, report| db.record(problem, report) if report}  # and problem ? # TIME LIMIT ici
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 30    
  end

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"


end



def exemple
  db = Database::new
  
  def my_iter db, &block
    (30..100).each do |n|
      (3*n..4*n).each do |k|
        problem, report = run_test(n,3,k,"dpll","dlis",5,1) # run_test(n,3,k,"dpll","dlis",10) 10 passages
        db.record(problem, report)
      end
    end
  end

  Threads.times do my_iter db end

  db
end

if __FILE__ == $0
  main
end

