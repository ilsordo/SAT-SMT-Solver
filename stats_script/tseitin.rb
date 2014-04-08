#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'pry'

load "stats_script/base.rb"

def tseitin1(name,threads)
  db = Database::new

  algos = ["dpll","wl"]
  heuristics = ["dlcs","dlis","jewa"]
  n = [100]
  l = [100,200,300,400,500,1000,1500,2000,2500,3000,3500,4000]
  sample = 3                    
  timeout = 305
     
  def boucle(algos,heuristics,&block)
    (100..100).each do |n|
      [100,200,300,400,500,1000,1500,2000,2500,3000,3500,4000].each do |c|
        (1..n).each do |k|
          sample.times do ### corrigé ici
            p = ProblemColor::new(10*n,x/5.0,10*k)
            puts p
            proc = p.gen
            algos.each do |algo|
              heuristics.each do |h|
                report = Report::new
                begin
                  entry,result = proc.call(algo,h,60)
                  report << result
                  yield(entry,report) if result
              end
            end
          end
        end
      end
    end
  end

  threads.times do 
    Thread::new do
      boucle(algos,heuristics) { |entry,report| db.record(entry,report) }
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 60
  end

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end


def color2(name,threads)
  db = Database::new

  algos = ["dpll","wl"]
  heuristics = ["dlcs","jewa","dlis"]
    
  def boucle(algos,heuristics,&block)
    (1..100).each do |n|
      (1..20).each do |x|
        (1..x).each do |k|
          10.times do 
            p = ProblemColor::new(100*n,(k.to_f/x),0).gen
            algos.each do |algo|
              heuristics.each do |h|
                report = Report::new
                entry,result = p.call(algo,h,600)
                report << result
                yield(entry,report) if result
              end
            end
          end
        end
      end
    end
  end

  threads.times do 
    Thread::new do
      boucle(algos,heuristics) { |entry,report| db.record(entry,report) }
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 360
  end

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end

pry
