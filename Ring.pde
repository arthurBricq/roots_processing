class Ring { 
  float noiseAmt;
  float radius;
  float resolution;
  float offset;
  color col;

  // The Constructor is defined with arguments.
  Ring(float _radius, float _noiseAmt, float _resolution, float _offset, color _col) { 
    noiseAmt = _noiseAmt;
    radius = _radius;
    resolution = _resolution;
    offset = _offset;
    col = _col;
  }

  void display() {
    float amt = 0.001;
    SMOOTH_DATA = lerp(SMOOTH_DATA, RAW_DATA, amt);
    float nInt = SMOOTH_DATA / 175 + offset;
    float nAmp = noiseAmt;

    pushMatrix();

    fill(col);
    beginShape();

    for (float i=0; i<resolution; i++) {
      drawCurveVertex(i, nInt, nAmp);
    }

    // redraw first 3 points to get perfect shape
    for (float i=0; i < 3; i++) {
      drawCurveVertex(i, nInt, nAmp);
    }

    endShape();
    popMatrix();
  }

  void drawCurveVertex(float index, float _nInt, float _nAmp) {
    float t = (millis() - float(INITIAL_TIME))/100000 ; // if the denumerator increase, animation goes slower.
    float angle = index/resolution*TWO_PI;
    float nVal = map(noise( cos(angle)*_nInt+1, sin(angle)*_nInt+1, t), 0.0, 1.0, _nAmp, 1.0);
    float x = cos(angle)*radius*nVal;
    float y = sin(angle)*radius*nVal;
    curveVertex(x, y);
  }
}
