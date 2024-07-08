import controlP5.*;
import java.util.Arrays;
ControlP5 previewcontrols; // the UI elements associated with the animation preview
ControlP5 maincontrols; /// the UI elements associated with the main screen
ControlP5 editcontrols;
ControlP5 exportcontrols;
ControlP5 birefcontrols;
ControlP5 fabsettingcontrols;
ControlP5 initcontrols;

//init controls
Button bD1M;
Button bD1;
Button bD2M;
Button bD2;

//main controls
Button bimportD1;
Button bimportD2;
Button bimportM;
Button bhome;
Button bpreview;
Button bbiref;
Button bexport;

//preview controls
PreviewKnob pk_polarizer;
PreviewKnob pk_analyzer;
PreviewKnob pk_design1;
PreviewKnob pk_design2;
PreviewKnob pk_mask;
Button updatepreview;

//edit controls
Accordion accordion;
Button accbutton;
CheckBox checkbox;
Toggle inverttoggle;
Toggle uniformtoggle;

//export controls
Button bmakeD1;
Button bmakeD2;
Button bmakeM;
Button bleft;
Button bright;
Button bfinish;
Button bmainexport;
Button bfabsettings;
Slider epsD1;
Slider epsD2;
RadioButton runits;
Button bcheck;

//custom slider to display more digits
CustomSlider birefslider;

int bw1 = 200;  //width of larger buttons
int bw2 = 110;  //width of smaller buttons
int bh = 50;   //height of buttons
int bgap = 20;  //gap between buttons
int main_by = 25; //y pos of buttons in main window
int adj = 100; //for init controls
boolean D1loaded = false;
boolean D2loaded = false;

void load_init_controls(){
  initcontrols = new ControlP5(this);
  //PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
  //ControlFont cfont = new ControlFont(font);

  bD1 = initcontrols.addButton("makeD1")
    .setLabel("Single Mosaic")
    .setPosition(500-bw1/2, height/4+adj)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
    
  bD1M = initcontrols.addButton("makeD1M")
    .setLabel("Single Mosaic + Mask")
    .setPosition(1100-bw1/2, height/4+adj)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
    
  bD2 = initcontrols.addButton("makeD2")
    .setLabel("Double Mosaic")
    .setPosition(500-bw1/2, 3*height/4+adj)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
    
  bD2M = initcontrols.addButton("makeD2M")
    .setLabel("Double Mosaic + Mask")
    .setPosition(1100-bw1/2, 3*height/4+adj)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;

}
  
void load_main_controls() {//for main UI window
  maincontrols = new ControlP5(this);
  PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
  ControlFont cfont = new ControlFont(font);

  bimportD1 = maincontrols.addButton("importD1")
    .setLabel("Edit Design 1")
    .setPosition(bgap, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;

  bimportD2 = maincontrols.addButton("importD2")
    .setLabel("Edit Design 2")
    .setPosition(2*bgap+bw1, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;

  bimportM = maincontrols.addButton("importM")
    .setLabel("Import Mask")
    .setPosition(3*bgap+2*bw1, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
    
  bhome = maincontrols.addButton("gohome")
    .setLabel("Home")
    .setPosition(width-4*bgap-3*bw2-bw1, main_by)
    .setSize(bw2, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
  
  bbiref = maincontrols.addButton("birefview")
    .setLabel("Calculate Biref")
    .setPosition(width-3*bgap-2*bw2-bw1, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
  
  bpreview = maincontrols.addButton("preview")
    .setLabel("Interact")
    .setPosition(width-2*bgap-2*bw2, main_by)
    .setSize(bw2, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;

  bexport = maincontrols.addButton("exportdesign")
    .setLabel("Export")
    .setPosition(width-bgap-bw2, main_by)
    .setSize(bw2, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;

  maincontrols.setFont(cfont);

}

void load_edit_controls(){
  PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
  ControlFont cfont = new ControlFont(font);
  
  editcontrols.addButton("changedesign")
    .setLabel("Change Design")
    .setPosition(bgap, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
  
  editcontrols.addButton("editdone")
    .setLabel("Done")
    .setPosition(width-bgap-bw2, height-3*main_by)
    .setSize(bw2, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
    
  Group g1= editcontrols.addGroup("filter cellophane")
                .setBackgroundColor(UIColor)
                ;
  
  checkbox = editcontrols.addCheckBox("checkBox")
                .setPosition(20, 30)
                .setSize(20, 20)
                .setItemsPerRow(1)
                .setSpacingColumn(30)
                .setSpacingRow(10)
                //.addItem("0.023 mm", 0.023)
                //.addItem("0.03 mm", 0.03)
                //.addItem("0.035 mm", 0.035)
                //.addItem("0.045 mm", 0.045)
                //.addItem("0.053 mm", 0.053)
                .moveTo(g1)
                .setColorBackground(buttonColor) 
                .setColorForeground(buttonHover)
                .setColorActive(buttonClick)
                //.activateAll()
                ;
                
                for (int i=0; i<avail_thickness.size();i++){
                  checkbox.addItem(str(avail_thickness.get(i))+" mm", avail_thickness.get(i));
                  checkbox.activate(i);
                }
                
  accbutton = editcontrols.addButton("acc_button")
                .setPosition(825,main_by)
                .setSize(225,25)
                .setLabel("")
                .setColorBackground(buttonColor) 
                .setColorForeground(buttonHover)
                .setColorActive(buttonClick)
                ;
  
  accordion = editcontrols.addAccordion("acc")
                 .setPosition(825,main_by)
                 .setWidth(225)
                 .setMinItemHeight(avail_thickness.size()*38)
                 .addItem(g1)
                 .setColorBackground(buttonColor) 
                 .setColorForeground(buttonHover)
                 .setColorActive(buttonClick)
                 .bringToFront()
                 ;    
  
  inverttoggle = editcontrols.addToggle("invert")
    .setPosition(1365, main_by)
    .setSize(50,20)
    .setState(false)
    .setValue(false)
    .setMode(ControlP5.SWITCH)
    .setLabel("")
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;  
    
  editcontrols.addLabel("inverton")
    .setPosition(1225, main_by)
    .setValue("use black BG")
    ;
    
  editcontrols.addLabel("invertoff")
    .setPosition(1435, main_by)
    .setValue("use white BG")
    ;

  editcontrols.setVisible(true);
  editcontrols.setFont(cfont);
}

void load_export_controls(){
  PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
  ControlFont cfont = new ControlFont(font);
  
  bmakeD1 = exportcontrols.addButton("makeD1")
    .setLabel("Make Design 1")
    .setPosition(bgap, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
  
  bmakeD2 = exportcontrols.addButton("makeD2")
    .setLabel("Make Design 2")
    .setPosition(bgap, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
  
  epsD1 = exportcontrols.addSlider("epsilon1")
    .setPosition(100, 305)
    .setWidth(bw1)
    .setHeight(20)
    .setRange(0.01, 0.1) // values can range from big to small as well
    .setValue(0.01)
    .setNumberOfTickMarks(10)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
  
  epsD2 = exportcontrols.addSlider("epsilon2")
    .setPosition(100, 305)
    .setWidth(bw1)
    .setHeight(20)
    .setRange(0.01, 0.1) // values can range from big to small as well
    .setValue(0.01)
    .setNumberOfTickMarks(10)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
    
  bmakeM = exportcontrols.addButton("makeM")
    .setLabel("Make Mask")
    .setPosition(bgap, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
 
  bleft = exportcontrols.addButton("back")
    .setLabel("")
    .setPosition(50, 400)
    .setImages(loadImage("/graphics/leftbutton_color.png"), loadImage("/graphics/leftbutton_hover.png"), loadImage("/graphics/leftbutton_click.png")) // button.setImages(defaultImage, rolloverImage, pressedImage);
    .updateSize()
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
    
  bright = exportcontrols.addButton("next")
    .setLabel("")
    .setPosition(1510, 400)
    .setImages(loadImage("/graphics/rightbutton_color.png"), loadImage("/graphics/rightbutton_hover.png"), loadImage("/graphics/rightbutton_click.png"))
    .updateSize()
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
    
  bfinish = exportcontrols.addButton("finish")
    .setLabel("Finish")
    .setPosition(1600-bw2-bgap, 900-bh-bgap)
    .setSize(bw2, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
  
  bmainexport = exportcontrols.addButton("mainexport")
    .setLabel("Export Home")
    .setPosition(bgap, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .hide()
    ;
    
  bfabsettings = exportcontrols.addButton("fabsettings")
    .setLabel("")
    .setPosition(1600-bgap-50, main_by)
    .setImages(loadImage("/graphics/setting_color.png"), loadImage("/graphics/setting_hover.png"), loadImage("/graphics/setting_click.png"))
    .updateSize()
    .show()
    ;
    
  bcheck = exportcontrols.addButton("checkcellophane")
    .setLabel("Check Cellophane")
    .setPosition(width-2*bgap-50-bw1, main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .show()
    ;
    
  exportcontrols.setFont(cfont);
}

public void load_biref_controls(){
  PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
  ControlFont cfont = new ControlFont(font);
  
  birefslider = new CustomSlider(birefcontrols, "birefslider");
  
  birefslider.setPosition(200, 100)
    .setSize(200, 20)
    .setRange(0, 0.02)
    .setNumberOfTickMarks(200)
    .setValue(0.005)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .setLabel("");
    ;

  birefcontrols.addTextfield("thickness")
     .setPosition(200,20)
     .setSize(80,30)
     .setAutoClear(false)
     .setColorBackground(buttonColor) 
     .setColorForeground(buttonHover)
     .setColorActive(buttonClick)
     .setLabel("")
     ;
  
  birefcontrols.addTextfield("numlayers")
     .setPosition(200,60)
     .setSize(80,30)
     .setAutoClear(false)
     .setColorBackground(buttonColor) 
     .setColorForeground(buttonHover)
     .setColorActive(buttonClick)
     .setLabel("")
     ;
     
  birefcontrols.addButton("birefdone")
    .setLabel("Done")
    .setPosition(750-bgap-bw2, 300-3*main_by)
    .setSize(bw2, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
    
  birefcontrols.addButton("updatedict")
    .setLabel("Update Biref")
    .setPosition(750-2*bgap-bw2-bw1, 300-3*main_by)
    .setSize(bw1, bh)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    ;
     
  birefcontrols.setFont(cfont);
  birefcontrols.setVisible(true);
}

public void load_fabsetting_controls(){
  PFont font = createFont("fakereceipt.ttf", 14/displayDensity());
  ControlFont cfont = new ControlFont(font);
  
  fabsettingcontrols.addTextfield("laserw")
     .setPosition(300,60)
     .setSize(80,30)
     .setAutoClear(false)
     .setColorBackground(buttonColor) 
     .setColorForeground(buttonHover)
     .setColorActive(buttonClick)
     .setLabel("")
     .setValue("32")
     ;
  
  fabsettingcontrols.addTextfield("laserh")
     .setPosition(300,100)
     .setSize(80,30)
     .setAutoClear(false)
     .setColorBackground(buttonColor) 
     .setColorForeground(buttonHover)
     .setColorActive(buttonClick)
     .setLabel("")
     .setValue("18")
     ;
  
  fabsettingcontrols.addTextfield("material_t")
     .setPosition(300,140)
     .setSize(80,30)
     .setAutoClear(false)
     .setColorBackground(buttonColor) 
     .setColorForeground(buttonHover)
     .setColorActive(buttonClick)
     .setLabel("")
     ;
  
  runits = fabsettingcontrols.addRadioButton("units")
    .setPosition(100,20)
    .setSize(40,25)
    .setItemsPerRow(2)
    .setSpacingRow(20)
    .addItem("in", 1)
    .addItem("cm", 2)
    .setColorBackground(buttonColor) 
    .setColorForeground(buttonHover)
    .setColorActive(buttonClick)
    .activate(0)
    ;
    
    for(Toggle t:runits.getItems()) {
       t.getCaptionLabel().getStyle().moveMargin(-5,0,0,-41);
       t.getCaptionLabel().getStyle().movePadding(5,5,5,5);
     }
    
    
  fabsettingcontrols.setFont(cfont);
  fabsettingcontrols.setVisible(true);
}

public void makeD1(int theValue){
  doneInit = true;
  bD1.hide();
  bD1M.hide();
  bD2.hide();
  bD2M.hide();
  options = "D1";
  first_design_file = "mosaic1.svg";
  
  println("initialize");
  set_imgplace();
  initialize(first_design_file,"editD1");
  load_mosaic1();
  load_main_controls();
  
}

public void makeD1M(int theValue){
  doneInit = true;
  bD1.hide();
  bD1M.hide();
  bD2.hide();
  bD2M.hide();
  options = "D1M";
  first_design_file = "mosaic1.svg";
  mask_file = "mask.svg";
  
  set_imgplace();
  initialize(first_design_file,"editD1");
  load_mosaic1();
  load_mask();
  load_main_controls();
  
}

public void makeD2(int theValue){
  doneInit = true;
  bD1.hide();
  bD1M.hide();
  bD2.hide();
  bD2M.hide();
  options = "D2";
  first_design_file = "mosaic1.svg";
  second_design_file = "mosaic2.svg";
  
  set_imgplace();
  initialize(first_design_file,"editD1");
  load_mosaic1();
  initialize(second_design_file,"editD2");
  load_mosaic2();
  load_main_controls();
}

public void makeD2M(int theValue){
  doneInit = true;
  bD1.hide();
  bD1M.hide();
  bD2.hide();
  bD2M.hide();
  options = "D2M";
  first_design_file = "mosaic1.svg";
  second_design_file = "mosaic2.svg";
  mask_file = "mask.svg";
  
  set_imgplace();
  initialize(first_design_file,"editD1");
  load_mosaic1();
  initialize(second_design_file,"editD2");
  load_mosaic2();
  load_mask();
  load_main_controls();
}

public void birefview(int theValue){
  println("biref window");
  birefwindow = new PWindow(4);
  birefwindow.init();
  doneInit = true;
}

public void gohome(){
  doneInit=false;
  options="";
  bhome.hide();
  bpreview.hide();
  bbiref.hide();
  bexport.hide();
  load_init_controls();
  
  // reset everything
  imgplace.clear();
  first_design_file = null;
  second_design_file = null;
  mask_file = null;
  firstmainviews.clear();
  secondmainviews.clear();
  maskviews.clear();
  first_loaded=false;
  second_loaded=false;
  maskset=false;
  mainpalette=null;
  origpalette=null;
  recoloredpalette=null;
  origimg=null; // displayed in edit window
  recoloredimg=null;
  D1editsettings = new EditSettings();
  D2editsettings = new EditSettings();
}

public void importD1(int theValue){
  println("edit design 1");
  if (first_design_file == null){
    println("importing first design");
    selectInput("Select a file to import:", "D1Selected");
    selected = "1,1,1,1,1";
  } else {
    editwindow = new PWindow(3);
    editwindow.init();
    editD1 = true;
    D1loaded = false;
  }
}

public void importD2(int theValue){
  println("edit design 2");
  if (second_design_file == null){
    println("importing second design");
    selectInput("Select a file to import:", "D2Selected");
    selected = "1,1,1,1,1";
  } else {
    editwindow = new PWindow(3);
    editwindow.init();
    editD2 = true;
    D2loaded = false;
  }
}

public void importM(int theValue){
  println("importing mask");
  selectInput("Select a file to import:", "MaskSelected");
}


void D1Selected(File selection){
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    first_design_file = null;
  } else {
    editD1 = true;
    D1loaded = false;
    first_design_file = selection.getName();
    selected="1,1,1,1,1";
    editwindow = new PWindow(3);
    editwindow.init();
    println("filename set");
    println(first_design_file);
  }
}

void D2Selected(File selection){
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    second_design_file = null;
  } else {
    editD2 = true;
    D2loaded = false;
    second_design_file = selection.getName();
    selected="1,1,1,1,1";
    editwindow = new PWindow(3);
    editwindow.init();
  }
}

void MaskSelected(File selection){
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    if (maskset){
      maskviews.clear(); // remove all mask instances in maskviews
      mask_file = selection.getName();
      if (first_loaded){
        maskviews.add(new Mask(this, mask_file, true, 1000, 300, false, true));
        maskviews.add(new Mask(this, mask_file, true, 1000, 700, true, true));
      }
      if (second_loaded){
        maskviews.add(new Mask(this, mask_file, true, 1400, 300, false, true));
        maskviews.add(new Mask(this, mask_file, true, 1400, 700, true, true));
      }
    } else {
      mask_file = selection.getName();
    }
  }
}

public void preview(int theValue){
  previewwindow = new PWindow(2);
  previewwindow.init();
  
  //secondpreview = new PWindow(7);
  //secondpreview.init();
}

public void exportdesign(int theValue) {
  println("exported design");
  exportwindow = new PWindow(1);
  exportwindow.init();
}


//subclass slider
public class CustomSlider extends Slider{

  //decimal format reference
  DecimalFormat df;

  //constructor
  public CustomSlider( ControlP5 cp5 , String name ) {
    super(cp5,name);
    df = new DecimalFormat();
    df.setMaximumFractionDigits(5);
  }

  @Override public Slider setValue( float theValue ) {
    super.setValue(theValue);
    if(df != null){
      _myValueLabel.set( df.format(getValue( )));
    }else{
      _myValueLabel.set( getValue( ) +"" );
    }
    return this;
  }

} 
