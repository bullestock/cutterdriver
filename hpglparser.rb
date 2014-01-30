def generateMoveCommands(bb, s)
  minX = bb[0]
  minY = bb[1]
  maxX = bb[2]
  maxY = bb[3]
  xScale = 15000/(maxX-minX)
  yScale = 15000/(maxY-minY)
  numbers = s.split(",")
  firstCoords = true
  isX = true
  coords = ""
  prevCoords = ""
  numbers.each { |n|
    n = n.to_i()
    if (isX)
      n -= minX
      n *= xScale
      coords = "#{n}, "
      isX = false
    else
      n -= minY
      n *= yScale
      coords += "#{n}"
      if (firstCoords)
        puts "move(sp, #{coords})"
        firstCoords = false
      else
        puts "line(sp, #{prevCoords}, #{coords}, delay)"
      end
      prevCoords = coords
      isX = true
      coords = ""
    end
  }
end

def computeBoundingBox(bb, s)
  numbers = s.split(",")
  firstCoords = true
  isX = true
  coords = ""
  prevCoords = ""
  numbers.each { |n|
    n = n.to_i()
    if (isX)
      bb[0] = [bb[0], n].min()
      bb[2] = [bb[2], n].max()
      isX = false
    else
      bb[1] = [bb[1], n].min()
      bb[3] = [bb[3], n].max()
      isX = true
    end
  }
  return bb
end

def pass1(lines)
  minX = 1e6
  maxX = 0
  minY = 1e6
  maxY = 0
  bb = [minX, minY, maxX, maxY]
  lines.each { |c|
    c.strip!
    prefix = c[0..1]
    if (prefix == "PA")
      bb = computeBoundingBox(bb, c[2..-1])
    end
  }
  puts "BB: #{bb}"
  return bb
end

def pass2(bb, lines)
  lines.each { |c|
    c.strip!
    #puts c
    prefix = c[0..1]
    #puts prefix
    if (prefix == "PU")
      puts "poweroff(sp)"
      generateMoveCommands(bb, c[2..-1])
    end
    if (prefix == "PD")
      if (c.length > 2)
        generateMoveCommands(c[2..-1])
      end
      puts "poweron(sp, power)"
    end
    if (prefix == "PA")
      generateMoveCommands(bb, c[2..-1])
    end
  }
end

filename = ARGV[0]

puts "# Generated from #{filename}"

text = File.open(filename).read()

commands = text.split(";")

bb = pass1(commands)

pass2(bb, commands)

