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
reset(sp)
poweroff(sp)
