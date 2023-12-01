#!/bin/bash
set -x

export CPPDEFINES="BOOST_ALL_DYN_LINK"

# https://jira.mongodb.org/browse/SERVER-30893
if [[ $target_platform == linux-aarch64 ]]; then
   export CFLAGS="${CFLAGS:-} -march=armv8-a+crc"
fi

if [[ $target_platform != $build_platform ]]; then
    unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
fi

# https://github.com/llvm/llvm-project/commit/f47b8851
if [[ $target_platform =~ osx-* ]]; then
   export CFLAGS="${CFLAGS:-} -Wno-undef-prefix"
   export CPPDEFINES="${CPPDEFINES:-} _LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ $target_platform == "linux-aarch64" ]]; then
    # compilation errors on aarch due to the code wrongly assuming equality
    # between the native {con,de}structive_interference_size (64 vs. 256);
    # should be fixed as of mongo 7.x
    export CXXFLAGS="${CXXFLAGS} --param destructive-interference-size=64"
fi

export NINJA_STATUS="[%f+%r/%t] "

declare -a _scons_xtra_flags
_scons_xtra_flags+=(--dbg=off)
_scons_xtra_flags+=(--disable-warnings-as-errors)
_scons_xtra_flags+=(--enable-http-client=on)
_scons_xtra_flags+=(--opt=on)
_scons_xtra_flags+=(--release)
_scons_xtra_flags+=(--server-js=on)
_scons_xtra_flags+=(--ssl=on)
_scons_xtra_flags+=(--wiredtiger=on)
_scons_xtra_flags+=(--ninja=enabled)
_scons_xtra_flags+=(CC="$CC" CXX="$CXX" OBJCOPY="$OBJCOPY" CPPDEFINES="$CPPDEFINES")
_scons_xtra_flags+=(CCFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LINKFLAGS="$LDFLAGS")
_scons_xtra_flags+=(HOST_ARCH="$HOST")
_scons_xtra_flags+=(RPATH="$PREFIX/lib")
_scons_xtra_flags+=(VERBOSE=on)
_scons_xtra_flags+=(DESTDIR="$PREFIX")
_scons_xtra_flags+=(MONGO_VERSION="$PKG_VERSION")
_scons_xtra_flags+=(--use-system-{boost,icu,pcre2,snappy,yaml,zlib,zstd,abseil-cpp})

if [[ $target_platform =~ linux-* ]]; then
    _scons_xtra_flags+=(--linker=gold)
fi

python buildscripts/scons.py "${_scons_xtra_flags[@]}" generate-ninja
ninja -f build.ninja install-core
