import processing.pdf.*;

class Exportfile {
  PApplet parent;
  String filename;
  ArrayList<PShape> laserfiles = new ArrayList<PShape>(); //list of all laser cut files
  ArrayList<String> laserfilenames = new ArrayList<String>();
  int currentidx = 0; //file that is red highlighted
  boolean design; //true = design file, false = mask
  Image img;
  Mask mask;
  float designscale;
  float epsilon = 0.01;
  String numfiles;
  int rotation; //first mosaic is rotated 45 deg, second mosaic is not rotated
  int exportwidth = 500;
  int exportheight = 500;

  public Exportfile(PApplet parent_, String filename_, Image img_, int rotation_) {
    parent = parent_;
    filename = filename_;
    img = img_;
    rotation = rotation_;
    design = true;

    float tmpw = img.orig.width;
    float tmph = img.orig.height;

    if (tmph > tmpw) this.designscale = exportheight/tmph;
    else this.designscale = exportwidth/tmpw;

    // generate laser files
    String input = "filename="+filename+"&epsilon="+nf(epsilon, 0, 2)+"&laserw="+laserw+"&laserh="+laserh+"&laserunit="+laserunit+"&rotation="+str(rotation);
    println("laser input: "+input);
    String res[] = loadStrings("http://127.0.0.1:3000/generate_laserfiles?"+input);
    numfiles = res[0];

    // load laserfiles
    load_laserfiles();

    create_pdf_files();
  }

  public Exportfile(PApplet parent_, String filename_, Mask mask_) {
    parent = parent_;
    filename = filename_;
    mask = mask_;
    design = false;

    float tmpw = mask.mask.width;
    float tmph = mask.mask.height;

    if (tmph > tmpw) this.designscale = exportheight/tmph;
    else this.designscale = exportwidth/tmpw;

    // generate laser files
    loadStrings("http://127.0.0.1:3000/generate_mask_laserfiles?filename="+filename);

    PShape masklaserfile = loadShape("cut/" + filename);
    laserfiles.add(masklaserfile);
    laserfilenames.add(filename);

    create_pdf_files();
  }

  public void update_epsilon(float epsilon_val) {
    epsilon = epsilon_val;

    // generate laser files
    String input = "filename="+filename+"&epsilon="+nf(epsilon, 0, 2)+"&laserw="+laserw+"&laserh="+laserh+"&laserunit="+laserunit+"&rotation="+str(rotation);
    String res[] = loadStrings("http://127.0.0.1:3000/generate_laserfiles?"+input);

    numfiles = res[0];

    laserfiles.clear();
    laserfilenames.clear();
    currentidx=0;

    // load laserfiles
    load_laserfiles();
  }
  
  public void update_lasersettings() {

    // generate laser files
    String input = "filename="+filename+"&epsilon="+nf(epsilon, 0, 2)+"&laserw="+laserw+"&laserh="+laserh+"&laserunit="+laserunit+"&rotation="+str(rotation);
    String res[] = loadStrings("http://127.0.0.1:3000/generate_laserfiles?"+input);

    numfiles = res[0];
    laserfiles.clear();
    laserfilenames.clear();
    currentidx=0;

    // load laserfiles
    load_laserfiles();
  }

  public void main_display() {
    if (design) img.display();
    else mask.display();
  }

  public void make_display() {
    int displayy = 450;

    //for (int i=0; i<currentidx; i++) {//all previous files have gray stroke
    //  PShape currentshape = laserfiles.get(i);
    //  currentshape.disableStyle();
    //  parent.pushMatrix();
    //  parent.translate(800, displayy);
    //  if (filename==first_design_file) parent.rotate(-PI/4);
    //  parent.scale(designscale);
    //  parent.fill(0, 0);
    //  parent.stroke(150);
    //  parent.shape(currentshape);
    //  parent.popMatrix();
    //}

    //curent file has red stroke
    PShape currentshape = laserfiles.get(currentidx);
    currentshape.disableStyle();
    parent.pushMatrix();
    if (design) {
      parent.translate(800, displayy);
    } else {
      parent.translate(800, displayy);
    }
    if (filename==first_design_file) parent.rotate(-PI/4);
    parent.scale(designscale);
    parent.fill(0, 0);
    parent.stroke(color(255, 0, 0));
    parent.shape(currentshape);
    parent.popMatrix();

    if (design) {
      String name = laserfilenames.get(currentidx);
      String splitheight[] = split(name, "height");
      String splitmm[] = split(splitheight[1], "mm");
      String laserz = splitmm[0];
      if (material_t!="") laserz = str(float(material_t)+float(laserz));
      String newname = splitheight[0] + "height" + laserz + "mm";
      
      String cellophane[] = split(name, "-");
      String cellophane_t = cellophane[1];

      parent.fill(0);
      parent.text("Cutting pass # " + str(currentidx+1), 800, 50);
      parent.text(newname, 800, 80);
      parent.fill(255,0,0);
      if (currentidx == 0) {
        parent.text("Place base acrylic sheet in the laser cutter", 800, 110); 
        parent.text("Place a sheet of " + cellophane_t + " cellophane in the laser cutter", 800, 140);
      } else {parent.text("Place a sheet of " + cellophane_t + " cellophane in the laser cutter", 800, 110);}
      parent.fill(0);
      parent.text("Power: 12.5% \nSpeed: 35% \nLaser z: "+laserz+ " mm", 800, 800); 

    } else {
      parent.fill(0);
      parent.text(filename.substring(0,filename.length()-4), 800, 100);
      parent.text("Power: 20% \nSpeed: 20% \nLaser z: 0.1 mm", 800, 800);
    }
  }

  void load_laserfiles() {
    String[] res = loadStrings("http://127.0.0.1:3000/getlaserfiles?filename="+filename);
    String[] filenames = split(res[0], ", ");
    String directory = "cut/"+filename+"/UI/";

    for (int i=0; i<filenames.length; i++) {
      
      String[] subpaths = split(filenames[i].substring(1, filenames[i].length()-1), "/");
      String lastitem = subpaths[subpaths.length-1];
      String name = lastitem.substring(0, lastitem.length()-4);
      laserfilenames.add(name);
      String tmp = "filename: "+filenames[i]+"; name: "+name;
      println(tmp);
      
      PShape f = loadShape(directory+name+"-UI.svg");
      laserfiles.add(f);

    }
  }

  void create_pdf_files() {
    String pdfname = filename.substring(0, filename.length()-4);
    PGraphicsPDF pdf = (PGraphicsPDF) createGraphics(1600*displayDensity(), 900*displayDensity(), PDF, "output/"+pdfname+"_output.pdf");
    pdf.beginDraw();
    pdf.background(255);

    pdf.textFont(font);
    pdf.textSize(20);
    pdf.textAlign(CENTER);
    pdf.shapeMode(CENTER);
    pdf.noStroke();

    for (int i=0; i<laserfiles.size(); i++) {
      int displayy = 450;

      for (int j=0; j<i; j++) {//all previous files have gray stroke
        PShape currentshape = laserfiles.get(j);
        currentshape.disableStyle();
        pdf.pushMatrix();
        pdf.translate(800, displayy);
        if (filename==first_design_file) pdf.rotate(-PI/4);
        pdf.scale(designscale);
        pdf.fill(0, 0);
        pdf.stroke(150);
        pdf.shape(currentshape);
        pdf.popMatrix();
      }

      //curent file has red stroke
      PShape currentshape = laserfiles.get(i);
      currentshape.disableStyle();
      pdf.pushMatrix();
      if (design) {
        pdf.translate(800, displayy);
      } else {
        pdf.translate(800, displayy);
      }
      if (filename==first_design_file) pdf.rotate(-PI/4);
      pdf.scale(designscale);
      pdf.fill(0, 0);
      pdf.stroke(color(255, 0, 0));
      pdf.shape(currentshape);
      pdf.popMatrix();

      if (design) {
        String name = laserfilenames.get(i);
        String splitheight[] = split(name, "height");
        String splitmm[] = split(splitheight[1], "mm");
        String laserz = splitmm[0];
        if (material_t!="") laserz = str(float(material_t)+float(laserz));
        String newname = splitheight[0] + "height" + laserz + "mm";
      
        String cellophane[] = split(name, "-");
        String cellophane_t = cellophane[1];


        pdf.fill(0);
        pdf.text("Cutting pass # " + str(i+1), 800, 75);
        pdf.text(newname, 800, 105);
        pdf.fill(255,0,0);
        if (currentidx == 0) {
          pdf.text("Place base acrylic sheet in the laser cutter", 800, 110); 
          pdf.text("Place a sheet of " + cellophane_t + " cellophane in the laser cutter", 800, 140);
        } else {pdf.text("Place a sheet of " + cellophane_t + " cellophane in the laser cutter", 800, 110);}
        pdf.fill(0);
        pdf.text("Power: 12.5% \nSpeed: 3% \nLaser z: "+laserz+ " mm", 800, 800);
      } else {
        pdf.fill(0);
        pdf.text(filename.substring(0,filename.length()-4), 800, 100);
        pdf.text("Power: 20% \nSpeed: 20% \nLaser z: 0.1 mm", 800, 800);
      }
      pdf.nextPage();
    }

    pdf.dispose();
    pdf.endDraw();

  }

}
