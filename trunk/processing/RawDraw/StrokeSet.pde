/**
 * Class for organizing and drawing a set of strokes
 */

import org.json.*;


class StrokeSet {

  // Number of possible trails
  int maxObjects = 100;

  // Number of points for stroke
  int maxStrokes = 1000;

  int numObjects;
  int mode;
  int[] numStrokes = new int[maxObjects];
  int[] startStroke = new int[maxObjects];
  PVector[][]strokeXYZ = new PVector[maxObjects][maxStrokes];
  color[]objectHues = new color[maxObjects];
  HashMap objectLookup;


  StrokeSet() {
    objectLookup = new HashMap();
    objectLookup.put("MB_Blue",130);
    objectLookup.put("MB_Red",0);
    objectLookup.put("MB_Green",80);
  }


  void draw() {

    strokeWeight(5);
    int hue;
    for (int j = 0; j < numObjects; j++) {

      if (mode == 0) {
        beginShape(POINTS);
        hue = (j*10) % 255;
      } 
      else {
        beginShape();
        hue = objectHues[j];
      }

      PVector[] s = strokeXYZ[j];

      for (int i = 0; i < numStrokes[j]; i++) {
        int alpha = (int)(255 * (float)i / (float)numStrokes[j]);
        int ii = (i + startStroke[j]) % maxStrokes;
        stroke(hue,255,255,alpha);
        vertex(s[ii].x,s[ii].y,s[ii].z);
      }

      endShape();
    }
  }

  void setObjectHue(String objectName, int objectNumber) {
    
     Object objectHue = objectLookup.get(objectName);
     int theHue = 200; // Default
     if (objectHue != null) {
       theHue = ((Number)objectHue).intValue();
     }
     
      objectHues[objectNumber] = theHue;
    
  }


  void addStrokesFromJSON(String message) {

    //UDP can produce some weird data. Make sure it looks like JSON
    if (message == "") return;
    if (! message.substring(0,1).equals("{")) {
      return;
    }

    try {
      JSONObject vp = new JSONObject(message); 
      int newMode = vp.getInt("mode");
      if (mode != newMode) {
        mode = newMode;
        clearStrokes();
      }
      JSONArray objs = vp.getJSONArray("objs");
      addLoopingStrokes(objs);
    }

    catch (JSONException e) { 
      println (e.toString()); 
      println( "Original Message: \""+message);
    }
  }


  // This function is a bit ugly. Strokes are kept in simple arrays
  // and when maxStrokes has been reached, they are written to the beginning
  // of the array. The startStroke array keeps track of where each stroke
  // starts so they can been drawn in that order.
  void addLoopingStrokes(JSONArray objs) {
    try {
      for (int i=0; i<objs.length(); i++) {
        if (i >= maxObjects) return;

        JSONArray xyz;

        // The two modes are handled here. In mode 1 (Raw) the xyz object
        // must be retrieved by extracting the t field. In mode 0 (Object)
        // this data is stored directly in the objs array.
        if (mode == 1) {
          JSONObject single = objs.getJSONObject(i);
          xyz = single.getJSONArray("t");
          String objName = single.getString("name");
          Boolean oc = single.getBoolean("oc");
          if (oc) continue;
          setObjectHue(objName, i);
        } 
        else {
          xyz = objs.getJSONArray(i);
        }

        float xx = (float)xyz.getDouble(0);
        float yy = (float)xyz.getDouble(1);
        float zz = (float)xyz.getDouble(2);

        if (zz < 0) continue;

        int newPosition = numStrokes[i];
        if (numStrokes[i] >= maxStrokes) {
          newPosition = startStroke[i];
          startStroke[i] = startStroke[i] + 1;
          if (startStroke[i] >= maxStrokes) startStroke[i] = 0;
        } 
        else {
          numStrokes[i]++;
        }

        strokeXYZ[i][newPosition] = new PVector(xx, yy, zz);
        numObjects = max(numObjects,i+1);
      }
    }  
    catch (JSONException e) { 
      println (e.toString());
    }
  }


  // This is a simpler version that loops around to start back at
  // the beginning of each stroke array but doesn't care about getting
  // the starting position correct. There may be flickering artifacts.
  void addSimpleStrokes(JSONArray objs) {

    try {
      for (int i=0; i<objs.length(); i++) {
        if (i >= maxObjects) return;
        int newPosition = numStrokes[i];

        if (numStrokes[i] >= maxStrokes) {
          newPosition = 0;
        } 
        else {
          numStrokes[i]++;
        }

        JSONArray xyz = objs.getJSONArray(i);

        float xx = (float)xyz.getDouble(0);
        float yy = (float)xyz.getDouble(1);
        float zz = (float)xyz.getDouble(2);
        strokeXYZ[i][newPosition] = new PVector(xx, yy, zz);
        numObjects = i+1;
      }
    }
    catch (JSONException e) { 
      println (e.toString());
    }
  }


  void clearStrokes() {

    for (int i = 0; i < maxObjects; i++) {
      numStrokes[i] = 0;
      startStroke[i] = 0;
    }
    numObjects = 0;
  }
}

