#include <Servo.h>

Servo myServo;
int pos = 0;    // variable to store the servo position
String inputString = "";         // a string to hold incoming data
boolean stringComplete = false;  // whether the string is complete


void setup() {
  // put your setup code here, to run once:
  myServo.attach(6);
  myServo.write(90);
    // initialize serial:
  Serial.begin(9600);
  // reserve 200 bytes for the inputString:
  inputString.reserve(200);
}

void loop() {
      // print the string when a newline arrives:
  if (stringComplete) {
    inputString.trim();
    if (inputString.equals("Block"))
    {
      myServo.write(180);
    }
    else if (inputString.equals("UnBlock"))
    {
      myServo.write(0);
    }
    // clear the string:
    inputString = "";
    stringComplete = false;
  }

  
}


/*
  SerialEvent occurs whenever a new data comes in the
 hardware serial RX.  This routine is run between each
 time loop() runs, so using delay inside loop can delay
 response.  Multiple bytes of data may be available.
 */
void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    inputString += inChar;
    // if the incoming character is a newline, set a flag
    // so the main loop can do something about it:
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}
