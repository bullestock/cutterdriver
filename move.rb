# Draw a line between two points. x: 0-15000, y: 0-10000
def line(s, p1x, p1y, p2x, p2y, delay, isTextMode)

  if isTextMode
    puts "line(sp, #{p1x}, #{p1y}, #{p2x}, #{p2y}, #{delay})"
  end

  deltax = (p2x - p1x).to_i()
  deltay = (p2y - p1y).to_i()

  ystep = deltay > 0 ? 1 : -1

  if deltax == 0
    y = p1y
    begin
      move(s, p1x, y, isTextMode)
      y += ystep
      if !isTextMode 
        sleep delay
      end
    end while y != p2y+ystep
    return
  end

  error = 0.0
  deltaerror = (deltay.to_f() / deltax.to_f()).abs()
  y = p1y
  x = p1x
  xstep = deltax > 0 ? 1 : -1

  if deltaerror > 1
    deltaerror = (deltax.to_f() / deltay.to_f()).abs()
    y = p1y
    x = p1x
    begin
      move(s, x, y, isTextMode)
      if !isTextMode 
        sleep delay
      end
      error += deltaerror
      while error >= 0.5
        x += xstep
        error -= 1.0
      end
      y += ystep
    end while y != p2y+ystep
  else
    begin
      move(s, x, y, isTextMode)
      if !isTextMode 
        sleep delay
      end
      error += deltaerror
      while error >= 0.5
        y += ystep
        error -= 1.0
      end
      x += xstep
    end while x != p2x+xstep
  end
end

# Move to a specific position. x: 0-15000, y: 0-10000
def move(s, x, y, isTextMode)
  if isTextMode
    puts "move(sp, #{x}, #{y})"
    puts "PA#{x.to_i()},#{y.to_i()};"
  else
    s.puts "PA#{x.to_i()},#{y.to_i()};"
  end
end

# Turn the laser on.
def poweron(s, level)
  sleep 0.1
  s.puts "PD#{level.to_i()};"
end

# Turn the laser off.
def poweroff(s)
  s.puts "PU;"
  sleep 0.1
end

# Turn the laser off and move to the home position.
def reset(s)
  poweroff(s)
  sleep 0.1
  s.puts "PA0,0;"
  sleep 0.1
end

# Draw a rectangle.
def rectangle(sp, x, y, width, length, delay, power)
  puts "Go to start"
  move(sp, x, y)
  sleep 1
  puts "Power: #{power} %"
  poweron(sp, power)
  puts "Line 1"
  line(sp, x, y, x+width, y, delay)
  puts "Line 2"
  line(sp, x+width, y, x+width, y+length, delay)
  puts "Line 3"
  line(sp, x+width, y+length, x, y+length, delay)
  puts "Line 4"
  line(sp, x, y+length, x, y, delay)
  poweroff(sp)
  puts "DONE"
end
