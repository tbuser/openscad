

if [ "`cat /etc/issue | grep -i 'Red Hat Enterprise'`" ]; then
  echo "Redhat Enterprise Linux detected"
  sudo yum install curl git qt-devel bison flex libXmu-devel \
   ImageMagick xorg-x11-server-Xvfb tigervnc-server

  if [ "`grep define.*__GNU_MP__.4 /usr/include/mp.h`" ]; then
    echo "GMP too old. Please try 'old linux' build (see README.md)"
    exit
  fi
  if [ ! -e /usr/include/CGAL/version.h ]; then
    echo "CGAL not found. Please try 'old linux' build (see README.md)"
    exit
  fi
  if [ ! -e /usr/include/opencsg.h ]; then
    echo "OpenCSG not found. Please try 'old linux' build (see README.md)"
    exit
  fi

  exit
fi


if [ "`cat /etc/issue | grep -i 'Fedora'`" ]; then
  echo "Tested on Fedora 17. If this fails try 'old linux' build (see README.md)"
  sleep 2

  sudo yum install curl cmake git qt-devel bison flex libXmu-devel ImageMagick \
   xorg-x11-server-Xvfb curl wget bash \
   eigen2-devel \
   boost-devel mpfr-devel gmp-devel glew-devel CGAL-devel gcc pkgconfig git

  echo
  echo "Now copy/paste the following to install OpenCSG from source:"
  echo
  # https://bugzilla.redhat.com/show_bug.cgi?id=144967
  echo "sudo echo /usr/local/lib | sudo tee -a /etc/ld.so.conf.d/local.conf"
  echo "sudo ldconfig"
  echo "sudo BASEDIR=/usr/local ./scripts/uni-build-dependencies.sh opencsg"
  echo
fi



too_old_debian()
{
  sudo apt-get install build-essential libqt4-dev libqt4-opengl-dev \
   libXi-dev libxmu-dev cmake bison flex git-core curl wget imagemagick
  echo
  echo "System version too low. Please try 'old linux' build (see README.md)"
  exit
}

if [ "`cat /etc/issue | grep Debian`" ]; then
  echo "Debian detected"
  if [ "`cat /etc/issue | grep 'Debian GNU/Linux 6.0'`" ]; then
    too_old_debian
  fi
  if [ "`cat /etc/issue | grep 'Debian GNU/Linux 5'`" ]; then
    too_old_debian
  fi
fi


if [ "`cat /etc/issue | grep Ubuntu`" ]; then
  echo "Ubuntu detected"
  if [ "`cat /etc/issue | grep 'Ubunutu [2-9] '`" ]; then
    too_old_debian
  fi
  if [ "`cat /etc/issue | grep 'Ubunutu 10'`" ]; then
    too_old_debian
  fi
  echo "tested on Ubuntu 12. If this fails try 'old linux' build (see README.md)"
  sudo apt-get install build-essential libqt4-dev libqt4-opengl-dev \
   libXi-dev libxmu-dev cmake bison flex git-core imagemagick curl wget \
   libeigen2-dev libboost-all-dev \
   libmpfr-dev libgmp-dev libboost-dev libglew1.6-dev \
   libcgal-dev libopencsg-dev
fi


if [ "`cat /etc/issue | grep -i opensuse`" ]; then
  echo "tested on OpenSUSE 12. If this fails try 'old linux' build (see README.md)"

  sudo zypper install libeigen2-devel mpfr-devel gmp-devel boost-devel \
   libqt4-devel glew-devel cmake git bash ImageMagick-devel curl wget

  echo "now copy/paste the following to install CGAL and OpenCSG from source:"
  echo "sudo BASEDIR=/usr/local ./scripts/uni-build-dependencies.sh cgal"
  echo "sudo BASEDIR=/usr/local ./scripts/uni-build-dependencies.sh opencsg"
fi

