// from atduskgreg on github 
Polagon polagon;
Image testimg;

class PWindow extends PApplet {
  
  public PWindow() {
    super();
    //PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  void init() {
    PApplet.runSketch(new String[] {this.getClass().getSimpleName()}, this);
  }

  public void settings() {
    size(750, 900);
  }

  public void setup() {
    surface.setTitle("Preview Window");
    background(255);
    previewcontrols = new ControlP5(this);
    load_preview_controls();
    
    shapeMode(CENTER);
    polagon = new Polagon(this, first_design_file, 375, 525);
    print("size of polagon layers: ");
    println(polagon.blayers.size());
    testimg = new Image(this, first_design_file, true, false);
  }

  public void draw() {
    background(bgcolor); 
    polagon.display();
    testimg.display();
  }
 

  public void mousePressed() {
  }
  
  void controlEvent(ControlEvent theEvent) {
    
    // use delta to control phi and theta together
    // simulates rotating birefringent layer
    float newdelta = radians(kdelta.getValue());
    float newmask = radians(maskdelta.getValue());
    float newtheta = radians(ktheta.getValue());
  
    if (DELTA != newdelta || MASKDELTA != newmask || THETA != newtheta) {
      
      if (DELTA!=newdelta) println("delta changed");
      if (THETA!=newtheta) println("theta changed");
      
      DELTA = newdelta;
      MASKDELTA = newmask;
  
      // simulates rotating front polarizer
      THETA = newtheta;
      
      bgcolor = map(THETA, 0, HALF_PI, 255, 0); 
      testimg.update();
      // refresh the polagon every time the user adjusts a slider
      polagon.update();
      //print("UI change polagon update parent check: ");
      //println(polagon.parent);
  
      rotationChanged = true;
  
      ktheta.setColorLabel(255-int(bgcolor));
      kdelta.setColorLabel(255-int(bgcolor));
      maskdelta.setColorLabel(255-int(bgcolor));
    }
    
    
  }
  
  void exit() {
    dispose();
  }
}
