// Polagons must comprise of at least one image layer
// users can optionally add a second image layer and a mask layer

class Polagon {
  ArrayList<Image> blayers; // the birefringent layers are colored images
  //Mask mask; 
  int bilayers = 0; 
  int x_pos, y_pos; 
  int angle = 0;
  PApplet parent;

  public Polagon(PApplet parent_, String designfile, int x_, int y_) {
    parent = parent_;
    print("polagon parent: ");
    println(parent);
    Image img1 = new Image(parent, designfile, true, false);  
    print("img1 parent: ");
    println(img1.parent);
    blayers = new ArrayList();
    blayers.add(img1);
    x_pos = x_; 
    y_pos = y_; 
    //mask = null;
  }

  public void setSecondImage(String designfile) {
    Image img2 = new Image(parent, designfile, false, false);  
    println("img2 parent");
    println(img2.parent);
    if (blayers.size() < 2) {
      blayers.add(img2);
    } else {
      blayers.set(1, img2);
    }
  }

  public void setFirstImage(String designfile) {
    Image img1 = new Image(parent, designfile, true, false);  
    blayers.set(0, img1);
  }

  public void update() {
    bgcolor = map(THETA, 0, HALF_PI, 255, 0); 
    for (int i = 0; i < blayers.size(); i++) {
      print("polagon blayer parent check: ");
      println(blayers.get(i).parent);
      blayers.get(i).update();
    }

  }

  public void display() {
    parent.pushMatrix();
    parent.translate(x_pos, y_pos); 
    
    parent.pushMatrix();
    parent.rotate(DELTA);

    for (int i = 0; i < blayers.size(); i++) {
      blayers.get(i).display();
    }
    parent.popMatrix();

    parent.popMatrix();

  }
}
