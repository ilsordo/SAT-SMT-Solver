#!/usr/bin/ruby
# -*- coding: utf-8 -*-

def color1(name,threads)
  db = Database::new

  algos = ["dpll","wl"]
  heuristics = ["dlis","dlcs","moms","jewa"]
    
  def boucle(algos,heuristics,&block)
    (0..10).each do |x|
      timeout = {}
      5.times do 
        p = ProblemColor::new(20,x/10.0,10)
        puts p
        proc = p.gen
        algos.each do |algo|
          heuristics.each do |h|
            report = Report::new
            begin
              raise Timeout::Error if timeout[algo+h]
              entry,result = proc.call(algo,h,50)
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


def analyze_time_versus_p(name, max_time = 60)
  db = Database::new name
  
  names = {:title => "Temps d'execution de color (n = 20, k = 10)", :xlabel=>"p", :ylabel => "Temps (s)"}

  l = select_data({}) { |p, r| [p[:algo]+"+"+p[:heuristic],p[:p],r["Time (s)"]] if r["Time (s)"]/r.count<= max_time }

  db.to_gnuplot l,"stats_script/skel.p",names
end

