import controlP5.*;
ControlP5 previewcontrols; // the UI elements associated with the animation preview
ControlP5 maincontrols; /// the UI elements associated with the main screen

Knob maskdelta;

void load_main_controls() {
  
  maincontrols = new ControlP5(this);

  maincontrols.addButton("exportdesign")
    .setLabel("export")
    .setPosition(width/2, height/2)
    .setSize(300, 60)
    ;
    
  
  //maincontrols.setVisible(true);
   
}

void load_preview_controls(){
  maskdelta = previewcontrols.addKnob("maskdeltaval")
    .setRange(0, 90)
    .setLabel("Mask rotation")
    .setPosition(500, 50)
    .setRadius(40)
    .setNumberOfTickMarks(90)
    //.setTickMarkLength(4)
    //.setTickMarkWeight(2)
    .snapToTickMarks(true)
    .setDragDirection(Knob.HORIZONTAL)
    .setColorLabel(255-50)
    .setVisible(true)
    .setResolution(500);
    ;
    
  previewcontrols.setVisible(true); 
}

public void exportdesign(int theValue) {
  println(theValue);
  println("exported design"); 
}
