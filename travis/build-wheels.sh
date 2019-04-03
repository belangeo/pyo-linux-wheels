#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y portaudio-devel portmidi-devel libsndfile-devel liblo-devel


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