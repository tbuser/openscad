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
#
# Purpose:
#  Used to start/stop a virtual framebuffer device on linux/bsd systems,
#  For integration with Cmake's Ctest tool, specifically the
#  CTestCustom.template and CMakeLists.txt from OpenSCAD.
#
#  By stop we mean kill all Xvfb/Xvnc processes running under the user's
#  uid, there is no mechanism in this particular design, as-is, to run
#  multiple VFBs & Ctest under a single userid.
#
# Usage:
#  See print_usage()
#
# Output:
#  In 'start' mode, the script should print DISPLAY=:x (x=a number)
#  which will get scraped by the CTestCustom.template ctest script
#
# Design:
#  Try to be portable to different shells and linux/bsd systems. This is 
#  not needed on Mac & Win, they have alternate access for OpenGL.
#
# Bugs:
#  Doesn't handle one user with multiple virtual fb's running
#  Doesn't detect if DISPLAY env var is set but no X is setup on that DISPLAY
#  Doesn't auto figure-out DISPLAY, always uses :5
#
# Edit NEWDISPLAY as needed

NEWDISPLAY=:5
SCREEN='-screen 0 800x600x24'
DEBUG=
LOGFILE_ERR=virtualfb.err
LOGFILE_OUT=virtualfb.out

print_usage()
{
  echo "  virtualfb.sh start [debug]"
  echo "  virtualfb.sh stop [debug]"
}

debug()
{
  if [ $DEBUG ]; then echo virtualfb.sh: $* ; fi
}

# find DISPLAY of any virtual fb running under the currnet userid
find_display()
{
  vfb_program=$1
  if [ `uname | grep Linux` ]; then
    debug Linux detected
    find_display_result="`ps -fu$USER | grep $vfb_program | grep -v grep | \
      grep -v sed | sed s/".*$vfb_program.*:"// | sed s/" .*"//`"
  elif [ `uname | grep BSD` ]; then
    debug BSD detected
    find_display_result="`ps | grep $vfb_program | grep -v grep | grep -v sed | \
      grep -v sed | sed s/".*$vfb_program.*:"// | sed s/" .*"//`"
  else
    echo find display: unknown operating system
    exit
  fi
  debug find_display_result: $find_display_result
}

# find pid of any virtual fb running under the currnet userid
findpid()
{
  debug findpid called with arg $1
  findpid_result=
  if [ `uname | grep Linux` ]; then
    debug findpid: Linux detected
    findpid_result="`ps -fu$USER | grep $1 | grep -v grep | grep -v sed | \
     awk ' { print $2 } '`"
  elif [ `uname | grep BSD` ]; then
    debug findpid: BSD detected
    findpid_result="`ps | grep $1 | grep -v grep | grep -v sed | \
     awk ' { print $1 } '`"
  else
    echo findpid: unknown operating system
    exit
  fi
  debug "findpid result" $findpid_result
  return
}

# stop any virtual fb's running under the current userid
stop_()
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

# start a new virtual fb
start_()
{
  debug start called
  start_result=

  find_display Xvfb
  if [ $find_display_result ]; then
    echo "Xvfb already running. DISPLAY=:"$find_display_result
    start_result="already_running"
    return
  fi

  find_display Xvnc
  if [ $find_display_result ]; then
    echo "Xvnc already running. DISPLAY=:"$find_display_result
    start_result="already_running"
    return
  fi

  debug "No Xvfb or Xvnc detected running. Attempting to start"
  debug "Logging to $LOGFILE_OUT and $LOGFILE_ERR"

  # To stop ctest from 'blocking' (hanging), we use 2>&1 > f < f2
  # per http://en.wikipedia.org/wiki/Nohup#Overcoming_hanging
  if [ "`command -v Xvfb`" ]; then
    debug Xvfb command found. starting w args: $NEWDISPLAY $SCREEN
    nohup Xvfb $NEWDISPLAY $SCREEN > $LOGFILE_OUT 2> $LOGFILE_ERR < /dev/null &
    start_result=1
  elif [ "`command -v Xvnc`" ]; then
    debug Xvnc command found. starting w args: $NEWDISPLAY $SCREEN
    nohup Xvnc $NEWDISPLAY $SCREEN > $LOGFILE_OUT 2> $LOGFILE_ERR < /dev/null &
    start_result=1
  else
    echo "Could not find a virtual framebuffer program (looked for Xvfb & Xvnc)"
    start_result=0
  fi
  return
}

# check whether a virtual fb is running under the current userid
check_running()
{
  check_running_result_progname=
  check_running_result_pid=

  findpid Xvfb
  if [ $findpid_result ] ; then
    debug xvfb running;
    check_running_result_progname=Xvfb
    check_running_result_pid=$findpid_result
  else
    debug findpid Xvfb gave no result
  fi

  findpid Xvnc
  if [ $findpid_result ] ; then
    debug xvnc running;
    check_running_result_progname=Xvnc
    check_running_result_pid=$findpid_result
  else
    debug findpid Xvnc gave no result
  fi

  return
}

check_arguments()
{
  for i in $*; do
    if [ $i = debug ]; then
      DEBUG=1
    fi
  done

  if [ ! $1 ]; then return; fi
  if [ $1 = start ]; then return; fi
  if [ $1 = stop ]; then return; fi

  echo Unknown option: $1. Usage:
  print_usage
  echo program stopped.
  exit
}


main()
{
  check_arguments $*

  if [ $1 ]; then
    if [ $1 = stop ]; then
      stop_
      if [ ! $stop_result ]; then
        echo Neither Xvnc nor Xvfb were found running.
      fi
      exit
    fi
  fi

  start_
  if [ $start_result = "already_running" ]; then exit; fi
  if [ $start_result = 0 ]; then exit; fi
  sleep 1
  check_running
  if [ ! $check_running_result_progname ]; then
    echo "Failed to start virtual framebuffer. Please see $LOGFILE_OUT & $LOGFILE_ERR"
  else
    fbprog=$check_running_result_progname
    xpid=$check_running_result_pid
    echo "started "$fbprog", pid "$xpid", DISPLAY="$NEWDISPLAY", logs "$LOGFILE_OUT, $LOGFILE_ERR
  fi
}

debug calling main
main $*
exit 0

