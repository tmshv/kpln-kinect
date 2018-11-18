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

  int[] rawDepth;

  boolean mirrorX = true;
  boolean mirrorY = false;

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
    kinect.start(); // comment for windows version
    // kinect.initDepth(); // for windows version
    kinect.enableDepth(true); // for macos version
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
    rawDepth = kinect.getRawDepth();

    for(int x = 0; x < activeFrameWidth; x++) {
      for(int y = 0; y < activeFrameHeight; y++) {
        int rawX = getRawX(x);
        int rawY = getRawY(y);

        int frameOffset = x + activeFrameWidth * y;
        int rawDepthOffset = rawX + width * rawY;
        int depth = rawDepth[rawDepthOffset];

        frame.pixels[frameOffset] = inRange(depth) ? 0xFFFFFFFF : 0;
      }
    }
  }

  int getRawX(int value){
    return mirrorX
      ? activeFrameStartX + (activeFrameWidth - 1 - value)
      : activeFrameStartX + value;
  }

  int getRawY(int value){
    return mirrorY
      ? activeFrameStartY + (activeFrameHeight - 1 - value)
      : activeFrameStartY + value;
  }

  int getColorAt(int x, int y){
    return frame.get(x, y);
  }

  boolean inRange(int value){
    return value >= minDepth && value <= maxDepth;
  }

  void toggleMirrorX() {
    mirrorX = !mirrorX;
  }

  void toggleMirrorY() {
    mirrorY = !mirrorY;
  }

  void stop() {
    kinect.quit(); // comment for windows version
  }
}
