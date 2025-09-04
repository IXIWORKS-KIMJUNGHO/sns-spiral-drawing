float r=1.0; // radius
float degree=0.0; // rotation degree
float px, py, cx, cy, x, y; // previous point, current point, start point
float b, oldb; // current and old brightness
PImage img; // image

void setup() {
  size(1000, 1000); // image size = screen size
  background(255);
  img = loadImage("ah.jpg"); // load image
  
  px = x = width/2;   // initialize
  py = y = height/2;
  px=x+r*cos(degree);
  py=y+r*sin(degree);

  oldb = 0;
}

void draw() {

  for (int i=0; i<(1+r/100); i++) { // outer faster
    degree+=map(r, 0, width/2, 0.1, 0.005); // degree increase smaller outside
    r=r+map(r, 0, width/2, 0.1, 0.02); // radius increase smaller outside 
    
    if (r>width/2) noLoop(); // stop condition

    cx=x+r*cos(degree); // cacluate x and y
    cy=y+r*sin(degree);

    b = map(brightness(img.get(int(cx), int(cy))), 0, 255, 4, 0); // brightness get from image

    strokeWeight((b+oldb)/2.0); // stroke size based on brightness

    line(cx, cy, px, py); // draw line

    oldb = b; // current b, x, y become old ones
    px = cx;
    py = cy;
  }
}