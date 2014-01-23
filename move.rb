def line(s, p1x, p1y, p2x, p2y, delay)

  deltax = (p2x - p1x).to_i()
  deltay = (p2y - p1y).to_i()

  ystep = deltay > 0 ? 1 : -1

  if deltax == 0
    y = p1y
    begin
      move(s, p1x, y)
      y += ystep
      sleep delay
    end while y != p2y+ystep
    return
  end

  error = 0
  deltaerror = (deltay.to_f() / deltax.to_f()).abs()
  xstep = deltax > 0 ? 1 : -1

  y = p1y
  x = p1x
  begin
    move(s, x, y)
    sleep delay
    error += deltaerror
    if error >= 0.5
      y += ystep
      --error
    end
    x += xstep
  end while x != p2x+xstep
  
end

def move(s, x, y)
  s.puts "PA#{x.to_i()},#{y.to_i()};"
end

def poweron(s, level)
  s.puts "PD#{level.to_i()};"
end

def poweroff(s)
  s.puts "PU;"
end

def reset(s)
  s.puts "PA0,0;"
end
