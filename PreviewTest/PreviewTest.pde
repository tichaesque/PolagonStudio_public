// [!!] polagon_service must be running for this to work [!!] 

/*
 * How to export SVGs from Illustrator to Processing: 
 * "Save As...SVG" -> SVG 1.1 -> CSS properties: 'Style Attributes'
 */

import processing.svg.*;

// for main UI display
Image IMG1; 


float biref = 0.0055; // birefringence value; material-dependent
float E0 = 1; // radiance

// Control values that the user changes
float THETA = 0; // absolute angle of top polarizer
float PHI = 0;   // absolute angle of bottom polarizer
float DELTA = 0; // angle of design
float MASKDELTA = 0; // angle of mask (third polarizer)

float oldANGLE = 0; 

float IMGWIDTH = 600;
float MAINIMGWIDTH = 500;
ArrayList<Image> mainviews = new ArrayList<Image>();

float bgcolor = 255; 

boolean rotationChanged = false;
boolean mouseOverDesign = false;
boolean mouseOverMask = false;
boolean mouseOverPolarizer = false;
boolean hovering = false;
boolean preview = true; // interactive preview of the polagon 

float mouseXStart = 0; 
float mouseYStart = 0; 

// knobs for rotation
float designknobradius = 200; 
float maskknobradius = 300;
float polarizerknobradius = 400;

float radialsize = 0; 

float distfromcenter;

String first_design_file;
String second_design_file;
String mask_file;
boolean first_imported = false;
boolean imported = false; //two files imported
boolean maskset = false;

PWindow previewwindow;

void settings() {
  size(1600, 900);
  pixelDensity(displayDensity());
}

void setup() {
  shapeMode(CENTER);
  noStroke();
  surface.setTitle("Polagon Studio");
  PFont font = createFont("fakereceipt.ttf", 16);
  textFont(font);

  // sets up the various knobs and input boxes
  previewwindow = new PWindow();
  load_main_controls();
}

void draw() {

  //main UI background
  background(255);

  if (first_design_file != null && !first_imported){
    mainviews.add(new Image(this, first_design_file, true, 400, 500, false, true));
    //mainviews.add(new Image(first_design_file, true, 200, 700, true));
    first_imported = true;
  }

  for (int i=0; i < mainviews.size(); i++) {
    mainviews.get(i).display();
  }
  
}
