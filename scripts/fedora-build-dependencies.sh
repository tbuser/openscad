
# RHEL does not contain CGAL, has very outdated GMP, etc. 
if [ "`cat /etc/issue | grep -i 'Red hat Enterprise'`" ]; then
	sudo yum install curl git qt-devel bison flex libXmu-devel \
	 ImageMagick xorg-x11-server-Xvfb
        echo "RHEL detected. Please try 'old linux' build (see README.md)"
        exit
fi

echo "Tested on Fedora 17. If this fails try 'old linux' build (see README.md)"
sleep 2

sudo yum install curl cmake git qt-devel bison flex libXmu-devel ImageMagick \
 xorg-x11-server-Xvfb \
 eigen2-devel \
 boost-devel mpfr-devel gmp-devel glew-devel CGAL-devel gcc pkgconfig git

#echo "now copy/paste the following to install CGAL and OpenCSG from source:"
#echo "sudo BASEDIR=/usr/local ./scripts/linux-build-dependencies.sh cgal-use-sys-libs"

echo
echo "Now copy/paste the following to install OpenCSG from source:"
echo
# https://bugzilla.redhat.com/show_bug.cgi?id=144967
echo "sudo echo /usr/local/lib | sudo tee -a /etc/ld.so.conf.d/local.conf"
echo "sudo ldconfig"
echo "sudo BASEDIR=/usr/local ./scripts/linux-build-dependencies.sh opencsg"
echo

