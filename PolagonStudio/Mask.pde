// the mask is the 3rd polarizer
// its visibility depends on its angle relative to the top polarizer
class Mask {
  PShape mask;
  float maskwidth; 
  float opacity; 
  float designscale;
  boolean visibleAtStart;
  int maskx;
  int masky;
  boolean rotated; // for main UI
  boolean maindisplay; // for whether main UI or preview window display
  PApplet parent;
  String filename;

  public Mask(PApplet parent_, String maskfile, boolean visibleAtStart, boolean maindisplay) {
    mask = loadShape(maskfile);
    float tmpw = mask.width;
    float tmph = mask.height;
    this.filename = maskfile;

    if (tmph > tmpw) this.designscale = IMGHEIGHT/tmph;
    else this.designscale = IMGWIDTH/tmpw;
    
    this.parent = parent_;
    this.designscale = IMGWIDTH/tmpw;
    this.maindisplay = maindisplay;

    mask.disableStyle();
    
    this.visibleAtStart = visibleAtStart;
    
    opacity = visibleAtStart ? 220 : 0;
  }
  
  public Mask(PApplet parent_, String maskfile, boolean visibleAtStart, int maskx, int masky, boolean rotated, boolean maindisplay) {//for main UI view
    mask = loadShape(maskfile);
    float tmpw = mask.width;
    
    this.designscale = MAINIMGWIDTH/tmpw;

    this.maskx = maskx;
    this.masky = masky;
    this.rotated = rotated;
    this.parent = parent_;
    this.maindisplay = maindisplay;
    
    mask.disableStyle();
    
    this.visibleAtStart = visibleAtStart;
    
    opacity = visibleAtStart ? 220 : 0;
  }

  void update() {
    float diff = abs(THETA - MASKDELTA)%PI;
    
    if (diff <= PI/2) opacity = map(diff, 0, HALF_PI, 0,220);
    else opacity = map(diff, HALF_PI, PI, 220, 0);
    if(visibleAtStart && inverted) opacity = 220-opacity;
  }

  void display() {
    parent.pushMatrix();
    
    if (maindisplay){
      parent.translate(maskx, masky); 
      if (rotated) parent.rotate(PI/2);
      parent.fill(0,opacity);
    } else {
      if(hovering && !mouseOverMask&&!mouseOverPolarizer) parent.fill(0, min(opacity,15));
      else parent.fill(0, opacity);
    }
    
    parent.scale(this.designscale);
    parent.shape(mask);
    parent.popMatrix();
    noStroke();
  }
  
}
