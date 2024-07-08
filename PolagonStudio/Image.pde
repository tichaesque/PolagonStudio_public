class Image {
  PShape orig;
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
  boolean updated=false; //want to color update once for complementary viewing in main UI
  boolean maindisplay; //to indicate whether main display or preview window

  PImage img;
  Gif imggif;
  int yadj = 150;
  PApplet parent;
  String tag;


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
    float tmph = tmp.height;

    if (tmph > tmpw) this.designscale = IMGHEIGHT/tmph;
    else this.designscale = IMGWIDTH/tmpw;

    loadStrings("http://127.0.0.1:3000/generatesvgs?filename="+filename+"&inverted="+str(int(inverted))+"&uniform="+str(int(uniformT))+"&selected="+selected); //generate new recolored svgs using Python
    this.visibleAtStart = visibleAtStart;

    make_recolored_image(visibleAtStart);
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
    orig = loadShape(filename); //absolute file path
    float origw = orig.width;
    float origh = orig.height;

    if (origh > origw) this.designscale = MAINIMGHEIGHT/origh;
    else this.designscale = MAINIMGWIDTH/origw;

    loadStrings("http://127.0.0.1:3000/generatesvgs?filename="+filename+"&inverted="+str(int(inverted))+"&uniform="+str(int(uniformT))+"&selected="+selected); //generate new recolored svgs using Python
    this.visibleAtStart = visibleAtStart;

    make_recolored_image(visibleAtStart);
  }

  public Image() {
  }
  
  public Image(PApplet parent_, String imgfile, String giffile, int imgx_, int imgy_){
    parent = parent_;
    filename = imgfile;
    imggif = new Gif(parent_, giffile);
    imggif.loop();
    imgx = imgx_;
    imgy = imgy_;
    img = loadImage(filename);
    shapeMode(CENTER);
    img.resize(300,0);
    tag = "gif";
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

  public Image copy_img(PApplet parent, boolean visibleAtStart, int imgx, int imgy, boolean complementary, boolean maindisplay) { // for main display
    Image newimg = new Image();
    newimg.orig = this.orig;
    newimg.filename = filename;

    if (!maindisplay) {
      float tmpw=newimg.orig.width;
      float tmph=newimg.orig.height;
      if (tmph>tmpw) newimg.designscale = IMGHEIGHT/tmph;
      else newimg.designscale = IMGWIDTH/tmpw;
    } else {
      newimg.designscale = this.designscale;
    }

    newimg.visibleAtStart = visibleAtStart;
    if (visibleAtStart) newimg.offset = QUARTER_PI;
    else newimg.offset = 0;

    newimg.complementary = complementary;
    newimg.maindisplay = maindisplay;
    newimg.imgx = imgx;
    newimg.imgy = imgy;
    newimg.parent = parent;

    newimg.recolored_img = new ArrayList<SVGChild>();

    for (int i=0; i<this.recolored_img.size(); i++) {
      PShape oldshape = this.recolored_img.get(i).child;
      String oldcomp = this.recolored_img.get(i).composition;
      int oldcolor = this.recolored_img.get(i).col;

      newimg.recolored_img.add(new SVGChild(parent, oldshape, oldcomp, oldcolor, visibleAtStart));
    }

    return newimg;
  }

  public void orig_img_display() {
    if (tag == "gif") {
      parent.image(img, imgx-img.width/2, imgy-img.height/2);
    }
    else {
      parent.pushMatrix();
      parent.translate(imgx, imgy);
      parent.scale(designscale);
      parent.shape(orig);
      parent.popMatrix();
    }
  }
  
  
  public void display_gif(){
    image(imggif, imgx-imggif.width/2, imgy-imggif.height/2-25);
  }
  
  public void init_display(){
    if (inside_img()) display_gif(); 
    else orig_img_display();
    //orig_img_display(); //need to rescale
  }
  
  public boolean inside_img(){
    if (imgx-img.width/2 <= mouseX && mouseX <= imgx+img.width/2 && imgy-img.height/2 <= mouseY && mouseY <= imgy+img.height/2){
      return true;
    } else {
      return false; 
    }
  }
  
  public void display() {
    parent.pushMatrix();
    if (maindisplay) {
      parent.translate(imgx, imgy);
      if (complementary && !inverted && !updated) {
        this.phi = PI/4;
        this.theta = -PI/4;
        update_color();
        updated=true;
      }
      if (complementary && inverted && !updated) {
        this.phi = PI/4;
        this.theta = PI/4;
        update_color();
        updated=true;
      }
    }

    parent.scale(designscale);

    for (int i=0; i<recolored_img.size(); i++) { //display recolored image in polage colors
      recolored_img.get(i).display();
    }
    parent.popMatrix();
  }

  public void update_palette() {
    loadStrings("http://127.0.0.1:3000/generatesvgs?filename="+filename+"&inverted="+str(int(inverted))+"&uniform="+str(int(uniformT))+"&selected="+selected); //generate new recolored svgs using Python
    recolored_img.clear();
    make_recolored_image(visibleAtStart);
  }

  // get the color groups and populates the arraylist of SVG children
  void make_recolored_image(boolean visibleAtStart) {
    String[] res = loadStrings("http://127.0.0.1:3000/getsvgfiles?filename="+this.filename);
    String[] filenames = split(res[0], ", ");

    for (int i=0; i<filenames.length; i++) {
      PShape f = loadShape(filenames[i].substring(1, filenames[i].length()-1));
      String c = filenames[i].split("_")[1]; // extract the color from the file name
      c = c.substring(1, c.length()-5); // trim off the .svg in the name

      JSONArray stackcomp = loadJSONArray("http://127.0.0.1:3000/stackcomposition?filename="+this.filename+"&colorkey="+c);
      String compstring = "";
      for (int j = 0; j<stackcomp.size(); j++) {
        compstring += stackcomp.getFloat(j);
        if (j < stackcomp.size()-1) compstring += "~";
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
    noStroke();

    if (hovering && !mouseOverDesign &&!mouseOverPolarizer) parent.fill(col, min(alpha, 15));
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
    // transparency calculations for the main window
    float transparency = (abs((degrees(DELTA)%90) - 45)/45f)*255;

    float analyzerangle = 0; 
    if (pk_analyzer != null) analyzerangle = degrees(pk_analyzer.getAngle());

    // visible at start means we're adjusting the alpha for design 1
    if (visibleAtStart) {
      alpha = transparency;

      // use knob values in preview window to determine transparency
      if (pk_design1 != null) {
        float design1angle = degrees(pk_design1.getAngle());
        float diff = abs(analyzerangle - design1angle)%90; 
        
        if(diff <= 45) alpha = map(diff, 0, 45, 0, 255);
        else alpha = map(diff, 45, 90, 255, 0);
      }
    } else {
      alpha = 255-transparency;

      if (pk_design2!= null) {
        float design2angle = degrees(pk_design2.getAngle());
        float diff = abs(analyzerangle - design2angle)%90; 

        if(diff <= 45) alpha = map(diff, 0, 45, 0, 255);
        else alpha = map(diff, 45, 90, 255, 0);
      }
    }
  }
}
