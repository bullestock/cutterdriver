require './move'
require 'rubygems'
require 'serialport'
require 'optparse'

doDryRun = false
isTextMode = false

OptionParser.new do |opts|
  opts.banner = "Usage: hpglparser.rb [-n] [-t] file width"

  opts.on("-n", "--dry-run", "Dry run") do |n|
    doDryRun = n
  end
  opts.on("-t", "--text", "Dump commands") do |n|
    isTextMode = n
  end
end.parse!

def generateMoveCommands(bb, s, sp, width, delay, doDryRun, isTextMode, xOffset, yOffset)
  numbers = s.split(",")
  generateMoveCommandsFromArray(bb, numbers, sp, width, delay, doDryRun, isTextMode, xOffset, yOffset)
end

def generateMoveCommandsFromArray(bb, numbers, sp, width, delay, doDryRun, isTextMode, xOffset, yOffset)
  minX = bb[0]
  minY = bb[1]
  maxX = bb[2]
  maxY = bb[3]
  stepsPerCm = 400.0
  xScale = width*stepsPerCm/(maxX-minX)
#  xScale = 15000.0/(maxX-minX)
  yScale = xScale
  firstCoords = true
  isX = true
  coords = []
  prevCoords = []
  numbers.each { |n|
    n = n.to_f()
    if (isX)
      n -= minX
      n *= xScale
      n += xOffset*stepsPerCm
      coords = [n.to_i()]
      isX = false
    else
      n -= minY
      n *= yScale
      n += yOffset*stepsPerCm
      coords.push(n.to_i())
      if (firstCoords)
        move(sp, coords[0], coords[1], isTextMode)
        firstCoords = false
      else
        if doDryRun
          move(sp, coords[0], coords[1], isTextMode)
        else
          line(sp, prevCoords[0], prevCoords[1], coords[0], coords[1], delay, isTextMode)
        end
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
  return bb
end

def pass2(bb, lines, sp, width, power, delay, doDryRun, isTextMode, xOffset, yOffset)
  line = 0
  lines.each { |c|
    c.strip!
    #puts c
    prefix = c[0..1]
    #puts prefix
    if (prefix == "PU")
      if !isTextMode
        poweroff(sp)
      end
      generateMoveCommands(bb, c[2..-1], sp, width, delay, doDryRun, isTextMode, xOffset, yOffset)
      if !isTextMode && !doDryRun
        sleep 1
      end
    end
    if (prefix == "PD")
      if (c.length > 2)
        numbers = c[2..-1].split(",")
        generateMoveCommands(numbers[0], sp, width, delay, doDryRun, isTextMode, xOffset, yOffset)
        if !doDryRun
          if isTextMode
            puts "poweron(sp, #{power})"
          else
            poweron(sp, power)
          end
        end
        if (numbers.length > 1)
          generateMoveCommands(numbers[1..-1], sp, width, delay, doDryRun, isTextMode, xOffset, yOffset)
        end
      end
    else
      if !doDryRun
        if isTextMode
          puts "poweron(sp, #{power})"
        else
          poweron(sp, power)
        end
      end
    end
    if (prefix == "PA")
      generateMoveCommands(bb, c[2..-1], sp, width, delay, doDryRun, isTextMode, xOffset, yOffset)
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

puts "Cutting #{filename} at width #{width} cm, #{power} % power"

sp = nil
if !isTextMode
  sp = SerialPort.new("/dev/ttyUSB0",
                      { 'baud' => 9600,
                        'data_bits' => 8,
                        'parity' => SerialPort::NONE
                      })
  sleep 1
  poweroff(sp)
end

#delay = 0.05
delay = 0.05

commands = text.split(";")

bb = pass1(commands)

pass2(bb, commands, sp, width, power, delay, doDryRun, isTextMode, xOffset, yOffset)

if !isTextMode
  reset(sp)
  poweroff(sp)
end
