class KinectController {
  Kinect kinect;
  int width  = 640;
  int height = 480;
  int tiltAngle  =  15;

  int activeFrameWidth = 270;
  int activeFrameHeight = height;
  int activeFrameStartX;
  int activeFrameStartY;

  PImage frame;
  int minDepth =  150;
  int maxDepth = 890;

  int blurKernel = 10;

  int[] kinectRawDepth;

  KinectController() {
    activeFrameStartX = (width - activeFrameWidth) / 2;
    activeFrameStartY = 0;
    frame = new PImage(
      activeFrameWidth,
      activeFrameHeight
    );
  }

  void initKinect(Kinect value){
    kinect = value;
    kinect.start();
    kinect.enableDepth(true);
    // kinect.enableMirror(true);

    tilt();
  }

  void tilt(){
    kinect.tilt(tiltAngle);
  }

  void update() {
    frame.loadPixels();
    updateKinect();
    frame.updatePixels();
    frame.filter(BLUR, blurKernel);
  }

  void updateKinect(){
    kinectRawDepth = kinect.getRawDepth();

    for(int x = 0; x < activeFrameWidth; x++) {
      for(int y = 0; y < activeFrameHeight; y++) {
        int rx = activeFrameStartX + x;
        int ry = activeFrameStartY + y;

        int frameOffset = x + activeFrameWidth * y;
        int rawDepthOffset = rx + width * ry;

        int depth = kinectRawDepth[rawDepthOffset];
        int c = inRange(depth) ? 0xFFFFFFFF : 0;
        // int v = (int) map(depth, 0, 2048, 0, 255);
        // int c = color(v, v, v);
        frame.pixels[frameOffset] = c;
      }
    }
  }

  boolean inRange(int value){
    return value >= minDepth && value <= maxDepth;
  }

  void stop() {
    kinect.quit();
  }
}
