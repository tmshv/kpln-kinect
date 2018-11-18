// import org.openkinect.freenect.*;  // for windows version
import org.openkinect.*;              // for macos version
import org.openkinect.processing.*;

KinectController kinect;
int blurKernelMax = 50;
int colorThreshold = 200;

int screenNumber = 1; // 1 - notebook display; 2 - big screen
int segmentTtl = 1;
float frameScale = 0.125;
float imageScale = 0.25;

PImage backgroundImg;
PImage foregroundImg;
PGraphics foregroundMask;

boolean showDebugInfo = false;
boolean showDebugKinectFrame = false;
boolean showDebugSegments = false;

Segment[] segments;

void setup() {
  fullScreen(P3D, screenNumber);

  kinect = new KinectController();
  kinect.initKinect(new Kinect(this));

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

  kinect.update();
  
  pushMatrix();
  // translate(width, 0);
  // scale(-1, 1);
  updateSegmentsAndForegroundMask();
  drawScene();
  // image(kinectRawDepth, 0, 0);
  if (showDebugKinectFrame) image(kinect.frame, 0, 0); 
  if (showDebugSegments) drawDebugSegments();
  // image(mask, 0, 0);
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
  int c = kinect.getColorAt(
    segment.getCentroidX(),
    segment.getCentroidY()
  );
  float r = red(c);

  return r > colorThreshold;
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

void drawScene(){
  foregroundImg.mask(foregroundMask);
  
  // // int sx = (width - mask.width) / 2;
  int sx = 0;

  image(backgroundImg, sx, 0);
  image(foregroundImg, sx, 0);
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
  int s = 10;
  text("(R/E) TTL: " + segmentTtl, s, pos); pos += 20;
  text("(Q/W) BLUR: " + kinect.blurKernel, s, pos); pos += 20;
  text("(A/S) MAX DEPTH: " + kinect.maxDepth, s, pos); pos += 20;
  text("(Z/X) MIN DEPTH: " + kinect.minDepth, s, pos); pos += 20;
  text("(D) MIRROR X: " + kinect.mirrorX, s, pos); pos += 20;
  text("(F) MIRROR Y: " + kinect.mirrorY, s, pos); pos += 20;
  text("(↑/↓) TILT: " + kinect.tiltAngle, s, pos); pos += 20;
}

void updateSegmentsTtl(){
  for(Segment s : segments){
    s.setActiveTtl(segmentTtl);
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      kinect.tiltAngle ++;
    } else if (keyCode == DOWN) {
      kinect.tiltAngle --;
    }
    kinect.tiltAngle = constrain(kinect.tiltAngle, 0, 30);
    kinect.tilt();
  }
  
  else if (key == 'z') {
    kinect.minDepth = constrain(kinect.minDepth-10, 0, kinect.maxDepth);
  } else if (key == 'x') {
    kinect.minDepth = constrain(kinect.minDepth+10, 0, kinect.maxDepth);
  }
  
  else if (key == 'a') {
    kinect.maxDepth = constrain(kinect.maxDepth-10, kinect.minDepth, 2047);
  } else if (key =='s') {
    kinect.maxDepth = constrain(kinect.maxDepth+10, kinect.minDepth, 2047);
  }
  
  else if (key == 'w') {
    kinect.blurKernel = constrain(kinect.blurKernel+1, 0, blurKernelMax);
  } else if (key == 'q') {
    kinect.blurKernel = constrain(kinect.blurKernel-1, 0, blurKernelMax);
  }

  else if (key == 'r') {
    segmentTtl = constrain(segmentTtl+1, 1, 1000000);
    updateSegmentsTtl();
  } else if (key == 'e') {
    segmentTtl = constrain(segmentTtl-1, 1, 1000000);
    updateSegmentsTtl();
  }

  else if (key == 'd') {
    kinect.toggleMirrorX();
  }
  else if (key == 'f') {
    kinect.toggleMirrorY();
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
  kinect.stop();
  super.stop();
}
