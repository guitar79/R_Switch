boolean isCh1 = false; // not sure that it'll be used, but save state anyway
// TODO : if done testing on ch1, must add visibility of ch2, ch4, ch5, too.

// current problem : when button gets into 'invisible' state, it stops at "light blue" state, and cannot press other buttons (not a lag. Clock goes well...)




// How about... let's just make toggle rectangle(?) to show each state. Making buttons visible/invisible won't be necessary.


public void ch1_on() {
  if (connectedSerial) {
    serial.write('q'); println("type 'q'");
    status_text("Ch1 on");
  }
  isPressedCh1Button = !isPressedCh1Button;
  messageBoxResult = -1;
  isCh1 = true;
  ((Toggle)cp5.getController("on/off1")).setState(false);
//  cp5.getController("ch1_on").setVisible(false);
//  cp5.getController("ch1_off").setVisible(true);
}

public void ch1_off() {
  createModalDialog("Ch1 off");
  if (messageBoxResult >= 1) return;
  if (connectedSerial) {
    serial.write('a'); println("type 'a'");
    status_text("Ch1 off");
  }
  isPressedCh1Button = !isPressedCh1Button;
  messageBoxResult = -1;
  isCh1 = false;
  ((Toggle)cp5.getController("on/off1")).setState(true);
//  cp5.getController("ch1_on").setVisible(true);
//  cp5.getController("ch1_off").setVisible(false);
}

/* 
public void ch2_on() { 
  if (connectedSerial) {
    serial.write('w'); println("type 'w'");
    status_text("Ch2 on");
  }
  isPressedCh2Button = !isPressedCh2Button;
  messageBoxResult = -1;
}


public void ch2_off() {
  createModalDialog("ch2 off");
  if (messageBoxResult >= 1) return;
  if (connectedSerial) {
    serial.write('s');
    status_text("Ch2 off");
  }
  isPressedCh2Button = !isPressedCh2Button;
  messageBoxResult = -1;
}   
*/


public void ch3_on() {
  if (connectedSerial) {
    serial.write('e');
    status_text("Ch3 on");
  }
  isPressedCh3Button = !isPressedCh3Button;
  messageBoxResult = -1;
}

public void ch3_off() {
  createModalDialog("Ch3 off");
  if (messageBoxResult >= 1) return;
  if (connectedSerial) {
    serial.write('d'); println("type 'd'");
    status_text("Ch3 off");
  }
  isPressedCh3Button = !isPressedCh3Button;
  messageBoxResult = -1;
}

public void ch4_on() {
  if (connectedSerial) {
    serial.write('r'); println("type 'r'");
    status_text("Ch4 on");
  }
  isPressedCh4Button = !isPressedCh4Button;
  messageBoxResult = -1;
}

public void ch4_off() {
  createModalDialog("Ch4 off");
   if (messageBoxResult >= 1)
    return;
  if (connectedSerial) {
    serial.write('f'); println("type 'f'");
    status_text("Ch4 off");
  }
  isPressedCh4Button = !isPressedCh4Button;
  messageBoxResult = -1;
}

public void ch5_on() {
  if (connectedSerial) {
    serial.write('t'); println("type 't'");
    status_text("Ch5 on");
  }
  isPressedCh5Button = !isPressedCh5Button;
  messageBoxResult = -1;
}

public void ch5_off() {
  createModalDialog("Ch5 off");
  if (messageBoxResult >= 1) return;
  if (connectedSerial) {
    serial.write('g'); println("type 'g'");
    status_text("Ch5 off");
  }
  isPressedCh5Button = !isPressedCh5Button;
  messageBoxResult = -1;
}
public void ch6_on() {
  createModalDialog("Are you sure to open roof?");
  if (connectedSerial) {
    serial.write('y'); println("type 'y'");
    status_text("Roof open");
  }
}
public void ch7_on() {
  createModalDialog("Are you sure to close roof?");
  if (connectedSerial) {
    serial.write('u'); println("type 'u'");
    status_text("Roof close");
  }
}

public void ch8_on() {
  if (connectedSerial) {
    serial.write('i'); println("type 'i'");
    status_text("Roof stop");
  }
}

void status_text(String status_message){
  fill(255);
  rect(status_text_x-50,15,150,25);
  textSize(11);
  fill(0);
  text(status_message, status_text_x, status_text_y);
}