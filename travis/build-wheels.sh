#!/bin/bash
set -e -x

# Install a system package required by our library
#yum update 
yum install -y guile-devel
#yum install -y portaudio-devel portmidi-devel libsndfile-devel liblo-devel

PATH=/usr/lib:$PATH

cd /io/deps/

tar -xzf autogen-5.11.8.tar.gz
cd autogen-5.11.8
./configure --prefix=/usr
make
make install
ldconfig
cd ..

#find / -name autogen.h
find / -name  python

echo $PATH

ln -s /usr/bin/python /opt/_internal/cpython-2.7.16-ucs4/bin/python

python --version

tar -xzf libsndfile-1.0.28.tar.gz
cd libsndfile-1.0.28
./autogen.sh
./configure --prefix=/usr
# make
#sudo make install

# Compile wheels
cd /io/pyo/
for PYBIN in /opt/python/*/bin; do
    #"${PYBIN}/pip" install -r /io/dev-requirements.txt
    "${PYBIN}/python" setup.py build_ext --minimal --use-double --use-jack
    "${PYBIN}/pip" wheel . -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair "$whl" -w wheelhouse/
done

# Install packages and test
#for PYBIN in /opt/python/*/bin/; do
#    "${PYBIN}/pip" install python-manylinux-demo --no-index -f /io/wheelhouse
#    (cd "$HOME"; "${PYBIN}/nosetests" pymanylinuxdemo)
#done