# used to start a virtual framebuffer device on linux/bsd systems where
# X11 is not runing.

NEWDISPLAY=:5

if [ ! $DISPLAY ]; then
  echo "No DISPLAY environment variable detected."
  if [ "`ps auxwww | grep Xvfb | grep -v grep`" ]; then
    echo "Xvfb already started"
    exit
  fi
  if [ "`ps auxwww | grep Xvnc | grep -v grep`" ]; then
    echo "Xvnc already started"
    exit
  fi
  echo "No Xvfb or Xvnc detected."
  echo "Attempting to start Virtual framebuffer"
  if [ "`command -v Xvfb`" ]; then
    echo "Xvfb $NEWDISPLAY -screen 0 800x600x24 &> Xvfb.log &"
    Xvfb $NEWDISPLAY -screen 0 800x600x24 &> Xvfb.log &
  elif [ "`command -v Xvnc`" ]; then
    echo "Xvnc $NEWDISPLAY -screen 0 800x600x24 &> Xvnc.log &"
    Xvnc $NEWDISPLAY -screen 0 800x600x24 &> Xvnc.log &
  fi
  DISPLAY=$NEWDISPLAY
  export DISPLAY
fi

