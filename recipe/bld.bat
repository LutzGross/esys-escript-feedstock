:: workaround for bug in win-64/boost-1.73.0-py38_11
if not exist "%LIBRARY_PREFIX%\include\boost\python.hpp" (
    if exist "%LIBRARY_PREFIX%\include\boost\python\python.hpp" (
        copy "%LIBRARY_PREFIX%\include\boost\python\python.hpp" "%LIBRARY_PREFIX%\include\boost"
    )
)

cd %SRC_DIR%
if errorlevel 1 exit /b 1

:: derive python "X.Y" -> "XY" (e.g. 3.11 -> 311) from conda's PY_VER
set PYVER=%PY_VER:.=%

:: write a conda-forge-specific options file (the bundled windows template
:: hard-codes a vcpkg cppunit path and enables mumps_seq from mingw-w64,
:: neither of which exist in the conda-forge environment)
(
    echo escript_opts_version = 203
    echo openmp = 1
    echo paso = 1
    echo trilinos = 0
    echo werror = 0
    echo verbose = 0
    echo compressed_files = 0
    echo cc_flags = '/EHsc /MD /DBOOST_ALL_NO_LIB /wd4068 /DH5_BUILT_AS_DYNAMIC_LIB'
    echo omp_flags = '/openmp'
    echo tools_names = ['msvc']
    echo hdf5 = 1
    echo hdf5_libs = ['hdf5_cpp', 'hdf5']
    echo umfpack = 0
    echo silo = 0
    echo mumps_seq = 0
    echo netcdf = 0
) > conda_win_options.py

call scons -j%CPU_COUNT% ^
    options_file="conda_win_options.py" ^
    build_dir="%BUILD_PREFIX%\escript_build" ^
    PREFIX="%PREFIX%" ^
    boost_prefix="%LIBRARY_PREFIX%" ^
    boost_libs="boost_python%PYVER%" ^
    cppunit_prefix="%LIBRARY_PREFIX%" ^
    hdf5_prefix="%LIBRARY_PREFIX%" ^
    build_trilinos=never ^
    trilinos_src="%SRC_DIR%" ^
    pythoncmd="%PYTHON%" ^
    pythonlibname="python3" ^
    pythonlibpath="%PREFIX%\libs" ^
    pythonincpath="%LIBRARY_INC%" ^
    build_full
if errorlevel 1 exit /b 1

xcopy /E /I /Y "%PREFIX%\esys" "%SP_DIR%\esys"
if errorlevel 1 exit /b 1
copy /y "%BUILD_PREFIX%\escript_build\scripts\release_sanity.py" "%TEMP%\release_sanity.py"
