class KinectTracker {
  // Size of kinect image
  int kw = 640;
  int kh = 480;
  int threshold = 745;

  float lerpFactor = 0.1;

  // Raw location
  PVector loc;

  // Interpolated location
  PVector lerpedLoc;

  KinectTracker(int w, int h) {
    kw = w;
    kh = h;

    loc = new PVector(0,0);
    lerpedLoc = new PVector(0,0);
  }

  void track(int[] depth) {
    // // Get the raw depth as array of integers
    // depth = kinect.getRawDepth();

    // Being overly cautious here
    // if (depth == null) return;

    float sumX = 0;
    float sumY = 0;
    float count = 0;

    for(int x = 0; x < kw; x++) {
      for(int y = 0; y < kh; y++) {
        // Mirroring the image
        // int offset = kw - x - 1 + (y * kw);
        int offset = x + kw * y;

        // Grabbing the raw depth
        int rawDepth = depth[offset];

        // Testing against threshold
        // if (rawDepth < threshold) {
        if (rawDepth != 0) {
          sumX += x;
          sumY += y;
          count++;
        }
      }
    }

    // As long as we found something
    if (count != 0) {
      // loc = new PVector(sumX/count, sumY/count);
      loc.set(sumX/count, sumY/count);
    }

    // Interpolating the location, doing it arbitrarily for now
    lerpedLoc.set(
      PApplet.lerp(lerpedLoc.x, loc.x, lerpFactor),
      PApplet.lerp(lerpedLoc.y, loc.y, lerpFactor)
    );
  }

  PVector getLerpedPos() {
    return lerpedLoc;
  }

  PVector getPos() {
    return loc;
  }

  int getThreshold() {
    return threshold;
  }

  void setThreshold(int t) {
    threshold =  t;
  }
}