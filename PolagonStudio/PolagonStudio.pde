// [!!] polagon_service must be running for this to work [!!] 

/*
 * How to export SVGs from Illustrator to Processing:
 * "Save As...SVG" -> SVG 1.1 -> CSS properties: 'Style Attributes'
 */

import processing.svg.*;
import gifAnimation.*;
import processing.video.*;


float biref = 0.0055; // birefringence value; material-dependent
float E0 = 1; // radiance

// Control values that the user changes
float THETA = 0; // absolute angle of top polarizer
float PHI = 0;   // absolute angle of bottom polarizer
float DELTA = 0; // angle of design
float MASKDELTA = 0; // angle of mask (third polarizer)

float IMGWIDTH = 600; // based on size of preview window
float IMGHEIGHT = 600;
float MAINIMGWIDTH = 325; // in main UI, each square is 400px x 400px
float MAINIMGHEIGHT = 325;
ArrayList<Image> firstmainviews = new ArrayList<Image>();
ArrayList<Image> secondmainviews = new ArrayList<Image>();
ArrayList<Mask> maskviews = new ArrayList<Mask>();

float bgcolor = 255; //for preview/interact window

boolean rotationChanged = false;
boolean mouseOverDesign = false;
boolean mouseOverMask = false;
boolean mouseOverPolarizer = false;
boolean hovering = false;
boolean preview = true; // interactive preview of the polagon

String first_design_file;
String second_design_file;
String mask_file;
boolean maskset = false;
boolean editD1 = false; // to signal which file has been changed - design 1 or design 2
boolean editD2 = false;
boolean first_inverted;
boolean second_inverted;
boolean first_loaded = false;
boolean second_loaded = false;

PWindow previewwindow; //view interaction with polagon
PWindow editwindow; //edit mosaic design colors
PWindow exportwindow; //view export settings and files
PWindow birefwindow; //calculate birefringence based on cellophane thickness & update palette
PWindow fabsetwindow; //edit laser cutter settings
PWindow exportcheck;
PWindow secondpreview;

color UIColor = color(76, 78, 99); 
color buttonColor = color(24, 26, 48); 
color buttonHover = color(188, 69, 196);
color buttonClick = color(226, 91, 235); 

PFont font;

boolean doneInit = false;
String options; // D1, D1M, D2, D2M
ArrayList<Integer> imgplace = new ArrayList<Integer>();
//boolean mainLoaded = false;
Gif D1M; // 1 design, 1 mask
Gif D2M; // 2 designs, 1 mask
Gif D2; // 2 designs, no mask
Image imD1;
Image imD1M;
Image imD2M;
Image imD2;

void settings() {
  size(1600, 900);
  pixelDensity(displayDensity());
}

void setup() {
  shapeMode(CENTER);
  noStroke();
  surface.setTitle("Polagon Studio");
  surface.setLocation(150,25);

  font = createFont("fakereceipt.ttf", 14);
  textFont(font);

  // sets up the controls for main UI
  //load_main_controls();
  load_init_controls();
  
  loadStrings("http://127.0.0.1:3000/clearmapping");
  
  String res[] = loadStrings("http://127.0.0.1:3000/getcellophanedict");
  String[] thicknesses = split(res[0], ",");
  
  for (int i=0; i<thicknesses.length; i++){
    avail_thickness.add(float(thicknesses[i])/1000000);
  }

  //imD1 = new Image(this, "/graphics/D1.png", "/graphics/D1_window.gif", 500, height/4-25);
  //imD1M = new Image(this, "/graphics/D1M.png", "/graphics/D1M_anatomy.gif", 1100, height/4-25);
  //imD2 = new Image(this, "/graphics/D2.png", "/graphics/D2_map.gif", 500, 3*height/4-25);
  //imD2M = new Image(this, "/graphics/D2M.png", "/graphics/D2M_glasses2.gif", 1100, 3*height/4-25);
  
}

void draw() {
  background(255);
  
  if (doneInit==false){
    //imD1.init_display();
    //imD1M.init_display();
    //imD2.init_display();
    //imD2M.init_display();
  } else {
    draw_mainUI();
  }
}



void draw_mainUI(){
  //main UI background
  background(255);
  noStroke();
  fill(UIColor);
  rect(0,0,width,100);
  fill(255);
  rect(0,100,width,400);
  fill(0);
  rect(0,500,width,400);
  
  stroke(UIColor);
  switch(options){ // D1, D1M, D2, D2M
   case "D1M":
     line(800, 100, 800, 900);
     break;
   case "D2":
     line(800, 100, 800, 900);
     break;
   case "D2M":
     line(400,100,400,900);
     line(800,100,800,900);
     line(1200,100,1200,900);
     break;
  }

  //display imgs and masks
  for (int i=0; i < firstmainviews.size(); i++) {
    firstmainviews.get(i).display();
  }
  
  for (int i=0; i < secondmainviews.size(); i++) {
    secondmainviews.get(i).display();
  }

  for (int i=0; i < maskviews.size(); i++) {
    maskviews.get(i).display();
  }
  
  if (firstmainviews.size()>0){ //if 1 design is imported, view options to import 2nd design or a mask
    if (options=="D1M"){
      bimportM.setPosition(2*bgap+bw1, main_by);
      bimportM.show();
    }
    if (options=="D2"){
      bimportD2.show();
    }
    if (options=="D2M"){
      bimportD2.show();
      bimportM.show();  
    }
  }
  
  textAlign(CENTER);
  //display text based on what is imported
  if (first_design_file != null) {
    fill(0);
    text("Design 1, parallel polarizers", imgplace.get(0), 490);
    fill(255);
    text("Design 1, orthogonal polarizers", imgplace.get(0), 890);
  }
  if (second_design_file!= null) {
    fill(0);
    text("Design 2, parallel polarizers", imgplace.get(1), 490);
    fill(255);
    text("Design 2, orthogonal polarizers", imgplace.get(1), 890);
  }
  if (mask_file!= null) {
    if (first_loaded){
      fill(0);
      text("masked Design 1, parallel polarizers", imgplace.get(2), 490);
      fill(255);
      text("masked Design 1, orthogonal polarizers", imgplace.get(2), 890);
    }
    if (second_loaded){
      fill(0);
      text("masked Design 2, parallel polarizers", imgplace.get(3), 490);
      fill(255);
      text("masked Design 2, orthogonal polarizers", imgplace.get(3), 890);
    }
  }
  //}
}

void set_imgplace(){
  if (imgplace.size()==0){
    switch(options){ // D1, D1M, D2, D2M
     case "D1":
       println("D1 case");
       imgplace.add(800);
       imgplace.add(0);
       imgplace.add(0);
       imgplace.add(0);
       break;
     case "D1M":
       println("D1M case");
       stroke(UIColor);
       line(800, 100, 800, 900);
       imgplace.add(400);
       imgplace.add(0);
       imgplace.add(1200);
       imgplace.add(0);
       break;
     case "D2":
       println("D2 case");
       stroke(UIColor);
       line(800, 100, 800, 900);
       imgplace.add(400);
       imgplace.add(1200);
       imgplace.add(0);
       imgplace.add(0);
       break;
     case "D2M":
       println("D2M case");
       stroke(UIColor);
       line(400,100,400,900);
       line(800,100,800,900);
       line(1200,100,1200,900);
       imgplace.add(200);
       imgplace.add(600);
       imgplace.add(1000);
       imgplace.add(1400);
       break;
    }
  }
}
void load_mosaic1(){
  println("load mosaic1");
  println("filename: "+first_design_file+", editD1: "+editD1+", firstloaded: "+first_loaded);
  if (first_design_file!=null && !editD1 && !first_loaded){
    println("add first file");
    println("recoloredimg", recoloredimg.filename);
    firstmainviews.add(recoloredimg.copy_img(this, true, imgplace.get(0), 300, first_inverted, true));
    firstmainviews.add(recoloredimg.copy_img(this, true, imgplace.get(0), 700, !first_inverted, true));
    first_loaded = true;
    print("items in firstmainviews",firstmainviews.size());
    recoloredimg = null;
    
    if (maskset) {
      firstmainviews.add(firstmainviews.get(0).copy_img(this, true, imgplace.get(2), 300, false, true));
      firstmainviews.add(firstmainviews.get(1).copy_img(this, true, imgplace.get(2), 700, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(2), 300, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(2), 700, false, true));
    }
  }
}

void load_mosaic2(){
  if (second_design_file!=null && !editD2 && !second_loaded){
    secondmainviews.add(recoloredimg.copy_img(this, true, imgplace.get(1), 300, second_inverted, true));
    secondmainviews.add(recoloredimg.copy_img(this, true, imgplace.get(1), 700, !second_inverted, true));
    second_loaded = true;
    recoloredimg = null;
    
    if (maskset){
      secondmainviews.add(secondmainviews.get(0).copy_img(this, true, imgplace.get(3), 300, false, true));
      secondmainviews.add(secondmainviews.get(1).copy_img(this, true, imgplace.get(3), 700, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(3), 300, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(3), 700, false, true));
    } 
  }
}


void initialize(String filename, String mode){ //img type editD1 or editD2
  if (mode=="editD1"){
    origimg = new Image(this, filename, true, 200, 300, false, true);
    recoloredimg = new Image(this, filename, true, 600, 300, false, true);
    origpalette = new Palette(this, filename, 20, 550, 780, 100, false);
    secondpaly = origpalette.palettey + origpalette.sampsize + origpalette.gap;
    recoloredpalette = new Palette(this, filename, 20, secondpaly, 780, 100, true);
    mainpalette = new Palette(this, 800, 160, 775, 650);
    first_inverted = inverted;
    D1editsettings.savesettings(origimg, recoloredimg, origpalette, recoloredpalette, mainpalette, inverted, uniformT, selected);
  }
  if (mode=="editD2"){
    origimg = new Image(this, filename, true, 200, 300, false, true);
    recoloredimg = new Image(this, filename, true, 600, 300, false, true);
    origpalette = new Palette(this, filename, 20, 550, 780, 100, false);
    secondpaly = origpalette.palettey + origpalette.sampsize + origpalette.gap;
    recoloredpalette = new Palette(this, filename, 20, secondpaly, 780, 100, true);
    mainpalette = new Palette(this, 800, 160, 775, 650);
    second_inverted = inverted;
    D2editsettings.savesettings(origimg, recoloredimg, origpalette, recoloredpalette, mainpalette, inverted, uniformT, selected);
  }
  
}

void load_mask(){
  if (mask_file != null && !maskset){ //for the first time mask is set
    if (first_loaded) {
      firstmainviews.add(firstmainviews.get(0).copy_img(this, true, imgplace.get(2), 300, false, true));
      firstmainviews.add(firstmainviews.get(1).copy_img(this, true, imgplace.get(2), 700, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(2), 300, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(2), 700, false, true));
    }
    if (second_loaded){
      secondmainviews.add(secondmainviews.get(0).copy_img(this, true, imgplace.get(3), 300, false, true));
      secondmainviews.add(secondmainviews.get(1).copy_img(this, true, imgplace.get(3), 700, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(3), 300, false, true));
      maskviews.add(new Mask(this, mask_file, true, imgplace.get(3), 700, false, true));
    }
    maskset = true;
  }
}
