PWindow controlwindow; 

void settings() {
  size(1280, 720);
  pixelDensity(displayDensity());
}

void setup() {
  surface.setTitle("Polagon Studio");
  controlwindow = new PWindow(); 
  load_main_controls();
}

void draw(){
  background(200);
  
}
