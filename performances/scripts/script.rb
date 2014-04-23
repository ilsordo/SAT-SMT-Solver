#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#################################
# Série 1                       #
#################################

def phase(name, threads)
  db = Database::new

  algos = ["wl"]
  h = ["dlcs"]
  n = (80..80).map {|x| 1*x}
  l = [3,4,5]
  k = (1..5).map {|x| 50*x}
  sample = 2                    # nombres de passages (*nb de proc)
  timeout = 6
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report}
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 6
  end

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end

#################################

def all1(name, threads)
  db = Database::new

  algos = ["dpll","wl"]
  h = ["next_rand","next_mf","rand_rand","rand_mf","dlcs","moms","dlis","jewa"]
  n = [100,200]
  l = [3,25,50,75,100]
  k = (1..30).map {|x| 100*x}
  sample = 3                  
  timeout = 305
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report} 
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

#################################

def sat3(name, threads)
  db = Database::new
  
  def my_iter db, &block
    (1..20).each do |m|
      problem, report = run_test(50*m,3,(4.27*50*m).round,"wl","dlcs",2,605)
      db.record(problem, report)
      end
  end

  threads.times do 
      Thread::new do
        my_iter db 
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

#################################

def all2(name, threads)
  db = Database::new

  algos = ["dpll","wl"]
  h = ["next_rand","next_mf","rand_rand","rand_mf","dlcs","moms","dlis","jewa"]
  n = [3000]
  l = [500,1000]
  k = [1000,5000,10000]
  sample = 3                    
  timeout = 305
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report}  # and problem ?
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

#################################
# Série 2                       #
#################################

def small_length(name, threads)
  db = Database::new

  algos = ["dpll","wl"]
  h = ["next_rand","next_mf","rand_rand","rand_mf","dlcs","moms","dlis","jewa"]
  n = [50,100,150,200]
  l = [3]
  k = (1..30).map {|x| 100*x}
  sample = 3                  
  timeout = 305
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report} 
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

#################################

def phase_transition(name, threads)
  db = Database::new

  algos = ["wl"]
  h = ["dlcs"]
  n = [80]
  l = [3,4,5]
  k = (1..30).map {|x| 100*x}
  sample = 2       
  timeout = 605
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report}
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

#################################

def big_length(name, threads)
  db = Database::new

  algos = ["dpll","wl"]
  h = ["next_rand","next_mf","rand_rand","rand_mf","dlcs","moms","dlis","jewa"]
  n = [2000]
  l = [500]
  k = [500,1500,2000,2500,3000,3500]
  sample = 3                    
  timeout = 305
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report}
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

#################################

def hard_3sat(name, threads)
  db = Database::new
  
  def my_iter db, &block
    (1..40).each do |m|
      problem, report = run_test(25*m,3,(4.27*25*m).round,"wl","dlcs",3,1200)
      db.record(problem, report)
      end
  end

  threads.times do 
      Thread::new do
        my_iter db 
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

#################################
#################################

def tseitin1(name, threads)
  db = Database::new

  algos = ["dpll","wl"]
  h = ["dlcs","dlis","jewa"]
  n = [100,500,1000,5000,10000,50000]
  l = [100,500,1000,5000,10000,25000]
  k = [1]
  sample = 3                    
  timeout = 305
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report}
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

#################################


def tseitin2(name, threads)
  db = Database::new

  algos = ["wl"] #"dpll"
  h = ["dlcs","dlis","jewa"]
  n = [100]
  l = [100,200,300,400,500,1000,1500,2000,2500,3000,3500,4000,4500,5000,6000,7000,8000,9000,10000,15000,20000,25000,30000,35000,40000,45000,50000]
  k = [1]
  sample = 3                    
  timeout = 305
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample,timeout) { |problem, report| db.record(problem, report) if report}
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


