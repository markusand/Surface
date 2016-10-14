public static class Projection {

    public enum Datum {
        WGS84(6378137, 298.257223563),
        NAD83(6378137, 298.257222101),
        GDA94(6378137, 298.257222101),
        PZ90(6378136, 298.257839803);
        
        public final float EQUATORIAL_RADIUS;    // in meters
        public final float POLAR_RADIUS;         // in meters
        public final float FLATTENING;
        public final float ECC;                  // First eccentricity
        
        private Datum(float equatorial_radius, float recip_flatt) {
            EQUATORIAL_RADIUS = equatorial_radius;
            FLATTENING = 1 / recip_flatt;
            POLAR_RADIUS = EQUATORIAL_RADIUS * (1 - FLATTENING);
            ECC = sqrt(1 - pow(POLAR_RADIUS, 2) / pow(EQUATORIAL_RADIUS, 2));
        }
        
        public String toString() { return "EQUATORIAL_RADIUS:" + EQUATORIAL_RADIUS + " POLAR_RADIUS:" + POLAR_RADIUS + " FLATTENING:" + FLATTENING + " ECCENTRICITY:" + ECC; }
    }
    
    
    
    public static PVector toUTM(PVector coords, Datum datum) {
        return toUTM(coords.x, coords.y, datum);
    }
    
    public static PVector toUTM(float lat, float lon, Datum datum) {
    
        if( Float.isNaN(lat) || lat > 90 || lat < -90 ) return null;
        if( Float.isNaN(lon) || lat > 180 || lat < -180 ) return null;
        
        // CONSTANTS --->
        final float K0 = 0.9996;    // Scale factor along central meridian (Browing series)
        
        float rLat = radians(lat);
        float zone = 1 + floor((lon + 180) / 6);    // UTM zone
        float m = 3 + 6 * (zone - 1) - 180;         // Central meridian of the zone
        float esq = (1 - pow(datum.POLAR_RADIUS, 2) / pow(datum.EQUATORIAL_RADIUS, 2));
        float e0sq = pow(datum.ECC, 2) / (1 - pow(datum.ECC, 2));
        
        float N = datum.EQUATORIAL_RADIUS / sqrt(1 - pow(datum.ECC * sin(rLat), 2));
        float T = pow(tan(rLat), 2);
        float C = e0sq * pow(cos(rLat), 2);
        float A = radians(lon - m) * cos(rLat);
        float A2 = pow(A, 2);
        
        // M calculation (USGS style) --->
        float M = rLat * (1 - esq * (0.25 + esq * (0.046875 + 5 * esq / 256)));
        M -= sin(2 * rLat) * (esq * (0.375 + esq * (0.09375 + 45 * esq / 1024)));
        M += sin(4 * rLat) * (pow(esq, 2) * (0.05859375 + esq * 45 / 1024));
        M -= sin(6 * rLat) * (pow(esq, 3) * 0.01139322917);
        M *= datum.EQUATORIAL_RADIUS;

        float easting = K0 * N * A * (1 + A2 * ((1 - T + C) / 6 + A2 * (5 - 18 * pow(T, 3) + 72 * C - 58 * e0sq) / 120)) + 500000;
        easting = round(10 * easting) / 10;
        
        float northing = K0 * (M + N * tan(rLat) * (A2 * (0.5 + A2 * ((5 - T + 9 * C + 4 * pow(C, 2)) / 24 + A2 * (61 - 58 * pow(T, 3) + 600 * C - 330 * e0sq) / 720))));
        if(northing < 0) northing += 10000000;
        northing = round(10 * northing) / 10;
        
        return new PVector(easting, northing, zone);
    }
     

}