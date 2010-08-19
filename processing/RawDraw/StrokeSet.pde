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
  int[] numStrokes = new int[maxObjects];
  int[] startStroke = new int[maxObjects];
  PVector[][]strokeXYZ = new PVector[maxObjects][maxStrokes];


  void draw() {

    strokeWeight(5);

    for (int j = 0; j < numObjects; j++) {

      beginShape(POINTS);
      PVector[] s = strokeXYZ[j];

      for (int i = 0; i < numStrokes[j]; i++) {
        int alpha = (int)(255 * (float)i / (float)numStrokes[j]);
        int ii = (i + startStroke[j]) % maxStrokes;
        stroke((j*10)%255,255,255,alpha);
        vertex(s[ii].x,s[ii].y,s[ii].z);
      }

      endShape();
    }
  }


  void addStrokesFromJSON(String message) {
    if (message == "") return;
    try {
      JSONObject vp = new JSONObject(message); 
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

        int newPosition = numStrokes[i];
        if (numStrokes[i] >= maxStrokes) {
          newPosition = startStroke[i];
          startStroke[i] = startStroke[i] + 1;
          if (startStroke[i] >= maxStrokes) startStroke[i] = 0;
        } 
        else {
          numStrokes[i]++;
        }

        JSONArray xyz = objs.getJSONArray(i);
        float xx = (float)xyz.getDouble(0);
        float yy = (float)xyz.getDouble(1);
        float zz = (float)xyz.getDouble(2);
        strokeXYZ[i][newPosition] = new PVector(xx, yy, zz);
        numObjects = max(numObjects,i+1);
      }

      for (int i = objs.length(); i < maxObjects; i++) {
        numStrokes[i] = 0;
        startStroke[i] = 0;
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

