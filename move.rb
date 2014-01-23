SleepTime = 0.1

def line(p1x, p1y, p2x, p2y)

  dx = (p1x-p2x).abs
  dy = (p1y-p2y).abs

  if dx > dy  
    begin
      xstep = dx.to_f()/dy.to_f();
      for y in p1y..p2y
        puts "PA#{x.to_i()},#{y.to_i()};"
        sleep SleepTime
        x += xstep
      end
    end
  else
    begin
      ystep = dy.to_f()/dx.to_f();
      y = p1y;
      for x in p1x..p2x
        puts "PA#{x.to_i()},#{y.to_i()};"
        sleep SleepTime
        y += ystep
      end
    end
  end
end


