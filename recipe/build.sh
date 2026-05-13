#!/bin/bash

set -x -e
set -o pipefail

CFLAGS="${CFLAGS} -I${PREFIX}/include -fPIC"
CXXFLAGS="${CXXFLAGS} -fPIC -w -fopenmp"

# OpenMP runtime: GNU libgomp on Linux, LLVM libomp on macOS.
if [[ "$(uname)" == "Darwin" ]]; then
    OMP_LIB="omp"
else
    OMP_LIB="gomp"
fi

BOOST_LIBS="boost_python${CONDA_PY}"
PYTHON_LIB_PATH="${PREFIX}/lib"
PYTHON_INC_PATH="${PREFIX}/include/python${PY_VER}"
PYTHON_LIB_NAME="python${PY_VER}"
BUILD_SILO=0

# debug
find ${PREFIX} -iname Python.h
find ${PREFIX} -iname libboost_python*
find ${PREFIX} -iname libpython*

export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH

# Source layout changed in 6.x: single tarball (no separate netcdf-cxx4
# folder), so build from ${SRC_DIR} directly rather than ${SRC_DIR}/escript.
cd ${SRC_DIR}

# conda-forge ships umfpack.h under include/suitesparse/, but scons
# findLibWithHeader only handles include/<header> when given a string prefix.
# SCons CLI args are strings, so set the [include, lib] list in the options
# file instead.
cat >> ${SRC_DIR}/scons/templates/anaconda_options.py <<EOF

import os as _os
umfpack_prefix = [_os.path.join('${PREFIX}', 'include', 'suitesparse'),
                  _os.path.join('${PREFIX}', 'lib')]
del _os

# hdf5_libs defaults to the literal string 'DEFAULT' which the build then
# tries to -lDEFAULT. Set the real conda-forge lib names.
hdf5_libs = ['hdf5_cpp', 'hdf5']
EOF

# dependencies.py hard-codes a Windows-style 'Lib/' path when CONDA_PREFIX is
# set, which fails on Linux. Patch it to use numpy.get_include() instead.
NUMPY_INC=$(${PREFIX}/bin/python -c 'import numpy; print(numpy.get_include())')
sed -i "s|conda_prefix+'/Lib/site-packages/numpy/core/include'|'${NUMPY_INC}'|" \
    ${SRC_DIR}/site_scons/dependencies.py

scons -j"${CPU_COUNT}" \
    options_file="${SRC_DIR}/scons/templates/anaconda_options.py" \
    build_dir=${BUILD_PREFIX}/escript_build \
    boost_prefix=${PREFIX} \
    boost_libs=${BOOST_LIBS} \
    cxx=${CXX} \
    cppunit_prefix=${PREFIX} \
    hdf5_prefix=${PREFIX} \
    ld_extra="-L${PREFIX}/lib -l${OMP_LIB}" \
    openmp=0 \
    omp_flags="-fopenmp" \
    paso=1 \
    PREFIX=${PREFIX} \
    pythoncmd=${PREFIX}/bin/python \
    pythonlibpath=${PYTHON_LIB_PATH} \
    pythonincpath=${PYTHON_INC_PATH} \
    pythonlibname=${PYTHON_LIB_NAME} \
    silo=${BUILD_SILO} \
    silo_prefix=${PREFIX} \
    trilinos=0 \
    build_trilinos=never \
    trilinos_src=${SRC_DIR} \
    umfpack=1 \
    build_full || cat config.log

ln -s ${PREFIX}/lib/buildvars ${PREFIX}/lib/buildvars.in
cp -R ${PREFIX}/esys ${SP_DIR}/esys
cp -R ${BUILD_PREFIX}/escript_build/scripts/release_sanity.py /tmp/release_sanity.py
