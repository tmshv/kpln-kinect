class Segment {
  PVector centroid;
  PVector[] polyline;

  int centroidX;
  int centroidY;

  int activeTtl = 0;
  int activeCurrentTtl = 0;
  boolean active = false;

  Segment(int ttl) {
    activeTtl = ttl;
  }

  void update(){
    if(active){
      activeCurrentTtl --;
      if(activeCurrentTtl == 0){
        active = false;
      }
    }
  }

  void activate(){
    active = true;
    activeCurrentTtl = activeTtl;
  }

  Segment setActiveTtl(int value){
    activeTtl = value;
    return this;
  }

  boolean isActive(){
    return active;
  }

  Segment setCentroid(PVector value){
    this.centroid = value;

    this.centroidX = (int) this.centroid.x;
    this.centroidY = (int) this.centroid.y;

    return this;
  }

  PVector getCentroid(){
    return this.centroid;
  }

  int getCentroidX(){
    return this.centroidX;
  }

  int getCentroidY(){
    return this.centroidY;
  }

  Segment setPolyline(PVector[] value) {
    this.polyline = value;
    return this;
  }

  PVector[] getPolyline() {
    return this.polyline;
  }

  void drawTo(PGraphics g){
    g.beginShape();
    
    for(PVector v : polyline) {
      g.vertex(v.x, v.y);
    }
    
    g.endShape();
  }
}