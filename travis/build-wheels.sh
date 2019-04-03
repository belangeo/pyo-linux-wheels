#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y portaudio-devel portmidi-devel libsndfile-devel liblo-devel

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    #"${PYBIN}/pip" install -r /io/dev-requirements.txt
    "${PYBIN}/python" /io/pyo/setup.py build_ext --use-double --use-jack
    "${PYBIN}/pip" wheel /io/pyo/ -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair "$whl" -w /io/pyo/wheelhouse/
done

# Install packages and test
#for PYBIN in /opt/python/*/bin/; do
#    "${PYBIN}/pip" install python-manylinux-demo --no-index -f /io/wheelhouse
#    (cd "$HOME"; "${PYBIN}/nosetests" pymanylinuxdemo)
#done