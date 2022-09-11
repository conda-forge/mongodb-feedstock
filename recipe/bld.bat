@echo ON
setlocal ENABLEDELAYEDEXPANSION

:REM it seems that ABSEIL requires some flag to be defined
:REM in windows if one uses the DLL
:REM https://github.com/conda-forge/mongodb-feedstock/pull/60#issuecomment-1242901106
:REM https://github.com/microsoft/vcpkg/issues/12021
:REM This flag can be removed when
:REM is merged https://github.com/conda-forge/abseil-cpp-feedstock/pull/49
set "CXXFLAGS=-DABSL_CONSUME_DLL %CXXFLAGS%"

set "NINJA_STATUS=[%%f+%%r/%%t] "

set "_scons_xtra_flags="
set "_scons_xtra_flags=--dbg=off"
set "_scons_xtra_flags=%_scons_xtra_flags% --disable-warnings-as-errors"
set "_scons_xtra_flags=%_scons_xtra_flags% --enable-free-mon=on"
set "_scons_xtra_flags=%_scons_xtra_flags% --enable-http-client=on"
set "_scons_xtra_flags=%_scons_xtra_flags% --link-model=static"
set "_scons_xtra_flags=%_scons_xtra_flags% --opt=on"
set "_scons_xtra_flags=%_scons_xtra_flags% --release"
set "_scons_xtra_flags=%_scons_xtra_flags% --server-js=on"
set "_scons_xtra_flags=%_scons_xtra_flags% --ssl=on"
set "_scons_xtra_flags=%_scons_xtra_flags% --wiredtiger=on"
set "_scons_xtra_flags=%_scons_xtra_flags% --ninja=enabled"
set "_scons_xtra_flags=%_scons_xtra_flags% VERBOSE=on"
set "_scons_xtra_flags=%_scons_xtra_flags% DESTDIR=%LIBRARY_PREFIX%"

for %%v in (boost icu pcre snappy yaml zlib zstd abseil-cpp) do (
 set "_scons_xtra_flags=!_scons_xtra_flags! --use-system-%%v"
)

set "_scons_xtra_flags=%_scons_xtra_flags% CCFLAGS=/I%LIBRARY_INC%"
set "_scons_xtra_flags=%_scons_xtra_flags% CXXFLAGS=/I%LIBRARY_INC%"
set "_scons_xtra_flags=%_scons_xtra_flags% LINKFLAGS=/LIBPATH:%LIBRARY_LIB%"
set "_scons_xtra_flags=%_scons_xtra_flags% CPPDEFINES=BOOST_ALL_DYN_LINK"

python buildscripts\scons.py %_scons_xtra_flags% generate-ninja
ninja -f build.ninja install-core
