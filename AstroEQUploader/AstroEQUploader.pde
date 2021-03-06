/*

   AstroEQ Firmware Update Utility
   
   by Thomas Carpenter
   
   [based on MX2 Firmware Update Utility GUI by Chris Church]
   
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Verison 3.7
*/
 
import controlP5.*;
import processing.serial.*;
import java.util.List;
import java.util.ArrayList;
import java.net.URI;
import java.net.URISyntaxException;
import java.awt.Image;
import java.awt.Toolkit; 
import java.awt.datatransfer.*;
import processing.awt.PSurfaceAWT.SmoothCanvas;
import javax.swing.JFrame;
import java.awt.Dimension;

public final static int __TESTING__ = 0;//

ControlP5 controlP5;
public UploaderGUI ui;

 // controlp5 elements
ScrollableList port, version;
int boardVersion;
//Button upload;
public Textarea info;

Executioner execute;
Thread executeThread;
ClipHelper cp;

PImage astroEQLogo;
public PFont wl_font;  
//PFont it_font;

String welcomeText;

public final String versionFilename = "versions.txt";

String[] avrdude = {"avrdude", "avrdude.conf", "-v", "-v", "-v",  "-p",  "-c",  "-b", "-D", "", ""  };
public String[][] variant = { { "atmega162",  "arduino",  "57600"},
                              { "atmega162",  "arduino",  "57600"},
                              {"atmega1280",  "arduino",  "57600"},
                              {"atmega2560",   "wiring", "115200"} };
                     

public String hexPath;

public final Boolean isBeta = false; //If a beta version.
public String configVersion = "3.7.2";

public String curFile;
public String curPort;

byte overLogo = 0;

public String filePath;
String firmwareVersion;
public String tempDirectory;

private static String OS = System.getProperty("os.name").toLowerCase();
public static boolean isWindows() {
  return (OS.indexOf("win") >= 0);
}
public static boolean isUnix() {
  return (OS.indexOf("nix") >= 0 || OS.indexOf("nux") >= 0 || OS.indexOf("aix") > 0 );
}


void exit () {
  if (isWindows()) {
    try {
      deleteDirectory(new File(tempDirectory));
    } catch (Exception e) {
    }
  }
  super.exit();
}

public static String dir() throws URISyntaxException {
  URI path=AstroEQUploader.class.getProtectionDomain().getCodeSource().getLocation().toURI();
  String name= AstroEQUploader.class.getPackage().getName()+".jar";
  String path2 = path.getRawPath();
  path2=path2.substring(1);

  if (path2.contains(".jar"))
  {
      path2=path2.replace(name, "");
  }
  return path2;
} 

public static boolean deleteDirectory(File dir) {
  if(! dir.exists() || !dir.isDirectory())    {
    return false;
  }

  String[] files = dir.list();
  for(int i = 0, len = files.length; i < len; i++)    {
    File f = new File(dir, files[i]);
    if(f.isDirectory()) {
      deleteDirectory(f);
    } else {
      f.delete();
    }
  }
  return dir.delete();
}
  /*if (isWindows()) {
  
  } else if (isUnix()) {
    
  }*/

public final static int BACKGROUND_COLOUR = #0A0C4B;//color(10,21,75);
public final static int BORDER_COLOUR = #5070AA;//color(80,112,170);


public final static int WINDOW_WIDTH = 510;
public final static int WINDOW_HEIGHT = 520;
public final static int LOGO_HEIGHT = 64;
public final static int ELEMENT_HEIGHT = 16;
public final static int TEXTBAR_HEIGHT = 20;
public final static int FONT_HEIGHT = ELEMENT_HEIGHT-3;
public final static int CONTROLP5_HEIGHT = 352;

public final Dimensions headerDim    = new Dimensions(0,0,                         0,0,                    WINDOW_WIDTH,LOGO_HEIGHT + 2*TEXTBAR_HEIGHT       );
public final Dimensions configDim    = new Dimensions(0,LOGO_HEIGHT+TEXTBAR_HEIGHT,0,0,                    WINDOW_WIDTH,TEXTBAR_HEIGHT                       );
public final Dimensions controlP5Dim = new Dimensions(0,0,                         0,headerDim.bottom(),   WINDOW_WIDTH,CONTROLP5_HEIGHT                     );
public final Dimensions infoDim      = new Dimensions(0,0,                         0,controlP5Dim.bottom(),WINDOW_WIDTH,WINDOW_HEIGHT - controlP5Dim.bottom());

JFrame jf;

int FrameHeightOffset = 0;
int FrameWidthOffset = 0;

void setup() { 
  Locale.setDefault(Locale.UK);
  
  println("Starting AstroEQ Config Utility, V" + configVersion + (isBeta ? "(beta)" : ""));
  println("Time is "+hour()+":"+minute()+":"+second());
  println("OS: " + System.getProperty("os.name") + ". JRE Version: " + System.getProperty("java.version") + ". JRE Arch: " + System.getProperty("os.arch"));
  
  println("Creating Window. Setting DPI Scaling to " + displayDensity());
  size(100, 100);
  pixelDensity(displayDensity());
  
  println("Setting Window Size to: "+WINDOW_WIDTH+" x "+WINDOW_HEIGHT);
  surface.setSize(510, 520); //STUPID F**ing Processing 3.0 not being able to use constants.
  
  SmoothCanvas sc = (SmoothCanvas) getSurface().getNative();
  jf = (JFrame) sc.getFrame();
  jf.setMinimumSize(jf.getSize());
  surface.setResizable(true);
  FrameHeightOffset = (int)jf.getSize().getHeight() - WINDOW_HEIGHT + 10;
  FrameWidthOffset = (int)jf.getSize().getWidth() - WINDOW_WIDTH + 10;
      
  println("Setting Frame Rate");
  frameRate(30);
  
  println("Creating Executioner thread");
  execute   = (Executioner) new NullInterface(this); //using NullInterface as it is an empty implementation of Executioner and we don't need a specialised type yet.
  executeThread = new Thread(execute);
  
  println("Connecting to Clipboard");
  
  try {
    cp = new ClipHelper();
  } catch (Exception e) {
    cp = null;
  }
  
  astroEQLogo = loadImage("astroEQLogo.jpg");
  try {
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); 
  } catch (Exception e){
    e.printStackTrace();
  }
  if (isWindows()) {
    try {
      filePath = /*URLDecoder.decode(AstroEQUploader.class.getProtectionDomain().getCodeSource().getLocat‌​ion().getPath(), "UTF-8")*/ dir() + java.io.File.separator;
    } catch (Exception e) {
      filePath = sketchPath("");
    }
    println("Current Dir: " + filePath);
    hexPath = filePath + "hex";  
    
    tempDirectory = "C:" + java.io.File.separator + "__temp__AstroEQUploader" + java.io.File.separator;
    println("Temp Dir: " + tempDirectory);
    File dir = new File(tempDirectory);
    dir.mkdir();
    String sourceFile = "" + filePath + "etc" + java.io.File.separator + avrdude[1];
    String destinationFile = "" + tempDirectory + avrdude[1];                        
    
    println("Copying AVRDude.conf to Temp Dir.");
    FileCopy copier = new FileCopy();                        
    copier.copyFile(sourceFile, destinationFile);
    
    avrdude[0] = "\""+filePath + "bin" + java.io.File.separator + avrdude[0]+"\"";
    avrdude[1] = "-C\"" + destinationFile+"\"";
  } else if (isUnix()) {
    filePath = java.io.File.separator + "usr" + java.io.File.separator + "share" + java.io.File.separator + "doc" + java.io.File.separator + "astroequploader" + java.io.File.separator;
    println("Current Dir: " + filePath);
    hexPath = filePath + "hex";
    avrdude[0] = "" + filePath + avrdude[0];
    avrdude[1] = "-C" + filePath + avrdude[1];
  }
  
  PImage astroEQIcon = loadImage("icon.png");
  surface.setIcon(astroEQIcon);
  surface.setTitle("AstroEQ Firmware Update Utility V" + configVersion + (isBeta ? "(beta)" : ""));
  
  String[] versions = listVersions();
  
  wl_font = createFont("Tahoma Bold",FONT_HEIGHT, false);//loadFont("Candara-Bold-16.vlw");
  //it_font = loadFont("CenturyGothic-12.vlw");
  
  welcomeText = "AstroEQ Firmware Update Utility";
  println("Loading ControlP5");
  controlP5 = new ControlP5(this);
  
  info = controlP5.addTextarea("output","",infoDim.x(),infoDim.y(),infoDim.width(),infoDim.height());
  
  info.setColorBackground(color(#000000));
  info.setColorValue(color(#ffffff));
  info.getValueLabel().setFont(createFont("Courier New",14, false));
  info.setMoveable(false);
  println("Building GUI");
  ui = new UploaderGUI(this,controlP5,controlP5Dim); //make the GUI.
  port = controlP5.addScrollableList("comport",70,configDim.top()+2,configDim.centre()-150,120);
  controlP5.addButton("refreshPorts")
           .setPosition(configDim.centre()-80,configDim.top()+2)
           .setImages(loadImage("Refresh.png"), loadImage("Refresh-Over.png"), loadImage("Refresh-Down.png"))
           .updateSize();
  version = controlP5.addScrollableList("version",configDim.centre()+5,configDim.top()+2,configDim.centre()-52,120);
  versionListDrop(version, versions);
  refreshComm();
  port.setMoveable(false);
  version.setMoveable(false); 
  
  firmwareVersion = getVersion(versions[0].replaceAll("\\s",""));
  
}

void refreshComm() {
  println("Initialising Serial Ports");
  String[] comports = Serial.list();
  println((Object[])comports);
  portListDrop(port, comports);
  curPort = null;
}

void draw() {
  Dimension jfSize = jf.getSize();
  int jfHeight = (int)jfSize.getHeight();
  if (infoDim.bottom() != jfHeight-FrameHeightOffset) {
    println("IB:"+infoDim.bottom()+" JFH:"+jfHeight+" JFHO:"+FrameHeightOffset);
    infoDim.setHeight(jfHeight-FrameHeightOffset - controlP5Dim.bottom());
    info.setHeight(infoDim.height());
  }
  int jfWidth = (int)jfSize.getWidth();
  if (jfWidth != WINDOW_WIDTH+FrameWidthOffset) {
    println("JFW:"+jfWidth+" JFWO:"+FrameWidthOffset);
    jf.setSize(new Dimension(WINDOW_WIDTH+FrameWidthOffset, jfHeight));
  }
  
  background(BACKGROUND_COLOUR);
  
  image(astroEQLogo, 0, 0); 
  fill(BORDER_COLOUR);
  noStroke();
  rect(headerDim.left(),headerDim.mapToGlobalY(LOGO_HEIGHT),headerDim.width(),TEXTBAR_HEIGHT);
  stroke(#000000);
  ui.updateDisplay(execute.status());
  port.show();
  version.show();
  
  fill(#FFFFFF);
  textAlign(CENTER);
  textFont(wl_font, 13);
  text(welcomeText, headerDim.centre(), headerDim.mapToGlobalY(LOGO_HEIGHT+TEXTBAR_HEIGHT/2+5));

  textAlign(LEFT);
  textFont(wl_font, 12);
  text("COM Port:", configDim.left()+4, configDim.middle()+5);
  text("Firmware:", configDim.centre()-60, configDim.middle()+5);
  text("V"+firmwareVersion, configDim.right()-42, configDim.middle()+5);
  
  
  if (overLogo > 0 && overLogo < 4) {
    String toolTipText = "";
    fill(255);
    rect(mouseX+10,mouseY+10,130+(overLogo==3 ? 8 : 3),16);
    fill(0);
    switch( overLogo ) {
      case 1:
        toolTipText = "Visit ASCOM Website";
        break;
      case 2:  
        toolTipText = "Visit EQMOD Website";
        break;
      case 3:
        toolTipText = "Visit AstroEQ Website";
        break;
    }
    text(toolTipText,mouseX+13,mouseY+23);
  }


  String[] executeOutput;  
    // updaste avrdude output?
   
  if( execute.status().isRunning() ) {
    info.setColorValue(color(#ffffff));
    executeOutput = execute.getOutput();
    if( executeOutput != null ) {
      for(String readback : executeOutput) {
     // for(int i = 0; i < myBuf.length; i++) {
        if( readback != null ) {
          info.setText( info.getText() + readback + "\n" );
          info.scroll(1);
        }
      }
    }
  } else if( execute.status().isComplete() || execute.status().isError() ) {
    if( execute.status().isError() ) {
      //upload.setColorBackground(color(#ee0000));
      info.setColorValue(color(#ee0000));
    } else {  
      info.setColorValue(color(#ffffff));
      //upload.setColorBackground(color(#5070aa));
    }
    
    // get anything left in the buffer
      
    executeOutput = execute.getOutput();
    if( executeOutput != null ) {
      for(String readback : executeOutput) {
        if( readback != null ) {
          info.setText( info.getText() + readback + "\n" );
          info.scroll(1);
        }
      }
    }
  }
}


String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    // If it's not a directory
    return null;
  }
}

String[] listVersions() {
  String versions[] = new String[]{
    "AstroEQ V4-DIY Board (including Kits)",
    "AstroEQ V4-EQ5 Board",
    "AstroEQ Arduino Mega 1280",
    "AstroEQ Arduino Mega 2560"
  };
  return versions;
}

void versionListDrop(ScrollableList ddl, String[] files) {
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(TEXTBAR_HEIGHT);
  ddl.setBarHeight(ELEMENT_HEIGHT);
  ddl.getCaptionLabel().set("Select Version");
  ddl.getCaptionLabel().getStyle().marginLeft = 3;

  int litem = 0;

  for (int i = 0; i < files.length; i++) {
    ddl.addItem(files[i], litem);
    litem++;
  }
  
  ddl.setValue(0);
  
  ddl.close();
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255,128));
}


void portListDrop(ScrollableList ddl, String[] files) {
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(TEXTBAR_HEIGHT);
  ddl.setBarHeight(ELEMENT_HEIGHT);
  ddl.getCaptionLabel().set("Select COM Port");
  ddl.getCaptionLabel().getStyle().marginLeft = 3;

  int litem = 0;
  ddl.clear();
  for (int i = 0; i < files.length; i++) {
    
    ddl.addItem(files[i], litem);
    litem++;
  }

  ddl.close();
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255,128));
}

private static boolean shiftDown = false;
private static boolean ctrlDown = false;
private static String clipboard = "";
void keyPressed() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      shiftDown = true;
    } else if (keyCode == CONTROL) {
      ctrlDown = true;
    }
  } else if (keyCode == TAB) {
    if (shiftDown) {
      ui.focusPreviousTextField();
    } else {
      ui.focusNextTextField();
    }
  } else if (ctrlDown && (keyCode == 'C')){
    if (cp != null) {
      cp.copyString(ui.getTextOfFocusTextField());
    } else {
      clipboard = ui.getTextOfFocusTextField();
    }
  } else if (ctrlDown && (keyCode == 'V')){
    if (cp != null) {
      ui.setTextOfFocusTextField(NumUtils.makeToDouble(cp.pasteString()));
    } else {
      ui.setTextOfFocusTextField(clipboard);
    }
  }
}
void keyReleased() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      shiftDown = false;
    } else if (keyCode == CONTROL) {
      ctrlDown = false;
    }
  }
}

Object getScrollableListEventItem(ControlEvent theEvent, String field) {
  ScrollableList ddl = (ScrollableList)theEvent.getController();
  Map<String,Object> item = ddl.getItem((int)theEvent.getValue());
  return item.get(field);
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isController()) {
    if( theEvent.getName().equals("version") ) {
      curFile = (String)getScrollableListEventItem(theEvent, "text");
      curFile = curFile.replaceAll("\\s","");
      print("Board Version: ");
      println(curFile);
      boardVersion = (Integer)getScrollableListEventItem(theEvent, "value");
      firmwareVersion = getVersion(curFile);
      
    } else if( theEvent.getName().equals("comport") ) {
      curPort = (String)getScrollableListEventItem(theEvent, "text");
      print("COM Port: ");
      println(curPort);
      
    } else if (theEvent.getName().equals("refreshPorts")) {
      refreshComm();
      
    } else if ((theEvent.getController() instanceof ScrollableList) && (ui != null) && ui.dropdownEvent(theEvent)){
     
    } else if ((ui != null) && ui.controlEvent(theEvent)){
      
    }
  }  
}

String getVersion(String file) {
    String version = "0";
    BufferedReader reader = null;
    try {
      // Create a URL for the desired page
      Map<String, String> files = new HashMap<String, String>();
      reader = new BufferedReader(createReader("" + hexPath + java.io.File.separator + versionFilename));
      String str;
      while ((str = reader.readLine()) != null) {
        if(str.contains("\t")){
          //println(str);
          String[] parts = str.split("\t");
          files.put(parts[0],parts[1]); //filename then version.
        }
      }
      reader.close();
      if (files.containsKey(file)){
        println("Matched to firmware file: "+file+".hex");
        version = files.get(file);
      }
    } catch (Exception e) {
      e.printStackTrace();
    } finally {
      
    }
    return version;
}


void mouseMoved() { 
  checkClick(); 
}
  
void mouseDragged() {
  checkClick(); 
}

void mousePressed() {
  switch( overLogo ) {
    case 1:
      link("http://ascom-standards.org/");//, "_new");
      break;
    case 2:  
      link("http://eq-mod.sourceforge.net/");//, "_new");
      break;
    case 3:
      link("https://astroeq.co.uk/");//, "_new");
      break;
    default:
      break;
  }
}

void checkClick() {
    // logo takes up top of screen
  if ((mouseY < headerDim.mapToGlobalY(LOGO_HEIGHT/2+25)) && (mouseY > headerDim.mapToGlobalY(LOGO_HEIGHT/2-25))) {
    if ((mouseX > headerDim.mapToGlobalX(5)) && (mouseX < headerDim.mapToGlobalX(49))) {
      overLogo = 1;
    } else if ((mouseX > headerDim.mapToGlobalX(52)) && (mouseX < headerDim.mapToGlobalX(102))) {
      overLogo = 2;
    } else if ((mouseX > headerDim.mapToGlobalX(106)) && (mouseX < headerDim.mapToGlobalX(156))) {
      overLogo = 3;
    } else {
      overLogo = 0;
    }
  } else {
    overLogo = 0;
  }
}

public static final class EEPROMProgrammer {
  public static final boolean ReadOrRun = true;
  public static final boolean Store = false;
  public static final boolean Repair = true;
  public static final boolean NoRepair = false;
}

void eepromProgrammerRun(boolean readWrite, boolean clean, String[] extraArgs) {
  int mode = ((readWrite? 1 : 2 )|(clean? 1 : 0));
  String[] args = {""+mode}; //1 = read, 3 = clean, 2 = store
  
  if ((extraArgs != null) && (extraArgs.length > 0)) {
    String[] result = Arrays.copyOf(args, args.length + extraArgs.length);
    System.arraycopy(extraArgs, 0, result, args.length, extraArgs.length);
    args = result;
  }
  
  executeTask(args);
}

void eqmodScript(String scriptName) {
  if (isWindows()) {
    String[] args = {"wscript", "\""+filePath + "bin" + java.io.File.separator + scriptName + "\""};
    //args[0] = args[0] + scriptName;
    executeTask(args);
  }
}

void avrdudeRun(String myFile, String myPort, int index) {
  
  // remaining avrdude argument creation (hex and comport #)
  String[] args = (String[])avrdude.clone();//new String[avrdude[0].length];
  
  for (int i = 0; i < 3; i++) {
    args[i+5] = args[i+5] + variant[index][i];
  } 
  String sourceFile = "" + hexPath + java.io.File.separator + myFile + ".hex";
  if (isWindows()) {
    String destinationFile = "" + tempDirectory + myFile + ".hex";                        
    FileCopy copier = new FileCopy();                        
    copier.copyFile(sourceFile, destinationFile);
    args[9] = "-P"+"\\\\.\\"+myPort;
    args[10] = "-Uflash:w:"+destinationFile+":i";
  } else if (isUnix()) {
    args[9] = "-P"+myPort;
    args[10] = "-Uflash:w:"+sourceFile+":i";
  }  
  
  executeTask(args);
}

void executeTask(String[] args){
  if((args == null) || (args.length == 0)) {
    return; //don't run as no arguments
  }
  // show avrdude command in text window
  for(int i = 0; i < args.length ; i++) {
    //t1.setText( t1.text() + avrdude[i] + " ");
    print(args[i] + " ");
  }
  
  // execute avrdude in the avr thread
  execute.setArgs(args);
  executeThread.start();
  
}