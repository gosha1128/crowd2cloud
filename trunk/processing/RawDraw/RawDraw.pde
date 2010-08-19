/**
 * Players draw by throwing balls around in a large
 * motion capture volume.
 *
 * Dragging the mouse changes the camera angle. Option-dragging
 *  (Alt-dragging) changes the zoom. Shift-drag controls dolly.
 *
 * Press s to skip ahead in the simulated data. 
 * Press spacebar to clear the current strokes. 
 * Press c to show/hide the cursor.
 *
 */

import processing.opengl.*;
import org.json.*;


// Top level globals you might want to change
boolean simulated = true;
int windowWidth = 1280;
int windowHeight = 800;
int skipAmount = 100;

// Variables for controlling the camera view
float delta = .05;
float minAngle = -5;
float maxAngle = 5;
float zoom = .15;
float minZoom = .05;
float maxZoom = 2;
PVector dolly, prevDolly;
float rotateFactor = .005;
float dollyFactor = 1;
float zoomFactor = .0005;

float angle, inc, prevZoom;
float deltaMouseX, deltaMouseY, startX, startY;

ViconData vd;
StrokeSet ss;





// Standard methods: setup, draw, mousePressed, mouseDragged, keyPressed, keyReleased

void setup() {

  size(windowWidth, windowHeight, OPENGL); 
  colorMode(HSB);

  vd = new ViconData(simulated);
  ss = new StrokeSet();
  dolly = new PVector();
  inc = delta;
  
  //Initially tilt the camera so we're looking with z up
  deltaMouseY = 300;
}


void draw() {

   
  String newData = vd.getData();
  ss.addStrokesFromJSON(newData);
  translate(-dolly.x*dollyFactor, -dolly.y*dollyFactor, 0);
  background(0); 
  noFill();

  // Center geometry in display window then zoom.
  translate(width/2, height/2, 0);
  scale(zoom);

  // Rotate so we're initially looking at the profile view
  //rotateX(PI/2);

  // Rotate based on the mouse delta plus the floating angle
  rotateY(radians(angle));
  rotateX(deltaMouseY*rotateFactor + radians(angle));
  rotateZ(deltaMouseX*rotateFactor);




  // Draw main bounding box
  strokeWeight(3);
  stroke(255,0,255,200);
  box(vd.deltaXYZ.x, vd.deltaXYZ.y, vd.deltaXYZ.z);

  // The box primitive is drawn centered though the true bounds may not be centered in
  //  the real world. We need to translate by this position so strokes come out aligned.
  pushMatrix();
  translate(-vd.meanXYZ.x, -vd.meanXYZ.y, -vd.meanXYZ.z);



  ss.draw();

  //Change the drifting camera angle
  angle+=inc;
  if (angle > maxAngle) inc = -delta;
  if (angle < minAngle) inc = delta;

  popMatrix();
}


void mousePressed() {
  startX = mouseX;
  startY = mouseY;
  prevDolly = dolly;
  prevZoom = zoom;
}


void mouseDragged() {

  // Option dragging vertically changes zoom
  if (keyCode == 18) {
    zoom += (startY - mouseY)*zoomFactor;
    if (zoom < minZoom) zoom = minZoom;
    if (zoom > maxZoom) zoom = maxZoom;

  }

  // Shift dragging changes dolly
  else if (keyCode == 16) {
    
    dolly.x += (startX - mouseX)*dollyFactor;
    dolly.y += (startY - mouseY)*dollyFactor;

  } else {

     deltaMouseX += -(mouseX - startX);
     deltaMouseY += (startY - mouseY);
  }
  
  
  startX = mouseX;
  startY = mouseY;
}


boolean cursorShowing = true;

void keyPressed() {

  if (key == ' ') {
    ss.clearStrokes();
  }

  if (key == 'c') {
    cursorShowing = !cursorShowing;
    if (cursorShowing) cursor();
    else noCursor();
  }

  if (key == 's' && simulated) {
    vd.skipFrames(skipAmount);
    ss.clearStrokes();
  }
}


// Need to clear the keyCode explicitly or you get stuck in zoom mode
void keyReleased() {
  keyCode = 0;
}







