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

# setup the modules to pull the latest, not just the declared version)
git submodule init
git submodule update
(cd modules; for file in * ; do (cd $file && git fetch origin; git reset --hard origin/master); done)

make -f tools/star/Makefile manifest

# get submodules # ??? is this doing anything?
git submodule foreach git pull origin master 2>&1 | tee submodule.log

# log the versions used on everything
echo "Rakudo" > $LOG_DIR/version.log
cat rakudo/VERSION >> $LOG_DIR/version.log
echo "NQP"   >> $LOG_DIR/version.log
cat nqp/VERSION >> $LOG_DIR/version.log
echo "modules"  >> $LOG_DIR/version.log
(cd modules; for file in * ; do echo "--------"; echo $file; (cd $file; git log HEAD^..HEAD); done) >> $LOG_DIR/version.log

# make a release candidate
make -f tools/star/Makefile release VERSION=daily 2>&1 | tee makefile.log

# explode the release candidate
tar xvf rakudo-star-daily.tar.gz

# build it.
cd rakudo-star-daily
perl Configure.pl --backend=parrot --gen-nqp --gen-parrot 2>&1 | tee $LOG_DIR/configure.log
make install 2>&1 | tee $LOG_DIR/build.log

# run tests
make rakudo-test 2>&1 | tee $LOG_DIR/test-rakudo.log
make modules-test 2>&1 | tee $LOG_DIR/test-modules.log
