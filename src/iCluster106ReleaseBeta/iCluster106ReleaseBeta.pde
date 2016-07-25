// (c) 2009 Dr Nick, n.hamilton@imb.uq.edu.au
// All rights reserved

// ChangeLog:

// 1.0.6
// Added support for libsvm. When writing a standard iCluster data file, 
//  a file containing the data and their classes in a format suitable for
//  libsvm is also created. It has the same name as the standard data file
//  but with .libsvm appended. A file with name .libsvm_classNames is also
//  created which gives the number to (text) class name mapping.
// mask smoothing added to get rid of noise.

// Markov Clustering code added by Daniel Marshall
// NOTE: Currently this is clustering based on the 3D embedding, not the high D distances.
//       Change ldata -> hdata in markov_cluster() to do high D clustering.

// Window resizing now works in processing 2.0 alpha!

// BUG FIX:
//   By introducing a minimum distance below which we don't consider the neighbours of a point to
//   move that point. This is currently set to minSep = 0.001

// 1.0.5
// PCA coordinates implemented by Daniel Marshall based on the jmathtools library (http://jmathtools.berlios.de/doku.php)
// * now using processing 1.0.5
// * fixed bug in sammon mapping where points colliding in 2D or 3D caused ungraceful exit

// 1.0.4
// * Input of distance matrix rather than statistics vectors is now supported
// * Added consecutive image joining. So will draw lines between images which are consecutive in the
//   data file and are of the same class
// * Fixed bug where images were not drawn with processing versions 1.02 and 1.03
// * Some minor code tidying
// * Fixed bug where points were sometimes randomised when sammon mapping started (because of choice
//   of too high a convergence factor epsilon).
// * Fixed irritation where images would show as pop ups when not in display image mode 
// * Mouse dragging in 2D has been reversed to be more intuitive.
// * Fixed problem in choosing legend colours when the number of colours is large (>22)
// * Available memory is now monitored, and warnings given rather than exiting ungracefully.

// 1.0.3 :
// TAS are now standardised rather than normalised on first calculation, see manual for details.

// TODO:
// BUG: If one data set has been loaded, then another is loaded, it will sometimes crash. 
//         Some of the variables not getting re-initialised properly? Hmmm, bug may have been fixed. Not observed for a few recent releases.
// BUG: If a distance matrix is specified in the file header by "# Distance", category names need to be supplied.
// BUG: If less than 22 classes are used then, more are assigned than 22, colour assignment will cause problems
//      Similarly, the number of categories is hard wired to less than 50.

// .png|.PNG|.tif|.TIF|.tiff|.TIFF can cause trouble when file names have "png" in them etc

// make buttons pretty and use menus

// should store selected statistics, normalisation state, etc

// consecutive neighbour joining, add to neighbour button.
// should be consecutive by class.

// remove JAI dependencies, there's now stuff for file open/close in processing,
// also  
// File dir = new File("sketchbook/default/fman2/data");
// String[] children = dir.list(); 

// window resizing?

// use the new asyncronous image loading, requestImage, available from processing-0144 to load images.
// clean up all the image drawing so its done in idata, including borders etc.

// scale volume to fit data when read
// make the data structures OO for images etc
// clean up the logic of it all, ie labeltoggle etc

// images should be indiviually selectable for display
// should record the current state for when switch to/back rep image etc

// should be able to read/write all calculated data to/from file, i.e. save system state. - Partly done

// representative images should be a boolean in the iData class, and should use high D data

// the "add class" case will cause a small problem of the number of classes
// changes from below 22 to more than 22, for then a new pallete will be used
// also, nearest neigbour calculation and representative image selection are a problem here
// should be able to move the image in 2/3D.

// select all visible/select none
// should have a select visible button
// fix the scale data stuff, it's stupid.

// should be recording current view as well as current data. The stuff in initVars could
// go into a state class.

// key pressed stuff should be cleaned up. A function that does the keyboard trapping written.


import processing.opengl.*;
import javax.swing.*; // for file choosing
import javax.swing.JFileChooser;
import javax.media.jai.*;
//import com.sun.opengl.util.FPSAnimator;
import org.math.array.*;
import org.math.array.LinearAlgebra.*;
import org.math.array.StatisticSample.*;
import org.math.array.util.*;
import org.math.array.DoubleArray.*;
import Jama.*; 

iData[] imgs;

int nnSameClass;
int nnHighSameClass;

int nImages;
int nImagesOn;

//int nCategories; // number of different categories that an image can be 
// distinguished from other image by.
//String[] categories; // stores the category names

Dataset hdata,ldata; // high dimensional stats data and low dimensional sammon mapped
sammonMap sam;

float res;
float resDiff;
float imageRes;
float imageResDiff;
float sphereR;
float sphereDiff;
float scaleData; 
float selectionRadius = 0;

// 3D positioning
float angle = 0;
float transYDiff;
float angleYDiff;
float transY;
float rotY;

// 2D positioning
float xPos;
float yPos;
float xPosDiff;
float yPosDiff;

int mouseXpress;
int mouseYpress;
boolean mouseHeld = false;

boolean saveD;

String newClassName = "";
String newFileName = "";

int[] repImages;

boolean showMasks = false;

PFont font;

//color[] colours;

float[][] dStats; // holds distances between currently selected highD stats

boolean saveframe = false;
boolean lightsOn = false;
boolean showLegend = true;
color bgColour;

int iScale;

checkButtonList[] classLegends;
int currentLegendIndex = 0; // records index of legend currently selected.

checkButtonList classAButtons; // used for statistical testing
checkButtonList classBButtons;
DiffTest classDiffTest;
boolean doneTesting = false;


Button selectStatsButton;
Button invertStatsSelectedButton;
checkButtonList selectedStatsButtons; // which statistics are currently used for sammon mapping?

Button sammonButton;

Button addClassButton;
Button reclassifySelectedButton;
Button selectedImagesOnlyButton;
Button repImagesOnlyButton;
Button repImagesOnButton;
Button deselectAllButton;
Button toggleDimButton;
quadButton nbrJoinButton;
triButton imagesNamesButton;
Button saveDataButton;
Button loadDataButton;
Button statsTestButton;
Button normaliseStatsButton;
Button PCAButton;
Button MCLButton;
//Button selectWithRadius;

Button classesSelectedButton;

Button selectCategoryButton;
checkButtonList categoryButtons;

int justSelected = -1; // indices of images that have just been selected
boolean shiftHeld = false;

// file stuff
String defaultDirectory = "data"; // Set Default Directory
String defaultFile = "icluster_coords_autoSave.txt";
String configFile = "config.txt";

JFileChooser fc;//= new JFileChooser( defaultDirectory );
File[]  folderFile = new File[0];

boolean gotFileName = false;
boolean fSelectorInvoked = false;
String fileDelimeter = "/";

// second window to show high res image
boolean errorFlag = true;
String errorMessage = "";

// flag for distance graph rather than vectors
// TRUE means stats vectors are distances to other elements
// FALSE stats vectors are usual stats vectors
boolean distance = false; // not currently fully tested

float minSep = 0.001; // minimum distance between points below which we don't bother trying to move them.

// flag when memory is getting low (<20M left)
boolean memoryLow = false; // this is only set during image loading.

void setup() 
{   

 //size(screen.width*98/100, screen.height*95/100, OPENGL); // this will do full screen mode.
 // size(screen.width*98/100, screen.height*95/100, P3D); // this will do full screen mode.

  size(3000,1600,OPENGL);
  frame.setResizable(true); // bug in processing that means this doesn't currently work well (processing 1.0.5 .. 1.5.1)

  String OS = System.getProperty("os.name");
  if (match(OS,"indows") != null) {
    fileDelimeter = "\\";
  }

  stroke(180);
  bgColour = color(10,40,50);
  initVars();
  sphereDetail(5);

  initButtons();
  readConfigFile();
  fSelectorInvoked =false;
  loadDataButton.setState(true);

  frameRate = 10;
}

void draw() 
{    
  // The amount of memory allocated so far (usually the -Xms setting)
  //long allocated = Runtime.getRuntime().totalMemory();

  // Free memory out of the amount allocated (value above minus used)
  //long free = Runtime.getRuntime().freeMemory();

  // The maximum amount of memory that can eventually be consumed
  // by this application. This is the value set by the Preferences
  // dialog box to increase the memory settings for an application.
  //long maximum = Runtime.getRuntime().maxMemory();
  //long allocated = Runtime.getRuntime().totalMemory();
  //println("Free: "+free);
  //println("Max: "+maximum);
  //println("Alloc:"+allocated);
  //println("MemoryLow: "+memoryLow);

  background(bgColour);
  if (loadDataButton.getState()) { // read data
    selectLoadData();
  }
  else {    
    if (selectCategoryButton.getState()) {
      drawCategoryLegend();
    }
    else 
      if (selectStatsButton.getState()) {// we're in select stats mode.
      drawStatsLegend();
    }
    else {
      if (!distance && statsTestButton.getState()) {// we're in stats mode.
        drawClassABLegend();
        if(classesSelectedButton.getState()) {
          if(classDiffTest.finished) {
            classesSelectedButton.setState(false);
          } 
          else {
            classDiffTest.calcPValue();
          }
        }
      }
      else {// we're just in normal drawing mode

          if (sammonButton.getState()) { 
          updateSammonCoords();
        }

        if (lightsOn == true) {
          lights();
        }        
        pushMatrix();
        translate(width/2,height/2);

        scale(res);
        if (mouseHeld) {
          mouseDrag();
        }

        if (saveDataButton.getState()) { // write data to selected file
          if(!fSelectorInvoked) {
            getSelectedFileName();
            fSelectorInvoked = true;
          }
          else {
            if (gotFileName) {
              writeData(defaultDirectory, defaultFile);
              writeConfigFile();
              saveDataButton.setState(false);
              fSelectorInvoked = false;
              gotFileName = false;
            }
          }
        }

        if(!toggleDimButton.getState()) {//3D
          rotateY(rotY);
          translate(0,transY,0);
        }
        else {
          translate(xPos,yPos); //2D
        }

        if (repImagesOnlyButton.getState())
        {
          drawRepImagesOnly();
        }
        else {
          if (selectedImagesOnlyButton.getState()) {
            drawSelectedImagesOnly();
          }
          else {  
            drawSpheres();

            switch (nbrJoinButton.getState()) {
            case 0:
              break;
            case 1:
              drawNNs();
              break;
            case 2:
              drawnnHigh();
              break;
            case 3:
              drawConsecutive();
              break;
            }

            switch (imagesNamesButton.getState()) {
            case 0: // no extras
              break;
            case 1: // draw images
              if (repImagesOnButton.getState()) {
                drawRepImages();
              }
              else {
                drawImages();
              }
              break;
            case 2:  // draw names
              drawNames();
              break;
            }
          }
        }
        popMatrix();

        if (showLegend) {
          classLegends[currentLegendIndex].display();
          drawLegend();
        }
      }
    }  
    if (saveframe == true) {
      saveFrame(); 
      saveframe =false;
    } // take a picture
  }
}



void initVars()
{
  res = 0.2;
  resDiff = res/20;
  imageRes = 2;
  imageResDiff = 0.01;
  sphereR = 10;
  sphereDiff = 2;
  scaleData = 200;
  //iScale = 3; // scale factor used to reduce image size for visualisation

  // 3D positioning stuff
  angle = 0;
  transYDiff = 10;
  angleYDiff = 0.02;
  transY = 0;
  rotY = 0;

  // 2D positioning
  xPos = 0;
  yPos = 0;
  xPosDiff = 10;
  yPosDiff = 10;
  // repImages
  currentLegendIndex = 0;
}

void initButtons() {

  font = loadFont("CourierNew36.vlw");   
  int xPos = 10;
  int yPos = 400;
  int yDiff = 20;

  addClassButton = new Button("Add Class", xPos, yPos, 10, color(255), bgColour, false);
  reclassifySelectedButton = new Button("Reclassify Selected", xPos, yPos+yDiff, 10, color(255), bgColour, false);  
  selectedImagesOnlyButton = new Button("Selected Images Only", xPos, yPos+2*yDiff, 10, color(255), bgColour, false);    
  //selectWithRadius = new Button("Selected Within Radius", xPos, yPos+3*yDiff, 10, color(255), bgColour, false);  
  deselectAllButton = new Button("Deselect All", xPos, yPos+3*yDiff, 10, color(255), bgColour, false);  
  repImagesOnlyButton = new Button("Rep Images Only", xPos, yPos+5*yDiff, 10, color(255), bgColour, false);
  repImagesOnButton = new Button("Toggle Rep Images", xPos, yPos+6*yDiff, 10, color(255), bgColour, false);
  toggleDimButton = new Button("Toggle 2D/3D", xPos, yPos+7*yDiff, 10, color(255), bgColour, false); 
  nbrJoinButton = new quadButton("Neighbour Join", xPos, yPos+8*yDiff, 10, bgColour, color(85), color(170), color(255), 0); 
  imagesNamesButton = new triButton("Show Images/Names", xPos, yPos+9*yDiff, 10, color(255), bgColour, color(128),  1);   
  saveDataButton = new Button("Save Data", xPos, yPos+10*yDiff, 10, color(255), bgColour, false); 
  loadDataButton = new Button("Load Data", xPos, yPos+11*yDiff, 10, color(255), bgColour, false); 

  classesSelectedButton = new Button("Finished Selecting Classes", xPos, yPos+10*yDiff, 10, color(255), bgColour, false);

  statsTestButton = new Button("Statistical Test", xPos, yPos+12*yDiff, 10, color(255), bgColour, false); 

  invertStatsSelectedButton = new Button("Invert Selected", xPos, yPos+11*yDiff, 10, color(255), bgColour, false); 
  selectStatsButton = new Button("Select Statistics", xPos, yPos+13*yDiff, 10, color(255), bgColour, false); 
  sammonButton = new Button("Sammon Map Statistics", xPos, yPos+14*yDiff, 10, color(255), bgColour, false); 
  PCAButton = new Button("PCA", xPos, yPos+15*yDiff, 10, color(255), bgColour, false); 
  MCLButton = new Button("MCL", xPos, yPos+16*yDiff, 10, color(255), bgColour, false); 

  selectCategoryButton = new Button("Change Image Categories", xPos, yPos+17*yDiff, 10, color(255), bgColour, false); 
  normaliseStatsButton = new Button("Use Normalised Stats", xPos, yPos+18*yDiff, 10, color(255), bgColour, true); 

  //wheelMouseSetup(); // only needed for old processing versions
}

void selectLoadData() {
  // select a data file and load it
  textFont(font, 18); 
  fill(255);
  text("Please select data file name to load",width/4,50);

  if(!fSelectorInvoked) {
    getSelectedFileName();
    fSelectorInvoked = true;
  }
  else {
    if (gotFileName) {
      initVars();
      readData(defaultDirectory, defaultFile);
      loadDataButton.setState(false);
      fSelectorInvoked = false;
      gotFileName = false;
    }
  }
}

boolean readConfigFile() {// reads default directory and data input file names
  String lines[] = loadStrings(configFile);
  println("Reading config file:"+configFile);
  if (lines == null) { // then go into file selection mode
    fSelectorInvoked = false;
    loadDataButton.setState(true);
    return false;
  }
  else {
    defaultDirectory = trim(lines[0]);
    defaultFile = trim(lines[1]);
    String[] sc = split(lines[2],'=');
    iScale = int(sc[1]);
    return true;
  }
}

void writeConfigFile() {// writes default directory and data input file names
  //String lines[] = loadStrings("file://"+directory+"/"+fileName);
  println("Writing config file"+configFile);  
  String[] output = new String[3];   
  output[0] = defaultDirectory;
  output[1] = defaultFile;
  output[2] = "iScale=3";//+iScale;
  saveStrings(configFile,output);
}

void getSelectedFileName() {

  SwingUtilities.invokeLater(new Runnable() {
    public void run() {      
      try
      {
        fc = new JFileChooser(defaultDirectory);     
        int returnVal;
        if (loadDataButton.getState()) {
          returnVal = fc.showDialog(null,"Select iCluster Data File to Open");
        }
        else {
          returnVal = fc.showDialog(null,"Select/Create Data File to Write");
        }
        if(returnVal == JFileChooser.APPROVE_OPTION)  
        {         
          defaultFile = fc.getSelectedFile().getName();
          defaultDirectory = fc.getSelectedFile().getParent();   
          println("Default file/dir = "+defaultFile+","+defaultDirectory);    
          writeConfigFile();
        }
        else {// operation cancelled, exit selection mode
          loadDataButton.setState(false);
          fSelectorInvoked = false;
        }
        gotFileName = true;
      }
      catch (Exception e)
      {  
        e.printStackTrace();
      }
    }
  }
  );
}

String[] getImageNamesInDirectory(String dirName) {
  // if there are pngs in directory, will return list of
  // their names, else it will return tif list
  // Note: PNG's are first choice

    File dir = new File(dirName);

  String[] children = dir.list();
  if (children == null) {
    // Either dir does not exist or is not a directory
  } 
  else {
    for (int i=0; i<children.length; i++) {
      // Get filename of file or directory
      String filename = children[i];
      //println("!!"+filename+"!!");
    }
  }

  FilenameFilter filterPng = new FilenameFilter() {
    public boolean accept(File dir, String name) {
      return name.endsWith(".png") | name.endsWith(".PNG");
    }
  };

  FilenameFilter filterTif = new FilenameFilter() {
    public boolean accept(File dir, String name) {
      return name.endsWith(".tif") | name.endsWith(".tiff") |
        name.endsWith(".TIF") | name.endsWith(".TIFF");
    }
  };   

  children = dir.list(filterPng);
  if (children.length == 0) {
    children = dir.list(filterTif);
  }

  return children;
}

void readData(String directory, String fileName) {
  // each line is x,y,z,imagename[,class]
  println("Reading in data");
  int firstFloat;
  String lines[];
  distance = false;

  if (match(fileName,".png\\z|.PNG\\z|.tif\\z|.TIF\\z|.tiff\\z|.TIFF\\z") != null) {
    lines = getImageNamesInDirectory(directory);
    for(int i=0; i<lines.length; i++) {
      lines[i] = lines[i]+",Default Class";
    }
  }
  else {
    lines = loadStrings(directory+fileDelimeter+fileName);
  }

  int dataStart;
  // if first line begins with a #, it's the names of categories and the statistics (comma separated)
  String[] lSplit = split(lines[0],'#'); 

  // first deal with any stats names and categories names that may have been supplied via a # line.
  if (lSplit.length == 1) {// no #, so no names supplied, just use numbers
    dataStart = 0;
    // format is imagename[,maskname][,class1][,class2][,stat1,...statn][;2Dcoors][;3Dcoords];
    String idata[] = split(lines[0], ';'); 
    String[] namesAndStats = split(idata[0],",");

    if (namesAndStats.length == 1) { // we've only been given names, nothing else
      String[] catNames = new String[1]; 

      color[] cols = new color[50];
      for(int i=0; i<50; i++) {// this is slightly crazy, but is so that if new categories are supplied, then colours are there already for them.
        cols[i] = color(255);
      }   
      catNames[0] = "Default";
      categoryButtons = new checkButtonList(catNames, 260, 150, cols, bgColour, false);   
      // create stats legend?
    } 
    else {
      // just name categories by numbers

      // figure out where first statistic is
      firstFloat = namesAndStats.length;
      for(int j=namesAndStats.length-1; j>0; j--) {
        if (match(namesAndStats[j],"[a-d]|[f-z]|[A-D]|[F-Z]")==null) {// numbers with e's may cause a problem here
          firstFloat = j;
        }
      }

      int nCategories = firstFloat-1;

      if (match(namesAndStats[1],".png|.PNG|.tif|.TIF|.tiff|.TIFF") != null) {
        // one less category if second element is a mask image name
        nCategories -= 1;
      }
      println("#cats = "+nCategories);
      String[] catNames = new String[nCategories]; 
      //color[] cols = new color[catNames.length];
      color[] cols = new color[50];
      for(int i=0; i<50; i++) {// this is slightly crazy, but is so that if new categories are supplied, then colours are there already for them.
        cols[i] = color(255);
      } 
      for(int i=0; i< catNames.length; i++) {
        catNames[i] = "Category "+str(i+1);
      }
      categoryButtons = new checkButtonList(catNames, 260, 150, cols, bgColour, false);   
      // now the stats    
      if (firstFloat != namesAndStats.length) { // stats have been supplied     
        String[] statNames = new String[namesAndStats.length-firstFloat]; // just name the stats by their index
        cols = new color[statNames.length];
        for(int i=1; i<= statNames.length; i++) {
          statNames[i-1] = "Stat"+str(i);
          cols[i-1] = color(255);
        }
        selectedStatsButtons = new checkButtonList(statNames, 260, 150, cols, bgColour, true);
      }
    }
  }
  else { // names supplied, initialises stats selection buttons
    String[] catsAndStats = split(lSplit[1],';');
    if (match(catsAndStats[0],"istance") != null) {// it's not stats, its a distance matrix
      distance = true;
      // sort out category names
      String[] catNames = split(catsAndStats[1],',');
      color[] cols = new color[50];
      for(int i=0; i<50; i++) {  
        cols[i] = color(255);
      }  
      categoryButtons = new checkButtonList(catNames, 260, 150, cols, bgColour, false); 
      // the "stat" names are just the names of the points, since we've a distance matrix
      cols = new color[lines.length-1];
      String[] statNames = new String[lines.length-1];
      for(int i=1; i<lines.length; i++) {  
        String idata[] = split(lines[i], ',');
        statNames[i-1] = idata[0];
        cols[i-1] = color(255);
      }  
      selectedStatsButtons = new checkButtonList(statNames, 260, 150, cols, bgColour, true);
    }
    else {
      // sort out category names
      String[] catNames = split(catsAndStats[0],',');
      color[] cols = new color[50];
      for(int i=0; i<50; i++) {  
        cols[i] = color(255);
      }  
      categoryButtons = new checkButtonList(catNames, 260, 150, cols, bgColour, false); 
      // sort out stats names
      String[] statNames = split(catsAndStats[1],','); 
      cols = new color[statNames.length];
      for(int i=0; i<statNames.length; i++) {  
        cols[i] = color(255);
      }  
      selectedStatsButtons = new checkButtonList(statNames, 260, 150, cols, bgColour, true);
    }
    dataStart = 1;
  }

  nImages = lines.length-dataStart;  
  imgs = new iData[nImages];   
  boolean generateStats = false;

  for (int i=0; i < nImages; i++) { // finally, read in the data

    String idata[] = split(lines[i+dataStart], ';');
    //println("i0="+idata[0]);
    // find first numeric value in idata, if it exists
    String namesAndStats[] = split(idata[0],',');
    //println(float(namesAndStats));
    firstFloat = namesAndStats.length;

    for(int j=namesAndStats.length-1; j>0; j--) {
      if (match(namesAndStats[j],"[a-d]|[f-z]|[A-D]|[F-Z]")==null) {//avoid e's because of scientific notation
        firstFloat = j;
      }
    }

    // record names/masks/class names in imgs[i].      
    imgs[i] = new iData(namesAndStats[0],subset(namesAndStats,1,firstFloat-1));

    println(imgs[i].name);
    for(int j=idata.length; j<5; j++) {
      idata = append(idata,"");
    }

    // extract stats
    if (firstFloat >= namesAndStats.length) {
      generateStats = true; // flag that we need to generate stats
    } 
    else {
      float stats[] = float(subset(namesAndStats,firstFloat, namesAndStats.length - firstFloat)); 
      imgs[i].copyStats(stats);
      imgs[i].printStats();
    }

    // 2D & 3D coords  
    String coords2[] = splitTokens(idata[1],",");
    if (coords2.length != 2) {
      //provide random coordinates if coords have not been provided.
      imgs[i].randCoords(2);
    }
    else {
      imgs[i].x2 = float(coords2[0]);
      imgs[i].y2 = float(coords2[1]);
    }      
    String coords3[] = splitTokens(idata[2],",");
    if (coords3.length != 3) {
      //provide random coordinates if coords have not been provided.
      imgs[i].randCoords(3);
    }
    else {
      imgs[i].x3 = float(coords3[0]);
      imgs[i].y3 = float(coords3[1]);
      imgs[i].z3 = float(coords3[2]);
    }
  }

  assignClassNumbersAndGenerateLegends(); 

  println("Gen stats "+generateStats);

  if (generateStats) { // if we've just
    println("Calculating stats ...");
    calculateStatsAndStandardise();
    defaultFile = "icluster_coords_autoSave.txt";
    writeConfigFile();
    writeData(defaultDirectory,defaultFile);
  }
  else { 
    hdata = statsDataCopy(classLegends[currentLegendIndex],selectedStatsButtons);  
    calculateStatsDistances(selectedStatsButtons); 
    calculateHighDNearestNeighbours();
    ldataInit();
    calculateLowDNearestNeighbours();
  }

  calculateRepImages();  
  println("There are "+nImages+" images");
}

void writeData(String directory, String fileName) {
  String[] output = new String[nImages+1];
  // first the category and stats names;
  println("Writing data directory-file:"+directory+"-"+fileName);
  output[0] = "#";
  if (distance) {
    output[0] += " Distance;";
  }
  for(int i=0; i<categoryButtons.nButtons-1;i++) {
    output[0] += categoryButtons.buttons[i].name+",";
  }
  output[0] += categoryButtons.buttons[categoryButtons.nButtons-1].name+";";
  if(!distance) {
    for(int i=0; i< selectedStatsButtons.nButtons-1;i++) {
      output[0] += selectedStatsButtons.buttons[i].name+",";
    }
    output[0] += selectedStatsButtons.buttons[selectedStatsButtons.nButtons-1].name;
  }
  for (int i=0; i < nImages; i++) {  
    output[i+1] = imgs[i].name;
    if(imgs[i].userMask) {
      output[i+1] = ","+imgs[i].nameMask;
    }
    output[i+1] += ",";
    for(int j=0; j<imgs[i].nCategories-1; j++) {
      output[i+1] +=  imgs[i].classNames[j]+",";
    }
    output[i+1] += imgs[i].classNames[imgs[i].nCategories-1]+",";
    for(int j=0; j<=imgs[i].iStats.length-2; j++) {
      output[i+1] += imgs[i].iStats[j]+",";
    }
    output[i+1] +=imgs[i].iStats[imgs[i].iStats.length-1]+";"+imgs[i].x2+","+imgs[i].y2+";"+imgs[i].x3+","+imgs[i].y3+","+imgs[i].z3;
  }   
  println("Saving data to "+fileName+" in directory "+directory);
  saveStrings(directory+fileDelimeter+fileName,output);

  // also write libsvmfile
  writeLibSVMdatafile(directory,fileName+".libsvm");
}

void writeLibSVMdatafile(String directory, String fileName) {
  // write out image names and stats in format suitable for using in libsvm
  // only used the currently selected category class for the images

  String[] output = new String[nImages];
  String[] classNames = new String[1];
  // first the category and stats names;
  println("Writing libsvm file to data directory-file:"+directory+"-"+fileName);
  classNames[0] = "";
  for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++) {
    classNames[0] += i+" "+classLegends[currentLegendIndex].buttons[i].name+"\n";
  }

  saveStrings(directory+fileDelimeter+fileName+"_classNames",classNames); 

  for (int i=0; i < nImages; i++) {  
    output[i] = imgs[i].classNums[0]+"   ";
    for(int j=0; j<=imgs[i].iStats.length-2; j++) {
      output[i] += j+1+":"+imgs[i].iStats[j]+" ";
    }
    output[i] +=imgs[i].iStats.length-1+1+":"+imgs[i].iStats[imgs[i].iStats.length-1];
  }   
  println("Saving data to "+fileName+" in directory "+directory);
  saveStrings(directory+fileDelimeter+fileName,output);
}


void assignClassNumbersAndGenerateLegends() {
  // assign a number 0..nClasses-1 for the class names in each category
  // find classes
  // returns maximum number of classes in a given category
  println("Assigning class numbers and generating legends");
  int nCategories = imgs[0].nCategories; // number of categories should be same for all images.
  println("Number of categories: "+nCategories);
  classLegends = new checkButtonList[nCategories];

  for(int k=0; k<nCategories; k++) {
    int nClasses = 1;
    String[] classes = new String[nImages];
    classes[0] = imgs[0].classNames[k];
    for(int i=1; i<nImages; i++) {
      // is it a new class
      //println(k+" "+i+" "+imgs[i].name);
      boolean newClass = true;
      for(int j=0; j<nClasses; j++) {
        if (classes[j].equals(imgs[i].classNames[k])) {
          newClass = false;
        }
      }
      if (newClass) {
        classes[nClasses] = imgs[i].classNames[k];
        nClasses++;
      }
    }
    //assign classes
    for(int i=0; i<nImages; i++) {
      for(int j=0; j<nClasses; j++) {
        if (classes[j].equals(imgs[i].classNames[k])) {
          imgs[i].classNums[k] = j;
        }
      }
    }
    color[] colours = chooseColours(nClasses);
    classes = subset(classes,0,nClasses);
    classLegends[k] = new checkButtonList(classes, 10, 10, colours, bgColour, true);
  }
}


void addClass(String newClassName) {
  // nearest neigbour calculation and representative image selection are a problem here
  // as are colour palettes
  //classes = append(classes,newClassName);
  println("Adding class:"+newClassName);
  classLegends[currentLegendIndex].addButton(newClassName,true);
  initClassABbuttons(); 
  addClassButton.setState(false);
}

String[] currentClasses() {
  String[] classes = new String[classLegends[currentLegendIndex].nButtons];
  for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++) {
    classes[i] = classLegends[currentLegendIndex].buttons[i].name;
  } 
  return classes;
}

color[] currentClassColours() {
  color[] colours = new color[classLegends[currentLegendIndex].nButtons];
  for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++) {
    colours[i] = classLegends[currentLegendIndex].buttons[i].fgColour;
  } 
  return colours;
} 

void initClassABbuttons() {
  // need to figure out current colour scheme and classes from the selcted legend.
  println("initClassABbuttons");
  String[] classes = currentClasses();
  color[] colours = currentClassColours();
  classAButtons = new checkButtonList(classes, 50, 100, colours, bgColour, false);// for class comparison statistics calculations
  classBButtons = new checkButtonList(classes, 550, 100, colours, bgColour, false);
}

int classRep(int classNum, checkButtonList statsButtons) {
  // copy stats that are 'on' for images that are 'on' in selected into sdata
  // should be method associated with Dataset

  int nClassImagesOn = 0;
  for(int i=0; i<nImages; i++) { // how many images are on
    if (imgs[i].classNums[currentLegendIndex] == classNum) { 
      nClassImagesOn++;
    }
  }
  int nStatsOn = 0;
  for(int i=0; i<statsButtons.currentStates.length; i++) {//How many stats are on?
    if (statsButtons.currentStates[i]) {
      nStatsOn++;
    }
  }
  println("There are "+nStatsOn+" statistics currently on");
  println("And "+nClassImagesOn+" images for class "+classNum);

  Dataset cdata = new Dataset(nClassImagesOn,nStatsOn); // this is all a bit untidy
  int imgIndexes[] = new int[nClassImagesOn];
  int k=0;
  for(int i=0; i<nImages; i++) {
    if (imgs[i].classNums[currentLegendIndex] == classNum) {  
      int l=0;   
      for(int j=0; j<statsButtons.currentStates.length; j++) {
        if(statsButtons.currentStates[j]) {
          cdata.data[k][l++] = imgs[i].iStats[j];
        }
      }
      imgIndexes[k] = i;
      k++;
    }
  }
  // normalise if normalisation switch is on
  if (normaliseStatsButton.getState()) {
    cdata.normalise();
  }
  // calculate the mean vector
  cdata.calcMeanVector();
  cdata.printMeanVector();
  println("closest to mean "+cdata.closestToMean());
  // which is closest to mean vector?

  return imgIndexes[cdata.closestToMean()];
}

void calculateRepImages()
{ 
  println("Calculating high D rep images");
  // calculate the average for each class, based on the stats currently selected, with or without normalisation as selected.
  repImages = new int[classLegends[currentLegendIndex].nButtons];
  for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++) {
    repImages[i] =  classRep(i, selectedStatsButtons);
  }
}

void calculateRepImages3D()
{  
  println("Calculating 3D rep images");
  repImages = new int[classLegends[currentLegendIndex].nButtons];
  float[] minDist = new float[classLegends[currentLegendIndex].nButtons];
  int[] classSize = new int[classLegends[currentLegendIndex].nButtons];
  float[][] aveCoords = new float[classLegends[currentLegendIndex].nButtons][4];

  // calculate average point for each class
  for(int i=0; i<nImages; i++) {
    aveCoords[imgs[i].classNums[currentLegendIndex]][0] =  aveCoords[imgs[i].classNums[currentLegendIndex]][0]+1;

    aveCoords[imgs[i].classNums[currentLegendIndex]][1] =  aveCoords[imgs[i].classNums[currentLegendIndex]][1]+imgs[i].x3;
    aveCoords[imgs[i].classNums[currentLegendIndex]][2] =  aveCoords[imgs[i].classNums[currentLegendIndex]][2]+imgs[i].y3;
    aveCoords[imgs[i].classNums[currentLegendIndex]][3] =  aveCoords[imgs[i].classNums[currentLegendIndex]][3]+imgs[i].z3;
  }  
  for(int i=0;i<classLegends[currentLegendIndex].nButtons; i++) {
    for (int j=1; j<4; j++)
    {
      aveCoords[i][j] = aveCoords[i][j]/aveCoords[i][0];
    }
  }

  // find nearest image to average
  for(int i=0;i<classLegends[currentLegendIndex].nButtons; i++) {
    minDist[i] = 10e20;
  }
  for(int i=0; i<nImages; i++) {
    float d = dist(imgs[i].x3,imgs[i].y3,imgs[i].z3,aveCoords[imgs[i].classNums[currentLegendIndex]][1],
    aveCoords[imgs[i].classNums[currentLegendIndex]][2],aveCoords[imgs[i].classNums[currentLegendIndex]][3]);
    if (d < minDist[imgs[i].classNums[currentLegendIndex]]) {
      minDist[imgs[i].classNums[currentLegendIndex]] = d;
      repImages[imgs[i].classNums[currentLegendIndex]] = i;
    }
  }
}

color[] chooseColours(int nColours) 
{

  color[] defaultcolours = {
    #ffffff,#ff0000,#00ff00,#0000ff,#ffff00,#ff00ff,#00ffff,#808080,
    #008080,#808000,#800080,#800000,#008000,
    #084C9E,#007FFF,#7FFFD4,#228B22,#FF7F50,
    #FF77FF,#843179,#DC143C
  };  
  color[] colours;   
  println("Choosing colours for "+nColours+" classes");  
  if (nColours < 17) {
    colours = defaultcolours;
  }
  else {
    colours = new color[nColours];
    for(int i=0; i<nColours; i++)// thanks Rob!
    {
      float value = float(i+1)/nColours;
      if (value > 1.0) value = 1.0;

      float rcol = 1.0,gcol = 1.0,bcol = 1.0;
      if (value < 0.25) { 
        rcol = 0; 
        gcol = sqrt(4.0 * value);
      }
      else { 
        if (value < 0.5) { 
          rcol = 0; 
          bcol = sqrt(2.0 - value * 4.0);
        }
        else { 
          if (value < 0.75) { 
            rcol = sqrt(4.0 * value - 2.0); 
            bcol = 0;
          }
          else { 
            gcol = sqrt(1.0 + 4.0 * (0.75 - value)); 
            bcol = 0;
          }
        }
      }
      //println(i+" "+rcol+" "+gcol+" "+bcol);
      colours[i] = color(255*rcol,255*gcol,255*bcol);
    }
  }
  return colours;
}

void drawSpheres() {

  if ((justSelected != -1) && mouseHeld) {      
    pushMatrix();           
    scale(scaleData);
    stroke(50,0,0,50);
    if (!toggleDimButton.getState()) {
      translate(imgs[justSelected].x3, imgs[justSelected].y3, imgs[justSelected].z3);
      scale(1/(scaleData*res));
      noFill();
      sphereDetail(20);
      sphere(selectionRadius);
      sphereDetail(5);
    }
    else {
      translate(imgs[justSelected].x2, imgs[justSelected].y2);
      scale(1/(scaleData*res));
      fill(50,0,0,100);
      ellipse(0,0,2*selectionRadius,2*selectionRadius);
    }
    popMatrix();
  }

  if(sphereR > 0) {
    if(!toggleDimButton.getState()) {
      for(int i=0; i<nImages; i++) //3D case
      {
        if(classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
          noStroke();
          //println(colours[imgs[i].classNum]);

          fill(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
          pushMatrix(); 
          scale(scaleData);//!!
          translate(imgs[i].x3, imgs[i].y3, imgs[i].z3);
          scale(1/scaleData);
          sphere(sphereR);
          popMatrix();
        }
      }
    }
    else {

      for(int i=0; i<nImages; i++) // 2D case
      {      
        if(classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
          noStroke();
          //println(colours[imgs[i].classNum]);
          fill(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
          pushMatrix(); 
          scale(scaleData);//!!
          translate(imgs[i].x2, imgs[i].y2);
          scale(1/scaleData);
          sphere(sphereR);
          popMatrix();
        }
      }
    }
  }
}

void drawNNs() {
  strokeWeight(5);   
  smooth();  
  if(!toggleDimButton.getState()) {//3D
    for(int i=0; i<nImages; i++)
    {
      if(classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
        pushMatrix();
        //scale(scaleData);//!!
        //strokeWeight(5);        
        line(imgs[i].x3*scaleData,imgs[i].y3*scaleData,imgs[i].z3*scaleData,
             imgs[imgs[i].nnLow].x3*scaleData,imgs[imgs[i].nnLow].y3*scaleData,imgs[imgs[i].nnLow].z3*scaleData);
        //strokeWeight(1);        
        popMatrix();
      }
    }
  }
  else {
    for(int i=0; i<nImages; i++)
    {
      if(classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
        pushMatrix();
        //scale(scaleData);//!!
        line(imgs[i].x2*scaleData,imgs[i].y2*scaleData,imgs[imgs[i].nnLow].x2*scaleData,imgs[imgs[i].nnLow].y2*scaleData);
        popMatrix();
      }
    }
  }
 strokeWeight(1);

}

void drawnnHigh() {
  smooth();
  strokeWeight(5);                
  if(!toggleDimButton.getState()) {//3D
    for(int i=0; i<nImages; i++)
    {
      if(classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
        pushMatrix();
        //scale(scaleData);//!!               
        line(imgs[i].x3*scaleData,imgs[i].y3*scaleData,imgs[i].z3*scaleData,
             imgs[imgs[i].nnHigh].x3*scaleData,imgs[imgs[i].nnHigh].y3*scaleData,imgs[imgs[i].nnHigh].z3*scaleData);
        
        popMatrix();
      }
    }
  }
  else {
    for(int i=0; i<nImages; i++)
    {
      if(classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
        pushMatrix();
        //scale(scaleData);//!!
        line(imgs[i].x2*scaleData,imgs[i].y2*scaleData,imgs[imgs[i].nnHigh].x2*scaleData,imgs[imgs[i].nnHigh].y2*scaleData);
        popMatrix();
      }
    }
  }
  strokeWeight(1);
}

void drawConsecutive() {
  strokeWeight(5);   
  smooth();  
  // join consecutive images that are of same class
  if(!toggleDimButton.getState()) {//3D
    for(int i=0; i<nImages-1; i++)
    {
      if((classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]) &&
        (imgs[i].classNums[currentLegendIndex] == imgs[i+1].classNums[currentLegendIndex]))) {
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
        pushMatrix();
        //scale(scaleData);//!!
        line(imgs[i].x3*scaleData,imgs[i].y3*scaleData,imgs[i].z3*scaleData,
             imgs[i+1].x3*scaleData,imgs[i+1].y3*scaleData,imgs[i+1].z3*scaleData);
        popMatrix();
      }
    }
  }
  else {
    for(int i=0; i<nImages-1; i++)
    {
      if((classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]) &&
        (imgs[i].classNums[currentLegendIndex]== imgs[i+1].classNums[currentLegendIndex]))) {
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour);
        pushMatrix();
        //scale(scaleData);//!!
        line(imgs[i].x2*scaleData,imgs[i].y2*scaleData,imgs[i+1].x2*scaleData,imgs[i+1].y2*scaleData);
        popMatrix();
      }
    }
  }
  strokeWeight(1);   
}

void drawClassABLegend() {
  classAButtons.display();
  classBButtons.display();
  classesSelectedButton.display();
  textFont(font, 18); 
  fill(255);
  if (classDiffTest.finished) {
    classDiffTest.displayResult();
  }
  else {
    if (!classesSelectedButton.getState()) {
      text("<- Choose classes to compare ->", 150, 50);  
      text("Once selected click Finished",170,70);
      text("Or Statistical Test to exit stats mode",170,90); 

      fill(255);
      text("Enter number of randomisations:"+classDiffTest.repeats, 
      classAButtons.x, classAButtons.y+classAButtons.spacer*classAButtons.buttons.length+20);
      int xPos =  classAButtons.x + int(1+textWidth("Enter number of randomisations:"+classDiffTest.repeats));   
      drawBlinkBox(xPos,classAButtons.y+classAButtons.spacer*classAButtons.buttons.length+8, 10, 15);
    }  
    else {
      text("Calculating statistics ...", 150, 50);
    }
  }

  statsTestButton.display(); 
  normaliseStatsButton.display();
}
void drawCategoryLegend() {
  text("Select the category to visualise:", 150, 50);  
  textFont(font, 18); 
  fill(255);
  selectCategoryButton.display();
  categoryButtons.display();
}  

void drawStatsLegend() {

  normaliseStatsButton.display();
  invertStatsSelectedButton.display();
  selectStatsButton.display();

  selectedStatsButtons.display();
  textFont(font, 18); 
  fill(255);

  text("Select/De-Select statistics to use for Sammon Mapping", 150, 50);  
  text("Click 'Select Statistics' to finish selection",150,80); 
  text("After that you probably want to click the 'Sammon Map' button",150,110);
}

void drawLegend() {

  // controls buttons
  addClassButton.display();
  reclassifySelectedButton.display();
  selectedImagesOnlyButton.display();

  //selectWithRadius.display();
  deselectAllButton.display();
  toggleDimButton.display();
  nbrJoinButton.display(); 
  imagesNamesButton.display();
  saveDataButton.display();
  loadDataButton.display();
  if (!distance) { // if a distance matrix has been supplied, we cant do these things
    statsTestButton.display();
    selectStatsButton.display();
    normaliseStatsButton.display();  
    repImagesOnlyButton.display();
    repImagesOnButton.display();
    PCAButton.display();
    MCLButton.display();
  }  

  sammonButton.display();

  selectCategoryButton.display();

  // other text input for some states
  textFont(font, 18); 

  if (memoryLow) {
    fill(255);
    text("Warning: Memory Low. Some images might not be displayed.", width/4, 100);  
    text("This warning may go away after a few seconds otherwise try",width/4,130);    
    text("reducing image size with '-' key, and waiting a few seconds",width/4,160);
  }

  if (sammonButton.getState()) {
    fill(255);
    text("Doing Sammon Mapping ... current error term: "+sam.currentCloseness, width/4, 50);      
    text("Click Sammon Map Statistics button to stop", width/4, 80);
  }

  if(reclassifySelectedButton.getState()) {
    fill(255);
    text("<- Select the class to reclassify selected images to.", width/4, 50);
  }
  if(addClassButton.getState()) {
    fill(255);
    text("Enter new class name:"+newClassName, width/4, 70);
    int xPos = int(1+textWidth("Enter new class name:"+newClassName)+width/4);
    drawBlinkBox(xPos, 58, 10, 15);
  }  

  if(saveDataButton.getState()) {
    fill(255);
    text("Create/Select File to Write:"+newFileName, width/4, 70);
  }  


  fill(200);
  stroke(200);  
  int dim = 3;
  if (toggleDimButton.getState()) {
    dim = 2;
  }
  switch (nbrJoinButton.getState()) {
  case 0:
    break;
  case 1:
    text(nnSameClass+fileDelimeter+nImagesOn+" neighbours ("+dim+"D) have same class", width/4, height-20);
    break;
  case 2:
    text(nnHighSameClass+fileDelimeter+nImagesOn+" neighbours (all stats) have same class", width/4, height-20);
    break;
  case 3:
    text("Joining consecutive images in description file that are same class", width/4, height-20);
    break;
  }
}


void drawNames() {
  // this is really dumb and inefficient, but it's a prototype, right?
  textFont(font, 24); 
  if(!toggleDimButton.getState()) {//3D
    for(int i=0; i<nImages; i++)
    {
      if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]) == true) {
        pushMatrix(); 
        scale(scaleData);//!!
        translate(imgs[i].x3, imgs[i].y3, imgs[i].z3);
        scale(1/scaleData);
        scale(imageRes);
        if(!toggleDimButton.getState()) {//3D
          rotateY(-rotY);
        }
        float tw = textWidth(imgs[i].name)+10;
        fill(100);
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour,200);
        rect(sphereR,-20,tw+20,25);    
        fill(220);    
        text(imgs[i].name,sphereR+2,0);
        popMatrix();
      }
    }
  }
  else {//2D
    for(int i=0; i<nImages; i++)
    {
      if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]) == true) {
        pushMatrix(); 
        scale(scaleData);//!!
        translate(imgs[i].x2, imgs[i].y2);
        scale(1/scaleData);
        scale(imageRes);
        if(!toggleDimButton.getState()) {//3D
          rotateY(-rotY);
        }
        float tw = textWidth(imgs[i].name)+10;
        fill(100);
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour,200);
        rect(sphereR,-20,tw+20,25);    
        fill(220);    
        text(imgs[i].name,sphereR+2,0);
        popMatrix();
      }
    }
  }
}     

void drawImages() {
  // this is really dumb and inefficient, but it's a prototype, right?

  fill(255);
  for(int i=0; i<nImages; i++)
  {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
      pushMatrix(); 
      scale(scaleData);//!!
      if (toggleDimButton.getState()) {
        translate(imgs[i].x2, imgs[i].y2);
      } 
      else {
        translate(imgs[i].x3, imgs[i].y3, imgs[i].z3);
      }
      scale(1/scaleData);
      scale(imageRes);
      if (!toggleDimButton.getState()) {//3D
        rotateY(-rotY);
      }

      if (showMasks) {
        imgs[i].displayMask();
      }
      else {
        imgs[i].displayImg();
        //print("Trying to display image "+i+" with name "+imgs[i].name);
      }

      if (imgs[i].imageSupplied) {
        noFill();
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour,200); 
        rect(-1,-1,imgs[i].iWidth+1,imgs[i].iHeight+1);
        fill(255);
      }   


      popMatrix();
    }
  }
}   

void drawRepImages() {

  fill(255);  
  for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++)
  {
    if (classLegends[currentLegendIndex].getState(i)) {

      pushMatrix(); 
      scale(scaleData); //!!
      if (toggleDimButton.getState()) {
        translate(imgs[repImages[i]].x2, imgs[repImages[i]].y2);
      }
      else {
        translate(imgs[repImages[i]].x3, imgs[repImages[i]].y3, imgs[repImages[i]].z3);
      }
      scale(1/scaleData);
      scale(imageRes);
      if (!toggleDimButton.getState()) {//3D
        rotateY(-rotY);
      }
      imgs[repImages[i]].displayImg();
      noFill();
      stroke(classLegends[currentLegendIndex].buttons[i].fgColour,200); 
      rect(-1,-1,imgs[repImages[i]].iWidth+1,imgs[repImages[i]].iHeight+1);
      fill(255);
      popMatrix();
    }
  }
}   

void drawRepImagesOnly() {
  // this is really dumb and inefficient, but it's a prototype, right?
  //textFont(font, 24); 

  fill(255);  
  int maxX = 0;
  int maxY = 0;
  int numOn = 0;

  for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++) {
    if (classLegends[currentLegendIndex].getState(i)) {
      if (imgs[repImages[i]].iWidth > maxX) {
        maxX = imgs[repImages[i]].iWidth;
      }   
      if (imgs[repImages[i]].iHeight > maxY) {
        maxY = imgs[repImages[i]].iHeight;
      }
      numOn++;
    }
  }
  maxX = int(imageRes*(maxX+20));
  maxY = int(imageRes*(maxY+20));
  int sqr = ((int) sqrt(numOn))+1;

  int k = 0;
  for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++) {
    if (classLegends[currentLegendIndex].getState(i)) {
      pushMatrix(); 

      scale(1/res);
      translate(-0.8*width/2,-0.8*height/2);
      translate((k % sqr)*maxX,(k / sqr) * maxY, 0);
      scale(imageRes);

      imgs[repImages[i]].displayImg();

      noFill();
      stroke(classLegends[currentLegendIndex].buttons[i].fgColour,200);

      rect(-1,-1,imgs[repImages[i]].iWidth+1,imgs[repImages[i]].iHeight+1);
      fill(255);
      stroke(200);
      textFont(font, 10); 
      text(classLegends[currentLegendIndex].buttons[i].name+":"+imgs[repImages[i]].name,0,-3);
      popMatrix();        
      k++;
    }
  }
}   

void drawSelectedImagesOnly() {
  // this is really dumb and inefficient, but it's a prototype, right?

  fill(255);  
  int maxX = 0;
  int maxY = 0;
  int nSelected = 0;

  for(int i=0; i<nImages; i++)
    if (imgs[i].selected && classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]))
    {
      if (imgs[i].iWidth > maxX) {
        maxX = imgs[i].iWidth;
      }   
      if (imgs[i].iHeight > maxY) {
        maxY = imgs[i].iHeight;
      } 
      nSelected++;
    }
  maxX = int(imageRes*(maxX+20));
  maxY = int(imageRes*(maxY+20));
  if (nSelected > 0) {
    //print("# selected is " + nSelected);
    int sqr = ((int) sqrt(nSelected))+1;
    int counter = 0;
    for(int i=0; i<nImages; i++) {
      if (imgs[i].selected && classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]))
      {

        pushMatrix(); 

        scale(1/res);
        translate(-0.8*width/2,-0.8*height/2);
        translate((counter % sqr)*maxX,(counter / sqr) * maxY, 0);
        scale(imageRes);

        imgs[i].displayImg();
        noFill();
        stroke(classLegends[currentLegendIndex].buttons[imgs[i].classNums[currentLegendIndex]].fgColour,200); 
        rect(-1,-1,imgs[i].iWidth+1,imgs[i].iHeight+1);
        fill(255);
        stroke(200);
        textFont(font, 12); 
        text(imgs[i].name,0,-3);
        popMatrix(); 
        counter++;
      }
    }
  }
}

int imageUnderMouse() {// return the index of the visible foreground image under coords x,y
  float minZ = 10e20;
  int fgImage = -1;
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]) && imgs[i].underMouse() && (imgs[i].mz0 <= minZ)) { 
      fgImage = i;
      minZ = imgs[i].mz0;
    }
  }
  return fgImage;
}

void deselectAllImages() {
  for(int i=0; i<nImages; i++) {
    imgs[i].selected = false;
    imgs[i].inSelection = false;
  }
}

void selectWithinRadius(int centerImg,int radialImg) { // OBSOLETE
  // the last two images selected define the centre and radius of a circle/sphere
  // all images within that sphere are selected/deselected
  //selectWithRadius.setState(false);
  float radius;
  if(toggleDimButton.getState()) {
    radius = dist(imgs[centerImg].x2,imgs[centerImg].y2,imgs[radialImg].x2,imgs[radialImg].y2);
  }
  else {
    radius = dist(imgs[centerImg].x3,imgs[centerImg].y3,imgs[centerImg].z3,imgs[radialImg].x3,imgs[radialImg].y3,imgs[radialImg].z3);
  }

  for(int j=0; j<nImages; j++) {
    if (classLegends[currentLegendIndex].getState(imgs[j].classNums[currentLegendIndex])) {
      float dist2;
      if(toggleDimButton.getState()) {
        dist2 = dist(imgs[centerImg].x2,imgs[centerImg].y2,imgs[j].x2,imgs[j].y2);
      }
      else {
        dist2 = dist(imgs[centerImg].x3,imgs[centerImg].y3,imgs[centerImg].z3,imgs[j].x3,imgs[j].y3,imgs[j].z3);
      }
      if(dist2 <= radius) {
        imgs[j].selected = true;
      }
    }
  }
} 

void mousePressed() {

  mouseHeld = true; 
  mouseXpress = mouseX;
  mouseYpress = mouseY;

  if (!sammonButton.getState()) {// no fiddling with selected classes if we're sammon mapping!
    int c = classLegends[currentLegendIndex].clicked(mouseX,mouseY); 
    if (c != -1) {
      if (reclassifySelectedButton.getState()) {
        classLegends[currentLegendIndex].flipState(c); //undo the selection
        for(int j=0; j<nImages; j++) { 
          if (imgs[j].selected && classLegends[currentLegendIndex].getState(imgs[j].classNums[currentLegendIndex])) {
            imgs[j].reclassify(c,classLegends[currentLegendIndex].buttons[c].name);
          }
        }
        deselectAllImages();   
        reclassifySelectedButton.setState(false);
      }
      visibleClassesOrStatsChanged(false);
    }
  }

  if ((mouseButton == RIGHT ) &&  !(selectedImagesOnlyButton.getState() || repImagesOnlyButton.getState())) {
    // check which image, if any is under the mouse and select/deselect it
    int fgImage = imageUnderMouse();
    if (fgImage != -1) {
      imgs[fgImage].selected = ! imgs[fgImage].selected;
      if (imgs[fgImage].selected) {
        justSelected = fgImage;
        println("Just selected:"+justSelected);
      }
    }
  }
  else {
    if (selectCategoryButton.getState()) {//we're in category selection mode
      selectCategoryButton.press(mouseX,mouseY);
      int cat = categoryButtons.clicked(mouseX,mouseY);
      if (cat != -1) {
        selectCategoryButton.setState(false);
        categoryButtons.buttons[cat].setState(false);
        currentLegendIndex = cat;
        // turn on all image classes to visible
        for(int i=0; i<classLegends[currentLegendIndex].nButtons; i++)
          classLegends[currentLegendIndex].setState(i,true);
      }
    }
    else 
      if (!distance && selectStatsButton.getState()) { // we're in stats selection mode.
      normaliseStatsButton.press(mouseX,mouseY);
      if (invertStatsSelectedButton.press(mouseX,mouseY)) {
        selectedStatsButtons.flipAllStates();
      }
      if (!distance && selectStatsButton.press(mouseX,mouseY)) {
        visibleClassesOrStatsChanged(true);
      }
      selectedStatsButtons.clicked(mouseX,mouseY);
    }
    else {
      boolean pressed = statsTestButton.press(mouseX,mouseY);
      if (!distance && statsTestButton.getState()) {
        if (pressed) {
          // this is a bit stupid, but we need something initialised so we can decide what to draw for the legend
          initClassABbuttons();  
          classDiffTest = new DiffTest(classAButtons,classBButtons);
        }
        normaliseStatsButton.press(mouseX,mouseY);
        classAButtons.clicked(mouseX,mouseY);
        classBButtons.clicked(mouseX,mouseY);
        if (classesSelectedButton.press(mouseX,mouseY) && classesSelectedButton.getState()) {
          classDiffTest.updateButtons(classAButtons,classBButtons);
          classDiffTest.finished = false;
        }
      }
      else {   
        if (!distance) {
          selectStatsButton.press(mouseX,mouseY);
        }
        selectCategoryButton.press(mouseX,mouseY);

        if(sammonButton.press(mouseX,mouseY)) {
          if (sammonButton.getState()) {
            if (nbrJoinButton.getState() == 1) {
              nbrJoinButton.setState(0);
            }//turn of low d NN's
            if (!distance && normaliseStatsButton.getState()) {
              hdata.normalise();
            }
            if (hdata.dimension == ldata.dimension) {// no mapping actually required, though maybe normalisation
              copyToCoords(hdata);
              sammonButton.setState(false);
            }
            else {
              frameRate = 5;
              sam = new sammonMap(distance,hdata, ldata);
            }
          }
          else {
            frameRate = 10;
          }
        }

        imagesNamesButton.press(mouseX,mouseY);
        addClassButton.press(mouseX,mouseY);  
        reclassifySelectedButton.press(mouseX,mouseY); 

        saveDataButton.press(mouseX,mouseY);
        loadDataButton.press(mouseX,mouseY);      
        if (!distance && normaliseStatsButton.press(mouseX,mouseY)) { 
          visibleClassesOrStatsChanged(false);
        }

        if (toggleDimButton.press(mouseX,mouseY)) {
          visibleClassesOrStatsChanged(false);
        }

        if (nbrJoinButton.press(mouseX,mouseY)) {
          if (nbrJoinButton.getState() == 1) {
            calculateLowDNearestNeighbours();
          }
        }

        if (!distance && repImagesOnButton.press(mouseX,mouseY)) {
          calculateRepImages();
        } 

        if (!distance && PCAButton.press(mouseX,mouseY)) {
          PCAmap();
          PCAButton.flipState();
        }

        if (MCLButton.press(mouseX,mouseY)) {
          markov_cluster();
          MCLButton.flipState();
        }

        if (!distance && repImagesOnlyButton.press(mouseX,mouseY)) {
          calculateRepImages();
          if (repImagesOnlyButton.getState()) {
            saveD = toggleDimButton.getState();
            toggleDimButton.setState(true);
          }
          else {
            toggleDimButton.setState(saveD);
          }
          if (!distance && repImagesOnlyButton.getState()) {
            calculateRepImages();
          }
          initVars();
        }
        /*
      if (selectWithRadius.press(mouseX,mouseY)){
         selectWithinRadius(lastSelected,justSelected); 
         }
         */
        if (selectedImagesOnlyButton.press(mouseX,mouseY)) {
          if (selectedImagesOnlyButton.getState()) {
            saveD = toggleDimButton.getState();
            toggleDimButton.setState(true);
          }
          else {
            toggleDimButton.setState(saveD);
          }
          initVars();
        }

        if(deselectAllButton.press(mouseX,mouseY)) {
          deselectAllImages();
          deselectAllButton.setState(false);
        }
      }
    }
  }
}

void visibleClassesOrStatsChanged(boolean statsChanged) {
  // when what is visible has changed we need to do a few things 
  println("Visible classes changed, updating stats distances, neighbours etc");

  if (distance) {// if were using a distance matrix, selectedStatsButtons that are on are just the visible images
    for(int i=0; i<nImages; i++) {// check which images are on
      if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {      
        selectedStatsButtons.setState(i,true);
      }   
      else {
        selectedStatsButtons.setState(i,false);
      }
    }
  }  

  hdata = statsDataCopy(classLegends[currentLegendIndex],selectedStatsButtons);
  if(!distance && normaliseStatsButton.getState()) {
    hdata.normalise(); 
    println("  Normalising data ...");
  }

  ldataInit();
  calculateLowDNearestNeighbours();
  if(statsChanged || distance) {
    calculateStatsDistances(selectedStatsButtons);
  }
  calculateHighDNearestNeighbours();
}

void mouseWheel(MouseEvent event) {
  float e = event.getAmount()*2;
  //print(e);println("x"+mouseButton);
  //println(key);
  if (!mouseHeld) {    
        res += resDiff * e*-1;  
        resDiff = res/20;
      }
      else {
        if ((keyCode == SHIFT)) {
          sphereR -= sphereDiff * e;
          //keyCode = 0;
        } 
        else if ((keyCode == CONTROL)) {
          imageRes -= imageResDiff * e * 4;
        }
      }
}


void wheelMouseSetup()
{ // only needed for old processing versions
  addMouseWheelListener(new java.awt.event.MouseWheelListener() {
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent e) { 
      //println( e.getWheelRotation()); 
      if (!mouseHeld) {    
        res += resDiff * e.getWheelRotation()*-1;  
        resDiff = res/20;
      }
      else {
        if (mouseButton == LEFT) {
          sphereR -= sphereDiff * e.getWheelRotation();
        } 
        else if (mouseButton == RIGHT) {
          imageRes -= imageResDiff * e.getWheelRotation() * 4;
        }
      }
    }
  }
  );
}

void mouseDrag() {
  if (mouseButton == LEFT) {  
    if (( (imagesNamesButton.getState() == 1)) && !(selectedImagesOnlyButton.getState() || repImagesOnlyButton.getState())) { 
      // do pop up of image under mouse 
      int fgImage = imageUnderMouse();
      if ((fgImage != -1) && (imgs[fgImage].imageSupplied)) {
        pushMatrix();
        scale(1/res);
        translate(width/2-imgs[fgImage].iWidth,-height/2,2);
        imgs[fgImage].displayImg();   
        fill(220);    
        textFont(font, 14);
        text(imgs[fgImage].name,10,20);
        popMatrix();
      }
    }
    // translate/rotate as required.
    if(!toggleDimButton.getState()) {// 3D case 
      if (abs(mouseY-pmouseY) > 5) {
        transY = transY - 2*(mouseY-pmouseY);
      }
      if (abs(mouseX-mouseXpress) > 10) {
        rotY -= 0.005*angleYDiff*(mouseX-mouseXpress);
      }
    }
    else {
      // 2D case
      if (shiftHeld) {  // this is for drag/drop in 2D
        int fgImage = imageUnderMouse();
        if (fgImage != -1) { 
          if ((abs(mouseX-pmouseX) > 1) || (abs(mouseY-pmouseY) > 1)) {
            imgs[fgImage].x2 += (mouseX-pmouseX)/(scaleData*res); 
            imgs[fgImage].y2 += (mouseY-pmouseY)/(scaleData*res);
          }
        }
      }
      else {
        if (abs(mouseY-pmouseY) > 5) {
          yPos = yPos + 2*(mouseY-pmouseY);
        }
        if (abs(mouseX-pmouseX) > 5) {
          xPos = xPos + 2*(mouseX-pmouseX);
        }
      }
    }
  }

  if (mouseButton == RIGHT) {
    if (!(selectedImagesOnlyButton.getState() || repImagesOnlyButton.getState())) {
      // check which image, if any is under the mouse and select/deselect it
      if (mouseHeld && (justSelected != -1) && ((abs(mouseX-pmouseX) > 1) || (abs(mouseY-pmouseY) > 1))) {
        selectionRadius = sqrt((mouseX-imgs[justSelected].mx0)*(mouseX-imgs[justSelected].mx0)
          +(mouseY-imgs[justSelected].my0)*(mouseY-imgs[justSelected].my0));
        checkImagesInRegion();
      }
    }
  }
}

void checkImagesInRegion() {
  float r = selectionRadius/(scaleData*res);
  if ((selectionRadius > 0) && (justSelected != -1)) {
    if (!toggleDimButton.getState()) { // 3D case
      for(int j=0; j<nImages; j++) {
        if (classLegends[currentLegendIndex].getState(imgs[j].classNums[currentLegendIndex])) {
          if(sqrt((imgs[j].x3-imgs[justSelected].x3)*(imgs[j].x3-imgs[justSelected].x3)
            +(imgs[j].y3-imgs[justSelected].y3)*(imgs[j].y3-imgs[justSelected].y3)
            +(imgs[j].z3-imgs[justSelected].z3)*(imgs[j].z3-imgs[justSelected].z3)) 
            < r) {
            imgs[j].inSelection = true;
          }
          else {
            imgs[j].inSelection = false;
          }
        }
      }
    } 
    else { // 2D case
      for(int j=0; j<nImages; j++) {
        if (classLegends[currentLegendIndex].getState(imgs[j].classNums[currentLegendIndex])) {
          if(sqrt((imgs[j].x2-imgs[justSelected].x2)*(imgs[j].x2-imgs[justSelected].x2)
            +(imgs[j].y2-imgs[justSelected].y2)*(imgs[j].y2-imgs[justSelected].y2))
            < r) {
            imgs[j].inSelection = true;
          }
          else {
            imgs[j].inSelection = false;
          }
        }
      }
    }
  }
}

void selectImagesInRegion() {
  for(int j=0; j<nImages; j++) {
    if (classLegends[currentLegendIndex].getState(imgs[j].classNums[currentLegendIndex])) {
      if(imgs[j].inSelection) {
        imgs[j].selected = true;
        imgs[j].inSelection = false;
      }
    }
  }
}

void mouseReleased() {


  // find which images are within this radius of just selected
  justSelected = -1;
  selectionRadius = -1; 
  selectImagesInRegion();
  mouseHeld = false;
}

void keyReleased() {
  shiftHeld = false; 
  println("Shift released");
}

void keyPressed()
{

  if (statsTestButton.getState() && !classDiffTest.finished && !classesSelectedButton.getState()) {// trap text input for name of new class
    char k;
    k = (char)key;
    switch(k) {
    case 8:
      if(classDiffTest.repeats.length()>0) {// backspace
        classDiffTest.repeats = classDiffTest.repeats.substring(0,classDiffTest.repeats.length()-1);
      }
      break;

      // Avoid special keys
    case 65535:
    case 127:
    case 27:
      break;
    case 10: //LF   
      classDiffTest.nRepeats = int(classDiffTest.repeats); // this is untidy
      break;
    case 13: // enter/return   
      classDiffTest.nRepeats = int(classDiffTest.repeats);
      break;
    default:
      classDiffTest.repeats=classDiffTest.repeats+k;
      break;
    }
    classDiffTest.nRepeats = int(classDiffTest.repeats);
    //println(classDiffTest.nRepeats+":"+classDiffTest.repeats);
  }
  else if (addClassButton.getState()) {// trap text input for name of new class
    char k;
    k = (char)key;
    switch(k) {
    case 8:
      if(newClassName.length()>0) {// backspace
        newClassName = newClassName.substring(0,newClassName.length()-1);
      }
      break;

      // Avoid special keys
    case 65535:
    case 127:
    case 27:
      break;
    case 10: //LF   
      addClass(newClassName);
      newClassName = "";  
      break;
    case 13: // enter/return   
      addClass(newClassName);
      newClassName = "";
      break;
    default:
      newClassName=newClassName+k;
      break;
    }
    println(newClassName);
  }  
  else {
    if(!toggleDimButton.getState()) {
      if( key == 'a') { 
        rotY += angleYDiff;
      }
      if( key == 'd') { 
        rotY -= angleYDiff;
      }
      if( key == 'w') { 
        transY += transYDiff;
      }
      if( key == 's') { 
        transY -= transYDiff;
      }
    }
    else {
      if( key == 'a') { 
        xPos += xPosDiff;
      }
      if( key == 'd') { 
        xPos -= xPosDiff;
      }
      if( key == 'w') { 
        yPos += yPosDiff;
      }
      if( key == 's') { 
        yPos -= yPosDiff;
      }
      if( keyCode == SHIFT) { 
        shiftHeld = true; 
        println("Shift held");
      } // used to move images with mouse in 2D
    }

    if( key == 'r') { 
      res += resDiff; 
      resDiff = res/40;
    }
    if( key == 'f') { 
      res -= resDiff; 
      resDiff = res/40;
    }    
    //if( key == '-') { imageRes -= imageResDiff;}
    //if( key == '=') { imageRes += imageResDiff;}

    if( key == '-') { 
      rescaleImages(1);
    } // reload images at new resolution for viewing
    if( key == '+') { 
      rescaleImages(-1);
    }

    if( key == 't') { 
      sphereR += sphereDiff;
    }
    if( key == 'g') { 
      sphereR -= sphereDiff;
    }

    if( key == '.') { 
      sammonButton.flipState();
      if(sammonButton.getState()) {
        sam = new sammonMap(distance, hdata, ldata);
      }
    }
    if( key == '/') {// randomise the coords
      for(int i=0; i<nImages; i++) {
        if(toggleDimButton.getState()) {
          imgs[i].randCoords(2);
        } 
        else {
          imgs[i].randCoords(3);
        }
      }
      ldataInit();
    }

    //if(key == ' ') {labelToggle = (labelToggle+1)%3;}
    /*
    if(key == '2') {
     repImagesOnlyButton.setState(true);
     fileName = twoDfileName;
     initVars();
     readData();
     }
     if(key == '3') {
     repImagesOnlyButton.setState(false);
     fileName = threeDfileName;
     initVars();
     readData();
     }
     */
    //if(key == 'n'){
    //  nnDraw = (nnDraw + 1) % 3;
    //  calculateLowDNearestNeighbours();
    //}
    if(key == 'l') {
      lightsOn = !lightsOn;
    }

    if(key == 'm') {
      showMasks = !showMasks;
    }

    if(key == 'p') {
      saveframe = true;
    }

    if(key == 'c') {
      calculateStatsAndStandardise();
    }

    if(key == 'L') {
      showLegend = !showLegend;
    }
  }
}


void rescaleImages(int scaleDiff) {
  iScale = iScale + scaleDiff;
  println("Rescaling images");
  if (iScale < 1) {
    iScale = 1; // maximum real resolution
  } 
  else {
    // null all of the images, they'll then be reloaded at new scale as required
    for(int i=0; i<nImages; i++) {
      imgs[i].img = null; 
      imgs[i].msk = null;
    }
  }
  //memoryLow = false;
}

class iData { // all the data associated with an image
  // implement nn as a method?
  PImage img; // scaled image
  PImage msk; // scale threshold image
  boolean memoryWasLow = false; // flags if memory was low when trying to load image, and hence image was not loaded

  String name;
  String nameMask;
  boolean imageSupplied; // true if user has supplied a png image
  boolean userMask; // true when user has supplied an image mask
  //String type;
  //int classNum;
  String[] classNames; // list of classes that image belongs to
  int[] classNums;       // and their numbers
  int nCategories;

  int iWidth; // image width and height
  int iHeight;

  float x3,y3,z3; // 3D coords
  float x2,y2;// 2D coords
  // mode view coordinates
  float mx0; // top left corner of image
  float my0;
  float mz0; 
  float mxc; // bottom right corner of image
  float myc;
  float mzc; 
  boolean underMouse;
  boolean selected = false;
  boolean inSelection = false; // whether it's currently in a region selection
  boolean representative; // not yet implemented this way
  boolean visible; // not yet implemented

  int nnLow; // Neighbour in 2D/3D
  int nnHigh; // Neighbour in high dimensions

  float[] iStats; // complete stats vector
  int iMean;
  int iMode;
  int iMedian;
  float iVariance;
  int iMaskMean;
  float iMaskVariance;

  iData(String nameIn, String[] maskAndClasses) {
    // initialise name and the classes the image belongs to.
    img = null;
    name = trim(nameIn);

    if (match(name, ".png|.PNG|.tif|.TIF|.TIFF|.tiff") != null) {
      imageSupplied = true;
    }
    else {
      imageSupplied = false;
      imagesNamesButton.setState(2);
      iWidth = 50;
      iHeight = 50;
    }

    String classList[];

    if ((maskAndClasses.length > 1) && (match(maskAndClasses[0], ".png|.PNG|.tif|.TIF|.TIFF|.tiff") != null)) {// first entry is mask name
      nameMask = trim(maskAndClasses[0]); // there is a user supplied mask to use
      userMask = true;  
      classList = subset(maskAndClasses,1,maskAndClasses.length-1);
      println("Users mask:"+nameMask);
    }
    else {
      userMask = false; 
      classList = maskAndClasses;
    }

    checkAndConvertImageTypes();

    classNames = new String[classList.length];
    classNums = new int[classList.length]; // we fill in the numbers later.
    nCategories = classNums.length;

    for(int i=0; i<classList.length; i++) {
      classNames[i] = trim(classList[i]);
      //println("  Classes"+classList[i]);
    }
  }

  void addCategory(int catNum, String catName) {
    nCategories++;
    classNums = expand(classNums,nCategories);
    classNums[nCategories-1] = catNum;
    classNames = (String[])expand(classNames,nCategories);
    classNames[nCategories-1] = catName;
  }

  void checkAndConvertImageTypes() {
    // check if the image or mask is tif. If so creates pngs of same name
    String[] m = match(name, "(.*)(.tif|.TIF|.tiff|.TIFF)");
    if ((m != null) && (m.length == 3)) {
      //println("Matched "+m[0]); 
      println("Converting image "+name+" to png");
      PlanarImage image1 = JAI.create("fileload", defaultDirectory+fileDelimeter+name);
      RenderedOp op = JAI.create("filestore", image1, defaultDirectory+fileDelimeter+m[1]+".png", "png");
      name = m[1]+".png";
    }
    if ((nameMask != null) && (match(nameMask, ".tif|.TIF|.tiff|.TIFF") != null)) {
      m = match(nameMask, "(.*)(.tif|.TIF|.tiff|.TIFF)");
      if ((m != null) && (m.length == 3)) {
        //println("Matched "+m[0]); 
        println("Converting image "+nameMask+" to png");
        PlanarImage image1 = JAI.create("fileload", defaultDirectory+fileDelimeter+name);
        RenderedOp op = JAI.create("filestore", image1, defaultDirectory+fileDelimeter+m[1]+".png", "png");
        nameMask = m[1]+".png";
      }
    }
  }

  void displayImg() { 
    if (imageSupplied) { 
      if (img == null || memoryWasLow) {
        loadAndScaleImage(name,iScale);
      }
      if (((selected && !selectedImagesOnlyButton.getState()) || inSelection) ) {
        tint(255,0,0);
      }
      image(img, 0, 0);
      //println("got here: "+name+" "+img.width+" "+img.height);
      noTint();
    }
    else {
      fill(255);
      if ((selected && !selectedImagesOnlyButton.getState())|| inSelection) {
        fill(255,0,0);
      }
      stroke(150,200); 
      rect(0,0,iWidth,iHeight); 
      noTint();
      //println("Got here");
    }
    recordView();
  }

  void loadAndScaleImage(String imageName, int scaleFactor) {

    // check if memory is getting low
    //long maxMem = Runtime.getRuntime().maxMemory();
    //long allocMem = Runtime.getRuntime().totalMemory();
    long freeMem = Runtime.getRuntime().freeMemory();
    //println("Allocated: "+allocMem+"   Max: "+maxMem + " Free: "+freeMem+" Low :"+memoryLow);
    memoryLow = ((freeMem) < 20000000); // flag low memory, only 20M left
    memoryWasLow = memoryLow;
    if (!memoryLow) {
      println("Loading image "+imageName+" from file");
      img = loadImage(defaultDirectory+fileDelimeter+imageName);
    }
    else {
      //println("Memory low: did not load "+imageName);
    }
    if ((img == null) || memoryLow) {
      errorFlag = true;
      errorMessage = "Could not load image "+imageName+"\n";
      img = createImage(40,40,RGB); // make a small image with an X on it
      for(int i=0; i<40; i++) {
        img.pixels[i+40*i] =color(255,0,0);
        img.pixels[40*i - i] = color(255,0,0);
      }          
      iWidth = 40;
      iHeight = 40;
    }
    else {
      int newWidth = img.width/scaleFactor; 
      if (iScale != 1) {
        img.resize(newWidth,0);
      }
      iWidth = img.width;
      iHeight = img.height;
    }
  }



  void displayMask() {
    if (msk == null) {
      createScaleMask(iScale);
    }
    if (selected) {
      tint(255,0,0);
    }
    image(msk, 0, 0);
    noTint();
    recordView();
  }

  void recordView() { // records coords of image within current reference frame

    mx0 = screenX(0,0,0);
    my0 = screenY(0,0,0);
    mz0 = screenZ(0,0,0);   
    if (imageSupplied) {  
      mxc = screenX(img.width,img.height,0);
      myc = screenY(img.width,img.height,0);
      mzc = screenZ(img.width,img.height,0);
    }
    else {
      mxc = screenX(imageRes*30,imageRes*30,0);
      myc = screenY(imageRes*30,imageRes*30,0);
      mzc = screenZ(imageRes*30,imageRes*30,0);
    }
  } 

  boolean underMouse() {// is the image under the mouse?
    underMouse = false;
    if(classLegends[currentLegendIndex].getState(classNums[currentLegendIndex])) { // this should use .visible when it gets implemented 
      if ((mx0 < mouseX) && (mouseX < mxc) 
        && (my0 < mouseY) && (mouseY < myc)) {
        underMouse = true;
      }
    }
    return underMouse;
  }

  void randCoords(int dim) {// randomise the 2D/3D coords
    if(dim == 3) {
      x3 = (float) random(-1.0,1.0);//*scaleData;
      y3 = (float) random(-1.0,1.0);//*scaleData;
      z3 = (float) random(-1.0,1.0);//*scaleData;
    }
    else {
      x2 = (float) random(-1.0,1.0);//*scaleData;
      y2 = (float) random(-1.0,1.0);//*scaleData;
    }
  }

  void reclassify(int newClassNum, String newType) {
    classNums[currentLegendIndex] = newClassNum;
    classNames[currentLegendIndex] = newType;
    println("Reclassifying image "+name+" to "+newType);
  }


  //
  // functions used by mask stats and hopefully nothing else
  //   

  int imgMean(PImage tmpImg) {
    iMean = 0;
    for (int i=0; i<tmpImg.pixels.length; i++)
    {
      iMean += brightness(tmpImg.pixels[i]);
    }
    iMean /= tmpImg.pixels.length;
    return iMean;
  }

  float imgVariance(PImage tmpImg) {
    imgMean(tmpImg);
    iVariance = 0; 

    for (int i=0; i<tmpImg.pixels.length; i++)
    {
      iVariance += (brightness(tmpImg.pixels[i])-iMean)*(brightness(tmpImg.pixels[i])-iMean);
    }
    iVariance /= tmpImg.pixels.length;
    return iVariance;
  }

  int imgMode(PImage tmpImg) {// most common intensity
    int[] iCount = new int[256];
    for (int i=0; i<tmpImg.pixels.length; i++)
    {
      iCount[int(brightness(tmpImg.pixels[i]))] += 1;
    }
    int maxCount = 0;
    for (int i=0; i<256; i++)
    {
      if (iCount[i] > maxCount) {
        iMode = i; 
        maxCount = iCount[i];
      }
    }
    return iMode;
  }

  int imgMedian(PImage tmpImg) {// median intensity
    int[] iCount = new int[256];
    for (int i=0; i<tmpImg.pixels.length; i++)
    {
      iCount[int(brightness(tmpImg.pixels[i]))] += 1;
    }
    int count = 0;
    iMedian = 0;
    for (int i=0; i<256; i++)
    {
      count += iCount[i];
      if (count <= tmpImg.pixels.length/2) {
        iMedian = i;
      }
    }
    return iMedian;
  }

  PImage createOrLoadMask(PImage tmpImg) {
    // create mask for stats calculations. If user supplied, loads from file
    PImage tmpMsk;
    if (userMask) {
      tmpMsk = loadImage(defaultDirectory+fileDelimeter+nameMask);
      //tmpMsk.filter(BLUR,2);
    }
    else {
      println("Creating mask for image "+name);
      tmpMsk = tmpImg.get(); 
      //createImage(tmpImg.width, tmpImg.height, RGB);

      imgVariance(tmpImg);
      imgMode(tmpImg);

      tmpMsk.filter(BLUR,2);  
      //tmpMsk.filter(THRESHOLD, iMode+0.9*sqrt(iVariance));
      float stdev09 = 0.9*sqrt(iVariance);
      for(int i=0; i < tmpMsk.pixels.length; i++) {
        if (brightness(tmpMsk.pixels[i]) > iMode+stdev09) { 
          tmpMsk.pixels[i] = color(255);
        }
        else {
          tmpMsk.pixels[i] = color(0);
        }
      }
    }      
    return tmpMsk;
  }

  void createScaleMask(int scaleFactor) {
    // really dumb img scaling
    // should use processing image scaling as for non-mask images above
    println("Scaling mask for image "+name);
    PImage tmpImg = loadImage(defaultDirectory+fileDelimeter+name);
    PImage tmpMsk = createOrLoadMask(tmpImg);

    int newWidth = tmpImg.width/scaleFactor;
    int newHeight = tmpImg.height/scaleFactor;

    msk = createImage(newWidth, newHeight, RGB);
    for(int i=0; i<newWidth; i++) {
      for(int j=0; j<newHeight; j++) {
        msk.pixels[i+j*newWidth] = tmpMsk.pixels[scaleFactor*(i+j*tmpImg.width)];
      }
    }
  }

  int maskMean(PImage tmpImg, PImage tmpMsk) {// calculate the mean intensity of the image over the mask area
    int count = 0;
    int sum = 0;
    for(int i=0; i < tmpMsk.pixels.length; i++) {
      if (brightness(tmpMsk.pixels[i]) != 0) {
        sum += brightness(tmpImg.pixels[i]);    
        count++;
      }
    }
    if (count == 0) {
      iMaskMean = 0;
    }
    else {
      iMaskMean = sum/count;
    }
    return iMaskMean;
  }

  float maskVariance(PImage tmpImg, PImage tmpMsk) {// calculate the variance of intensity of the image over the mask area
    maskMean(tmpImg,tmpMsk);
    iMaskVariance = 0; 
    int count = 0;
    for (int i=0; i<tmpImg.pixels.length; i++) {
      if (brightness(tmpMsk.pixels[i]) != 0) {
        iMaskVariance += (brightness(tmpImg.pixels[i])-iMaskMean)*(brightness(tmpImg.pixels[i])-iMaskMean);
        count++;
      }
    }
    if (count == 0) { 
      iMaskVariance = 0;
    }
    else { 
      iMaskVariance /= count;
    }

    return iMaskVariance;
  }

  void clearStats() {
    iStats = null;
  }

  void copyStats(float stats[]) {
    iStats = new float[stats.length]; 
    for(int i=0; i<stats.length; i++) {
      iStats[i] = stats[i];
    }
  }
  void printStats() {
    for(int i=0; i<iStats.length; i++) {
      print(iStats[i]+" ");
    }
    println();
  }

  void jiggleStat() {
    // for sammon mapping, if two images have same stats it's trouble.
    // this jiggles one of the coordingates by +/-0.1% to fix this
    int stat = int(random(iStats.length - 1)); // pick random stat.
    float jiggle = random(-0.001,0.001);
    iStats[stat] += jiggle*iStats[stat];
  }

  void calcTASstats() {
    println("Calculating TAS stats for:"+name);
    int index;
    if (iStats == null) {
      iStats = new float[27]; 
      index = 0;
    }
    else { // add to the end of the array 
      index = iStats.length;
      iStats = expand(iStats, index + 27);
    }
    println("Calculating TAS stats for image "+name);
    PImage tmpImg = loadImage(defaultDirectory+fileDelimeter+name);
    PImage tmpMsk = createOrLoadMask(tmpImg);
    maskMean(tmpImg,tmpMsk);
    //maskVariance();
    //println(iMaskMean+" "+sqrt(iMaskVariance)+" "+name+" "+ iMode+" " + sqrt(iVariance));
    int[] threshMask = new int[tmpImg.pixels.length];

    // SHOULD REALLY MAKE A FUNCTION TO DO THESE THREE CASES, THEY'RE ESSENTIALLY THE SAME

    int thresh = iMaskMean; // this is the first of 3 sets of 9 stats to calculate
    for(int i=0; i<tmpImg.pixels.length; i++) { //find above threshold pixels within mask region
      if ((brightness(tmpMsk.pixels[i]) != 0) && (brightness(tmpImg.pixels[i]) >= thresh)) {
        threshMask[i] = 1;
      } 
      else {
        threshMask[i] = 0;
      }
    }
    int count = 0;
    for(int i=1; i<tmpMsk.height-1; i++) {
      for(int j=1; j<tmpMsk.width-1; j++) {
        int k = tmpMsk.width * i + j; // index of current pixel
        if (threshMask[k] != 0) { // take sum of adjacent threshMask pixels
          int sum = threshMask[k-1] + threshMask[k+1] + threshMask[k-tmpMsk.width] + threshMask[k+tmpMsk.width];
          sum += threshMask[k-1-tmpMsk.width] + threshMask[k+1-tmpMsk.width] 
            + threshMask[k-1+tmpMsk.width] + threshMask[k+1+tmpMsk.width];
          iStats[index+sum] += 1;
          count++;
        }
      }
    }
    //print(name+ " ");
    for(int i=0; i<9; i++) {// normalise stats so far
      if (count == 0) {
        iStats[index+i] = 0;
      }
      else {
        iStats[index+i] /= count;
      } 
      //print(iStats[index+i]+ " ");
    }

    index += 9;
    //println();
    thresh = iMaskMean-30; // this is the second of 3 sets of 9 stats to calculate
    for(int i=0; i<tmpImg.pixels.length; i++) { //find above threshold pixels within mask region
      if ((brightness(tmpMsk.pixels[i]) != 0) && (brightness(tmpImg.pixels[i]) >= thresh)) {
        threshMask[i] = 1;
      } 
      else {
        threshMask[i] = 0;
      }
    }
    count = 0;
    for(int i=1; i<tmpMsk.height-1; i++) {
      for(int j=1; j<tmpMsk.width-1; j++) {
        int k = tmpMsk.width * i + j; // index of current pixel
        if (threshMask[k] != 0) { // take sum of adjacent threshMask pixels
          int sum = threshMask[k-1] + threshMask[k+1] + threshMask[k-tmpMsk.width] + threshMask[k+tmpMsk.width];
          sum += threshMask[k-1-tmpMsk.width] + threshMask[k+1-tmpMsk.width] 
            + threshMask[k-1+tmpMsk.width] + threshMask[k+1+tmpMsk.width];
          iStats[index+sum] += 1;
          count++;
        }
      }
    }
    //print(name+ " ");
    for(int i=0; i<9; i++) {// normalise stats so far
      if (count == 0) {
        iStats[index+i] = 0;
      }
      else {
        iStats[index+i] /= count;
      } 
      //print(iStats[index+i]+ " ");
    }
    index += 9;

    thresh = iMaskMean-30; // this is the third of 3 sets of 9 stats to calculate
    for(int i=0; i<tmpImg.pixels.length; i++) { //find above threshold pixels within mask region
      if ((brightness(tmpMsk.pixels[i]) != 0) && (brightness(tmpImg.pixels[i]) >= thresh)
        && (brightness(tmpImg.pixels[i]) < thresh+60)) {
        threshMask[i] = 1;
      } 
      else {
        threshMask[i] = 0;
      }
    }
    count = 0;
    for(int i=1; i<tmpMsk.height-1; i++) {
      for(int j=1; j<tmpMsk.width-1; j++) {
        int k = tmpMsk.width * i + j; // index of current pixel
        if (threshMask[k] != 0) { // take sum of adjacent threshMask pixels
          int sum = threshMask[k-1] + threshMask[k+1] + threshMask[k-tmpMsk.width] + threshMask[k+tmpMsk.width];
          sum += threshMask[k-1-tmpMsk.width] + threshMask[k+1-tmpMsk.width] 
            + threshMask[k-1+tmpMsk.width] + threshMask[k+1+tmpMsk.width];
          iStats[index+sum] += 1;
          count++;
        }
      }
    }
    //print(name+ " ");
    for(int i=0; i<9; i++) {// normalise stats so far
      if(count == 0) {
        iStats[index+i] =0;
      }
      else {
        iStats[index+i] /= count;
      } 
      //print(iStats[index+i]+ " ");
    }
    index += 9;
  }
}

void calculateLowDNearestNeighbours()//Neighbours of images currently visible
{
  println("Calculating low D neighbours");
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
      float mindist = 10e20;
      for(int j=0; j<nImages; j++) {
        if ((j != i) && classLegends[currentLegendIndex].getState(imgs[j].classNums[currentLegendIndex])) {
          float dist2;
          if(toggleDimButton.getState()) {
            dist2 = dist(imgs[i].x2,imgs[i].y2,imgs[j].x2,imgs[j].y2);
          }
          else {
            dist2 = dist(imgs[i].x3,imgs[i].y3,imgs[i].z3,imgs[j].x3,imgs[j].y3,imgs[j].z3);
          }
          if(dist2 < mindist) {
            mindist = dist2;
            imgs[i].nnLow = j;
          }
        }
      }
    }
    else {
      imgs[i].nnLow = -1;
    }
  }

  nnSameClass = 0;
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]) && 
      (imgs[i].classNums[currentLegendIndex] == imgs[imgs[i].nnLow].classNums[currentLegendIndex])) {
      nnSameClass++;
    }
  }
}
void calculateHighDNearestNeighbours()
{//Neighbours of images currently visible using statistics selected, 
  // ie distances in dStats (which are assumed to have already been calculated 
  // by calculateStatsDistances(); 
  println("Calculating high D neighbours");
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
      float mindist = 10e20;
      for(int j=0; j<nImages; j++) {
        if ((j != i) && classLegends[currentLegendIndex].getState(imgs[j].classNums[currentLegendIndex])) {         
          if(dStats[i][j] < mindist) {
            mindist = dStats[i][j];
            imgs[i].nnHigh = j;
          }
        }
      }
    }
    else {
      imgs[i].nnHigh = -1;
    }
  }

  nnHighSameClass = 0;
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex]) && 
      (imgs[i].classNums[currentLegendIndex] == imgs[imgs[i].nnHigh].classNums[currentLegendIndex])) {
      nnHighSameClass++;
    }
  }
}

/* Sammon mapping code */

void ldataInit() {
  // copy 2d/3d points from images into ldata
  // should be method associated with Dataset
  println("Copying points into ldata");
  nImagesOn = 0;
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) { 
      nImagesOn++;
    }
  }
  println("nImagesOn "+nImagesOn);
  int k;
  if (!toggleDimButton.getState()) {
    ldata = new Dataset(nImagesOn,3);
    k=0;
    for(int i=0; i<nImages; i++) {
      //
      if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        ldata.data[k][0]=imgs[i].x3;///scaleData;
        ldata.data[k][1]=imgs[i].y3;///scaleData;     
        ldata.data[k][2]=imgs[i].z3;///scaleData; 
        //println(i+ " "+k); 
        k++;
      }
    }
  }
  else {
    ldata = new Dataset(nImagesOn,2);
    k=0;
    for(int i=0; i<nImages; i++) {

      if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        ldata.data[k][0]=imgs[i].x2;///scaleData;
        ldata.data[k][1]=imgs[i].y2;///scaleData;     
        k++;
      }
    }
  }
}

Dataset statsDataCopy(checkButtonList selected, checkButtonList statsButtons) {
  // copy stats that are 'on' for images that are 'on' in selected into sdata
  // should be method associated with Dataset
  println("Copying data for images and stats that are on");
  nImagesOn = 0;
  for(int i=0; i<nImages; i++) { // how many images are on
    if (selected.currentStates[imgs[i].classNums[currentLegendIndex]]) { 
      nImagesOn++;
    }
  }
  int nStatsOn = 0;
  for(int i=0; i<statsButtons.currentStates.length; i++) {//How many stats are on?
    if (statsButtons.currentStates[i]) {
      nStatsOn++;
    }
  }
  println("there are "+nStatsOn+" statistics currently on");

  Dataset sdata = new Dataset(nImagesOn,nStatsOn); // this is all a bit untidy
  int k=0;
  for(int i=0; i<nImages; i++) {
    if (selected.currentStates[imgs[i].classNums[currentLegendIndex]]) {  
      int l=0;   
      for(int j=0; j<statsButtons.currentStates.length; j++) {
        if(statsButtons.currentStates[j]) {
          sdata.data[k][l++] = imgs[i].iStats[j];
        }
      }
      k++;
    }
  }
  return sdata;
}

void calculateStatsDistances(checkButtonList selectedStats) { 
  dStats = new float[nImages][nImages];
  if(distance) { // we've been given distance matrix, just copy it
    for(int i=0; i<nImages; i++) {
      for(int j=i; j<nImages; j++) {  
        dStats[i][j] = imgs[i].iStats[j];
        dStats[j][i] = imgs[i].iStats[j];
      }
    }
  } 
  else { // calculate distance between stats vectors  
    println("Calculating distances between all images using stats that are on");
    int[] statsIndices = new int[selectedStats.currentStates.length];
    int j=0;
    for(int i=0; i<selectedStats.currentStates.length; i++) { // figure out which stats are on.
      if (selectedStats.currentStates[i]) {
        statsIndices[j++] = i;
      }
    }
    for(int i=0; i<nImages; i++) {
      for(j=i; j<nImages; j++) {  
        float sum = 0;
        for(int k=0; k<statsIndices.length; k++) {
          float pSum = (imgs[i].iStats[statsIndices[k]] - imgs[j].iStats[statsIndices[k]]);
          sum += pSum*pSum;
        }
        dStats[i][j] = sum;
        dStats[j][i] = sum;
      }
    }
  }
}

void calculateStatsAndStandardise() {
  // calculate stats for images that are ON
  println("Calculating all stats and standardising ...");
  nImagesOn = 0;
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) { 
      nImagesOn++;
    }
  }

  // do stats for each Image 
  int statsLength = 0;
  for(int i=0; i<nImages; i++) {
    // put the result into hdata
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
      imgs[i].clearStats();
      imgs[i].calcTASstats();
      statsLength = imgs[i].iStats.length;
    }
  }
  // create legend for Tas stats
  String[] statNames = new String[statsLength];
  color[] cols = new color[statsLength];
  for(int i=1; i<= statsLength; i++) {
    statNames[i-1] = "TAS"+i;
    cols[i-1] = color(255);
  }
  selectedStatsButtons = new checkButtonList(statNames, 260, 150, cols, bgColour, true);

  calculateStatsDistances(selectedStatsButtons);
  // and load up into ldata, hdata;
  ldataInit();
  hdata = statsDataCopy(classLegends[currentLegendIndex], selectedStatsButtons);
  hdata.standardise();


  // copy the standardised data back into stats
  int k = 0;
  for(int i=0; i<nImages; i++) {
    if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) { 
      imgs[i].copyStats(hdata.data[k]);
      k++;
    }
  }

  calculateStatsDistances(selectedStatsButtons); // it's dumb to do this twice, but it's because of jiggling image stats that are equal.
  calculateHighDNearestNeighbours();
  calculateLowDNearestNeighbours();
}

void updateSammonCoords() {
  float error = 0;
  float olderror = 100;

  int i=0;
  while (i<10) {
    error = sam.iterate();
    if (error > 50) {
      sam.epsilon = sam.epsilon/2;  
      println("Nan Error "+error);
      ldata.randFill(); // try again  
      ldata.copyFrom(sam.lowDataCopy,0,ldata.numPoints,0);
    }
    else {
      if (i == 0) {
        olderror = error;
      }      
      i++; 
      //println("  #Iteration: "+sam.nIterations+"   Old error:"+olderror+"  Epsilon:"+sam.epsilon);
    }
  }



  println("Iteration: "+sam.nIterations+"   Current error:"+error+"  Epsilon:"+sam.epsilon); 
  if ((error > olderror) && (sam.epsilon > 0.5)) { // slow the convergence
    sam.epsilon = sam.epsilon*0.8;
  }
  copyToCoords(ldata);
  /*
  if(abs(olderror - error) < 1E-10){// Error term has converged, stop mapping
   sammonButton.setState(false);
   println("Sammon mapping error term has converged, stopping mapping");
   }
   */
}

void copyToCoords(Dataset dset) {
  println("Copying sammon result to coords");
  // copy dset into image coords. 
  int k = 0;
  if(!toggleDimButton.getState()) {
    for(int i=0; i<nImages; i++) {
      if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        imgs[i].x3 = (dset.data[k][0]); //scaleData*
        imgs[i].y3 = (dset.data[k][1]); //scaleData*
        imgs[i].z3 = (dset.data[k][2]); //scaleData*  
        k++;
      }
    }
  }
  else {
    for(int i=0; i<nImages; i++) {
      if (classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
        imgs[i].x2 = (dset.data[k][0]); //scaleData*
        imgs[i].y2 = (dset.data[k][1]); //scaleData* 
        k++;
      }
    }
  }
}

class Dataset {

  int numPoints; // number of vectors
  int dimension; // vector dimension
  float[][] data;
  float[][] distances;
  float[] meanVector;
  float sumDistances;

  Dataset(int nP, int dim) {
    numPoints = nP;
    dimension = dim;
    data = new float[numPoints][dimension];
    distances = new float[numPoints][numPoints];
    meanVector = new float[dimension];
  }

  void copyFrom(Dataset A, int fromRow, int nRows, int intoRow) {
    // copy Dataset A into the current dataset starting at row intoRow of data
    if ((intoRow+nRows > numPoints) || (A.dimension > dimension)) {
      println("Error copyFrom : attempt to write data past size of array\n");
      exit();
    } 
    else
    {
      for(int i=0; i<nRows; i++) {
        for(int j=0; j<A.dimension; j++) {
          data[i+intoRow][j] = A.data[i+fromRow][j];
        }
      }
    }
  }
  /*
  Dataset rowSubset(int startRow, int endRow){
   // return a subset of the rows
   Dataset rowSub = new Dataset(startRow - endRow, dimension);
   for(int i=startRow; i<=endRow; i++){
   for(int j=0; j<dimension; j++){
   rowSub.data[i-startRow][j] = data[i][j]; 
   }
   }
   return rowSub;
   }
   */

  float colMean(int col) {// mean of column col
    float mean = 0;
    for (int i=0; i<numPoints; i++)
    {
      mean += data[i][col];
    }
    mean /= numPoints;
    return mean;
  }

  float colStdDev(int col) {// std deviation of column col
    float variance = 0; 
    float mean = colMean(col);
    for (int i=0; i<numPoints; i++)
    {
      variance += (data[i][col]-mean)*(data[i][col]-mean);
    }
    variance /= numPoints; // put in variance 0 test!
    return sqrt(variance);
  }


  void normalise() {// studentize columns of the data
    println("Normalising the data");
    for(int j=0; j<dimension; j++) {
      float mean = colMean(j); // could be more efficient here, fix!
      print(mean+",");
    }
    println();
    for(int j=0; j<dimension; j++) {    
      float stdDev = colStdDev(j);
      print(stdDev+",");
    }
    println();

    for(int j=0; j<dimension; j++) {
      float mean = colMean(j); // could be more efficient here, fix!
      float stdDev = colStdDev(j);
      if (stdDev == 0) {
        // leave data as is
      }
      else {
        for(int i=0; i<numPoints; i++) {
          data[i][j] = (data[i][j] - mean)/stdDev;
        }
      }
    }
  }

  void standardise() { // for TAS stats, use standard mean and std dev vectors to "normalise" the data
    // this method does not really belong here since it's specific to TAS
    if (dimension != 27) {
      println("Error: attempt to standardise vectors not of length 27");
      exit();
    } 
    else {
      // these are the TAS mean and standard deviation vectors for ImageSetA from the Statistical and Visual ... paper.
      float[] means = {
        0.0032552786,0.005906407,0.010647887,0.02507514,0.04156314,0.056066427,0.05419464,0.07327416,0.73001707,0.0022119775,0.0037334582,0.0063936096,0.012582723,0.020063695,0.027167339,0.030129252,0.044177663,0.85354006,0.0026123496,0.004546756,0.008124578,0.016650213,0.029182838,0.0439826,0.052385364,0.07631827,0.7661973
      };
      float[] stdevs = {
        0.0021238574,0.0032804054,0.0050860303,0.01092163,0.013338872,0.015246947,0.011837602,0.015074708,0.070497006,0.0028259612,0.003881074,0.0055346857,0.008877343,0.010758474,0.0123276375,0.013388201,0.018370401,0.07293287,0.002936258,0.003984432,0.0056588403,0.009128056,0.012076275,0.016125178,0.017733095,0.023573859,0.085525416
      };

      for(int j=0; j<dimension; j++) {
        for(int i=0; i<numPoints; i++) {
          data[i][j] = (data[i][j] - means[j])/stdevs[j];
        }
      }
    }
  }

  void calcMeanVector() {
    for(int i=0; i<dimension; i++) {
      meanVector[i] = colMean(i);
    }
  }

  void printMeanVector() {
    for(int i=0; i<dimension; i++) {
      print(meanVector[i]+",");
    } 
    println();
  }

  int closestToMean() {// return index of vector in data closest to the mean vector
    // Assumes mean vector has already been calculated
    float minDist = 10e20;
    int closest = -1;
    for(int i=0; i<numPoints; i++) {
      float sum = 0;
      for(int j=0; j<dimension; j++) {
        sum += (data[i][j] - meanVector[j])*(data[i][j] - meanVector[j]);
      }
      if (sum < minDist) {
        minDist = sum;
        closest = i;
      }
    }
    return closest;
  }

  void randFill() { // provide a randomised [-1,1] range dataset;
    for(int i=0; i<numPoints; i++) {
      for(int j=0; j<dimension; j++) {
        data[i][j] = (float) random(-1.0,1.0);
      }
    }
  }

  void setPoint(int m, float[] pt) {
    for(int i=0; i<dimension;i++) {
      data[m][i] = pt[i];
    }
  }

  int getNumPoints() {
    return numPoints;
  }

  float[][] getDataset() {
    return data;
  }

  float distance(int m,int n) {// distance between mth and nth data vector
    float sum = 0;
    for(int i=0; i<dimension; i++) {
      sum += (data[m][i] - data[n][i])*(data[m][i] - data[n][i]);
    } 
    return sqrt(sum);
  }

  void calculateDistances() {
    //println("CalculateDistances called");
    for (int i=0; i<numPoints; i++) {
      for (int j=i; j<numPoints; j++) {
        distances[i][j] = distance(i,j);
        distances[j][i] = distances[i][j];
      }
    }
  }
  /*   
   void calculateDistancesJiggle(){ // calculated the distances, but give coords a bit of a jiggle if distance is 0
   for (int i=0; i<numPoints; i++){
   for (int j=i; j<numPoints; j++){
   distances[i][j] = distance(i,j);
   distances[j][i] = distances[i][j];
   if((i !=j) && distances[i][j] == 0){
   println("Jiggling stats for image "+j+" because of image "+i);
   boolean noZeros = false;
   while (!noZeros){
   noZeros = true;    
   jiggleVector(j);
   for(int l=0; l<numPoints; l++){  
   distances[l][j] = distance(l,j);
   distances[j][l] = distances[l][j];
   if ((distances[l][j] == 0) && (l != j)){
   println("   Bother, got to jiggle again because of "+l);
   noZeros = false;
   }
   
   }            
   }
   }
   
   } 
   }
   }
   */
  /*
 void jiggleVector(int i){
   int j = int(random(dimension - 1)); // pick element at random
   float jiggle = random(-0.001,0.001);
   if (data[i][j] != 0){
   data[i][j] += jiggle*data[i][j];} // jiggle it by up to 0.1%
   else {
   data[i][j] = jiggle;
   }
   }
   */
  float[][] getDistances() {
    calculateDistances();
    return distances;
  }

  float getSumDistances() {
    calculateDistances();
    float sum = 0;
    for (int i = 0; i < numPoints; i++ ) {
      for (int j = i + 1; j < numPoints; j++) {
        sum += distances[i][j];
      }
    }
    return 2*sum;
  }
}


class sammonMap {

  Dataset highData;
  Dataset lowData;
  Dataset lowDataCopy;// A copy of lowData when sammonMap was initialised;

  float[][] Y;
  float[] Ynew;	

  float[][] dstar; // high dimensional distances		
  float[][] d;	   // low dimensional distances
  float dstarSum,PartSum, currentCloseness, E;		
  int highDimension;
  int lowDimension;
  float epsilon; 
  int nIterations;
  //float d;

  int numPoints;

  sammonMap(boolean distanceMatrix, Dataset high, Dataset low) {
    // distanceMatrix defines whether high is a distance matrix (true) or a statistics matrix (false)
    // based on code from the HiSee sourceforge project
    // should write some code to perturb overlapping points
    println("Initialising sammon mapping");
    highData = high;
    lowData = low;
    lowDataCopy = new Dataset(lowData.numPoints,lowData.dimension);
    lowDataCopy.copyFrom(lowData,0,lowData.numPoints,0);
    epsilon = 2000; // setting epsilon too high leads to NaN errors
    nIterations = 0;

    // need to set the data sets
    numPoints = highData.numPoints;
    highDimension = highData.dimension;
    lowDimension = lowData.dimension;

    if (distanceMatrix) {
      dstar = new float[numPoints][numPoints];
      dstarSum = 0;
      for(int i=0;i<numPoints;i++) {
        float sum = 0;
        for(int j=0;j<numPoints;j++) {
          dstar[i][j]=highData.data[i][j];
          dstarSum += highData.data[i][j];
        }
      }
    }
    else {
      highData.calculateDistances();
      dstar = highData.getDistances();
      dstarSum = highData.getSumDistances();
    }
    checkdstar();
  }

  void checkdstar() {
    // check that non-diagonal elements are non-zero, and make them (small) = minSep if they are
    /*
    float minVal = 1e20;
    boolean zeroFlag = false;
    for(int i=0;i<numPoints;i++) {
      for(int j=0;j<numPoints;j++) {
        if ((i != j)) {
          if (dstar[i][j] == 0) { 
            zeroFlag = true;
          }
          if ((dstar[i][j] > 0) && (dstar[i][j] < minVal)) { 
            minVal = dstar[i][j];
          }
        }
      }
    }
    */
    //if (zeroFlag) {// find minimum distances and set to minSep //1/10 of smallest non-zero distance
      for(int i=0;i<numPoints;i++) {
        for(int j=0;j<numPoints;j++) {
          if ((i != j) && (dstar[i][j] < minSep)) {
            dstar[i][j] = minSep;//minVal/10;
          }
        }
      }
    //}
  }

  float iterate() {
    //String[] output = new String[1];     
    if (numPoints < 2) {
      return 0;
    }

    nIterations++;
    Y = new float[numPoints][lowDimension];
    Y = lowData.getDataset();

    lowData.calculateDistances();
    d = lowData.getDistances();

    // sammon.m seems to use a different convergence algorithm, it may be more efficient?
    for (int m = 0; m < numPoints; m++) {

      Ynew = new float[lowDimension];
      for (int n = 0; n < lowDimension; n++) {
        PartSum = 0.0;
        for (int i = 0; i < numPoints; i++) {
          if (i == m)
            continue;
          if (d[i][m] != 0) {
            PartSum += ((dstar[i][m] - d[i][m]) * (Y[i][n] - Y[m][n]) / dstar[i][m] / d[i][m]);
          }
          //output[0] = output[0]+i+" "+m+" "+d[i][m];
        }
        Ynew[n] = Y[m][n] - epsilon* 2 * PartSum / dstarSum;
      }
      lowData.setPoint(m, Ynew);
    }

    //saveStrings("/home/nick/tmp/tmp.txt",output);  

    E = 0.0;
    for (int i = 0; i < numPoints; i++) {
      for (int j = i + 1; j < numPoints; j++) {
        E += (dstar[i][j] - d[i][j]) * (dstar[i][j] - d[i][j]) / dstar[i][j];
        //if (dstar[i][j] == 0){println(i+" "+j+"\n");}
      }
    }
    //println(dstarSum);
    //println(dstarSum);
    currentCloseness = E / dstarSum;
    return currentCloseness;
  }
}

float euclidDistance(Dataset dataA, Dataset dataB) {
  // calculates the Euclidean distance between two data sets
  // i.e. the distance between the average vectors for the classes.
  float distance = 0;
  dataA.calcMeanVector();
  dataB.calcMeanVector();    

  for(int i=0; i<dataA.dimension; i++) {
    distance += (dataA.meanVector[i] - dataB.meanVector[i])*(dataA.meanVector[i] - dataB.meanVector[i]);
  } 
  distance = sqrt(distance);  

  return distance;
}

class DiffTest {
  // testing difference of two image sets
  Dataset classA, classB;
  Dataset randA,randB; //randomised versions of classA/Bdata
  float pvalue;
  float distance;
  int nRepeats = 1000;
  String repeats; // used for keyboard input of nRepeats
  int nFurther; // number of randomisations that gave better separation
  boolean finished;

  DiffTest(checkButtonList AButtons, checkButtonList BButtons) { 
    updateButtons(AButtons, BButtons);
    finished = false;
    repeats = str(nRepeats);
    println("Initialising difference testing");
  } 

  void updateButtons(checkButtonList AButtons, checkButtonList BButtons) { 
    classA = statsDataCopy(AButtons,selectedStatsButtons); 
    classB = statsDataCopy(BButtons,selectedStatsButtons);
    if (normaliseStatsButton.getState()) { // need to normalise the union of A and B
      int dim = classA.dimension;
      int nrA = classA.numPoints;
      int nrB = classB.numPoints;
      Dataset AB = new Dataset(nrA+nrB, dim);
      AB.copyFrom(classA,0,nrA,0);
      AB.copyFrom(classB,0,nrB,nrA);
      AB.normalise();
      classA.copyFrom(AB,0,nrA,0);
      classB.copyFrom(AB,nrA,nrB,0);
    }
  }

  float calcPValue() {
    nFurther = 0;
    pvalue = 0;
    println("Calculating p-value");
    // calculate stats and normalise?
    distance = euclidDistance(classA, classB);
    for(int i=0; i<nRepeats; i++) {
      permutationRandomise();
      float d = euclidDistance(randA,randB);
      println(i+" of "+nRepeats+": distance "+distance+"   rand distance"+d);
      if (euclidDistance(randA,randB) >= distance) {
        nFurther++;
      }
    }
    pvalue = float(nFurther)/float(nRepeats);
    finished  = true;
    return pvalue;
  }

  void randomiseResample() {// randomisation with re-sampling
    // create randA and randB which have the same size as classAdata and classBdata
    // but have data randomly chosed from classAdata and classBdata with re-sampling allowed
    int nPoints = classA.numPoints+classB.numPoints;

    randA = new Dataset(classA.numPoints,classA.dimension);
    randB = new Dataset(classB.numPoints,classB.dimension);

    for(int i=0; i<randA.numPoints; i++) {  // fill up randA 
      // find a vector that has not been chosen already
      int r=int(random(nPoints));

      if(r<randA.numPoints) {
        for(int j=0; j<classA.dimension; j++) {
          randA.data[i][j] = classA.data[r][j];
        }
      }
      else {
        r = r-classA.numPoints; 
        for(int j=0; j<classB.dimension; j++) {
          randA.data[i][j] = classB.data[r][j];
        }
      }
    }

    for(int i=0; i<randB.numPoints; i++) {  // fill up randB
      // find a vector that has not been chosen already
      int r=int(random(nPoints));
      if(r<randA.numPoints) {
        for(int j=0; j<classA.dimension; j++) {
          randB.data[i][j] = classA.data[r][j];
        }
      }
      else {
        r = r-classA.numPoints;
        for(int j=0; j<classB.dimension; j++) {
          randB.data[i][j] = classB.data[r][j];
        }
      }
    }
  }

  void permutationRandomise() {
    // create randA and randB which have the same size as classAdata and classBdata
    // but have data randomly chosed from classAdata and classBdata
    int nPoints = classA.numPoints+classB.numPoints;
    boolean[] chosen = new boolean[nPoints];
    for(int i=0; i<nPoints; i++) {
      chosen[i] = false;
    }
    randA = new Dataset(classA.numPoints,classA.dimension);
    randB = new Dataset(classB.numPoints,classB.dimension);

    for(int i=0; i<randA.numPoints; i++) {  // fill up randA 
      // find a vector that has not been chosen already
      int r=int(random(nPoints));
      while (chosen[r]) {
        r=int(random(nPoints));
      }
      //println(i+":"+r);
      chosen[r] = true;
      if(r<randA.numPoints) {
        for(int j=0; j<classA.dimension; j++) {
          randA.data[i][j] = classA.data[r][j];
        }
      }
      else {
        r = r-classA.numPoints; 
        for(int j=0; j<classB.dimension; j++) {
          randA.data[i][j] = classB.data[r][j];
        }
      }
    }

    for(int i=0; i<randB.numPoints; i++) {  // fill up randB
      // find a vector that has not been chosen already
      int r=int(random(nPoints));
      while (chosen[r]) {
        r=int(random(nPoints));
      }
      //println(i+":"+r);
      chosen[r] = true;
      if(r<randA.numPoints) {
        for(int j=0; j<classA.dimension; j++) {
          randB.data[i][j] = classA.data[r][j];
        }
      }
      else {
        r = r-classA.numPoints;
        for(int j=0; j<classB.dimension; j++) {
          randB.data[i][j] = classB.data[r][j];
        }
      }
    }
  }


  void displayResult() {
    textFont(font, 18); 
    fill(255);
    text("p-value for same: "+pvalue+" based on "+nRepeats+" repeats", 150, 30); 
    text(nFurther+" of "+nRepeats+" randomisations were at least as separated",150,50);  
    text("Distance between pair tested: "+distance,150,70);
    text("Click Statistical Test button to exit", 150,90); 
    //text(classA.numPoints+" "+classB.numPoints,150,110);
  }
}

void PCAmap() {
  // Principle Component Analysis
  // Assumes hdata and ldata are as defined elsewhere in the program

  // 1. convert hdata to double
  // 2. normalise hdata with respect to column means
  // 3. calculate covariance matrix for hdata
  // 4. calculate eigenvectors of covariance matrix
  // 5. pick feature vectors
  // 6. Transform hdata using feature vector
  // 7. convert data back to float for ldata
  // 8. Update image positions

  double[][] double_hdata = new double[hdata.numPoints][hdata.dimension];
  double[][] double_ldata = new double[ldata.numPoints][];

  double[][] double_hdata_transformed = new double[hdata.numPoints][hdata.dimension];
  double[] mean;
  double[][] covariance_matrix;
  double[][] feature_vector;
  double[][] feature_vector_3D = new double[hdata.dimension][3];
  double[][] feature_vector_2D = new double[hdata.dimension][2];

  EigenvalueDecomposition eigen;

  // convert hdata to doubles
  for(int i=0; i < hdata.numPoints; i++) {
    for(int j = 0; j < hdata.dimension; j++) {
      double_hdata[i][j] = (double) hdata.data[i][j];
    }
  }

  // calculate column means
  mean = StatisticSample.mean(double_hdata);

  // normalization of x relatively to mean
  for (int i = 0; i < double_hdata.length; i++) {
    for (int j = 0; j < double_hdata[i].length; j++) {
      double_hdata_transformed[i][j] = double_hdata[i][j] - mean[j];
    }
  }

  // calculate covariance matrix
  covariance_matrix = StatisticSample.covariance(double_hdata_transformed);

  // calculate eigenvectors and eigenvalues of covariance matrix
  eigen = LinearAlgebra.eigen(covariance_matrix);

  // get full-dimensional feature vector from eigenvectors
  feature_vector = LinearAlgebra.transpose((eigen.getV()).getArray());

  // calculate smaller dimensional feature vectors (matrices)
  // eigenvectors are ordered from worst to best in full-dimensional feature vector
  // 2D and 3D feature vectors are ordered from best to worst
  for(int i = 0; i < covariance_matrix.length; i++) {
    for(int j = 0; j < 3; j++) {
      feature_vector_3D[i][j] = 5*feature_vector[i][covariance_matrix.length - j - 1];
      if (j < 2) {
        feature_vector_2D[i][j] = 5*feature_vector[i][covariance_matrix.length - j - 1];
      }
    }
  }

  // transform data to pca coordinates
  if (ldata.dimension == 3) {
    double_ldata = LinearAlgebra.times(LinearAlgebra.transpose(feature_vector_3D), LinearAlgebra.transpose(double_hdata_transformed));
  } 
  else {
    double_ldata = LinearAlgebra.times(LinearAlgebra.transpose(feature_vector_2D), LinearAlgebra.transpose(double_hdata_transformed));
  }

  // convert data back to floats for ldata (and stuff)
  double[][] double_ldata_transpose = new double[double_ldata[0].length][double_ldata.length];

  double_ldata_transpose = LinearAlgebra.transpose(double_ldata);
  for(int i=0; i < double_ldata_transpose.length; i++) {
    for(int j = 0; j < double_ldata_transpose[0].length; j++) {
      ldata.data[i][j] = (float) double_ldata_transpose[i][j];
    }
  }

  // update image positions
  rotY = PI/2; // reset the view
  transY = 0;
  copyToCoords(ldata);
}

void markov_cluster() {
  // perform markov clustering on visible classes.

  double[][] double_dist = new double[hdata.numPoints][hdata.numPoints];

  hdata.calculateDistances();

  for(int i = 0; i < hdata.numPoints; i++) {
    for(int j = 0; j < hdata.numPoints; j++) {
      double_dist[i][j] = (double) hdata.distances[i][j];
    }
  }

  MarkovCluster mc = new MarkovCluster(double_dist, 2, 5.0);

  ArrayList clusters = mc.getClusters();

  // Add a new catgory MCL

  int nCategories = imgs[0].nCategories+1; // number of categories after MCL
  categoryButtons.addButton("MCL",false);

  // add class legend to new category
  classLegends = (checkButtonList[])expand(classLegends,nCategories);
  println("Number of categories (after MCL): "+classLegends.length); 
  println("MCL category has "+clusters.size()+" classes"); 

  // add classes to the new category

  String classes[] = new String[clusters.size()];

  for(int i=0; i<clusters.size(); i++) {
    classes[i] = "mcl-"+i;
  }
  color[] clrs = chooseColours(clusters.size());
  classLegends[nCategories-1] = new checkButtonList(classes, 10, 10, clrs, bgColour, true); 

  // if image was not visible, assign it to Not Clustered class.
  int lookup[] = new int[hdata.numPoints];
  int ind = 0;
  for(int i=0; i<nImages; i++) {

    if (!classLegends[currentLegendIndex].getState(imgs[i].classNums[currentLegendIndex])) {
      imgs[i].addCategory(clusters.size(), "Not Clustered");
      println("Image "+i+" not selected for MCL");
    }
    else { // create hdata indexing to total image set indexing lookup
      lookup[ind]=i;
      ind++;
    }
  }  


  // now assign visible images to mcl classes
  for(int j = 0; j < clusters.size(); j++) {

    System.out.printf("Cluster %d: ", j);

    //addClass("Cluster "+j);

    int number_of_images_in_cluster = ((ArrayList) clusters.get(j)).size();

    for(int k = 0; k < number_of_images_in_cluster; k++) {

      Integer image_index = (Integer) ((ArrayList) clusters.get(j)).get(k);

      System.out.printf("%d, ", image_index);  

      imgs[lookup[image_index]].addCategory(j, classes[j]);
    }
    System.out.printf("\n");
  }

  currentLegendIndex = nCategories-1; 
  addClass("Not Clustered");

  visibleClassesOrStatsChanged(false);
}


//this is a first stab at multiple windows. 
/*
import javax.media.opengl.*;
 class GLRenderer implements GLEventListener {
 GL gl;
 
 public void init(GLAutoDrawable drawable) {
 this.gl = drawable.getGL();
 gl.glClearColor(0, 0, 0, 0);
 }
 
 public void display(GLAutoDrawable drawable) {
 gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT );
 gl.glColor3f(1, 1, 1);  
 gl.glRectf(-0.8, 0.8, frameCount%100/100f -0.8, 0.7);
 }
 
 public void reshape(GLAutoDrawable drawable, int x, int y, int width, int height) {
 }
 
 public void displayChanged(GLAutoDrawable drawable, boolean modeChanged, boolean deviceChanged) {
 }
 } 
 */
