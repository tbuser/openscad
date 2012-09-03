# used to start a virtual framebuffer device on linux/bsd systems where
# X11 is not runing.

NEWDISPLAY=:5

if [ ! $DISPLAY ];
  echo "no DISPLAY environment variable detected. attempting to start Virtual framebuffer"
  if [ "`ps auxwww | grep Xvfb`" ]; then
    echo "Xvfb already started"
    exit
  fi
  if [ "`ps auxwww | grep Xvnc`" ]; then
    echo "Xvnc already started"
    exit
  fi
  if [ "`command -v Xvfb`" ]; then
    Xvfb $NEWDISPLAY -screen 0 800x600x256 &> Xvfb.log &
  elif [ "`command -v Xvnc`" ]; then
    Xvnc $NEWDISPLAY -screen 0 800x600x256 &> Xvnc.log &
  fi
  DISPLAY=$NEWDISPLAY
  export DISPLAY
fi

