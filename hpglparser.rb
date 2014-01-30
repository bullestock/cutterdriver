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

def generateMoveCommands(bb, s, sp, width, delay, doDryRun, isTextMode)
  minX = bb[0]
  minY = bb[1]
  maxX = bb[2]
  maxY = bb[3]
  stepsPerCm = 400.0
  xScale = width*stepsPerCm/(maxX-minX)
#  xScale = 15000.0/(maxX-minX)
  yScale = xScale
  numbers = s.split(",")
  firstCoords = true
  isX = true
  coords = []
  prevCoords = []
  numbers.each { |n|
    n = n.to_f()
    if (isX)
      n -= minX
      n *= xScale
      coords = [n.to_i()]
      isX = false
    else
      n -= minY
      n *= yScale
      coords.push(n.to_i())
      if (firstCoords)
        if isTextMode
          puts "move(sp, #{coords[0]}, #{coords[1]})"
        else
          move(sp, coords[0], coords[1])
        end
        firstCoords = false
      else
        if isTextMode
          puts "line(sp, #{prevCoords[0]}, #{prevCoords[1]}, #{coords[0]}, #{coords[1]}, #{delay})"
        else
          if doDryRun
            move(sp, coords[0], coords[1])
          else
            line(sp, prevCoords[0], prevCoords[1], coords[0], coords[1], delay)
          end
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

def pass2(bb, lines, sp, width, power, delay, doDryRun, isTextMode)
  lines.each { |c|
    c.strip!
    #puts c
    prefix = c[0..1]
    #puts prefix
    if (prefix == "PU")
      if !isTextMode
        poweroff(sp)
      end
      generateMoveCommands(bb, c[2..-1], sp, width, delay, doDryRun, isTextMode)
    end
    if (prefix == "PD")
      if (c.length > 2)
        generateMoveCommands(c[2..-1], sp, width, delay, doDryRun, isTextMode)
      end
      if !doDryRun && !isTextMode
        poweron(sp, power)
      end
    end
    if (prefix == "PA")
      generateMoveCommands(bb, c[2..-1], sp, width, delay, doDryRun, isTextMode)
    end
  }
end

filename = ARGV[0]
text = File.open(filename).read()

width = ARGV[1].to_f()
if width == 0
  puts "Missing width"
  exit
end

puts "Cutting #{filename} at #{width}"

sp = nil
if !isTextMode
  sp = SerialPort.new("/dev/ttyUSB0",
                      { 'baud' => 9600,
                        'data_bits' => 8,
                        'parity' => SerialPort::NONE
                      })
end

if !isTextMode
  sleep 1
  poweroff(sp)
end

power = 30
#delay = 0.05
delay = 0.02

commands = text.split(";")

bb = pass1(commands)

pass2(bb, commands, sp, width, power, delay, doDryRun, isTextMode)

if !isTextMode
  reset(sp)
  poweroff(sp)
end
