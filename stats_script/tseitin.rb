#!/usr/bin/ruby
# -*- coding: utf-8 -*-

def tseitin(name,threads)
  db = Database::new

  algos = ["dpll","wl"]
  heuristics = ["dlcs","dlis","jewa"]
  l = [100,200,300,400,500,1000,1500,2000,2500,3000,3500,4000]
     
  def boucle(l,algos,heuristics,&block)
    l.each do |c|
      2.times do
        p = ProblemTseitin::new(100,c)
        puts p
        proc = p.gen
        algos.each do |algo|
          heuristics.each do |h|
            report = Report::new
            begin
              entry,result = proc.call(algo,h,150) #### ici
              report << result
              yield(entry,report) if result
            rescue Timeout::Error
              puts "Timeout : #{p}, #{algo}, #{h}"
              timeout[algo+h] = true
            end               
          end
        end
      end
    end
  end
  
  threads.times do 
    Thread::new do
      boucle(l,algos,heuristics) { |entry,report| db.record(entry,report) }
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

