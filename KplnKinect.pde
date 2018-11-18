import org.openkinect.*;
import org.openkinect.processing.*;

Kinect kinect;
int kinectFrameWidth  = 640;
int kinectFrameHeight = 480;
int kinectTiltAngle  =  15;

PImage kinectFrameImage;
int minDepth =  150;
int maxDepth = 890;

int blurKernel = 10;
int blurKernelMax = 50;

int screenNumber = 1; // 1 - notebook display; 2 - big screen
int segmentTtl = 1;

PImage backgroundImg;
PImage foregroundImg;
PGraphics foregroundMask;

int[] kinectRawDepth;
int[] activeRawDepth;
PVector kinectActiveFrameStart;
PVector kinectActiveFrameArea = new PVector(270, kinectFrameHeight);

KinectTracker tracker;

boolean showDebugInfo = false;
boolean showDebugKinectFrame = false;
boolean showDebugSegments = false;

Segment[] segments;

void setup() {
  fullScreen(P3D, screenNumber);

  kinect = new Kinect(this);
  kinect.start();
  kinect.enableDepth(true);
  // kinect.enableMirror(true);
  kinect.tilt(kinectTiltAngle);

  kinectActiveFrameStart = new PVector((kinectFrameWidth - kinectActiveFrameArea.x) / 2, 0);
  activeRawDepth = new int[(int) (kinectActiveFrameArea.x * kinectActiveFrameArea.y)];
  kinectFrameImage = new PImage((int) kinectActiveFrameArea.x, (int) kinectActiveFrameArea.y);
  tracker = new KinectTracker(kinectFrameImage.width, kinectFrameImage.height);
  // kinectFrameImage = new PImage(kinectFrameWidth, kinectFrameHeight);

  float frameScale = 0.125;
  float imageScale = 0.5;
  foregroundMask = createGraphics(
    (int) (2160 * imageScale),
    (int) (3840 * imageScale)
  );
  segments = loadSegments("centroids.json", "polylines.json", frameScale, imageScale);
  backgroundImg = loadImg("background.jpg", imageScale);
  foregroundImg = loadImg("foreground.jpg", imageScale);
}

void draw() {
  background(200);

  kinectFrameImage.loadPixels();

  updateKinect();
  // tracker.track(kinectFrameImage.pixels);

  kinectFrameImage.updatePixels();

  kinectFrameImage.filter(BLUR, blurKernel);

  // int sx = (kinectFrameWidth - mask.width) / 2;
  // mask.copy(kinectFrameImage, sx, 0, mask.width, kinectFrameHeight, 0, 0, mask.width, mask.height);

  pushMatrix();
  // translate(width, 0);
  // scale(-1, 1);
  updateSegmentsAndForegroundMask();
  drawScene();
  // image(kinectRawDepth, 0, 0);
  if (showDebugKinectFrame) image(kinectFrameImage, 0, 0); 
  if (showDebugSegments) drawDebugSegments();
  // image(mask, 0, 0);
  // drawSceneDebugInfo();
  popMatrix();

  if (showDebugInfo) drawDebugInfo();
}

void updateSegmentsAndForegroundMask(){
  foregroundMask.beginDraw();
  foregroundMask.background(0);
  foregroundMask.stroke(255);
  foregroundMask.fill(255);

  for(Segment segment : segments){
    if(isSegmentInFocus(segment)){
      segment.activate();
    }

    if(segment.isActive()){
      segment.drawTo(foregroundMask);      
    }

    segment.update();
  }

  foregroundMask.endDraw();
}

boolean isSegmentInFocus(Segment segment){
  int c = kinectFrameImage.get(
    segment.getCentroidX(),
    segment.getCentroidY()
  );

  float r = red(c);

  return r > 200;
}

Segment[] loadSegments(String centroids, String polylines, float centroidsScale, float polylinesScale){
  JSONArray cs = loadJSONArray(centroids);

  Segment[] result = new Segment[cs.size()];

  for (int i = 0; i < cs.size(); i++) {
    JSONArray a = cs.getJSONArray(i);

    Segment s = new Segment(segmentTtl);
    s.setCentroid(
      fromJsonArray(a, centroidsScale)
    );

    result[i] = s;
  }

  JSONArray ps = loadJSONArray(polylines);

  for (int i = 0; i < cs.size(); i++) {
    JSONArray pl = ps.getJSONArray(i);

    Segment s = result[i];
    PVector[] polyline = new PVector[pl.size()];

    for (int j = 0; j < pl.size(); j++) {
      JSONArray p = pl.getJSONArray(j);
      polyline[j] = fromJsonArray(p, polylinesScale);
    }

    s.setPolyline(polyline);
  }

  return result;
}

PImage loadImg(String filepath, float scale){
  PImage img = loadImage(filepath);
  if (scale != 1) {
    img.resize(
      (int) (img.width * scale),
      (int) (img.height * scale)
    );
  }

  return img;
}

PVector fromJsonArray(JSONArray p, float scale){
  return new PVector(
    p.getFloat(0) * scale,
    p.getFloat(1) * scale
  );
}

void runFlock() {
  
}

void drawScene(){
  foregroundImg.mask(foregroundMask);
  
  // // int sx = (width - mask.width) / 2;
  int sx = 0;

  image(backgroundImg, sx, 0);
  image(foregroundImg, sx, 0);
}

void drawSceneDebugInfo(){
  fill(255, 0, 0);
  // PVector t = tracker.getPos();
  PVector t = tracker.getLerpedPos();
  // t.sub(kinectActiveFrameStart);
  ellipse(t.x, t.y, 5, 5);
}

void drawDebugSegments(){
  for(Segment segment : segments){
    stroke(200, 0, 0);
    PVector centroid = segment.getCentroid();
    point(centroid.x, centroid.y);

    PVector[] pl = segment.getPolyline();
    stroke(0, 200, 0);
    noFill();
    beginShape();
    for(PVector v : pl) {
      vertex(v.x, v.y);
    }
    endShape();
  }
}

void drawDebugInfo(){
  fill(100);
  int pos = 20;
  text("(Q/W)BLUR: " + blurKernel, 10, pos); pos += 20;
  text("(R/E) TTL: " + segmentTtl, 10, pos); pos += 20;
  text("(A/S) MAX DEPTH: " + maxDepth, 10, pos); pos += 20;
  text("(Z/X) MIN DEPTH: " + minDepth, 10, pos); pos += 20;
  text("TILT: " + kinectTiltAngle, 10, pos); pos += 20;
}

void updateSegmentsTtl(){
  for(Segment s : segments){
    s.setActiveTtl(segmentTtl);
  }
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
  //   kinectFrameImage.pixels[i] = color(v, v, v);
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
      kinectFrameImage.pixels[frameOffset] = c;
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

  else if (key == 'r') {
    segmentTtl = constrain(segmentTtl+1, 1, 1000000);
    updateSegmentsTtl();
  } else if (key == 'e') {
    segmentTtl = constrain(segmentTtl-1, 1, 1000000);
    updateSegmentsTtl();
  }

  else if (key == '1') {
    showDebugInfo = !showDebugInfo;
  }
  else if (key == '2') {
    showDebugKinectFrame = !showDebugKinectFrame;
  }
  else if (key == '3') {
    showDebugSegments = !showDebugSegments;
  }
}

void stop() {
  kinect.quit();
  super.stop();
}
