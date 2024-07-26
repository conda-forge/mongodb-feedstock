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

# need extra include path for js-confdefs.h which is target-dependent, see
# https://github.com/mongodb/mongo/blob/r7.3.0-rc4/bazel/mongo_src_rules.bzl#L340-L349
JS_CONFDEFS_BASE="src/third_party/mozjs/platform"
if [[ $target_platform == linux-64 ]]; then
    # see https://scons.org/doc/latest/HTML/scons-user/apa.html#cv-CPPPATH
    export CPPPATH="#/${JS_CONFDEFS_BASE}/x86_64/linux/include"
elif [[ $target_platform == linux-aarch64 ]]; then
    export CPPPATH="#/${JS_CONFDEFS_BASE}/aarch64/linux/include"
elif [[ $target_platform == linux-ppc64le ]]; then
    export CPPPATH="#/${JS_CONFDEFS_BASE}/ppc64le/linux/include"
elif [[ $target_platform == osx-64 ]]; then
    export CPPPATH="#/${JS_CONFDEFS_BASE}/x86_64/macOS/include"
elif [[ $target_platform == osx-arm64 ]]; then
    export CPPPATH="#/${JS_CONFDEFS_BASE}/aarch64/macOS/include"
fi

# build of mozjs also needs includes from that source folder...
export CPPPATH="$CPPPATH #/src/third_party/mozjs/extract/js/src"
# ... and the general includes for mozjs
export CPPPATH="$CPPPATH #/src/third_party/mozjs/include"
# ... and another
export CPPPATH="$CPPPATH #/src/third_party/mozjs/extract/mfbt"

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
_scons_xtra_flags+=(CPPPATH="$CPPPATH")
_scons_xtra_flags+=(HOST_ARCH="$HOST")
_scons_xtra_flags+=(RPATH="$PREFIX/lib")
_scons_xtra_flags+=(VERBOSE=on)
_scons_xtra_flags+=(DESTDIR="$PREFIX")
_scons_xtra_flags+=(MONGO_VERSION="$PKG_VERSION")
_scons_xtra_flags+=(--use-system-{boost,icu,pcre2,snappy,yaml,zlib,zstd,abseil-cpp})

if [[ $target_platform =~ linux-* ]]; then
    _scons_xtra_flags+=(--linker=gold)
    # cirun-openstack-cpu-large runs out of memory with default parallelism
    PARALELLISM="-j2"
else
    # ensure we pick up the required settings from
    # https://github.com/mongodb/mongo/blob/r7.0.12/SConstruct#L3818-L3827
    _scons_xtra_flags+=(--libc++)
fi

python buildscripts/scons.py "${_scons_xtra_flags[@]}" generate-ninja
ninja ${PARALELLISM} -f build.ninja install-core
