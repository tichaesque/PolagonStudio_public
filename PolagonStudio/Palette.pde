int selectedpolagecolor = -1; //to find corresponding polage color in main palette
int selectedimgidx = -1; //index of chosen color in original palette
int selectedpolageidx = -1; //index of chosen color in polage palette
int polageidx2change = -1;

class Palette {

  ArrayList<Integer> colorpalette; //arraylist of only colors for easy checking
  ArrayList<String> colorcomps; 
  PApplet parent;
  int palettex = 0;
  int palettey = 0; 
  int palettewidth; // number of palette squares per row
  int displayw; //width of entire palette display
  int displayh; //height of entire palette display
  int sampsize;
  int gap = 5;
  boolean polage;
  boolean mainpalette;
  String filename;

  int selectedcolor = -1; 
  
  public Palette(){}

  public Palette(PApplet parent, int palettex_, int palettey_, int displayw_, int displayh_) {// for main palette
    this.parent = parent;
    mainpalette = true;
    
    JSONObject palette = loadJSONObject("http://127.0.0.1:3000/getpalette?inverted="+str(int(inverted))+"&uniform="+str(int(uniformT))+"&selected="+selected);
    JSONArray colors = palette.getJSONArray("colorstring");
    JSONArray comps = palette.getJSONArray("composition");

    colorpalette = new ArrayList<Integer>();
    colorcomps = new ArrayList<String>(); 
    
    for (int k = 0; k < colors.size(); k++) {
      String col = colors.getString(k); 
      color newfill = color(unhex("FF"+col.substring(1,col.length())));

      colorpalette.add(newfill); 
      colorcomps.add(comps.getString(k));
    }

    palettex = palettex_;
    palettey = palettey_;
    displayw = displayw_;
    displayh = displayh_;
    
    autoResizePalette(); //fit palette within given space
     
  }

  public Palette(PApplet parent, String filename, int palettex_, int palettey_, int displayw_, int displayh_, boolean polage_) { // for image palette
    this.parent = parent;
    this.polage = polage_;
    this.filename = filename;
    mainpalette = false; //img palette
    
    JSONObject palette;
    
    if (polage){
      palette = loadJSONObject("http://127.0.0.1:3000/getpolagecolors?filename="+filename);
    } else {
      palette = loadJSONObject("http://127.0.0.1:3000/getorigcolors?filename="+filename);
    }
    
    JSONArray colors = palette.getJSONArray("colorstring");

    colorpalette = new ArrayList<Integer>();
    
    for (int k = 0; k < colors.size(); k++) {
      String col = colors.getString(k); 
      color newfill = color(unhex("FF"+col.substring(1,col.length())));

      colorpalette.add(newfill); 
    }

    palettex = palettex_;
    palettey = palettey_;
    displayw = displayw_;
    displayh = displayh_;
    
    autoResizePalette();
  }
  
  public Palette copy_palette(PApplet parent, boolean mainpalette){
    Palette newpalette = new Palette();
    newpalette.parent = parent;
    newpalette.polage = polage;
    
    newpalette.colorpalette = colorpalette;
    
    if (mainpalette){
      newpalette.colorcomps = colorcomps;
      newpalette.mainpalette = true;
    } else {
      newpalette.mainpalette = false;
      newpalette.filename = filename;
    }
    
    newpalette.palettex = palettex;
    newpalette.palettey = palettey;
    newpalette.displayw = displayw;
    newpalette.displayh = displayh;
    newpalette.autoResizePalette();
    
    return newpalette;
  }
  
  public void autoResizePalette(){ // auto-rescaling of the palette based on how many colors exist
  
    if (!mainpalette){
      palettewidth = colorpalette.size();
      sampsize = (int) displayw/palettewidth-gap;
      if (sampsize > 75) sampsize = 75;
    }
    
    else{
      sampsize = (int) sqrt(displayw*displayh/colorpalette.size()) - gap;
      palettewidth = (int) displayw/(sampsize+gap);
      
      int counter = 1;
      while ((sampsize+gap)*((int)colorpalette.size()/palettewidth + 1) > displayh){
        sampsize = (int) sqrt(displayw*(displayh-counter*50)/colorpalette.size()) - gap;
        palettewidth = (int) displayw/(sampsize+gap);
        counter ++;
      }
    }
    
  }
  
  public void reorderPalette(){
    JSONObject palette = loadJSONObject("http://127.0.0.1:3000/sortpalette?inverted="+str(int(inverted))+"&uniform="+str(int(uniformT))+"&selected="+selected+"&polagecolor="+hex(selectedpolagecolor, 6));
    JSONArray colors = palette.getJSONArray("colorstring");
    JSONArray comps = palette.getJSONArray("composition");

    colorpalette = new ArrayList<Integer>();
    colorcomps = new ArrayList<String>(); 
    
    for (int k = 0; k < colors.size(); k++) {
      String col = colors.getString(k); 
      color newfill = color(unhex("FF"+col.substring(1,col.length())));

      colorpalette.add(newfill); 
      colorcomps.add(comps.getString(k));
    }
    
    autoResizePalette();
  }
  
  public void mouseOverPalette() {
    selectedcolor = -1; // for main palette highlight
    selectedpolagecolor = -1;
    if (!mainpalette) {
      if (polage){
        selectedpolageidx = -1; // index of chosen color in polage palette
      } else {
        selectedimgidx = -1; // index of chosen color in original palette
      }    
    }
    
    for (int i = 0; i < colorpalette.size(); i++) {
      int row = (int) i/palettewidth; 
      int col = i%palettewidth; 

      int xpos = palettex + col*(sampsize+gap);
      int ypos = palettey + row*(sampsize+gap);
      if (xpos < parent.mouseX && parent.mouseX < xpos+sampsize && 
          ypos < parent.mouseY && parent.mouseY <ypos+sampsize) {
            if (mainpalette) selectedcolor = i;
            if (!mainpalette) {
              if (polage){
                selectedpolageidx = i;
                selectedpolagecolor = colorpalette.get(i);
              } else {
                selectedimgidx = i;
              }    
            }
            break;
      }
    }   
    
  }
  
  public void display() {
    for (int i = 0; i < colorpalette.size(); i++) {
      int row = (int) i/palettewidth; 
      int col = i%palettewidth; 
      color c = colorpalette.get(i); 
      parent.fill(c);
      parent.noStroke();
      
      if(i==selectedcolor) {// highlight main palette if hovered over main palette
        parent.strokeWeight(10); 
        //parent.stroke(0,255,255); 
        parent.stroke(colorpalette.get(i));
      }

      if (!mainpalette && i==selectedpolageidx){// highlight orig palette if hovered over polage palette
        parent.strokeWeight(10);
        parent.stroke(colorpalette.get(i));
      }
      
      if (!mainpalette && i==selectedimgidx){// highlight polage palette if hovered over image palette
        parent.strokeWeight(10); 
        parent.stroke(colorpalette.get(i));
        selectedpolagecolor = colorpalette.get(i);
      }
 
      if (mainpalette && colorpalette.get(i)==selectedpolagecolor){// highlight main palette if hovered of orig/polage palette
        parent.strokeWeight(10);
        parent.stroke(colorpalette.get(i));
      }
      
      parent.rect(palettex + col*(sampsize+gap), palettey + row*(sampsize+gap), sampsize, sampsize);
      
    }
    
    if (selectedcolor > -1 && mainpalette) {
      int numlines = colorcomps.get(selectedcolor).split("\r\n|\r|\n").length;
      int txtboxh = (numlines+2)*30+10;
      if (parent.mouseX > 1200) {
        parent.fill(UIColor,200);
        parent.rect(parent.mouseX-420, parent.mouseY-35, 400, txtboxh);
        parent.fill(255); 
        parent.text(colorcomps.get(selectedcolor)+"\ncolor: "+hex(colorpalette.get(selectedcolor),6), parent.mouseX-410, parent.mouseY); 
      } else{
        parent.fill(UIColor,200);
        parent.rect(parent.mouseX+20, parent.mouseY-35, 400, txtboxh);
        parent.fill(255); 
        parent.text(colorcomps.get(selectedcolor)+"\ncolor: "+hex(colorpalette.get(selectedcolor),6), parent.mouseX+30, parent.mouseY); 
      }
    }
    
    if (800<parent.mouseX && parent.mouseX<width && 150<parent.mouseY && parent.mouseY<800) parent.cursor(HAND);
    else parent.cursor(ARROW);
  }
  
  public void update_img_palette(){
    print("update img palette -- recolored palette name: ");
    println(this.filename);
    JSONObject palette = loadJSONObject("http://127.0.0.1:3000/getpolagecolors?filename="+filename);
    JSONArray colors = palette.getJSONArray("colorstring");

    colorpalette = new ArrayList<Integer>();
    
    for (int k = 0; k < colors.size(); k++) {
      String col = colors.getString(k); 
      color newfill = color(unhex("FF"+col.substring(1,col.length())));
      colorpalette.add(newfill); 
    }

    autoResizePalette();
  }
  
  
  public void update_palette(){
    colorpalette.clear();
    colorcomps.clear();
    
    JSONObject palette = loadJSONObject("http://127.0.0.1:3000/getpalette?inverted="+str(int(inverted))+"&uniform="+str(int(uniformT))+"&selected="+selected);
    JSONArray colors = palette.getJSONArray("colorstring");
    JSONArray comps = palette.getJSONArray("composition");

    colorpalette = new ArrayList<Integer>();
    colorcomps = new ArrayList<String>(); 
    
    for (int k = 0; k < colors.size(); k++) {
      String col = colors.getString(k); 
      color newfill = color(unhex("FF"+col.substring(1,col.length())));

      colorpalette.add(newfill); 
      colorcomps.add(comps.getString(k));
    }
    
    autoResizePalette();
  }
  
  
}
