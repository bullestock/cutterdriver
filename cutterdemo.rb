require './move'
require 'rubygems'
require 'serialport'

sp = SerialPort.new("/dev/ttyUSB0",
                    { 'baud' => 9600,
                      'data_bits' => 8,
                      'parity' => SerialPort::NONE
                    })

sleep 1
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

delay = 0.05

length = 100

power = 10

x = 200
y = 0

for i in 1..10
  rectangle(sp, x, y, length, length, delay, power)
  power += 10
  y += 200
end

reset(sp)

sleep 1
