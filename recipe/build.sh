#!/bin/bash

set -x -e
set -o pipefail

CFLAGS="${CFLAGS} -I${PREFIX}/include -fPIC"
CXXFLAGS="${CXXFLAGS} -fPIC -w -fopenmp"

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
scons -j"${CPU_COUNT}" \
    options_file="${SRC_DIR}/scons/templates/anaconda_options.py" \
    build_dir=${BUILD_PREFIX}/escript_build \
    boost_prefix=${PREFIX} \
    boost_libs=${BOOST_LIBS} \
    cxx=${CXX} \
    cxx_extra="-w -fPIC -fdiagnostics-color=always -std=c++17 --verbose" \
    cppunit_prefix=${PREFIX} \
    ld_extra="-L${PREFIX}/lib -lgomp" \
    openmp=0 \
    omp_flags="-fopenmp" \
    paso=1 \
    prefix=${PREFIX} \
    pythoncmd=${PREFIX}/bin/python \
    pythonlibpath=${PYTHON_LIB_PATH} \
    pythonincpath=${PYTHON_INC_PATH} \
    pythonlibname=${PYTHON_LIB_NAME} \
    silo=${BUILD_SILO} \
    silo_prefix=${PREFIX} \
    trilinos=0 \
    build_trilinos=never \
    trilinos_src=${SRC_DIR} \
    umfpack=0 \
    umfpack_prefix=${PREFIX} \
    build_full || cat config.log

ln -s ${PREFIX}/lib/buildvars ${PREFIX}/lib/buildvars.in
cp -R ${PREFIX}/esys ${SP_DIR}/esys
cp -R ${BUILD_PREFIX}/escript_build/scripts/release_sanity.py /tmp/release_sanity.py
