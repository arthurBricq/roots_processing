class Particle {
  PVector loc, dir, vel;
  float speed;
  int d = 1; // direction change
  color col;

  Particle(PVector _loc, PVector _dir, float _speed, color _col) {
    loc = _loc;
    dir = _dir;
    speed = _speed;
    col = _col;
  }

  void run() {
    update();
    move();
    checkEdges();
    display();
  }

  void move() {
    float angle=noise(loc.x/noiseScale, loc.y/noiseScale, frameCount/noiseScale)*TWO_PI*noiseStrength*0.2;
    dir.x = cos(angle);
    dir.y = sin(angle);
    vel = dir.copy();
    vel.mult(speed*d);
    loc.add(vel);
  }

  void update() {
    float amt = 0.01;
    SMOOTH_DATA = lerp(SMOOTH_DATA, RAW_DATA, amt);
    noiseScale = SMOOTH_DATA;
    noiseStrength = 0.1 * SMOOTH_DATA;
    
    float hue = hue(col);
    float saturation = saturation(col);
    float brightness = brightness(col);
    boolean brightness_animation = false;
    
    if (plant_touched)
    {
      
      brightness += 10;
      hue += 1;
      if (speed < 3)
        speed *= 1.5;
    }
    
    if (speed >= 1)
        speed *= 0.9;
    
    col = color(hue, saturation, brightness);
  }

  void checkEdges() {
    if (loc.x<0 || loc.x>width || loc.y<0 || loc.y>height) {    
      loc.x = random(width*1.2);
      loc.y = random(height);
    }
  }

  void display() {
    fill(col);
    ellipse(loc.x, loc.y, 3, 3);
  }
}
