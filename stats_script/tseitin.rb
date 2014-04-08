#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'pry'

load "stats_script/base.rb"

def tseitin(name,threads)
  db = Database::new

  algos = ["dpll","wl"]
  heuristics = ["dlcs","dlis","jewa"]
  l = [100,200,300,400,500,1000,1500,2000,2500,3000,3500,4000]
  sample = 3                    
  timeout = 305
     
  def boucle(algos,heuristics,&block)
      [100,200,300,400,500,1000,1500,2000,2500,3000,3500,4000].each do |c|
          sample.times do
            p = ProblemTseitin::new([100],c)
            puts p
            proc = p.gen
            algos.each do |algo|
              heuristics.each do |h|
                report = Report::new
                begin
                  entry,result = proc.call(algo,h,timeout)
                  report << result
                  yield(entry,report) if result
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



pry
