# virtualfb.sh copyright Don Bright <hugh.m.bright@gmail.com> 2012
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
# AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Permission is granted to Marius Kintel and Clifford Wolf to change
# this license for use in OpenSCAD or any other projects they are involved in.
#
# Purpose:
#  Used to start/stop a virtual framebuffer device on linux/bsd systems
#  'stop' means kill all Xvfb/Xvnc processes running under the user's uid
#
# Usage:
#  virtualfb.sh start
#  virtualfb.sh stop
#
# Output:
#  In 'start' mode, the script should print DISPLAY=:x (x=a number)
#  which will get scraped by the CTestCustom.template ctest script
#
# Design:
#  use as few external tools as possible (grep, sed)

# Edit NEWDISPLAY as needed

NEWDISPLAY=:5
SCREEN='-screen 0 800x600x24'
DEBUG= # set to 1 for debug
LOGFILE=virtualfb.log

debug()
{
  if [ $DEBUG ]; then echo $* ; fi
}

find_display()
{
  vfb_program=$1
  find_display_result=`ps -fu$USER | grep $vfb_program | grep -v grep | \
    grep -v sed | sed s/".*$1.*:"// | sed s/" .*"//`;
}

findpid()
{
  debug findpid called w arg $1
  findpid_result=
  if [ `uname | grep Linux` ]; then
    debug findpid: Linux detected
    findpid_result=`ps -fu$USER | grep $1 | grep -v grep | grep -v sed | \
     sed s/"$USER *"// | sed s/" .*"//`
  elif [ `uname | grep BSD` ]; then
    debug findpid: BSD detected
    findpid_result=`ps | grep $1 | grep -v grep | grep -v sed | \
     sed s/"\([0-9 ]*\)"/\\1/ | sed s/" *"//`
  else
    echo findpid: unknown operating system
    exit
  fi
}

stop()
{
  debug stop called
  stop_result=

  findpid Xvfb
  if [ $findpid_result ]; then
    echo stopping Xvfb, pid $findpid_result ;
    kill $findpid_result ;
    stop_result=1
  else
    debug no Xvfb found to stop
  fi

  findpid Xvnc
  if [ $findpid_result ]; then
    echo stopping Xvnc, pid $findpid_result ;
    kill $findpid_result ;
    stop_result=1
  else
    debug no Xvnc found to stop
  fi
}

start()
{
  debug start called

  find_display Xvfb
  if [ $find_display_result ]; then
    echo "Xvfb already running. DISPLAY=:"$find_display_result
    exit
  fi

  find_display Xvnc
  if [ $find_display_result ]; then
    echo "Xvnc already running. DISPLAY=:"$find_display_result
    exit
  fi

  debug "No Xvfb or Xvnc detected. Attempting to start"
  debug "Logging to $LOGFILE"

  if [ "`command -v Xvfb`" ]; then
    debug Xvfb command found. starting w args: $NEWDISPLAY $SCREEN
    Xvfb $NEWDISPLAY $SCREEN &> $LOGFILE &
  elif [ "`command -v Xvnc`" ]; then
    debug Xvnc command found. starting w args: $NEWDISPLAY $SCREEN
    Xvnc $NEWDISPLAY $SCREEN &> $LOGFILE &
  fi
}

check_running()
{
  check_running_result=
  check_running_pid=

  findpid Xvfb
  if [ $findpid_result ] ; then
    debug xvfb running;
    check_running_result=Xvfb
    check_running_pid=$findpid_result
  fi

  findpid Xvnc
  if [ $findpid_result ] ; then
    debug xvnc running;
    check_running_result=Xvnc
    check_running_pid=$findpid_result
  fi
}

if [ $1 ]; then
  if [ $1 = stop ]; then
    stop
    if [ ! $stop_result ]; then
      echo Neither Xvnc nor Xvfb were found running.
    fi
    exit
  fi
fi

start
sleep 2
check_running
if [ ! check_running_result ]; then
  echo Failed to start virtual framebuffer. Please see $LOGFILE
else
  echo "started "$check_running_result", pid "$check_running_pid", DISPLAY="$NEWDISPLAY", logfile "$LOGFILE
fi
