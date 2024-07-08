class PreviewKnob{
  
  PApplet parent;
  PShape icon;
  boolean rotationChanged = false;

  float mouseXStart = 0; 
  float mouseYStart = 0; 
  
  float angle = 0;
  float oldangle = 0;
  
  // the reference point of the rotation
  float refX;
  float refY;
  
  float ellipsewidth = 60; 
  float len = 60;
  float designscale;
  boolean selected=false;
  boolean rotatebothpolarizers = false;
  
  String label;
  
  Textfield txtfield; //for manually setting angle

  public PreviewKnob(PApplet parent_, float refx_, float refy_, String filename, String label_){ // for mask & design layer
    parent = parent_;
    refX = refx_;
    refY = refy_;
    label = label_;
    parent.shapeMode(CENTER);
    icon = loadShape(filename);
    icon.disableStyle();
    
    float tmpw = icon.width;
    float tmph = icon.height;
    if (tmpw>tmph) designscale = (ellipsewidth-10)/tmpw;
    else designscale = (ellipsewidth-10)/tmph;
    
    PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
    ControlFont cfont = new ControlFont(font);
    txtfield = previewcontrols.addTextfield(label)
     .setPosition(refX+len+20,refY-10)
     .setSize(60,35)
     .setAutoClear(false)
     .setColorBackground(buttonColor) 
     .setColorForeground(buttonHover)
     .setColorActive(buttonClick)
     .setLabel("")
     .setValue(str(angle))
     .hide()
     .setFont(cfont)
     ;
  }
  
  public float getAngle() {
    return angle; 
  }
  
  public PreviewKnob(PApplet parent_, float refx_, float refy_, String label_){ // for polarizer
    parent = parent_;
    refX = refx_;
    refY = refy_;
    label = label_;
    parent.shapeMode(CENTER);
    
    PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
    ControlFont cfont = new ControlFont(font);
    txtfield = previewcontrols.addTextfield(label)
     .setPosition(refX+len+20,refY-10)
     .setSize(60,30)
     .setAutoClear(false)
     .setColorBackground(buttonColor) 
     .setColorForeground(buttonHover)
     .setColorActive(buttonClick)
     .setLabel("")
     .setValue(angle)
     .hide()
     .setFont(cfont)
     ;
  }
  
  
  public void mousePressedKnob(){
    if (refX - ellipsewidth < parent.mouseX && parent.mouseX < refX + ellipsewidth && 
      refY - ellipsewidth < parent.mouseY && parent.mouseY < refY + ellipsewidth) {
      rotationChanged = true;
    }
    mouseXStart = parent.mouseX;
    mouseYStart = parent.mouseY;
  }
  
  public void mouseReleasedKnob(){
    rotationChanged = false;
    oldangle = angle;
  }
  
  public void update(){
    if (rotationChanged && (parent.mouseX-mouseXStart)!=0) {
      if (parent.mouseX > refX) angle = atan2(parent.mouseX-refX, refY-parent.mouseY); // different equations bc want 0 to be the vertical
      else angle = atan2(refX - parent.mouseX, parent.mouseY-refY) + PI; 
    }
  }
  
  public boolean clicked_on(){//knob is clicked on
    if (refX - ellipsewidth < parent.mouseX && parent.mouseX < refX + ellipsewidth + len + 20 && 
      refY - ellipsewidth < parent.mouseY && parent.mouseY < refY + ellipsewidth) { //includes text label + knob
      return true;
    } else return false;
  }
  
  public boolean hover_over(){//knob is hovered over
    if (refX - ellipsewidth < parent.mouseX && parent.mouseX < refX + ellipsewidth + len + 80 && 
      refY - ellipsewidth < parent.mouseY && parent.mouseY < refY + ellipsewidth) { //includes text label + knob
      return true;
    } else return false;
  }
  
  public void arrow() { // function for drawing the arrow & angle text
    parent.pushMatrix();
    parent.translate(refX, refY);
    parent.fill(255);
    parent.textAlign(LEFT, CENTER);
    parent.text(nf(degrees(angle),0,1), len+20, 0);
    parent.textAlign(CENTER, CENTER);
    parent.text(label, 0, -len-20);
    parent.rotate(angle);
    parent.line(0,0,0,-len);
    parent.line(0, -len, -8, -(len-8));
    parent.line(0, -len, 8, -(len-8));
    parent.popMatrix();
  }
  
  public void display(){
    update();
    
    if (selected) {
      parent.stroke(buttonClick);
      parent.strokeWeight(5);
    } else parent.noStroke();
    parent.fill(buttonColor);
    parent.ellipse(refX, refY, ellipsewidth+30, ellipsewidth+30);  //draw larger ellipse
    parent.fill(buttonClick);
    if (rotationChanged) { //draw arc to show how much the item has been rotated
      parent.stroke(buttonClick);
      parent.strokeWeight(5);
    }
    parent.arc(refX, refY, ellipsewidth+30, ellipsewidth+30, -PI/2, angle-PI/2);
    parent.noStroke();
    parent.fill(buttonColor); 
    parent.ellipse(refX, refY, ellipsewidth, ellipsewidth); //smaller ellipse to make it look like the control P5 knob
    
    if (icon != null) { // for design/mask knobs
      parent.pushMatrix();
      parent.translate(refX, refY);
      parent.scale(designscale);
      if (label=="Design 1") parent.rotate(angle-PI/4);
      else parent.rotate(angle);
      parent.fill(0,0);
      parent.strokeWeight(5);
      if (rotationChanged) parent.stroke(buttonClick);
      else parent.stroke(buttonHover);
      parent.shape(icon);
      parent.popMatrix();
    }
    
    parent.stroke(255); 
    parent.strokeWeight(3); 
    arrow(); 
  }
}
