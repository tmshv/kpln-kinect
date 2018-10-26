import org.openkinect.*;
import org.openkinect.processing.*;

Kinect kinect;
int kinectFrameWidth  = 640;
int kinectFrameHeight = 480;
int kinectTiltAngle  =  15;

PImage activeImage;
int minDepth =  150;
int maxDepth = 890;

int blurKernel = 15;
int blurKernelMax = 50;

PImage background;
PImage foreground;
PImage mask;

int[] kinectRawDepth;
int[] activeRawDepth;
PVector kinectActiveFrameStart;
PVector kinectActiveFrameArea = new PVector(270, kinectFrameHeight);

KinectTracker tracker;

void setup() {
  fullScreen(P3D);
  // fullScreen(P3D, 2);
  // size(240, 720);
  pixelDensity(2);

  kinect = new Kinect(this);
  kinect.start();
  kinect.enableDepth(true);
  // kinect.enableMirror(true);
  kinect.tilt(kinectTiltAngle);

  kinectActiveFrameStart = new PVector((kinectFrameWidth - kinectActiveFrameArea.x) / 2, 0);
  activeRawDepth = new int[(int) (kinectActiveFrameArea.x * kinectActiveFrameArea.y)];
  activeImage = new PImage((int) kinectActiveFrameArea.x, (int) kinectActiveFrameArea.y);
  tracker = new KinectTracker(activeImage.width, activeImage.height);
  // activeImage = new PImage(kinectFrameWidth, kinectFrameHeight);

  background = loadImage("background.jpg");
  foreground = loadImage("foreground.jpg");

  mask = new PImage(240, 720);
}

void draw() {
  background(200);

  activeImage.loadPixels();

  updateKinect();
  tracker.track(activeImage.pixels);

  activeImage.updatePixels();

  // int sx = (kinectFrameWidth - mask.width) / 2;
  // mask.copy(activeImage, sx, 0, mask.width, kinectFrameHeight, 0, 0, mask.width, mask.height);

  pushMatrix();
  translate(width, 0);
  scale(-1, 1);

  // image(kinectRawDepth, 0, 0);
  // image(activeImage, 0, 0);
  // image(mask, 0, 0);
  drawScene();
  drawSceneDebugInfo();

  popMatrix();

  drawDebugInfo();
}

void drawScene(){
  PImage mask = activeImage.copy();
  mask.resize(foreground.width, foreground.height);
  mask.filter(BLUR, blurKernel);

  foreground.mask(mask);
  
  int sx = (width - mask.width) / 2;

  image(background, sx, 0);
  image(foreground, sx, 0);
}

void drawSceneDebugInfo(){
  fill(255, 0, 0);
  PVector t = tracker.getPos();
  ellipse(t.x, t.y, 5, 5);
}

void drawDebugInfo(){
  fill(255);
  int pos = 20;
  text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, pos); pos += 20;
  text("BLUR: " + blurKernel, 10, pos); pos += 20;
  //text("TILT: " + kinectTiltAngle, 10, pos); pos += 20;
}

void updateKinect(){
  kinectRawDepth = kinect.getRawDepth();

  int frameWidth = (int) kinectActiveFrameArea.x;
  int frameHeight = (int) kinectActiveFrameArea.y;
  int startX = (int) kinectActiveFrameStart.x;
  // int startX = (int) map(mouseX, 0, width, 0, kinectFrameWidth - kinectActiveFrameArea.x);
  int startY = (int) kinectActiveFrameStart.y;

  // int size = kinectFrameWidth * kinectFrameHeight;
  // for (int i=0; i<size; i ++){
  //   int v = (int) map(kinectRawDepth[i], 0, 4500, 0, 255);
  //   activeImage.pixels[i] = color(v, v, v);
  // }

  for(int x = 0; x < frameWidth; x++) {
    for(int y = 0; y < frameHeight; y++) {
      int rx = startX + x;
      int ry = startY + y;

      int frameOffset = x + frameWidth * y;
      int rawDepthOffset = rx + kinectFrameWidth * ry;

      int depth = kinectRawDepth[rawDepthOffset];
      int c = inRange(depth) ? 0xFFFFFFFF : 0;
      // int v = (int) map(depth, 0, 2048, 0, 255);
      // int c = color(v, v, v);
      activeImage.pixels[frameOffset] = c;
    }
  }
}

boolean inRange(int value){
  return value >= minDepth && value <= maxDepth;
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      kinectTiltAngle ++;
    } else if (keyCode == DOWN) {
      kinectTiltAngle --;
    }
    kinectTiltAngle = constrain(kinectTiltAngle, 0, 30);
    kinect.tilt(kinectTiltAngle);
  }
  
  else if (key == 'z') {
    minDepth = constrain(minDepth-10, 0, maxDepth);
  } else if (key == 'x') {
    minDepth = constrain(minDepth+10, 0, maxDepth);
  }
  
  else if (key == 'a') {
    maxDepth = constrain(maxDepth-10, minDepth, 2047);
  } else if (key =='s') {
    maxDepth = constrain(maxDepth+10, minDepth, 2047);
  }
  
  else if (key == 'w') {
    blurKernel = constrain(blurKernel+1, 0, blurKernelMax);
  } else if (key == 'q') {
    blurKernel = constrain(blurKernel-1, 0, blurKernelMax);
  }
}

void stop() {
  kinect.quit();
  super.stop();
}
