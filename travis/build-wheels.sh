#!/bin/bash
set -e -x

# Install a system package required by our library
#yum update 
yum install -y guile-devel zlib-devel
#yum install -y portaudio-devel portmidi-devel libsndfile-devel liblo-devel

PATH=/usr/lib:$PATH
LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
PKG_CONFIG_PATH=/usr/lib/pkgconfig:$PKG_CONFIG_PATH

cd /io/deps/

echo ====== Build and install autogen. ======
tar -xzf autogen-5.11.8.tar.gz
cd autogen-5.11.8
./configure --prefix=/usr
make
make install
ldconfig
cd ..

# python version in /usr/bin is 2.4, link to 2.7.
rm /usr/bin/python
ln -s /opt/_internal/cpython-2.7.16-ucs4/bin/python /usr/bin/python

export ACLOCAL_PATH=/usr/share/aclocal

echo ====== Build and install libogg. ======
tar -xzf libogg-1.3.3.tar.gz
cd libogg-1.3.3
./configure --prefix=/usr
make
make install
ldconfig
cd ..

echo ====== Build and install libvorbis. ======
tar -xzf libvorbis-1.3.6.tar.gz
cd libvorbis-1.3.6
./configure --prefix=/usr
make
make install
ldconfig
cd ..

echo ====== Build and install libflac. ======
tar -xzf flac-1.3.2.tar.gz
cd flac-1.3.2
./autogen.sh
./configure --prefix=/usr
make
make install
ldconfig
cd ..

echo ====== Build and install libsndfile. ======
tar -xzf libsndfile-1.0.28.tar.gz
cd libsndfile-1.0.28
./autogen.sh
./configure CFLAGS="-I../flac-1.3.2/include -I../libvorbis-1.3.6/include  -I../libogg-1.3.3/include" --prefix=/usr
make
make install
ldconfig
cd ..

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