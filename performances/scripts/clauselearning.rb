#!/usr/bin/ruby
# -*- coding: utf-8 -*-


def all_cl(name, threads)
  db = Database::new

  couples = [["dpll","moms"],["wl","dlcs"],["dpll","jewa"],["dpll","dlcs"],["wl","jewa"]]
  n = [100,150,200,250,300]
  l = [3]
  k = (1..20).map {|x| 100*x}
  cl = [true,false]
  sample = 3                   
  timeout = 700
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,couples,cl,sample,timeout) { |problem, report| db.record(problem, report) if report}
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 600
  end
  
  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end


def partial_cl(name, threads)
  db = Database::new

  couples = [["dpll","rand_rand"],["wl","rand_rand"]]
  n = [100,150,200,250,300]
  l = [3]
  k = (1..20).map {|x| 100*x}
  cl = [true,false]
  sample = 3                   
  timeout = 700
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,couples,cl,sample,timeout) { |problem, report| db.record(problem, report) if report}
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 600
  end
  
  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end


def shake(name, threads)
  db = Database::new

  couples = [["wl","jewa"],["wl","dlcs"]]
  n = [200,250]
  l = [3]
  k = (1..20).map {|x| 100*x}
  cl = [true,false]
  sample = 2                   
  timeout = 700
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,couples,cl,sample,timeout) { |problem, report| db.record(problem, report) if report}
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 600
  end
  
  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end


def analyze_cl name
  db = Database::new name

  filter = select_data({:algo => "wl"},2) { |p,r| ["Cl:#{p[:cl]}", p[:k], r["Total execution (s)"]]}
  names = {:title => "n = 80, l = 3, algo dpll+jewa", :xlabel => "k", :ylabel => "Time (s)"}
  db.to_gnuplot(filter,names)
end
