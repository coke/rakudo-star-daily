#!/bin/sh

# default to sysperl
PATH=/usr/local/bin:$PATH

# save current directory
LOG_DIR=`pwd`/log

# start fresh
rm -rf star

git clone git://github.com/rakudo/star.git
cd star

# get skeleton - don't use the default target, since we are building
# nqp-latest and rakudo-latest. (but keeping the defined version of parrot)

make -f tools/star/Makefile parrot
git clone https://github.com/perl6/nqp.git
(cd nqp && git ls-files > MANIFEST; git describe > VERSION)
git clone https://github.com/rakudo/rakudo.git
(cd rakudo && git ls-files > MANIFEST; git describe > VERSION)
make -f tools/star/Makefile manifest

# get submodules
git submodule foreach git pull origin master 2>&1 | tee submodule.log

# make a release candidate
make -f tools/star/Makefile release VERSION=daily 2>&1 | tee makefile.log

# explode the release candidate
tar xvf rakudo-star-daily.tar.gz

# build it.
cd rakudo-star-daily
perl Configure.pl --gen-nqp --gen-parrot 2>&1 | tee $LOG_DIR/configure.log
make install 2>&1 | tee $LOG_DIR/build.log

# run tests
make rakudo-test 2>&1 | tee $LOG_DIR/test-rakudo.log
make modules-test 2>&1 | tee $LOG_DIR/test-modules.log
