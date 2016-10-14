Terrain terrain;

PVector mousePos;

final PVector ESTANYO = Projection.toUTM(42.609709, 1.578969, Projection.Datum.WGS84);
final PVector PK_SORTENY = Projection.toUTM(42.626027, 1.551794, Projection.Datum.WGS84);
final PVector ENGOLASTERS = new PVector(42.519762, 1.568418);
final PVector JUCLAR = new PVector(42.610509, 1.718317);
final PVector CALDEA = new PVector(42.511632, 1.537178);
final PVector PARC_CENTRAL = new PVector(42.506050, 1.525898);
final PVector CASA = new PVector(42.506513, 1.515993);

final PVector PISCINA = new PVector(42.644868, 1.257052);
final PVector AINETO = new PVector(42.638217, 1.249210);
final PVector CASETA = new PVector(42.645875, 1.260295);


void setup() {
    
    size(1000, 650, P3D);
    //fullScreen(P3D);
    //pixelDensity(2);
  
    println(ESTANYO);
  
    terrain = new Terrain(700, 700, 200, 200);
    terrain.load("capital_5x5.txt", "capital_5x5.jpg");
  
    //terrain.include( piscina );
    //terrain.include( aineto );
    //terrain.include( petitaCasa );
  
    //terrain.include( caldea );
    //terrain.include( parccentral );
    //terrain.include( calspares );
    
}

void draw() {
    
    background(0);
  
    terrain.draw(width/2, height/2);
  
    // Terrain info --->  
    fill(#FFFFFF);
    textAlign(LEFT,TOP); textSize(9);
    text("Min: " + terrain.getMin() + "m, Max: " + terrain.getMax() + "m", 10, 10);
    text("Resolution: " + terrain.getResolution() + "m", 10, 25);
    text("Rotation: " + terrain.getRotation(), 10, 40);
    text("Zoom: " + terrain.getZoom() + "/" + terrain.getMaxZoom(), 10, 55);
    text("FrameRate: " + round(frameRate) + "fps", 10, 70);
  
    //terrain.rotate(0, 0, 0.01 );
   
}



void mousePressed() {
    mousePos = new PVector(mouseX, mouseY);
}

void mouseDragged() {
    float dX = mousePos.x-mouseX;
    terrain.rotate(0, 0, map(dX, 0, width, 0, TWO_PI) );
    mousePos = new PVector(mouseX, mouseY);
}

void keyPressed() {
    
    switch(key) {
  
        case '-':
            terrain.zoom(-1);
            break;
          
        case '+':
            terrain.zoom(1);
            break;
          
        case ' ':
            terrain.setTexture(Visibility.TOGGLE);
            break;
      
        case CODED:
            switch(keyCode) {
                case LEFT:
                    terrain.move(1,0,0);
                    break;
                case RIGHT:
                    terrain.move(-1,0,0);
                    break;
                case UP:
                    terrain.move(0,1,0);
                    break;
                case DOWN:
                    terrain.move(0,-1,0);
                    break;
            }
            break;
      
    }  
  
}
  