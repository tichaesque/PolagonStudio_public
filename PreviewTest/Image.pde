

class Image {
  int imgx;
  int imgy;
  String filename;
  float designscale;

  float theta = 0;
  float phi = 0;
  float brfangle = 0;

  // the angle of the image relative to aligned polarizers
  float offset; 

  // recolored image 
  // each PShape in the list is a group of same-colored shapes
  ArrayList<SVGChild> recolored_img = new ArrayList<SVGChild>();
  
  boolean visibleAtStart;
  boolean complementary;
  boolean maindisplay;
  boolean updated=false; //want to color update once for complementary viewing in main UI
  
  PApplet parent;

  public Image(PApplet parent_, String filename_, boolean visibleAtStart, boolean maindisplay) {
    if (visibleAtStart) offset = QUARTER_PI;
    else offset = 0; 

    theta = offset; 
    phi = offset; 

    filename = filename_;
    parent = parent_;
    this.maindisplay = maindisplay;

    PShape tmp = loadShape(filename); //basename
    float tmpw = tmp.width;
    
    this.designscale = IMGWIDTH/tmpw;

    loadStrings("http://127.0.0.1:3000/generatesvgs?filename="+filename); //generate new recolored svgs using Python
    println("generated new files");
    this.visibleAtStart = visibleAtStart;

    make_recolored_image(visibleAtStart);
    
    println("for preview window");
    for (int i=0; i<recolored_img.size(); i++) {
      println("recolored image parent: ");
      println(recolored_img.get(i).parent);
    }

  }
  
  public Image(PApplet parent_, String filename_, boolean visibleAtStart, int imgx, int imgy, boolean complementary, boolean maindisplay) {//for main UI
    if (visibleAtStart) offset = QUARTER_PI;
    else offset = 0; 

    theta = offset; 
    phi = offset; 
    this.imgx = imgx;
    this.imgy = imgy;
    this.complementary = complementary;
    this.parent = parent_;
    this.maindisplay = maindisplay;

    filename = filename_;
    PShape tmp = loadShape(filename); //absolute file path
    float tmpw = tmp.width;
    
    this.designscale = MAINIMGWIDTH/tmpw;

    loadStrings("http://127.0.0.1:3000/generatesvgs?filename="+filename); //generate new recolored svgs using Python
    println("generated new files");
    this.visibleAtStart = visibleAtStart;

    make_recolored_image(visibleAtStart);
    println("main ui img created");
    for (int i=0; i<recolored_img.size(); i++) {
      println("recolored image parent: ");
      println(recolored_img.get(i).parent);
    }
  }

  void update() {
    update_rotation();
    update_color();
  }

  public void update_rotation() {
    brfangle = DELTA + offset; 
    phi = PHI + brfangle; 
    theta = THETA + brfangle;
  }

  public void update_color() {
    for (int i=0; i < recolored_img.size(); i++) { // loop through children
      SVGChild child = recolored_img.get(i);

      String zvals = child.getComposition();
      
      String input = "theta="+this.theta+"&phi="+this.phi+"&zvalues="+zvals;
      String[] res = loadStrings("http://127.0.0.1:3000/getcolor2?"+input); 
      String result = res[0].substring(1, res[0].length()-1).trim(); 
      String[] newc = result.split("\\s+"); 
      color newfill = color(float(newc[0]), float(newc[1]), float(newc[2])); 
      
      child.setColor(newfill);
    }
  }

  public void display() {
    parent.pushMatrix();
    if (maindisplay){
      parent.translate(imgx, imgy); 
      if(complementary && !updated) {
        this.phi = PI/4;
        this.theta = -PI/4;
        update_color();
        updated=true;
      }
    }
    
    parent.scale(designscale);
    if(!visibleAtStart) parent.rotate(-PI/4);
    
    for (int i=0; i<recolored_img.size(); i++) { //display recolored image in polage colors
      recolored_img.get(i).display();
    }

    parent.popMatrix();
  }

  // get the color groups and populates the arraylist of SVG children 
  void make_recolored_image(boolean visibleAtStart) {
    String[] res = loadStrings("http://127.0.0.1:3000/getsvgfiles?filename="+this.filename);
    println("make recolored images");
    String[] filenames = split(res[0], ", ");

    for (int i=0; i<filenames.length; i++) {
      PShape f = loadShape(filenames[i].substring(1, filenames[i].length()-1));
      String c = filenames[i].split("_")[1]; // extract the color from the file name
      c = c.substring(1, c.length()-5); // trim off the .svg in the name

      JSONArray stackcomp = loadJSONArray("http://127.0.0.1:3000/stackcomposition?colorkey="+c);
      String compstring = ""; 
      for(int j = 0; j<stackcomp.size(); j++) {
        compstring += stackcomp.getFloat(j);
        if(j < stackcomp.size()-1) compstring += "~";
      }
      //String layers = layersres[0].substring(1, layersres[0].length()-1);


      recolored_img.add(new SVGChild(parent, f, compstring, unhex("FF"+c), visibleAtStart));
      
    }
  }
}

// group of same-colored shapes
class SVGChild {
  PShape child;
  String composition;
  color col; 
  float alpha; 
  boolean visibleAtStart;
  PApplet parent;
  
  public SVGChild(PApplet parent_, PShape child, String comp, int col, boolean visibleAtStart) {
    this.col = col; 
    this.child = child;
    this.alpha = (visibleAtStart ? 255 : 0);
    this.visibleAtStart = visibleAtStart;
    this.child.disableStyle();
    this.composition = comp; 
    this.parent = parent_;
  }

  public void display() {
    if(hovering && !mouseOverDesign &&!mouseOverPolarizer) parent.fill(col,min(alpha,15));
    else parent.fill(col, alpha);
    parent.shape(child);
  }

  public PShape getShape() {
    return child;
  }

  public String getComposition() {
    return composition;
  }

  public color getColor() {
    return col;
  }

  public void setColor(color newcol) {
    col = newcol;
    
    float transparency = (abs((degrees(DELTA)%90) - 45)/45f)*255;
    alpha = visibleAtStart ? transparency : (255-transparency);
  }
}
