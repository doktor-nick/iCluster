
class checkButtonList {
  Button[] buttons;
  boolean[] currentStates; // keeps track of current state of all buttons
  int nButtons;
  int x;
  int y;
  int spacer = 25;  
  int xspacer = 300;
  int buttonSize = 10;
  color[] colours;
  color bgColour;
  
 checkButtonList(String[] names, int xpos, int ypos, color[] clrs, color bgCol, boolean initState){
   x = xpos;
   y = ypos;
   nButtons = names.length;
   colours = new color[clrs.length];
   arraycopy(clrs,colours);
   bgColour = bgCol;
   buttons = new Button[nButtons];
   currentStates = new boolean[nButtons];
   for(int i=0; i<nButtons; i++){
     // check if we'd go off the bottom of the screen
     
      buttons[i] = new Button(names[i],x+xspacer*int(((i*spacer)/(height-y-50))), 
                                       y+(((i*spacer) % (height-y-50))), 
                               buttonSize,colours[i],bgColour,initState);
      currentStates[i] = initState;
   }  
 }

 void display(){
   for(int i=0; i<buttons.length; i++){
      buttons[i].display();
   }
 }

 int clicked(int mx, int my){
   // checks if a button was clicked, is so, updates it's state and returns class number;
   // returns -1 if no class clicked
  int classClicked = -1; 
  for(int i=0; i<nButtons; i++){
    if (buttons[i].press(mx,my)){
      currentStates[i] = buttons[i].getState();
      classClicked = i; 
    }
  }
  return classClicked;
 } 
 
 void setAllStates(boolean[] newStates){// set states of all the buttons
   for (int i=0; i<nButtons; i++){
      buttons[i].setState(newStates[i]);
   }
 }
 
 void addButton(String name,boolean bState){
   currentStates = (boolean[]) expand(currentStates,nButtons+1);
   buttons = (Button[])expand(buttons,nButtons+1);    
   buttons[nButtons] = new Button(name,x,y+(nButtons)*spacer,
                                          buttonSize,colours[nButtons],bgColour,bState);
   currentStates[nButtons] = bState; 
   nButtons++;
 }
 
 boolean[] getAllStates(){// returns list of buttons currently selected
  return currentStates;
 }
 
 void setState(int i, boolean bState){
   buttons[i].setState(bState);
   currentStates[i] = bState;
 }
 
 void flipState(int i){
   buttons[i].flipState();
   currentStates[i] = buttons[i].getState();
 } 
 
 void flipAllStates(){
  for(int i=0; i<nButtons; i++){
   flipState(i);
  } 
 }
boolean getState(int i){
   return buttons[i].getState();
 }
 
 
 
}

class Button {
  int x, y; // The x- and y-coordinates
  int size; // Dimension (width and height)
  color fgColour; // Default color value
  String name;   // text next to box 
  boolean checked; // True when the check box is selected
  color bgColour;

  Button(String namep, int xp, int yp, int s, color b, color bg, boolean bState) {
    x = xp;
    y = yp;

    name = namep;
    size = s;
    fgColour = b;
    bgColour = bg;
    checked = bState;
  }

  // Updates the boolean variable checked. Returns true if it was clicked
  boolean press(float mx, float my) {
    if ((mx >= x) && (mx <= x + size) && (my >= y) && (my <= y + size)) {
      checked = !checked; // Toggle the check box on and off
      return true;
    }
    else{
      return false;
    }
  }
  
  boolean getState(){
     return checked; 
  }
  
  void setState(boolean bState){
    checked = bState;
  }
  
  void flipState(){
   checked = !checked; 
  }

  void display() {
    textFont(font, 16); 
    stroke(200);
    if (checked == true) {
      fill(fgColour);
    }
    else{
      fill(bgColour);
    }
    rect(x, y, size, size);

    fill(200);
    text(name, x+2*size, y+size);
  }

}

class triButton {// 3 state button
  int x, y; // The x- and y-coordinates
  int size; // Dimension (width and height)
  color[] stateColours = new color[3]; // Colours for 3 states
  String name;   // text next to box 
  int state; // True when the check box is selected

  triButton(String namep, int xp, int yp, int s, color b0, color b1, color b2, int iState) {
    x = xp;
    y = yp;
    name = namep;
    size = s;
    stateColours[0]=b0;
    stateColours[1]=b1;
    stateColours[2]=b2;
    state = iState;
  }

  // Updates the boolean variable checked
  boolean press(float mx, float my) {
    if ((mx >= x) && (mx <= x + size) && (my >= y) && (my <= y + size)) {
      state = (state+1)%3; // Toggle the check box on and off
      return true;
    }
    else{
      return false;
    }
  }
  
  int getState(){
     return state; 
  }
  
  void setState(int bState){
    state = bState;
  }
  
  void display() {
    textFont(font, 16); 
    stroke(200);
    fill(stateColours[state]);
    
    rect(x, y, size, size);

    fill(200);
    text(name, x+2*size, y+size);
  }

}

class quadButton {// 4 state button
  int x, y; // The x- and y-coordinates
  int size; // Dimension (width and height)
  color[] stateColours = new color[4]; // Colours for 3 states
  String name;   // text next to box 
  int state; // True when the check box is selected

  quadButton(String namep, int xp, int yp, int s, color b0, color b1, color b2, color b3, int iState) {
    x = xp;
    y = yp;
    name = namep;
    size = s;
    stateColours[0]=b0;
    stateColours[1]=b1;
    stateColours[2]=b2;
    stateColours[3]=b3;    
    state = iState;
  }

  // Updates the boolean variable checked
  boolean press(float mx, float my) {
    if ((mx >= x) && (mx <= x + size) && (my >= y) && (my <= y + size)) {
      state = (state+1)%4; 
      return true;
    }
    else{
      return false;
    }
  }
  
  int getState(){
     return state; 
  }
  
  void setState(int bState){
    state = bState;
  }
  
  void display() {
    textFont(font, 16); 
    stroke(200);
    fill(stateColours[state]); 
    rect(x, y, size, size);
    fill(200);
    text(name, x+2*size, y+size);
  }
}

void drawBlinkBox(int x,int y, int w, int h){
   fill(255);
   if((millis() % 500) < 250){  // Only fill cursor half the time
    noFill();
    }
    else{
      fill(255);
      stroke(0);
    }
    rect(x, y, w, h);
}
