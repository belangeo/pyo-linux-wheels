#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y guile-devel zlib-devel
#yum install -y portaudio-devel portmidi-devel libsndfile-devel liblo-devel

PATH=/usr/lib:$PATH
LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
PKG_CONFIG_PATH=/usr/lib/pkgconfig:$PKG_CONFIG_PATH

cd /io/deps/

echo ====== Build Berkley libdb. ======
tar -xzf db-6.2.23.NC.tar.gz
cd db-6.2.23.NC/build_unix
../dist/configure --prefix=/usr --enable-compat185 --enable-dbm --disable-static --enable-cxx --quiet
make --quiet
make install --quiet
ldconfig
cd ../..

echo ====== Build and install cmake. ======
tar -xzf cmake-3.13.4.tar.gz
cd cmake-3.13.4
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

echo ====== Build and install alsa-lib. ======
tar -xjf alsa-lib-1.1.8.tar.bz2
cd alsa-lib-1.1.8
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

# Build portmidi without java dependency from:
# https://github.com/schollz/portmidi-1
echo ====== Build and install portmidi. ======
tar -xzf portmidi-1-master.tar.gz
cd portmidi-1-master
cmake -DCMAKE_INSTALL_PREFIX=/usr .
make --quiet
make install --quiet
ldconfig
cd ..

echo ====== Build and install autogen. ======
tar -xzf autogen-5.11.8.tar.gz
cd autogen-5.11.8
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

# python version in /usr/bin is 2.4, link to 2.7 instead.
rm /usr/bin/python
ln -s /opt/_internal/cpython-2.7.16-ucs4/bin/python /usr/bin/python

export ACLOCAL_PATH=/usr/share/aclocal

echo ====== Build and install liblo. ======
tar -xzf liblo-0.30.tar.gz
cd liblo-0.30
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

echo ====== Build and install libogg. ======
tar -xzf libogg-1.3.3.tar.gz
cd libogg-1.3.3
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

echo ====== Build and install libvorbis. ======
tar -xzf libvorbis-1.3.6.tar.gz
cd libvorbis-1.3.6
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

echo ====== Build and install libflac. ======
tar -xzf flac-1.3.2.tar.gz
cd flac-1.3.2
./autogen.sh
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

echo ====== Build and install libsndfile. ======
tar -xzf libsndfile-1.0.28.tar.gz
cd libsndfile-1.0.28
./autogen.sh
# Not sure we really need CFLAGS here.
./configure CFLAGS="-I../flac-1.3.2/include -I../libvorbis-1.3.6/include  -I../libogg-1.3.3/include" --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

echo ====== Build and install portaudio. ======
tar -xzf pa_stable_v190600_20161030.tgz
cd portaudio
./configure --prefix=/usr --quiet
make --quiet
make install --quiet
ldconfig
cd ..

#echo ====== Build and install libffado. ======
#tar -xzf libffado-2.3.0.tgz
#cd libffado-2.3.0
#scons
#scons install
#ldconfig
#cd ..

echo ====== Build and install jack2. ======
tar -xzf jack2-1.9.12.tar.gz
cd jack2-1.9.12
./waf configure LDFLAGS="-lstdc++" --prefix=/usr --alsa=yes
./waf build
./waf install
ldconfig
cd ..

# Compile wheels
cd /io/pyo/
for PYBIN in /opt/python/*/bin; do
	if [ "$PYBIN" == "/opt/python/cp34-cp34m/bin" ]
	then
		continue
	fi
    #"${PYBIN}/pip" install -r /io/dev-requirements.txt
    "${PYBIN}/python" setup.py build_ext --use-double --use-jack
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