import org.openkinect.*;
import org.openkinect.processing.*;

Kinect kinect;
int kinectFrameWidth  = 640;
int kinectFrameHeight = 480;
int kinectTiltAngle  =  15;

PImage depthImg;
int minDepth =  150;
int maxDepth = 890;

int blurKernel = 15;
int blurKernelMax = 30;

PImage background;
PImage foreground;
PImage mask;

void setup() {
  fullScreen(2);
  // size(240, 720);
  //pixelDensity(2);

  kinect = new Kinect(this);
  kinect.start();
  kinect.enableDepth(true);
  kinect.tilt(kinectTiltAngle);

  depthImg = new PImage(kinectFrameWidth, kinectFrameHeight);
  mask = new PImage(240, 720);
  
  background = loadImage("background.jpg");
  foreground = loadImage("foreground.jpg");
}

void draw() {
  background(0);

  applyThreshold();

  int sx = (kinectFrameWidth - mask.width) / 2;
  mask.copy(depthImg, sx, 0, mask.width, kinectFrameHeight, 0, 0, mask.width, mask.height);

  pushMatrix();
  translate(width, 0);
  scale(-1, 1);

  // image(mask, 0, 0);
  drawScene();

  popMatrix();

  drawDebugInfo();
}

void drawScene(){
  // PImage mask = depthImg.copy();
  // mask.resize(width, height);
  mask.filter(BLUR, blurKernel);

  foreground.mask(mask);
  
  int sx = (width - mask.width) / 2;

  image(background, sx, 0);
  image(foreground, sx, 0);
}

void drawDebugInfo(){
  fill(255);
  int pos = 20;
  text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, pos); pos += 20;
  text("BLUR: " + blurKernel, 10, pos); pos += 20;
  //text("TILT: " + kinectTiltAngle, 10, pos); pos += 20;
}

void applyThreshold(){
  int size = kinectFrameWidth * kinectFrameHeight;
  int[] depth = kinect.getRawDepth();

  for (int i = 0; i < size; i ++) {
    if (depth[i] >= minDepth && depth[i] <= maxDepth) {
      depthImg.pixels[i] = 0xFFFFFFFF;
    } else {
      depthImg.pixels[i] = 0;
    }
  }

  depthImg.updatePixels();
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
  
  else if (key == 'a') {
    minDepth = constrain(minDepth-10, 0, maxDepth);
  } else if (key == 's') {
    minDepth = constrain(minDepth+10, 0, maxDepth);
  }
  
  else if (key == 'z') {
    maxDepth = constrain(maxDepth-10, minDepth, 2047);
  } else if (key =='x') {
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
