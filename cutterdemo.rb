require './move'
require 'rubygems'
require 'serialport'

sp = SerialPort.new("/dev/ttyUSB0",
                    { 'baud' => 9600,
                      'data_bits' => 7,
                      'parity' => SerialPort::NONE
                    })

banner = sp.read_nonblock(80);
puts "Banner: #{banner}"

sleep 1

for i in 1..10
  puts "OFF"
  sp.write "PU;"
  sleep 2
  puts "ON"
  sp.write "PD;"
  sleep 1
end

puts "LINE"
line(0, 0, 150, 200)

sleep 1000
