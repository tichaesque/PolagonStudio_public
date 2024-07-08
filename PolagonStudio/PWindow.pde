// from atduskgreg on github 
import java.awt.Frame;
import processing.awt.PSurfaceAWT;
import processing.awt.PSurfaceAWT.SmoothCanvas;
import java.text.DecimalFormat;

//***********************************************
//   Preview Window Constants
//***********************************************
Polagon polagon;
boolean rotateMosaic = true; //for when both polarizers rotated together or not
boolean rotateMask = true; //false for when both polarizers rotated together
ArrayList<PreviewKnob> knobs = new ArrayList<PreviewKnob>(); //custom preview knobs
boolean isshiftpressed = false;
ArrayList<PreviewKnob> groupknob = new ArrayList<PreviewKnob>();
PreviewKnob currentknob;
float newdelta=0;
float newmaskdelta=0;
float newtheta=0;
float newphi=0;

boolean pol_in = false; 
boolean anly_in = false; 
boolean mask_in = false;

PImage previewpng;

//***********************************************
//   Edit Design Window Constants
//***********************************************
Palette mainpalette;
Palette origpalette;
Palette recoloredpalette;
Image origimg
; // displayed in edit window
Image recoloredimg;
EditSettings D1editsettings = new EditSettings();
EditSettings D2editsettings = new EditSettings();
boolean mask_visibleAtStart=false;
boolean change = false;
String selected = "1,1,1,1,1"; // default value from checkbox input
boolean inverted = false; // aligned vs crossed color palette
boolean uniformT = false; // all layers of the same thickness
int secondpaly; // y position of recolored palette
boolean accstate = false; //true = open, false = closed accordion of thicknesses

//***********************************************
//   Export Window Constants
//***********************************************
ArrayList<Exportfile> exportfiles = new ArrayList<Exportfile>();
boolean mainexportwindow = true; // in main export window or file export window
Exportfile makefile; //current file fabricated
float old_eps1;
float old_eps2;
CellophaneCheck cc;

//***********************************************
//   Biref Verication Window Constants
//***********************************************
ArrayList<Integer> birefcolors;
float curr_biref = 0.005;
float old_biref = curr_biref;
int birefsampsize = 50;
int birefgap = 5;
float thickness = -1; //user input
int numlayers = -1; //user input
ArrayList<Float> avail_thickness = new ArrayList<Float>();
ArrayList<Float> new_thickness = new ArrayList<Float>();
long startTime;
long endTime;
long minutes;
long seconds;
boolean donegenerating = false;

Thread genpal_thread = new Thread(){ // thread for generating palette -- takes about 20-30 min
  public void run(){
    println("start loading");
    startTime = System.currentTimeMillis();
    //delay(8000); //for testing thread
    String[] res = loadStrings("http://127.0.0.1:3000/generatepalette");
    print("done loading: ");
    println(res[0]);
  
    endTime = System.currentTimeMillis();
  
    System.out.println("That took " + (endTime - startTime) + " milliseconds");
    System.out.println("Total time: "
                           + minutes + " minutes and "
                           + seconds + " seconds.");
  }
};

//***********************************************
//   Fabrication Setting Window Constants
//***********************************************
String laserw = "32";
String laserh = "18";
String material_t = ""; //unit mm
String laserunit = "in";


public class PWindow extends PApplet {
  int type;
  PApplet parent = this;
  
  public PWindow(int type_) {
    super();
    type = type_; //type 1 = export, type 2 = preview, type 3 = edit window, type 4 = biref verification, type 5 = fabrication settings
  }
  
  public PWindow(int type_, PApplet parent_){
    super();
    type = type_;
    parent = parent_;
  }
  
  void init() {
    println(this.getClass().getSimpleName());
    PApplet.runSketch(new String[] {this.getClass().getSimpleName()}, this);
  }

  public void settings() {

    pixelDensity(displayDensity());
    if (type==1) size(1600,900); // for export window
    if (type==2) size(1200, 900); // for visualization UI
    if (type==3) size(1600,900); // for edit image window
    if (type==4) size(750, 300); // for biref window
    if (type==5) size(500, 200); // for laser settings
    if (type==6) size(800,500);
    if (type==7) size(600,600); // for png preview
  }

  public void setup() {
    textFont(font); 

    if (type==1){
      surface.setTitle("Export");
      surface.setAlwaysOnTop(true);
      surface.setLocation(150,25);
      shapeMode(CENTER);
      noStroke();
      textAlign(CENTER);
      
      exportcontrols = new ControlP5(this); 
      load_export_controls();
      exportfiles.clear();
      
      //load export files and set button settings based on what is imported
      if (first_loaded && !second_loaded && !maskset){ //only one design imported
        Image d1 = firstmainviews.get(0).copy_img(this, true, 800, 400, false, true); 
        exportfiles.add(new Exportfile(this, first_design_file, d1, -45));
        bmakeD1.setPosition(800-bw1/2, 400+325/2+bgap);
        epsD1.setPosition(800-bw1/2, 400+325/2+1.5*bgap+bh);
        epsD1.show();
        bmakeD2.hide();
        bmakeM.hide();
      } else if (first_loaded && second_loaded && !maskset){ // two designs + no mask
        Image d1 = firstmainviews.get(0).copy_img(this, true, 550, 400, false, true);
        Image d2 = secondmainviews.get(0).copy_img(this, true, 1050, 400, false, true);
        exportfiles.add(new Exportfile(this, first_design_file, d1, -45));
        exportfiles.add(new Exportfile(this, second_design_file, d2, 0));
        epsD1.setPosition(550-bw1/2, 400+325/2+1.5*bgap+bh);
        epsD1.show();
        epsD2.setPosition(1050-bw1/2, 400+325/2+1.5*bgap+bh);
        epsD2.show();
        bmakeD1.setPosition(550-bw1/2, 400+325/2+bgap);
        bmakeD2.setPosition(1050-bw1/2, 400+325/2+bgap);
        bmakeM.hide();
      } else if (first_loaded && !second_loaded && maskset){// one design + mask
        Image d1 = firstmainviews.get(0).copy_img(this, true, 550, 400, false, true);
        Mask m = new Mask(this, mask_file, true, 1050, 400, false, true);
        exportfiles.add(new Exportfile(this, first_design_file, d1, -45));
        exportfiles.add(new Exportfile(this, mask_file, m));
        epsD1.setPosition(550-bw1/2, 400+325/2+1.5*bgap+bh);
        epsD1.show();
        bmakeD1.setPosition(550-bw1/2, 400+325/2+bgap);
        bmakeD2.hide();
        bmakeM.setPosition(1050-bw1/2, 400+325/2+bgap);
      } else if (first_loaded && second_loaded && maskset){// two designs + mask
        Image d1 = firstmainviews.get(0).copy_img(this, true, 400, 400, false, true);
        Image d2 = secondmainviews.get(0).copy_img(this, true, 800, 400, false, true);
        Mask m = new Mask(this, mask_file, true, 1200, 400, false, true);
        exportfiles.add(new Exportfile(this, first_design_file, d1, -45));
        exportfiles.add(new Exportfile(this, second_design_file, d2, 0));
        exportfiles.add(new Exportfile(this, mask_file, m));
        epsD1.setPosition(400-bw1/2, 400+325/2+1.5*bgap+bh);
        epsD1.show();
        epsD2.setPosition(800-bw1/2, 400+325/2+1.5*bgap+bh);
        epsD2.show();
        bmakeD1.setPosition(400-bw1/2, 400+325/2+bgap);
        bmakeD2.setPosition(800-bw1/2, 400+325/2+bgap);
        bmakeM.setPosition(1200-bw1/2, 400+325/2+bgap);
      }
      
      bfabsettings.show();
    }
   
    if (type==2){
      surface.setTitle("Interact");
      surface.setAlwaysOnTop(true);
      surface.setLocation(150,25);
      previewcontrols = new ControlP5(this); 
      shapeMode(CENTER);
      noStroke();
      rotateMosaic=true;
      bgcolor=255;
      
      float knobx = 125;
      float adjy = 20;
      
      //load preview knobs
      pk_polarizer = new PreviewKnob(this, knobx, 450+180*2+adjy, "Polarizer");
      pk_analyzer = new PreviewKnob(this, knobx, 450-180*2+adjy, "Analyzer");

      if (first_loaded){
        Image img1 = firstmainviews.get(0).copy_img(this, true, 750, 450, false, false); //Image copy_img(PApplet parent, boolean visibleAtStart, int imgx, int imgy, boolean complementary, boolean maindisplay)
        polagon = new Polagon(this, img1, 750, 450);
        pk_design1 = new PreviewKnob(this, knobx, 450+adjy, first_design_file, "Design 1");
        pk_design1.angle = PI/4;
        newdelta=pk_design1.angle-PI/4;
      } else pk_design1 = new PreviewKnob(this, knobx, 450+adjy, "Design 1");
      
      if (second_loaded){
        Image img2 = secondmainviews.get(0).copy_img(this, false, 750, 450, false, false);
        polagon.setSecondImage(img2);
        pk_design2 = new PreviewKnob(this, knobx, 450+180+adjy, second_design_file, "Design 2");
      } else pk_design2 = new PreviewKnob(this, knobx, 450+180+adjy, "Design 2");
      
      if(maskset){
        polagon.setMask(mask_file, mask_visibleAtStart);
        pk_mask = new PreviewKnob(this, knobx, 450-180+adjy, mask_file, "Mask");
      } else pk_mask = new PreviewKnob(this, knobx, 450-180+adjy, "Mask");
      
      knobs.add(pk_polarizer); //idx 0
      knobs.add(pk_analyzer); //idx 1
      knobs.add(pk_design1); //idx 2
      knobs.add(pk_design2); //idx 3
      knobs.add(pk_mask); //idx 4
      
      for (int i=0; i<groupknob.size(); i++){
        groupknob.get(i).selected = false;
      }
      for (int i=0; i<knobs.size(); i++){
        knobs.get(i).selected = false;
      }
      groupknob.clear();
      currentknob = null;
      
      //load preview button
      updatepreview = previewcontrols.addButton("updatesnap")
        .setLabel("Create Snapshot")
        .setPosition(750-bw1/2, 800)
        .setSize(bw1, bh)
        .setColorBackground(buttonColor) 
        .setColorForeground(buttonHover)
        .setColorActive(buttonClick)
        .show()
        ;
    }
    
    if (type==3){
      surface.setTitle("Edit Design");
      surface.setLocation(150,25);
      editcontrols = new ControlP5(this);
      load_edit_controls();
      
      for (int i=0; i<new_thickness.size(); i++){
        checkbox.addItem(str(new_thickness.get(i))+" mm", new_thickness.get(i));
      }
      checkbox.activateAll();
      
      accordion.setMinItemHeight(200+30*new_thickness.size());
      accordion.updateItems();

      shapeMode(CENTER);
      noStroke();
    }
    
    if (type==4){
      surface.setTitle("Birefringence Calculation");
      surface.setAlwaysOnTop(true);
      surface.setLocation(600,300);
      shapeMode(CENTER);
      noStroke();
      birefcontrols = new ControlP5(this); 
      load_biref_controls();
      
    }
    
    if (type==5){
      surface.setTitle("Fabrication Settings");
      surface.setAlwaysOnTop(true);
      surface.setLocation(600,400);
      shapeMode(CENTER);
      noStroke();
      fabsettingcontrols = new ControlP5(this);
      load_fabsetting_controls();
    }
    
    if (type==6){
      surface.setTitle("Check Cellophane Colors");
      surface.setAlwaysOnTop(true);
      surface.setLocation(500,200);
      shapeMode(CENTER);
      noStroke();
      pixelDensity(displayDensity());
      background(255);
      cc = new CellophaneCheck(this, avail_thickness); 
    }
    
    if (type==7){
      surface.setTitle("png preview");
      surface.setAlwaysOnTop(true);
      noStroke();
      background(bgcolor);
      //updatesnap();
      //previewpng = loadImage("/data/snapshot/"+polagon.pname+"/png/"+"0.0+0.0_0.0_0.0.png");
    }
  }

  public void draw() {
    if (type==1){
      background(255);
      
      if (mainexportwindow){ //main export window that displays all designs to fabricate
        noStroke();
        fill(0);
        text("Fabricate Designs", 800, 50);
        fill(255,0,0);
        if (material_t=="") text("Please input base material thickness in settings", 800, 75);
        fill(0);
        
        for (int i=0; i<exportfiles.size(); i++){
          exportfiles.get(i).main_display();
          if(exportfiles.get(i).filename == first_design_file) {
            bmakeD1.show();
            epsD1.show();
            fill(0);
            text("# Files: "+exportfiles.get(i).numfiles, epsD1.getPosition()[0]+bw1/2, epsD1.getPosition()[1]+40);
          }
          if(exportfiles.get(i).filename == second_design_file) {
            bmakeD2.show();
            epsD2.show();
            fill(0);
            text("# Files: "+exportfiles.get(i).numfiles, epsD2.getPosition()[0]+bw1/2, epsD2.getPosition()[1]+40);
          }
          if(exportfiles.get(i).filename == mask_file) bmakeM.show();
        }
        
      } else {
        fill(0);
        makefile.make_display();
      }
    }
    
    if (type==2){ // preview/interact window display
      background(bgcolor);
      textAlign(CENTER);
      fill(UIColor);
      noStroke();
      rect(0,0,300,height);      
      
      if (currentknob!=null && groupknob.contains(currentknob)){  // for grouped knobs     
        for(int i=0; i<groupknob.size();i++){
          if (groupknob.get(i).label == "Polarizer") {
            groupknob.get(i).angle = currentknob.angle; 
            pol_in=true;
          }
          if (groupknob.get(i).label == "Analyzer") {
            groupknob.get(i).angle = currentknob.angle; 
            anly_in=true; 
          }
          if (groupknob.get(i).label == "Mask") {
            groupknob.get(i).angle = currentknob.angle; 
            mask_in=true; 
          }
        }
        
        if (pol_in && anly_in){
          pk_design1.selected=false;
          pk_design2.selected=false;
          rotateMosaic = false;
          rotateMask = false;
          newtheta = 0; newphi = 0;
          newdelta = currentknob.angle+pk_design2.angle;
          newmaskdelta = abs(currentknob.angle - pk_mask.angle);
        } else{
          if (pol_in) newphi = currentknob.angle;
          if (anly_in) newtheta = currentknob.angle; 
          if (mask_in) newmaskdelta = currentknob.angle; 
        } 
      }
      pol_in=false;
      anly_in=false;
      mask_in=false;
      
      if (currentknob != null && !groupknob.contains(currentknob)){ // for single knob rotations
        newphi = pk_polarizer.angle;
        newtheta = pk_analyzer.angle;
        newdelta = pk_design2.angle;
        newmaskdelta = pk_mask.angle;
        if (currentknob.label == "Mask"){ 
          rotateMask = true;
          newmaskdelta = currentknob.angle;
          newphi = pk_polarizer.angle;
          newtheta = pk_analyzer.angle;
          newdelta = pk_design2.angle;
        }
        if (currentknob.label == "Analyzer"){
          newtheta = currentknob.angle;
        }
        if (currentknob.label == "Polarizer"){
          newphi = currentknob.angle;
        }
        if (currentknob.label == "Design 1"){
          rotateMosaic = true;
          if (!second_loaded){ //only one design imported
            newdelta = currentknob.angle-PI/4;
          } else { // design 1 & 2 are rotated together
            currentknob.selected=true;
            pk_design2.selected=true;
            if (currentknob.angle >= PI/4) pk_design2.angle = currentknob.angle - PI/4;
            else pk_design2.angle = 7*PI/4 + currentknob.angle;
            newdelta = currentknob.angle-PI/4;
          }
        }
        if (currentknob.label == "Design 2"){
          rotateMosaic = true;
          currentknob.selected=true;
          pk_design1.selected=true;
          newdelta = currentknob.angle;
          if (currentknob.angle>=7*PI/4) pk_design1.angle = 2*PI-currentknob.angle + PI/4;
          else pk_design1.angle = currentknob.angle + PI/4;
        }
      } 
      
      
      if (DELTA != newdelta || MASKDELTA != newmaskdelta || THETA != newtheta || PHI != newphi) {
        
        DELTA = newdelta;
        MASKDELTA = newmaskdelta;
    
        
        THETA = newtheta; // simulates rotating front polarizer (analyzer)
        PHI = newphi; // simulates rotating back polarizer (polarizer)
        
        //for debugging
        //print("theta: "+degrees(THETA));
        //print(", maskdelta: "+degrees(MASKDELTA)); 
        //print(", diff: " + abs(degrees(THETA-MASKDELTA)));
        //print(", phi: "+ degrees(PHI));
        //print(", delta: "+degrees(DELTA));
        //println();
    
        // refresh the polagon every time the user adjusts a slider
        polagon.update();
    
        rotationChanged = true;
      }
      
      if (isshiftpressed & mousePressed) {        
        //println("shift and mouse pressed");
        for (int i=0; i<knobs.size(); i++){
          if (knobs.get(i).clicked_on()) {
            groupknob.add(knobs.get(i));
            knobs.get(i).selected=true;
          }
        }
      }
      
      for (int i=0; i<knobs.size(); i++){
        knobs.get(i).display();
      }
           
      noStroke();
      polagon.display();  
      
      //info box
      fill(UIColor);
      rect(1125, 20, 50, 50);
      fill(225);
      text("?", 1150, 45);
      String instructions = "CLICK+DRAG to rotate knob \nSHIFT+CLICK to select multiple knobs \nTAB to deselect knobs \nDOUBLE CLICK on knob value to manually change angle \nENTER/RETURN to set angle";
      if (1125<=parent.mouseX && parent.mouseX<=1175 && 20<=parent.mouseY && parent.mouseY<=70){
        fill(UIColor);
        rect(525, 20, 1125-525, 160);
        fill(225);
        textAlign(LEFT);
        text(instructions, 550, 55);
      }
    }
    
    if (type==3){ // edit design window display
      if (inverted) background(0);
      else background(255);
      fill(UIColor);
      noStroke();
      rect(800,0,800,125);
      
      if (!D1loaded && first_design_file !=null && editD1){
        surface.setAlwaysOnTop(true);
        if (D1editsettings.origimg == null){ // first time loading edit window for D1
          println("create new");
          createnew(first_design_file);
          mainpalette = new Palette(this, 800, 160, 775, 650);
        } else { // if design has already been edited once, load past settings
          println("load past settings for D1");
          D1editsettings.loadsettings();
          origimg = D1editsettings.origimg.copy_img(this, true, D1editsettings.origimg.imgx, D1editsettings.origimg.imgy, false, true);
          recoloredimg = D1editsettings.recoloredimg.copy_img(this, true, D1editsettings.recoloredimg.imgx, D1editsettings.recoloredimg.imgy, false, true);
          origpalette = D1editsettings.origpalette.copy_palette(this,false);
          recoloredpalette = D1editsettings.recoloredpalette.copy_palette(this,false);
          mainpalette = D1editsettings.mainpalette.copy_palette(this,true);
          println("reloaded parent" + recoloredpalette.parent);
        }
        D1loaded = true;
      }
      
      if (!D2loaded && second_design_file !=null && editD2){
        surface.setAlwaysOnTop(true);
        if (D2editsettings.origimg == null) { //first time loading edit window for D2
          createnew(second_design_file);
          mainpalette = new Palette(this, 800, 160, 775, 650);
        } else { //if D2 already edited, load past settings
          println("load past settings for D2");
          D2editsettings.loadsettings();
          origimg = D2editsettings.origimg.copy_img(this, true, D2editsettings.origimg.imgx, D2editsettings.origimg.imgy, false, true);
          recoloredimg = D2editsettings.recoloredimg.copy_img(this, true, D2editsettings.recoloredimg.imgx, D2editsettings.recoloredimg.imgy, false, true);
          origpalette = D2editsettings.origpalette.copy_palette(this,false);
          recoloredpalette = D2editsettings.recoloredpalette.copy_palette(this,false);
          mainpalette = D2editsettings.mainpalette.copy_palette(this,true);
        }
        D2loaded=true;
      }

      if ((D1loaded && editD1) || (D2loaded && editD2)){
        textAlign(CENTER);
        if (inverted) fill(255);
        else fill(0);
        textSize(14);
        text("Original Design", 200, 120);
        text("Recolored Design", 600, 120);
        textAlign(LEFT);
        text("Original Palette", 20, 530);
        text("Recolored Palette", 20, secondpaly+recoloredpalette.sampsize+30);
        text("Available Colors", 800, 150);
        
        origimg.orig_img_display();
        recoloredimg.display();
        
        origpalette.display();
        recoloredpalette.display();
        mainpalette.display();
      }
    }
    
    if (type==4){
      background(255); //should be able to invert
      fill(0);
      textAlign(LEFT);
      textSize(14);
      text("Thickness (mm):", 20, 40);
      text("Num layers: ", 20, 80);
      text("Biref value: ", 20, 120);
      if (thickness>0) text(thickness,300,40);
      if (numlayers>0) text(numlayers,300,80);
      
      if (thickness>0 && numlayers >0){
        if (old_biref != curr_biref) biref_update();
        for (int i = 0; i < numlayers; i++) {
          color col = birefcolors.get(i); 
          fill(col);
          rect(20+i*(birefsampsize+birefgap), 90+birefsampsize+birefgap, birefsampsize, birefsampsize);
        }
      }   
      
      fill(255,0,0);
      text("To generate a new palette, \nclick Done", 450, 50);
      //text("Can take 20-30 min", 450, 120);
      
      if (genpal_thread.isAlive()){
        birefslider.hide();
        fill(UIColor);
        rect(200, 85, 400, 100);
        fill(255);
        textAlign(CENTER);
        text("Generating Palette", 400, 130);
        long duration = System.currentTimeMillis() - startTime;
        minutes= (duration / 1000) / 60;
        seconds = (duration / 1000) % 60;
        text("Elapsed Time: "+minutes + ":"+ seconds, 400, 160);
        donegenerating = true;
      }
      
      if (donegenerating && !genpal_thread.isAlive()){
        println("close biref window");
        Frame frame = ( (SmoothCanvas) ((PSurfaceAWT)surface).getNative()).getFrame();
        frame.dispose();
        birefwindow = null;
        type = 0;
        donegenerating=false;
      }
    }
    
    if (type==5){
      background(255); 
      fill(0);
      textSize(14);
      text("Units: ", 20, 40);
      text("Workspace width:", 20, 80);
      text("Workspace height: ", 20, 120);
      text("Material thickness (mm): ", 20, 160);
      text(laserw, 400, 80);
      text(laserh, 400, 120);
      text(material_t, 400, 160);
    }
    
    if (type==7){
      background(bgcolor);
      
    }
  }
  
  

  //***********************************************
  //   Biref Window Control Functions
  //***********************************************
  
  public void updatedict(){ //add new cellophane thickness to dictionary
    loadStrings("http://127.0.0.1:3000/updatecellophanedict?thickness="+thickness*1000000+"&biref="+nf(curr_biref,0,5));
    println("upated cellophane dict");
    
    if (!avail_thickness.contains(thickness)) new_thickness.add(thickness);
  }
  
  public void birefdone(){
    //generate new palette
    println("generate new palette");
    genpal_thread.start();
    //println("close window");
    //Frame frame = ( (SmoothCanvas) ((PSurfaceAWT)surface).getNative()).getFrame();
    //frame.dispose();
    //birefwindow = null;
    //type = 0;
  }
  
  public void birefslider(float theValue){
    curr_biref = theValue;
  }
  
  public void biref_update() {
    for (int i = 0; i < numlayers; i++) {
      String input = "theta="+PI/4+"&phi="+PI/4+"&biref="+nf(curr_biref,0,5)+"&thickness="+thickness*pow(10, 6)*(i+1);
      String[] res = loadStrings("http://127.0.0.1:3000/getcolor?"+input);
      String result = res[0].substring(1, res[0].length()-1).trim();
      String[] newc = result.split("\\s+");
      color newfill = color(float(newc[0]), float(newc[1]), float(newc[2]));
  
      birefcolors.set(i, newfill);
    }
    old_biref = curr_biref;
  }
  
  //***********************************************
  //   Export Window Control Functions
  //***********************************************
  
  public void checkcellophane(){
    exportcheck = new PWindow(6);
    exportcheck.init();
  }
  
  public void fabsettings(int theValue){
    println("settings window");
    fabsetwindow = new PWindow(5);
    fabsetwindow.init();
  }
  
  public void back(int theValue){
    if (makefile.currentidx > 0) makefile.currentidx -= 1;
    if (makefile.currentidx == 0) bleft.hide();
    else bright.show();
    if (makefile.currentidx < makefile.laserfiles.size()-1) bfinish.hide();
  }
  
  public void next(int theValue){
    if (makefile.currentidx < makefile.laserfiles.size()-1) makefile.currentidx += 1;
    if (makefile.currentidx == makefile.laserfiles.size()-1) {
      bright.hide();
      bfinish.show();
    } else {
      bleft.show();
      bfinish.hide();
    }
  }
  
  public void finish(int theValue){
    Frame frame = ( (SmoothCanvas) ((PSurfaceAWT)surface).getNative()).getFrame();
    frame.dispose();
    exportwindow = null;
    type = 0;
    exportfiles.clear();
    mainexportwindow = true;
    makefile = null;
  }
  
  public void mainexport(int theValue){
    mainexportwindow = true;
    bmainexport.hide();
    bleft.hide();
    bright.hide();
    bfinish.hide();
    bfabsettings.show();
    bcheck.show();
  }
  
  public void makeD1(int theValue){
    println("makeD1");
    mainexportwindow = false;
    for (int i=0; i<exportfiles.size(); i++){
      if (exportfiles.get(i).filename == first_design_file) {
        makefile = exportfiles.get(i);
        makefile.currentidx = 0;
        println("makefile name: " + makefile.filename);
        break;
      }
    }
    bmakeD1.hide();
    bmakeD2.hide();
    bmakeM.hide();
    bcheck.hide();
    epsD1.hide();
    epsD2.hide();
    bright.show();
    bmainexport.show();
    bfabsettings.hide();
  }
  
  public void makeD2(int theValue){
    println("makeD2");
    mainexportwindow = false;
    for (int i=0; i<exportfiles.size(); i++){
      if (exportfiles.get(i).filename == second_design_file){
        makefile = exportfiles.get(i);
        makefile.currentidx = 0;
        break;
      } 
    }
    bmakeD1.hide();
    bmakeD2.hide();
    bmakeM.hide();
    bcheck.hide();
    epsD1.hide();
    epsD2.hide();
    bright.show();
    bmainexport.show();
    bfabsettings.hide();
  }
  
  public void makeM(int theValue){
    println("makeM");
    mainexportwindow=false;
    for (int i=0; i<exportfiles.size(); i++){
      if (exportfiles.get(i).filename == mask_file){
        makefile = exportfiles.get(i);
        makefile.currentidx = 0;
        break;
      } 
    }
    bmakeD1.hide();
    bmakeD2.hide();
    bmakeM.hide();
    bcheck.hide();
    epsD1.hide();
    epsD2.hide();
    //bright.show();
    bmainexport.show();
    bfinish.show();
    bfabsettings.hide();
  }
  
  
  //***********************************************
  //   Edit Window Control Functions
  //***********************************************
  
  public void acc_button(int theValue){
    accstate = !accstate;
    if (accstate) accordion.open();
    else accordion.close();
  }
  
  public void createnew(String filename){
    origimg = new Image(this, filename, true, 200, 300, false, true);
    recoloredimg = new Image(this, filename, true, 600, 300, false, true);
    origpalette = new Palette(this, filename, 20, 550, 780, 100, false);
    secondpaly = origpalette.palettey + origpalette.sampsize + origpalette.gap;
    recoloredpalette = new Palette(this, filename, 20, secondpaly, 780, 100, true);
  }
  
  public void changedesign(int theValue){
    surface.setAlwaysOnTop(false);
    selectInput("select file:", "changeSelected", null, this);
  }
  
  public void changeSelected(File selection){
    if (editD1) {
      println("change D1");
      first_design_file = selection.getName();
      createnew(first_design_file);
    }
    if (editD2){
      println("change D2");
      second_design_file = selection.getName();
      createnew(second_design_file);
    }
    change = false;
  }

  public void editdone(int theValue){
    Frame frame = ( (SmoothCanvas) ((PSurfaceAWT)surface).getNative()).getFrame();
    frame.dispose();
    editwindow = null;
    type = 0;
    
    if (editD1){
      first_inverted = inverted;
      firstmainviews.clear();
      first_loaded=false;
      
      D1editsettings.savesettings(origimg, recoloredimg, origpalette, recoloredpalette, mainpalette, inverted, uniformT, selected);
      editD1=false;
      load_mosaic1();
      
      //println("start saving recolored_D1");
      //loadStrings("http://127.0.0.1:3000/updatesvg?filename="+recoloredimg.filename);
      //println("saved recolored_D1");
    }
    
    if (editD2){
      second_inverted = inverted;
      secondmainviews.clear();
      second_loaded=false;
      
      D2editsettings.savesettings(origimg, recoloredimg, origpalette, recoloredpalette, mainpalette, inverted, uniformT, selected);
      editD2=false;
      load_mosaic2();
    }
    
    origimg = null;
    origpalette = null;
    recoloredpalette = null;
    mainpalette = null;

  }
  
  public void invert(boolean theFlag){
    print("invert toggle value: ");
    println(theFlag);
    loadStrings("http://127.0.0.1:3000/clearmapping");
    inverted = theFlag;
    if (recoloredimg != null) {
      mainpalette.update_palette();
      recoloredimg.update_palette();
      recoloredpalette.update_img_palette();
    }
    
  }
  
  //public void uniform(boolean theFlag){
  //  print("uniform toggle value: ");
  //  println(theFlag);
  //  loadStrings("http://127.0.0.1:3000/clearmapping");
  //  uniformT = theFlag;
  //  if (recoloredimg != null) {
  //    mainpalette.update_palette();
  //    recoloredimg.update_palette();
  //    recoloredpalette.update_img_palette();
  //  }
  //}
  
  public void mousePressed() {
    if (type==2){//for animate window
      for (int i=0; i<knobs.size(); i++){ //single click to get current knob
        knobs.get(i).mousePressedKnob();
        if (knobs.get(i).clicked_on()) {
          currentknob = knobs.get(i); 
        }
      }
      if (mouseEvent.getCount()==2){ //double click to edit angle value
        //print("double click: ");
        if (currentknob!=null){
          print(currentknob.label + "angle: ");
          println(degrees(currentknob.angle));
          currentknob.txtfield.setValue("");
          currentknob.txtfield.show();
        }
      }
    }
    if (type==3){ //for picking new polage color
      if (selectedpolagecolor != -1) {//if polage color clicked, reorder main palette
        mainpalette.reorderPalette();
        polageidx2change = selectedpolageidx;
        
      }
      if (polageidx2change > -1 && mainpalette.selectedcolor > -1){//change recolored polage color to new color
        int newpolagecolor = mainpalette.colorpalette.get(mainpalette.selectedcolor);
        print("new polage color: ");
        println(hex(newpolagecolor,6));
        JSONArray stackcomp = loadJSONArray("http://127.0.0.1:3000/stackcomposition?filename="+recoloredimg.filename+"&colorkey="+hex(newpolagecolor,6));
        String compstring = "";
        for(int j = 0; j<stackcomp.size(); j++) {
          compstring += stackcomp.getFloat(j);
          if(j < stackcomp.size()-1) compstring += "~";
        }
        
        String origcolor = hex(origpalette.colorpalette.get(polageidx2change),6);
        String newcolor = hex(newpolagecolor, 6);
        String filename = origimg.filename;
        
        String input1 = "filename="+filename+"&inverted="+str(int(inverted))+"&uniform="+str(int(uniformT))+"&selected="+selected;
        String input2 = "&origcolor="+origcolor+"&newcolor="+newcolor;
        loadStrings("http://127.0.0.1:3000/generatesvgs?" + input1 + input2); //generate new recolored svgs using Python

        //update color and comp
        println("update color parent" + recoloredpalette.parent);
        recoloredpalette.colorpalette.set(polageidx2change,newpolagecolor);
        recoloredimg.make_recolored_image(true);  
      }
    }
  }

  public void mouseMoved() {
    if (type==3){
      mainpalette.mouseOverPalette();
      origpalette.mouseOverPalette();
      recoloredpalette.mouseOverPalette();
    }
  }
  
  //***********************************************
  //   Animate Window Control Functions
  //***********************************************
  void updatesnap(){
    // for each image,mask in polagon, snapshot depends on each phi & theta value
    println("update snap");
    String input = "delta=" + str(DELTA) + "&phi=" + str(PHI) + "&theta=" + str(THETA) + "&maskdelta=" + str(MASKDELTA);
    String filename="";
    String img1_info="";
    String img2_info="";
    String mask_info="";
    if (first_loaded) {
      Image img1 = polagon.blayers.get(0);
      img1_info = get_img_info(img1);
      filename += img1.filename;
      println("img1_info: ", img1_info);
    }
    if (second_loaded){
      Image img2 = polagon.blayers.get(1);
      img2_info = get_img_info(img2);
      filename += ";" + img2.filename;
      println("img2_info: ", img2_info);
    }
    if (maskset) {
      mask_info = str(polagon.mask.opacity/255);
      filename += ";" + polagon.mask.filename;
    }
    input += "&filename=" + filename + "&img1_info=" + img1_info + "&img2_info=" + img2_info + "&mask_info=" + mask_info;
    input += "&background=" + hex(color(int(bgcolor),int(bgcolor),int(bgcolor)),6);
    println("input: " + input);
    loadStrings("http://127.0.0.1:3000/updatesvg?"+input);
  }
  
  String get_img_info(Image img){
    ArrayList<String> img_colors = new ArrayList<String>();
    for (int i=0; i < img.recolored_img.size(); i++) { // loop through children
      SVGChild child = img.recolored_img.get(i);
      img_colors.add("("+hex(child.col,6)+","+str(child.alpha/255)+")");
    }
    String img_info = String.join(";",img_colors);
    println("img info: ", img_info);
    return img_info;
  }
  
  void mouseReleased() {
    if (type==2){
      currentknob = null;
      for (int i=0; i<knobs.size(); i++){
        knobs.get(i).mouseReleasedKnob();
      }
      
    }
  }
  
  void keyPressed(){
    if (type==2){
      if (key == CODED){
        if (keyCode == SHIFT){ //press shift + click to select multiple knobs
          //println("shift pressed");
          isshiftpressed = true;
        }
      }
      if (key==TAB){ //press tab to deselect grouped knobs
        //println("tab pressed");
        for (int i=0; i<groupknob.size(); i++){
          groupknob.get(i).selected = false;
        }
        for (int i=0; i<knobs.size(); i++){
          knobs.get(i).selected = false;
        }
        groupknob.clear();
        currentknob = null;
        rotateMosaic = true;
        pk_design2.rotatebothpolarizers = false;
        polagon.blayers.get(1).visibleAtStart = true;
        
        newphi = pk_polarizer.angle;
        newtheta = pk_analyzer.angle;
        newdelta = pk_design2.angle;
        newmaskdelta =   pk_mask.angle;
      }
    }
  }
  
  void keyReleased(){
    if (type==2){
      if (key == CODED){
        if (keyCode == SHIFT){
          //println("shift released");
          isshiftpressed = false;
        }
      }
    }
  }
  
  //***********************************************
  //   Fab Settings Window Control Functions
  //***********************************************
  void units(int a) {
    if (a==1) laserunit = "in";
    if (a==2) laserunit = "cm";
    println("laserunit: "+laserunit);
    for (int i=0; i<exportfiles.size(); i++){
      exportfiles.get(i).update_lasersettings();
    }
  }
 

  void controlEvent(ControlEvent theEvent) {
    
    if (theEvent.isFrom(checkbox)){
      selected = "";
      for (int i=0;i<checkbox.getArrayValue().length;i++) {
        selected += str(int(checkbox.getArrayValue()[i]));
        selected += ",";
      }
      selected = selected.substring(0,selected.length()-1);
      loadStrings("http://127.0.0.1:3000/clearmapping");
      if (recoloredimg != null & recoloredpalette != null) {
        mainpalette.update_palette();
        recoloredimg.update_palette();
        recoloredpalette.update_img_palette();
      }
    }
    
    //***********************************************
    //   Export Epsilon Slider Control Functions
    //***********************************************
    
    if (theEvent.isController()) { 
      // dragging epsilon1 slider changes tolerance of D1
      if (theEvent.getController().getName()=="epsilon1" && exportfiles.size()>0) {
        float value = theEvent.getController().getValue();
        if (value != old_eps1) {
          print("epsilon change D1 name: ");
          print(exportfiles.get(0).filename);
          print(", new eps val: ");
          print(value);
          exportfiles.get(0).update_epsilon(value);
          old_eps1 = value;
        }
      }
      
      if (theEvent.getController().getName()=="epsilon2" && exportfiles.size()>1) {
        float value = theEvent.getController().getValue();
        if (value != old_eps2) {
          print("epsilon change D2 name: ");
          print(exportfiles.get(1).filename);
          print(", new eps val: ");
          print(value);
          exportfiles.get(1).update_epsilon(value);
          old_eps2 = value;
        }
      }
      
    }
    
    //***********************************************
    //   Biref Verification Window Control Functions
    //***********************************************
    
    if(theEvent.isAssignableFrom(Textfield.class)) {
      if (theEvent.getName() == "thickness"){
        println("setting thickness to "+theEvent.getStringValue());
        thickness = float(theEvent.getStringValue());
        biref_update();
      }
      if (theEvent.getName() == "numlayers"){
        println("setting numlayers to "+theEvent.getStringValue());
        numlayers = int(theEvent.getStringValue());
        birefcolors = new ArrayList<Integer>();
        for (int i = 0; i < numlayers; i++) {
          birefcolors.add(color(0, 0, 0));
        }
        biref_update();
      }
    }
    
    //***********************************************
    //   Fab Setting Window Control Functions
    //***********************************************
    
    if(theEvent.isAssignableFrom(Textfield.class)) {
      if (theEvent.getName() == "laserw"){
        println("setting laserw to "+theEvent.getStringValue());
        laserw = theEvent.getStringValue();
        for (int i=0; i<exportfiles.size(); i++){
          exportfiles.get(i).update_lasersettings();
        }
      }
      if (theEvent.getName() == "laserh"){
        println("setting laserh to "+theEvent.getStringValue());
        laserh = theEvent.getStringValue();
        for (int i=0; i<exportfiles.size(); i++){
          exportfiles.get(i).update_lasersettings();
        }
      }
      if (theEvent.getName() == "material_t"){
        //println("setting material_t to "+theEvent.getStringValue());
        material_t = nf(float(theEvent.getStringValue()),0,4);
      }
    }
    
    //***********************************************
    //   Preview Window Control Functions
    //***********************************************
    
    if(theEvent.isAssignableFrom(Textfield.class)) {
      for (int i=0; i<knobs.size(); i++){
        if (knobs.get(i).hover_over()) currentknob = knobs.get(i);
      }
      if (theEvent.getName() == currentknob.label){
        if (theEvent.getStringValue() != ""){
          currentknob.angle = radians(float(theEvent.getStringValue()));
          currentknob.txtfield.hide();
        } else {currentknob.txtfield.hide();}
      }
    }
    
  }
  
  public void exit() {
    println("window exited");
    if (type==2){
      THETA = 0; // absolute angle of top polarizer
      PHI = 0;   // absolute angle of bottom polarizer
      DELTA = 0; // angle of design
      MASKDELTA = 0; // angle of mask (third polarizer)
      newdelta=0;
      newmaskdelta=0;
      newtheta=0;
      newphi=0;
    }
    dispose();
    
  }
  
}


//Edit Settings class to keep track of previous edits
class EditSettings{
  Image origimg;
  Image recoloredimg;
  Palette origpalette;
  Palette recoloredpalette;
  Palette mainpalette;
  boolean inverted;
  boolean uniform;
  String selected;
  
  public EditSettings(){}
  
  public EditSettings(Image origimg_, Image recoloredimg_, Palette origpalette_, Palette recoloredpalette_, Palette mainpalette_, boolean inverted_, boolean uniform_, String selected_){
    this.origimg = origimg_;
    this.recoloredimg = recoloredimg_;
    this.origpalette = origpalette_;
    this.recoloredpalette = recoloredpalette_;
    this.mainpalette = mainpalette_;
    this.inverted = inverted_;
    this.uniform = uniform_;
    this.selected = selected_;
  } 
  
  public void savesettings(Image origimg_, Image recoloredimg_, Palette origpalette_, Palette recoloredpalette_, Palette mainpalette_, boolean inverted_, boolean uniform_, String selected_){
    this.origimg = origimg_;
    this.recoloredimg = recoloredimg_;
    this.origpalette = origpalette_;
    this.recoloredpalette = recoloredpalette_;
    this.mainpalette = mainpalette_;
    this.inverted = inverted_;
    this.uniform = uniform_;
    this.selected = selected_;
  }
  
  public void loadsettings(){
    //load checkboxes
    checkbox.deactivateAll();
    int[] checkidx = int(split(this.selected,","));
    for (int i=0; i<checkidx.length; i++){
      if (checkidx[i]==1) checkbox.activate(i);
    }
    
    //load toggles
    inverttoggle.setValue(this.inverted);
    //uniformtoggle.setValue(this.uniform);
  }
}
  
