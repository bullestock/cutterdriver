def generateMoveCommands(s)
  numbers = s.split(",")
  firstCoords = true
  isX = true
  coords = ""
  prevCoords = ""
  numbers.each { |n|
    n = n.to_i()
    if (isX)
      n += 9039
      n = (n/5).to_i()
      coords = "#{n}, "
      isX = false
    else
      n += 9050
      n = (n/5).to_i()
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

filename = ARGV[0]

puts "# Generated from #{filename}"

text = File.open(filename).read()

commands = text.split(";")

commands.each { |c|
  c.strip!
  #puts c
  prefix = c[0..1]
  #puts prefix
  if (prefix == "PU")
    puts "poweroff(sp)"
    generateMoveCommands(c[2..-1])
  end
  if (prefix == "PD")
    if (c.length > 2)
      generateMoveCommands(c[2..-1])
    end
    puts "poweron(sp, power)"
  end
  if (prefix == "PA")
    generateMoveCommands(c[2..-1])
  end
}
