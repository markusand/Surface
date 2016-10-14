public enum Visibility { SHOW, HIDE, TOGGLE }

public class Terrain {

    private final int HEADER_LINES = 6;
    
    private int width, height;
    private PVector origin;
    private PVector center;
    private int cols;
    private int rows;
    private float min = Float.NaN;
    private float max = Float.NaN;
    
    private float[][] buffer;
    private int resolution = 1;
    private PVector refCoords = new PVector();
    private PVector coords = new PVector();
    
    //private Window window;
    private PVector rotation = new PVector(PI / 4, 0, 0);
    private int sampling;
    private int maxSampling;
    
    private PImage texture;
    private boolean showTexture;
    
    
    final PVector ESTANYO = Projection.toUTM(42.609709, 1.578969, Projection.Datum.WGS84);
    final PVector PK_SORTENY = Projection.toUTM(42.626027, 1.551794, Projection.Datum.WGS84);
    
    
    Terrain(int width, int height, int cols, int rows) {
        this.width = width;
        this.height = height;
        this.origin = new PVector();
        this.cols = cols;
        this.rows = rows;
    }
  
    public float getMin() { return min; }
    public float getMax() { return max; }
    public int getResolution() { return resolution * sampling; }
    public float getRotation() { return degrees(rotation.z) % 360; }
    public int getZoom() { return maxSampling - sampling + 1; }
    public int getMaxZoom() { return maxSampling; }
    
    
    public void setTexture(Visibility v) {
        switch(v) {
            case SHOW:
                showTexture = true;
                break;
            case HIDE:
                showTexture = false;
                break;
            case TOGGLE:
                showTexture = !showTexture;
                break;
        }
    }
    
    
    public void load(String raster, String image) {
        // READ HEADER --->
        int bufferCols = 0;
        int bufferRows = 0;
        float noData = 0;
        
        print("Reading raster file... ");
        String[] lines = loadStrings(raster);
        for(int i = 0; i < HEADER_LINES; i++) {
            String[] headerLine = split(trim(lines[i].replaceAll("\\s{2,}", " ")), " ");
            if(headerLine[0].toUpperCase().equals("CELLSIZE")) resolution = int(headerLine[1]);
            else if (headerLine[0].toUpperCase().equals("NCOLS")) bufferCols = int(headerLine[1]);
            else if (headerLine[0].toUpperCase().equals("NROWS")) bufferRows = int(headerLine[1]);
            else if (headerLine[0].toUpperCase().equals("NODATA_VALUE")) noData = float(headerLine[1]);
            else if (headerLine[0].toUpperCase().equals("XLLCORNER")) refCoords.x = float(headerLine[1]);
            else if (headerLine[0].toUpperCase().equals("YLLCORNER")) refCoords.y = float(headerLine[1]);
        }
        
        // FILL BUFFER POINTS --->
        print("Reading points... ");
        buffer = new float[bufferCols][bufferRows];
        for(int y = 0; y < bufferRows; y++) {
            String[] line = split(lines[HEADER_LINES + y], " ");
            for(int x = 0; x < bufferCols; x++) {
                float point = float(line[x]);
                buffer[x][y] = point != noData ? point : Float.NaN;
            }
        }
        println("COMPLETED.");
        println("BUFFER. Size:" + bufferCols + "x" + bufferRows);
        
        // DEFINE SAMPLING (ZOOM) --->
        sampling = maxSampling = max(bufferCols / cols, bufferRows / rows) + 1; 
        
        // GENERATE  FIRST 
        print("Generating surface window... ");
        center = new PVector(bufferCols / 2, bufferRows / 2);
        update();
        println("COMPLETED");
        println("SURFACE: " + cols + "x" + rows + " min:" + min + " max:" + max);
        
        // SAVE TEXTURE --->
        texture = loadImage(image);
        texture.resize(bufferCols, bufferRows);
        
    }
    

    private void update() {   
        
        min = Float.NaN;
        max = Float.NaN;
        
        for(int y = 0; y < rows; y++) {
            int iY = (int) center.y + sampling * (-rows/2 + y);
            if(iY >= 0 && iY < buffer[0].length) {
                for(int x = 0; x < cols; x++) {
                    int iX = (int) center.x + sampling * (-cols/2 + x);
                    if(iX >= 0 && iX < buffer.length) {
                        float point = buffer[iX][iY];
                        if( !Float.isNaN(point) ) {
                            if( Float.isNaN(min) || point < min ) min = point;
                            if( Float.isNaN(max) || point > max ) max = point;
                        }
                    }
                }
            }
        }
        
        PVector centerCoords = PVector.add(refCoords, PVector.mult(center, resolution));
        coords = new PVector(centerCoords.x - resolution * sampling * cols / 2, centerCoords.y - resolution * sampling * rows / 2);
        //println(coords);
        //println((coords.x + cols * resolution * sampling) + "," + (coords.y + rows * resolution * sampling));
        
    }


    public void draw(int centerX, int centerY) {
        pushMatrix();
        
        lights();
        
        translate(centerX, centerY);
        rotateX(rotation.x); rotateY(rotation.y); rotateZ(rotation.z);
        
        rectMode(CENTER); noFill(); stroke(#FFFFFF, 100); strokeWeight(1); 
        rect(0, 0, width, height);
        
        translate(-width/2, -height/2, 0);
        
        float dX = (float) width / cols;
        float dY = (float) height / rows;
        float px4m = resolution * sampling / dX;
        
        noStroke(); fill(#FFFFFF);
        
        for(int y = 0; y < rows; y++) {
            int iY = (int) center.y + sampling * (-rows/2 + y);
            if(iY >= 0 && iY < buffer[0].length - sampling) {
                beginShape(TRIANGLE_STRIP);
                if(showTexture) texture(texture);
                for(int x = 0; x < cols; x++) {
                    int iX = (int) center.x + sampling * (-cols/2 + x);
                    if(iX >= 0 && iX < buffer.length) {
                        float p1 = buffer[iX][iY];
                        float p2 = buffer[iX][iY + sampling];
                        if( !Float.isNaN(p1) && !Float.isNaN(p2) ) {
                            vertex(x * dX, y * dY, (p1 - min) / px4m, iX, iY);
                            vertex(x * dX, (y + 1) * dY, (p2 - min) / px4m, iX, iY + sampling);
                        }
                    }
                }
                endShape();
            }
        }
        
        
        stroke(#FF0000); strokeWeight(2);
        PVector pos = toXY(ESTANYO);
        PVector pos2 = toXY(PK_SORTENY);
        line(pos.x, pos.y, 0, pos.x, pos.y, 1000);
        line(pos2.x, pos2.y, 0, pos2.x, pos2.y, 1000);
        
        
        popMatrix();
        
    }
    
    
    public void rotate(float x, float y, float z) {
        rotation.add(x, y, z);
    }
    
    
    public void move(int x, int y, int z) {
        PVector dir = new PVector(x, y, z);
        dir.rotate( -rotation.z ).mult( resolution * sampling );
        center.add(dir);
        update();
    }
    
    
    public void zoom(int i) {
        sampling = constrain(sampling - i, 1, maxSampling);
        update();
    }
    
    
    public PVector toXY(PVector point) {
        return new PVector(
            map(point.x, coords.x, coords.x + cols * resolution * sampling, 0, width),
            map(point.y, coords.y, coords.y + rows * resolution * sampling, height, 0)
        );
    }
    
  
}