require './move'
require 'rubygems'
require 'serialport'
require 'optparse'

doDryRun = false
isTextMode = false
doMirror = false

OptionParser.new do |opts|
  opts.banner = "Usage: hpglparser.rb [-n] [-t] file width [power] [xOffset] [yOffset] [speed]"

  opts.on("-n", "--dry-run", "Dry run") do |n|
    doDryRun = n
  end
  opts.on("-t", "--text", "Dump commands") do |n|
    isTextMode = n
  end
  opts.on("-m", "--mirror", "Mirror around Y.axis") do |n|
    doMirror = n
  end
end.parse!

def scale(x, y, bb, xOffset, yOffset, xScale, yScale, doMirror)
  stepsPerCm = 400.0
  minX = bb[0]
  minY = bb[1]
  maxX = bb[2]
  maxY = bb[3]
  sX = x
  sX -= minX
  sX *= xScale
  sX += xOffset*stepsPerCm
  sY = y
  if doMirror
    sY = maxY - sY
  else
    sY -= minY
  end
  sY *= yScale
  sY += yOffset*stepsPerCm
  return [ sX.to_i(), sY.to_i()]
end

def generateMoveCommands(bb, numbers, penDown, prevPos, sp, width, delay, power, doDryRun, isTextMode, doMirror, xOffset, yOffset)
  minX = bb[0]
  minY = bb[1]
  maxX = bb[2]
  maxY = bb[3]
  stepsPerCm = 400.0
  xScale = width*stepsPerCm/(maxX-minX)
  yScale = xScale
  firstCoords = true
  isX = true
  coords = []
  x = 0
  sX = 0
  numbers.each { |n|
    n = n.to_f()
    if (isX)
      x = n
      isX = false
    else
      y = n
      coords = scale(x, y, bb, xOffset, yOffset, xScale, yScale, doMirror)
      if isTextMode
        puts "# (#{x}, #{y}) -> (#{coords[0]}, #{coords[1]})"
      end
      if (firstCoords && !penDown)
        move(sp, coords[0], coords[1], isTextMode)
        firstCoords = false
      else
        if doDryRun
          move(sp, coords[0], coords[1], isTextMode)
        else
          line(sp, prevPos[0], prevPos[1], coords[0], coords[1], delay, isTextMode)
        end
      end
      prevPos = coords
      isX = true
      coords = ""
    end
  }
  return prevPos
end

def moveTo(bb, numbers, sp, isTextMode, doMirror, width, xOffset, yOffset)
  minX = bb[0]
  minY = bb[1]
  maxX = bb[2]
  maxY = bb[3]
  stepsPerCm = 400.0
  xScale = width*stepsPerCm/(maxX-minX)
  yScale = xScale
  x = numbers[0].to_f()
  y = numbers[1].to_f()
  coords = scale(x, y, bb, xOffset, yOffset, xScale, yScale, doMirror)
  if isTextMode
    puts "# (#{x}, #{y}) -> (#{coords[0]}, #{coords[1]})"
  end
  move(sp, coords[0], coords[1], isTextMode)
  return [coords[0], coords[1]]
end

def computeBoundingBox(bb, s)
  numbers = s.split(",")
  firstCoords = true
  isX = true
  coords = ""
  numbers.each { |n|
    n = n.to_f()
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

def pass1(lines, isTextMode)
  minX = 1e6
  maxX = 0
  minY = 1e6
  maxY = 0
  bb = [minX, minY, maxX, maxY]
  lines.each { |c|
    c.strip!
    prefix = c[0..1]
    if (prefix == "PA") || (prefix == "PU") || (prefix == "PD")
      bb = computeBoundingBox(bb, c[2..-1])
    end
  }
  if isTextMode
    puts "# Bounding box #{bb}"
  end
  return bb
end

def pass2(bb, lines, sp, width, power, delay, doDryRun, isTextMode, doMirror, xOffset, yOffset)
  line = 0
  penDown = false
  prevPos = []
  lines.each { |c|
    c.strip!
    #puts c
    prefix = c[0..1]
    #puts prefix
    if (prefix == "PU")
      if isTextMode
        puts "# PU #{c[2..-1]}"
        puts "poweroff(sp)"
      else
        poweroff(sp)
      end
      penDown = false
      pos = c[2..-1].split(",")
      prevPos = moveTo(bb, pos, sp, isTextMode, doMirror, width, xOffset, yOffset)
      if !isTextMode && !doDryRun
        sleep 1
      end
    end
    if (prefix == "PD")
      if isTextMode
        puts "# PD #{c[2..-1]}"
      end
      penDown = true
      if (c.length > 2)
        numbers = c[2..-1].split(",")
        if !doDryRun
          if isTextMode
            puts "poweron(sp, #{power})"
          else
            poweron(sp, power)
          end
        end
        prevPos = generateMoveCommands(bb, numbers, penDown, prevPos, sp, width, delay, power, doDryRun, isTextMode, doMirror, xOffset, yOffset)
      else
        if !doDryRun
          if isTextMode
            puts "poweron(sp, #{power})"
          else
            poweron(sp, power)
          end
        end
      end
    end
    if (prefix == "PA")
      if isTextMode
        puts "# PA #{c[2..-1]}"
        puts "# prevPos #{prevPos}"
      end
      prevPos = generateMoveCommands(bb, c[2..-1].split(","), penDown, prevPos, sp, width, delay, power, doDryRun, isTextMode, doMirror, xOffset, yOffset)
    end
    line += 1
    percent = line*100.0/lines.size()
    if !isTextMode && !doDryRun
      print "#{percent.to_i()} %\r"
      STDOUT.flush
    end
  }
  if !isTextMode && !doDryRun
    puts ""
  end
end

filename = ARGV[0]
text = File.open(filename).read()

width = ARGV[1].to_f()
if width == 0
  puts "Missing width"
  exit
end

power = ARGV[2].to_i()
if power == 0
  power = 30
end

xOffset = ARGV[3].to_i()
yOffset = ARGV[4].to_i()

speed = ARGV[5].to_i()

puts "Cutting #{filename} at width #{width} cm, #{power} % power"

$sp = nil
if !isTextMode
  $sp = SerialPort.new("/dev/ttyUSB0",
                      { 'baud' => 9600,
                        'data_bits' => 8,
                        'parity' => SerialPort::NONE
                      })
  sleep 1
  poweroff($sp)

  trap("SIGINT") {
    poweroff($sp)
    exit!
  }

end

delay = 0.1/(speed+1)
puts "Using delay #{delay}"

commands = text.split(";")

startTime = Time.now

bb = pass1(commands, isTextMode)

pass2(bb, commands, $sp, width, power, delay, doDryRun, isTextMode, doMirror, xOffset, yOffset)

if !isTextMode
  sleep 1
  reset($sp)
  poweroff($sp)
end

endTime = Time.now

puts "Completed in #{endTime-startTime} seconds"
