/// Variables for the UPD setting
import hypermedia.net.*;
int PORT_RX=5005;
int PORT_TX=5500; 
String HOST_IP="192.168.43.122";
ArrayList<String> sensorsIP = new ArrayList<String>() ;
String receivedFromUDP = "";
UDP udp, udpTX;

/// Variables for the graphic generation

// - Time related variables
float timeWhenModeChanged = 0;
float timeToShowModeChange = 6000;
int INITIAL_TIME = millis() ; 

// - rings generation (MODE1)
int nRings = 20; // number of rings
ArrayList<Ring> RINGS = new ArrayList<Ring>();

// - noisy rings (MODE1)
boolean plant_touched = false; // so far, only used in the class 'Particle'. Must be REFACTOR ! 
float RAW_DATA = 100;
float SMOOTH_DATA = RAW_DATA;

// - particules (MODE2)
int num = 10000;
Particle[] particles = new Particle[num];
float noiseScale, noiseStrength;

// - waves (MODE3)
float incX = 0.09;
float incY = 0.08;
float distance = 15;
int wavesHeight = 15;

/// bootscreen
PImage img;

/// Variables for the different modes
int MODE = 1 ; 
boolean INFO;

void setup() {
  // set up the udp serverS on the device 
  udp = new UDP(this,PORT_RX,HOST_IP);
  udp.log(false);
  udp.listen(true);
  
  udpTX = new UDP(this);
  udpTX.log(true);
//  udpTX.setBuffer(10);
//  udpTX.loopback(true);
  super.start();
  
  //setup modes and the screen
  INFO = false;
  fullScreen();
  colorMode(HSB, 360, 100, 100);

  // bootscreen
  background(255);
  img = loadImage("images/logo_chic.png");
  imageMode(CENTER);
  img.resize(0, height/3);
  image(img, width/2, height/2);

  // generate the first rings displayed on the screen
  float radius= 80; // first ring size
  float noiseAmt = 0.05; // noise quantity, increase to reduce noise 
  float resolution = 10; // shape complexity
  float offset = 0;
  float hue = 171;
  float saturation = 100;
  float brightness = 47.45;

  for (int i = 0; i < nRings; i++) {
    RINGS.add(new Ring(radius, noiseAmt, resolution, offset, color(hue, saturation, brightness)));
    radius +=10 + random(40, 90);
    noiseAmt += 0.01;
    resolution += 10;
    offset = random(0.01, 0.06);
    hue = random(160, 200);
    saturation = random(50, 80);
    brightness = random(10, 50);
  }

  noiseDetail(20);
  
  noStroke();
  for (int i=0; i<num; i++) {
    PVector loc = new PVector(random(width*1.2), random(height), 2);
    float angle = random(TWO_PI);
    PVector dir = new PVector(cos(angle), sin(angle));
    //float speed = random(.5, .2);
    float speed = 0.5;
    particles[i]= new Particle(loc, dir, speed, color(hue, saturation, brightness));
    hue = random(160, 200);
    saturation = random(50, 80);
    brightness = random(10, 50);
  }
}

void draw() {  
  if (MODE == 1) {
    push();
    background(#007968);
    translate(width/2, height/2);
    noStroke();
    for (int i = RINGS.size()-1; i >= 0; i--) {
      Ring ring = RINGS.get(i);
      ring.display();
    }
    pop();
    displayModeText("Concentric");
  }

  if (MODE == 2) {
    push();
    fill(#000519, 10);
    noStroke();
    rect(0, 0, width, height);
    for (int i=0; i<particles.length; i++) {
      particles[i].run();
    }
    pop();
    displayModeText("Colony");
  }

  if (MODE == 3) {
    float amt = 0.01;
    SMOOTH_DATA = lerp(SMOOTH_DATA, RAW_DATA, amt);
    noiseScale = SMOOTH_DATA;
    noiseStrength = 0.01 * SMOOTH_DATA;
    push();
    float zOff = frameCount * 0.01;
    background(#0e2f3a);
    noStroke();
    float yOff = 0;
    for (int y = - wavesHeight; y < height + wavesHeight; y += distance) {
      float xOff = 0;
      beginShape();
      for (int x = -wavesHeight; x < width * 2; x += distance) {
        float n = noise(xOff, yOff, zOff + noiseStrength);
        //float g = n;
        //float b = yOff;
        float value = map(n, 0, 1, -wavesHeight, wavesHeight);
        curveVertex(x, y + value);
        xOff += incX;
        fill(#007968);
      }
      endShape();
      yOff += incY;
    }
    pop();
    displayModeText("Waves");
  }

  // display informations if required
  if (INFO) {
    fill(0, 150);
    rect(width/1.2, height/1.15, 225, 90, 20, 20, 20, 20);
    fill(255);
    text("Resonant frequency: " + nf(SMOOTH_DATA, 0, 2), width/1.17, height/1.05, height/1.3);
    text("Conductance: " + nf(RAW_DATA, 0, 2), width/1.17, height/1.08, height/1.25);
    noStroke();
  }
}

/// Helper functions for the drawing code

// This function displays on the screen a text box, if the mode was changed in the last 'timeToShowModeChange' milliseconds. 
void displayModeText(String modeName) {
  if (millis() - timeWhenModeChanged < timeToShowModeChange ) {
      push();
      fill(0, 150);
      rectMode(CENTER);
      rect(width/2, height/30, 200, 30, 20, 20, 20, 20);
      fill(255);
      textAlign(CENTER);
      text("visual mode : " + modeName, width/2, height/26);
      pop();
    }
}

// This function changes the current MODE to the next one, in the order 1 --> 2 --> 3 --> 1
void changeMode() {
  timeWhenModeChanged = millis() ; 
  if (MODE == 1) {
    MODE = 2 ; 
  } else if (MODE == 2) {
    MODE = 3;
  } else {
    MODE = 1;
  }
}

// Switch the value of the INFO variable
void setINFO() {
  if (INFO) {
    INFO = false;
    println("INFO:" + INFO);
  } else if (!INFO) {
    INFO = true;
    println("INFO:" + INFO);
  }
}

/// UDP functions

// This function is called when new data is received from UDP.
// Every time it is called, it will update the image
void receive(byte[] data, String HOST_IP, int PORT_RX) {
  // 1. Verifiy what sender it is and registrer its new IP address. 
  if (!sensorsIP.contains(HOST_IP)){
     sensorsIP.add(HOST_IP);
     println("New device detected: ", HOST_IP);
  }
  
  // 2. Treat the data
  receivedFromUDP = "";
  println(data) ; 
  for (int i = 0; i < data.length; i++) {
      String value = new String(data);
      receivedFromUDP = value;
  }  
  if (receivedFromUDP.equals("end")) {
    finishedReading();        
  } else if (receivedFromUDP.equals("change_mode")) {
    changeMode();
  } else if (receivedFromUDP.equals("Hello server")) {
    println("Device connected") ; 
  } else { 
    float timeTouched = Float.valueOf(receivedFromUDP);
    onData(timeTouched);
  }
}

// This function is called when the sensor is touched ! 
// The function is not called when sensor is not read. 
void onData(float dataValue) {
  println(dataValue);
  // float random = random(1)/50 ;
  // float resize = 600 ;
  RAW_DATA += 30 ;
  plant_touched = true ; 
}

// This function is called when a sensor is not read anymore 
void finishedReading() {
  RAW_DATA = 100 ;
  plant_touched = false ; 
}

// This function is used to reload the code when the key 'r' is touched on the user keyboard.
void keyPressed() {
  if (keyCode==82){
    // sends a message to reload all sensors
    for (String ip: sensorsIP) {
     // println("Sending one message : ", ip);
      udpTX.send("r", ip, PORT_TX); 
    }
  } else if (keyCode==32){
    INFO = !INFO; 
    // plant_touched = true;
  } else if (keyCode == 37){  // if left arrow: change visuals
      MODE = MODE - 1;
      if (MODE < 1)
        MODE = 3;
  } else if (keyCode == 39){  // if right arrow: change visuals
      MODE = MODE + 1;
      if (MODE > 3)
        MODE = 1;
  }
}

// for simulation (not with sensor)
void keyReleased() {
  if (keyCode == 32) {        // if spacebar is pressed
     // plant_touched = false;
  }
}
