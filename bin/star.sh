#!/bin/sh -x

# default to sysperl
PATH=/usr/local/bin:$PATH

# save current directory
LOG_DIR=`pwd`/log

# start fresh
rm -rf star

git clone git@github.com:rakudo/star.git
cd star
# get skeleton
make -f tools/star/Makefile

# get submodules
git submodule foreach git pull origin master

# make a release candidate
make -f tools/star/Makefile release VERSION=daily

# explode the release candidate
tar xvf rakudo-star-daily.tar.gz

# build it.
cd rakudo-star-daily
perl Configure.pl --gen-nqp --gen-parrot 2>&1 | tee $LOG_DIR/configure.log
make install 2>&1 | tee $LOG_DIR/build.log

# run tests
make rakudo-test 2>&1 | tee $LOG_DIR/test-rakudo.log
make rakudo-spectest 2>&1 | tee $LOG_DIR/test-roast.log
make modules-test 2>&1 | tee $LOG_DIR/test-modules.log
