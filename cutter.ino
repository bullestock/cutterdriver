/*
 ROLAND PLOTTER LASERCUTTER
 
 The circuit: 
 * RX is digital pin 10 (connect to TX of other device)
 * TX is digital pin 11 (connect to RX of other device)
 * PWM is digital pin 9 
 
 */
#include <SoftwareSerial.h>

// Pin 13 has an LED connected.
int led = 13;

int pwmPin = 9;

SoftwareSerial mySerial(10, 11); // RX, TX

void setup()  
{
  int i;
  
  pinMode(led, OUTPUT);     

  // 0 -> Laser off
  analogWrite(pwmPin, 0);

  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }


  Serial.println("Laserplotter v0.0.4");

  // set the data rate for the SoftwareSerial port
  mySerial.begin(9600);
  // Reset plotter to defaults
  mySerial.print("IN;");
  delay(100);
}

int state = 0;
char buffer[5] = "";
int c;
int penUp = 0;
// Argument to PD, i.e. laser power
int argument = 0;

void Push(int c)
{
    char s[2];
    s[0] = c;
    s[1] = 0;
    strcat(buffer, s);
}

int flashSpeedOn = 10000;
int flashSpeedOff = 30000;
int flashSpeed = flashSpeedOff;

void SetPower(int c, int _argument)
{
   if (penUp)
   {
      flashSpeed = flashSpeedOff;
//      Serial.println("Laser OFF");
      // 0 -> Laser off
      analogWrite(pwmPin, 0);
   }
   else
   {
      flashSpeed = flashSpeedOn;
      /*
      Serial.print("Laser ");
      Serial.print(_argument);
      Serial.println("%");
      */
      // 255 -> Laser at 100%
      analogWrite(pwmPin, 255*_argument/100.0);
   }
   argument = 0;
}

int count = 0;

void loop()
{
  ++count;
  if (count == 1)
  {
    digitalWrite(led, HIGH);
  }
  else if (count == flashSpeed)
  {
    digitalWrite(led, LOW);
  }
  else if (count == flashSpeed*2)
  {
    count = 0;
  }

    if (mySerial.available())
    {
        Serial.write("RCV: ");
        Serial.write(mySerial.read());
        Serial.write("\n");
    }  
  
    if (Serial.available())
    {
       // Command from PC
       c = Serial.read();
       switch (state)
       {
       case 0:
          // Looking for P
          Push(c);
          if ((c == 'P') || (c == 'p'))
          {
             state = 1;
          }
          else
          {
             state = 0;
             mySerial.write(buffer);
             buffer[0] = 0;
          }
          break;
       case 1:
          // Looking for D or U
          Push(c);
          if ((c == 'D') || (c == 'd') ||
              (c == 'U') || (c == 'u'))
          {
             state = 2;
             penUp = (c == 'U') || (c == 'u');
          }
          else
          {
             state = 0;
             mySerial.write(buffer);
             buffer[0] = 0;
          }
          break;
       case 2:
          // Looking for number or ;
          if ((c >= '0') && (c <= '9'))
          {
             state = 3;
             argument = c - '0';
          }
          else
          {
             if (c == ';')
             {
               Push(c);
               SetPower(c, 100);
               state = 0;
               buffer[0] = 0;
             }
             else
            {
               state = 0;
               mySerial.write(buffer);
               buffer[0] = 0;
            }
          }
          break;
       case 3:
          if ((c >= '0') && (c <= '9'))
          {
             argument = argument*10 + c - '0';
          }
          else if (c == ';')
          {
             Push(c);
             SetPower(c, argument);
             state = 0;
             buffer[0] = 0;
          }
             else
            {
               state = 0;
               mySerial.write(buffer);
               buffer[0] = 0;
            }
       }
    }
}

