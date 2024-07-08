import java.util.Map;

class CellophaneCheck{
  PApplet parent;
  int squarew = 40; 
  int numcellophane; 
  int rectw = 8; 
  int recth = 6;
  int recttotalw = rectw*squarew; 
  int recttotalh = recth*squarew; 
  
  ArrayList<Float> cellophanethicknesses; 
  // coordinates of upper left corners of all rectangles
  ArrayList<int[]> upperleft = new ArrayList<int[]>(); 
  
  int offsetx = 0;
  int offsety = 0; 
  
  public CellophaneCheck(PApplet parent_, ArrayList<Float> cellothick_){
    parent = parent_;  
    cellophanethicknesses = cellothick_;
    createRect();
  }
  
  void createRect(){
    initRectangles();
  
    parent.translate(100,50); 
  
    for (int i = 0; i < numcellophane; i++) {
      for (int row = 0; row < recth; row++) {
        for (int col = 0; col < rectw; col++) {
          int squarex = (col+offsetx)*squarew;
          int squarey = (row+offsety)*squarew;
  
          String coeff = "";
          for (int idx = 0; idx < upperleft.size(); idx++) { 
            int[] coord = upperleft.get(idx); 
            if (contains(coord, squarex, squarey)) {
              coeff += "1";
            } else {
              coeff += "0";
            }
  
            if (idx < upperleft.size() -1) coeff += "~";
          }
  
          String input = "theta="+PI/4+"&phi="+PI/4+"&coeffs="+coeff;
          String[] res = loadStrings("http://127.0.0.1:3000/getcolortest?"+input);
          String result = res[0].substring(1, res[0].length()-1).trim();
          String[] newc = result.split("\\s+"); 
          color newfill = color(float(newc[0]), float(newc[1]), float(newc[2]));
  
          parent.fill(newfill); 
          parent.rect(squarex, squarey, squarew, squarew);
        }
      }
  
      offsetx++; 
      offsety++;
    }
  
    for (int i = 0; i < numcellophane; i++) {
      parent.strokeWeight(1);
      parent.stroke(255); 
      parent.noFill(); 
      parent.rect(upperleft.get(i)[0], upperleft.get(i)[1], recttotalw, recttotalh); 
      
      parent.fill(0); 
      parent.text(cellophanethicknesses.get(i) + "mm", 5+upperleft.get(i)[0] + recttotalw, upperleft.get(i)[1]); 
    }
  }
  
  boolean contains(int[] ul, int squarex, int squarey) {
    return ul[0] <= squarex && squarex + squarew <= ul[0] + recttotalw &&
      ul[1] <= squarey && squarey + squarew <= ul[1] + recttotalh;
  }
  
  void initRectangles() {
  
    int upperleftx = 0;
    int upperlefty = 0; 
    for (float thickness : cellophanethicknesses) {
      int[] coord = {upperleftx, upperlefty};
      upperleft.add(coord); 
  
      upperleftx += squarew;
      upperlefty += squarew;
    }
  
    numcellophane = cellophanethicknesses.size();
    println("num cellophane: " + str(numcellophane));
  }
  
}
