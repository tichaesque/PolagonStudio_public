// Polagons must comprise of at least one image layer
// users can optionally add a second image layer and a mask layer

class Polagon {
  ArrayList<Image> blayers; // the birefringent layers are colored images
  Mask mask; 
  int bilayers = 0; 
  int x_pos, y_pos; 
  int angle = 0;
  PApplet parent;
  String pname;

  public Polagon(PApplet parent_, String designfile, int x_, int y_) {
    parent = parent_;
    Image img1 = new Image(parent, designfile, true, false);  
    blayers = new ArrayList();
    blayers.add(img1);
    x_pos = x_; 
    y_pos = y_; 
    mask = null;
  }
  
  public Polagon(PApplet parent_, Image img1_, int x_, int y_){
    parent = parent_;
    blayers = new ArrayList();
    blayers.add(img1_);
    x_pos = x_; 
    y_pos = y_; 
    mask = null;
  }

  public void setSecondImage(Image img2_) {
    Image img2 = img2_;
    if (blayers.size() < 2) {
      blayers.add(img2);
    } else {
      blayers.set(1, img2);
    }
    pname += ";"+img2.filename;
  }

  public void setFirstImage(Image img1_) {
    Image img1 = img1_;
    blayers.set(0, img1);
    pname = img1.filename;
  }

  public void setMask(String maskfile, boolean visibleAtStart) {
    mask = new Mask(parent, maskfile, visibleAtStart, false);
    pname += ";"+mask.filename;
  }

  public void update() {
    //update background color
    float combineangle = abs(THETA - PHI)%PI;

    if (combineangle <= HALF_PI) bgcolor = map(combineangle, 0, HALF_PI, 255, 0); 
    else bgcolor = map(combineangle, HALF_PI, PI, 0, 255);
    
    for (int i = 0; i < blayers.size(); i++) {
      blayers.get(i).update();
    }

    if (mask != null) {
      mask.update();
    }
  }

  public void display() {
    parent.pushMatrix();
    parent.translate(x_pos, y_pos); 
    
    parent.pushMatrix();
    if (rotateMosaic) parent.rotate(DELTA);

    for (int i = 0; i < blayers.size(); i++) {
      blayers.get(i).display();
    }
    parent.popMatrix();
    
    parent.pushMatrix();
    if (rotateMask) parent.rotate(pk_mask.angle);
    if (mask != null) {
      mask.display();
    }

    parent.popMatrix();
    parent.popMatrix();

  }
}
