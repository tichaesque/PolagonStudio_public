import controlP5.*;
ControlP5 previewcontrols; // the UI elements associated with the animation preview
ControlP5 maincontrols; /// the UI elements associated with the main screen

Knob ktheta;
Knob kphi;
Knob kdelta; // controls theta and phi in tandem
Knob maskdelta;

int bw1 = 200;  //width of larger buttons 
int bw2 = 110;  //width of smaller buttons
int bh = 50;   //height of buttons
int bgap = 20;  //gap between buttons
int main_by = 25; //y pos of buttons in main window


void load_main_controls() {
  maincontrols = new ControlP5(this);
  PFont font = createFont("fakereceipt.ttf", 16);
  ControlFont cfont = new ControlFont(font);
  
  maincontrols.addButton("importD1")
    .setLabel("Import Design 1")
    .setPosition(bgap, main_by)
    .setSize(bw1, bh)
    ;
    
  maincontrols.addButton("preview")
    .setLabel("Preview")
    .setPosition(width-2*bgap-2*bw2, main_by)
    .setSize(bw2, bh)
    ;

  maincontrols.setFont(cfont);

} 


void load_preview_controls(){
  PFont font = createFont("fakereceipt.ttf", 14);
  ControlFont cfont = new ControlFont(font);
  
  ktheta = previewcontrols.addKnob("thetaval")
    .setRange(0, 90)
    .setLabel("Polarizer rotation")
    .setPosition(100, 25)
    .setRadius(40)
    .setNumberOfTickMarks(90)
    //.setTickMarkLength(4)
    //.setTickMarkWeight(2)
    .snapToTickMarks(true)
    .setDragDirection(Knob.HORIZONTAL)
    .setColorLabel(255-int(bgcolor))
    .setVisible(true)
    .setResolution(500);
  ;

  kdelta = previewcontrols.addKnob("deltaval")
    .setRange(0, 360)
    .setLabel("Image rotation")
    .setPosition(325, 25)
    .setRadius(40)
    .setNumberOfTickMarks(360)
    //.setTickMarkLength(4)
    //.setTickMarkWeight(2)
    .snapToTickMarks(true)
    .setDragDirection(Knob.HORIZONTAL)
    .setColorLabel(255-int(bgcolor))
    .setVisible(true)
    .setResolution(500);
  ;

  maskdelta = previewcontrols.addKnob("maskdeltaval")
    .setRange(0, 90)
    .setLabel("Mask rotation")
    .setPosition(550, 25)
    .setRadius(40)
    .setNumberOfTickMarks(90)
    //.setTickMarkLength(4)
    //.setTickMarkWeight(2)
    .snapToTickMarks(true)
    .setDragDirection(Knob.HORIZONTAL)
    .setColorLabel(255-int(bgcolor))
    .setVisible(true)
    .setResolution(500);
  ;
  
  previewcontrols.setVisible(preview);
  previewcontrols.setFont(cfont);
}

public void importD1(int theValue){
  println(theValue);
  println("importing first design");
  selectInput("Select a file to import:", "D1Selected");
}

void D1Selected(File selection){
  
  first_design_file = selection.getName();
}

public void preview(int theValue){
  previewwindow = new PWindow();
  previewwindow.init();
}
