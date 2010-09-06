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
int windowWidth = 1024;
int windowHeight = 768;
int skipAmount = 300;

// Variables for controlling the camera view
float delta = .05;
float minAngle = -PI/2;
float maxAngle = PI/2;
float startZoom = .05;
float zoom = startZoom;
float minZoom = .032;
float maxZoom = 2;
PVector dolly, prevDolly;
float rotateFactor = .005;
float dollyFactor = 1;
float zoomFactor = .0005;

float angle, inc, prevZoom;
float deltaMouseX, deltaMouseY, startX, startY;
float startDeltaX = 0;
float startDeltaY = 320;
float minDeltaY = 320;
float maxDeltaY = 650;

boolean paused;


ViconData vd;
StrokeSet ss;
PFont font;
PImage colImg, floorImg;

float columnWidth = 400;
PVector[] columns;


void initColumns() {
  columns = new PVector[4];
  columns[0] = new PVector(-4000,-3900);
  columns[1] = new PVector(3800,-3900);
  columns[2] = new PVector(3800,3950);
  columns[3] = new PVector(-4000,3950);

  floorImg = loadImage("concrete.jpg");
  colImg = loadImage("column.jpg");
}




void drawColumn() {

  float xx = columnWidth/2;
  float yy = columnWidth/2;
  float zz = -vd.deltaXYZ.z/2;

  float texWidth = 40;
  float texHeight = 200;

  beginShape();
  texture(colImg);
  vertex(xx, yy, zz, 0, 0);
  vertex(-xx, yy, zz, texWidth, 0);
  vertex(-xx, yy, -zz, texWidth, texHeight);
  vertex(xx, yy, -zz, 0, texHeight);
  endShape();

  beginShape();
  texture(colImg);
  vertex(xx, -yy, zz, 0, 0);
  vertex(-xx, -yy, zz, texWidth, 0);
  vertex(-xx, -yy, -zz, texWidth, texHeight);
  vertex(xx, -yy, -zz, 0, texHeight);
  endShape();

  beginShape();
  texture(colImg);
  vertex(xx, yy, zz, 0, 0);
  vertex(xx, -yy, zz, texWidth, 0);
  vertex(xx, -yy, -zz, texWidth, texHeight);
  vertex(xx, yy, -zz, 0, texHeight);
  endShape();

  beginShape();
  texture(colImg);
  vertex(-xx, yy, zz, 0, 0);
  vertex(-xx, -yy, zz, texWidth, 0);
  vertex(-xx, -yy, -zz, texWidth, texHeight);
  vertex(-xx, yy, -zz, 0, texHeight);
  endShape();
}


// Standard methods: setup, draw, mousePressed, mouseDragged, keyPressed, keyReleased
void setup() {
  
  noCursor();
  
  //Hack to get a black frame in an exported application
  frame.setBackground(new java.awt.Color(0, 0, 0));
  frameRate(30);
  size(windowWidth, windowHeight, OPENGL); 
  colorMode(HSB);

  initColumns();
  vd = new ViconData(simulated);
  font = loadFont("CourierNew36.vlw");
  textFont(font, 36);

  ss = new StrokeSet();
  dolly = new PVector();
  inc = delta;
  angle = 0;

  deltaMouseY = startDeltaY;
  deltaMouseX = startDeltaX;
}

void loadData() {  
    String message = vd.getData();
    ss.addStrokesFromJSON(message);
}


void draw() {

  if (!paused) {
    loadData();
  }
  
  pushMatrix();
  background(0); 
  noFill();

  // Center geometry in display window then zoom.
  translate(width/2, height/2, 0);
  
  //Adjust for dolly and scale, -zoom for zscale flips us appropriately
  translate(-dolly.x*dollyFactor, -dolly.y*dollyFactor, 0);
  scale(zoom,zoom,-zoom);

  // Rotate based on the mouse delta plus the floating angle
  float rr = sin(angle)/20;
  rotateY(rr);
  rotateX(deltaMouseY*rotateFactor);
  rotateZ(deltaMouseX*rotateFactor);

  // Draw main bounding box
  strokeWeight(3);
  stroke(255,0,255,200);
  //box(vd.deltaXYZ.x, vd.deltaXYZ.y, vd.deltaXYZ.z);

  //Draw floor texture
  noStroke();
  beginShape();
  texture(floorImg);
  float zz = -vd.deltaXYZ.z/2;
  vertex(vd.minXYZ.x, vd.minXYZ.y, zz, 0, 0);
  vertex(vd.minXYZ.x, vd.maxXYZ.y, zz, 0, 512);
  vertex(vd.maxXYZ.x, vd.maxXYZ.y, zz, 512, 512);
  vertex(vd.maxXYZ.x, vd.minXYZ.y, zz, 512, 0);
  endShape();


  //Draw each column
  for (int i = 0; i < columns.length; i++) {
    pushMatrix();
    translate(columns[i].x, columns[i].y);
    drawColumn();
    popMatrix();
  }


  // The box primitive is drawn centered though the true bounds may not be centered in
  //  the real world. We need to translate by this position so strokes come out aligned.
  pushMatrix();
  translate(-vd.meanXYZ.x, -vd.meanXYZ.y, -vd.meanXYZ.z);
  
  ss.draw();
  

  //Change the drifting camera angle
  angle+=inc;
  if (angle > maxAngle) {
    angle = maxAngle;
    inc = -delta;
  }
  if (angle < minAngle) {
    inc = delta;
    angle = minAngle;
  }

  popMatrix();
  popMatrix();

}

boolean firstMouse = true;

void mousePressed() {
  startX = mouseX;
  startY = mouseY;
  prevDolly = dolly;
  prevZoom = zoom;
}

void mouseDragged() {
  //Prevents a glitch that arises of the first mouse movement is a drag
  if (firstMouse) {
    mousePressed();
    firstMouse = false;
    return;
  }

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
  } 
  else {

    deltaMouseX += -(mouseX - startX);
    deltaMouseY += (startY - mouseY);
  }


  if (deltaMouseY < minDeltaY) deltaMouseY = minDeltaY;
  if (deltaMouseY > maxDeltaY) deltaMouseY = maxDeltaY;

  startX = mouseX;
  startY = mouseY;

  //println(deltaMouseX + "/" + deltaMouseY + "/" + zoom);
}


boolean cursorShowing = true;

void keyPressed() {

  if (key == ' ') {
    ss.clearStrokes();
  }

  if (key == 'p' && simulated) {
    paused = !paused;
  }

  if (key == 'c') {
    cursorShowing = !cursorShowing;
    if (cursorShowing) cursor();
    else noCursor();
  }

  if (key == 'j' && simulated) {
    for (int i = 0; i < skipAmount; i++) {
      String newData = vd.getData();
      ss.addStrokesFromJSON(newData);
    }
  }

  if (key == 's' && simulated) {
    vd.skipFrames(skipAmount);
    ss.clearStrokes();
  }

  if (key == 'r') {
    deltaMouseX = startDeltaX;
    deltaMouseY = startDeltaY;
    zoom = startZoom;
    dolly.x = 0;
    dolly.y = 0;
  }
}

// Need to clear the keyCode explicitly or you get stuck in zoom mode
void keyReleased() {
  keyCode = 0;
}

void stop() {

}

