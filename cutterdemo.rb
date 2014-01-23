require './move'
require 'rubygems'
require 'serialport'

sp = SerialPort.new("/dev/ttyUSB0",
                    { 'baud' => 9600,
                      'data_bits' => 8,
                      'parity' => SerialPort::NONE
                    })

sleep 5
poweroff(sp)

#banner = sp.readpartial(80);
#puts "Banner: #{banner}"

# for i in 1..10
#   puts "OFF"
#   sp.write "PU;"
#   sleep 2
#   puts "ON"
#   sp.write "PD;"
#   sleep 1
# end

delay = 0.1

length = 100

power = 75

x = 0
y = 500

poweron(sp, power)
puts "Line 1"
line(sp, x, y, x+length, y, delay)
puts "Line 2"
line(sp, x+length, y, x+length, y+length, delay)
puts "Line 3"
line(sp, x+length, y+length, x, y+length, delay)
puts "Line 4"
line(sp, x, y+length, x, y, delay)
poweroff(sp)
reset(sp)
puts "DONE"

sleep 1
