# used to start a virtual framebuffer device on linux/bsd systems where
# X11 is not runing.

# Usage:
#  virtualfb.sh start
#  virtualfb.sh stop

NEWDISPLAY=:5

if [ ! $DISPLAY ]; then
  echo "No DISPLAY environment variable detected."
  echo "Checking if Xvfb or Xvnc is running..."
  if [ "`ps auxwww | grep Xvfb | grep -v grep`" ]; then
    DPY=`ps auxwww | grep Xvfb | grep -v grep | grep -v sed | \
     sed s/".*Xvfb.*:"// | sed s/" .*"//`
    echo "Xvfb already started, DISPLAY=:"$DPY
    exit
  fi
  if [ "`ps auxwww | grep Xvnc | grep -v grep`" ]; then
    DPY=`ps auxwww | grep Xvnc | grep -v grep | grep -v sed | \
     sed s/".*Xvnc.*:"// | sed s/" .*"//`
    echo "Xvnc already started, DISPLAY=:"$DPY
    exit
  fi
  echo "No Xvfb or Xvnc detected. Attempting to start"
  if [ "`command -v Xvfb`" ]; then
    echo "Xvfb $NEWDISPLAY -screen 0 800x600x24 &> Xvfb.log &"
    Xvfb $NEWDISPLAY -screen 0 800x600x24 &> Xvfb.log &
  elif [ "`command -v Xvnc`" ]; then
    echo "Xvnc $NEWDISPLAY -screen 0 800x600x24 &> Xvnc.log &"
    Xvnc $NEWDISPLAY -screen 0 800x600x24 &> Xvnc.log &
  fi
  DISPLAY=$NEWDISPLAY
  export DISPLAY
  echo "DISPLAY="$NEWDISPLAY
fi

