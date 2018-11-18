class Segment {
  PVector centroid;
  PVector[] polyline;

  int centroidX;
  int centroidY;

  Segment() {
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