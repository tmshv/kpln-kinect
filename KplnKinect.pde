import org.openkinect.*;
import org.openkinect.processing.*;

Kinect kinect;
int kWidth  = 640;
int kHeight = 480;
int kAngle  =  0;

PImage depthImg;
int minDepth =  350;
int maxDepth = 830;

PImage background;
PImage foreground;

void setup() {
  size(240, 720);
  //pixelDensity(2);

  kinect = new Kinect(this);
  kinect.start();
  kinect.enableDepth(true);
  kinect.tilt(kAngle);

  depthImg = new PImage(kWidth, kHeight);
  background = loadImage("background.jpg");
  foreground = loadImage("foreground.jpg");
}

void draw() {
  background(255);
  // draw the raw image
  //image(kinect.getDepthImage(), kWidth, 0);

  // threshold the depth image
  int[] rawDepth = kinect.getRawDepth();
  for (int i=0; i < kWidth*kHeight; i++) {
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
      depthImg.pixels[i] = 0xFFFFFFFF;
    } else {
      depthImg.pixels[i] = 0;
    }
  }

  // draw the thresholded image
  depthImg.updatePixels();
  
  PImage mask = depthImg.copy();
  mask.resize(width, height);

  //maskImage = loadImage("mask.jpg");
  foreground.mask(mask);
  
  //image(depthImg, 0, 0, width, height);
  image(background, 0, 0, width, height);
  image(foreground, 0, 0, width, height);
    //filter(BLUR, 10);
  //filter(BLUR, 20);

  fill(100);
  //translate(0, kHeight);
  int pos = 20;
  //text("TILT: " + kAngle, 10, pos); pos += 20;
  text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, pos); pos += 20;
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      kAngle++;
    } else if (keyCode == DOWN) {
      kAngle--;
    }
    kAngle = constrain(kAngle, 0, 30);
    kinect.tilt(kAngle);
  }
  
  else if (key == 'a') {
    minDepth = constrain(minDepth+10, 0, maxDepth);
  } else if (key == 's') {
    minDepth = constrain(minDepth-10, 0, maxDepth);
  }
  
  else if (key == 'z') {
    maxDepth = constrain(maxDepth+10, minDepth, 2047);
  } else if (key =='x') {
    maxDepth = constrain(maxDepth-10, minDepth, 2047);
  }
}

void stop() {
  kinect.quit();
  super.stop();
}
