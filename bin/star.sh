#!/bin/sh

# default to sysperl
PATH=/usr/local/bin:$PATH

# save current directory
TOP_DIR=`pwd`
LOG_DIR=`pwd`/log
REPO_DIR=`pwd`/repos

# start fresh

for impl in parrot; do
    cd $TOP_DIR;
    rm -rf star-$impl
    git clone $REPO_DIR/star.git star-$impl
    cd star-$impl

    # get the latest everything

    git clone $REPO_DIR/parrot.git
    (cd parrot && git describe --tags > VERSION_GIT)
    git clone $REPO_DIR/MoarVM.git
    (cd MoarVM && git describe --tags > VERSION_GIT)
    git clone $REPO_DIR/nqp.git
    (cd nqp && git ls-files > MANIFEST; git describe > VERSION)
    git clone $REPO_DIR/rakudo.git
    (cd rakudo && git ls-files > MANIFEST; git describe > VERSION)

    # setup the modules to pull the latest, not just the declared version)
    #git submodule init
    #git submodule update
    #(cd modules; for file in * ; do (cd $file && git fetch origin; git reset --hard origin/master); done)

    make -f tools/star/Makefile manifest

    # get submodules # ??? is this doing anything?
    #git submodule foreach git pull origin master 2>&1 | tee submodule.log

    # log the versions used on everything
    echo $impl > $LOG_DIR/$impl-version.log
    cat $impl/VERSION_GIT >> $LOG_DIR/$impl-version.log
    echo "Rakudo" > $LOG_DIR/$impl-version.log
    cat rakudo/VERSION >> $LOG_DIR/$impl-version.log
    echo "NQP"   >> $LOG_DIR/$impl-version.log
    cat nqp/VERSION >> $LOG_DIR/$impl-version.log
    echo "modules"  >> $LOG_DIR/$impl-version.log
    #(cd modules; for file in * ; do echo "--------"; echo $file; (cd $file; git log HEAD^..HEAD); done) >> $LOG_DIR/$impl-version.log
    
    # make a release candidate
    make -f tools/star/Makefile release VERSION=daily 2>&1 | tee makefile.log
    
    # explode the release candidate
    tar xvf rakudo-star-daily.tar.gz
    
    # build it.
    cd rakudo-star-daily
    config_args="";
    if [ "$impl" = "parrot" ] ; then 
        config_args="--gen-parrot"
    elif [ "$impl" = "MoarVM" ] ; then
        config_args="--gen-moar"
    fi
    perl Configure.pl --backend=$impl --gen-nqp $config_args 2>&1 | tee $LOG_DIR/$impl-configure.log

    make install 2>&1 | tee $LOG_DIR/$impl-build.log
    
    # run tests
    make rakudo-test 2>&1 | tee $LOG_DIR/$impl-test-rakudo.log
    make modules-test 2>&1 | tee $LOG_DIR/$impl-test-modules.log
done
