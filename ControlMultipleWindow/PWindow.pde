// from atduskgreg on github 
class PWindow extends PApplet {
  
  public PWindow() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  //void init() {
  //  PApplet.runSketch(new String[] {this.getClass().getSimpleName()}, this);
  //}

  public void settings() {
    size(600, 900);
  }

  public void setup() {
    surface.setTitle("Child Window");
    background(255);
    previewcontrols = new ControlP5(this);
    load_preview_controls();
  }

  public void draw() {
    background(255); 
  }
 

  public void mousePressed() {
    println("mousePressed in secondary window");
  }
  
  void exit() {
    dispose();
  }
}
