#!/bin/bash
# This script is invoked from my Travis-CI commands
# It bootstraps to grab the 'neil' tool and run 'neil test'
set -e # exit on errors
set -x # echo each line

retry(){ "$@" || "$@" || "$@"; }

if [ "$GHCVER" != "" ]; then
    if [ "$GHCVER" = "head" ]; then
        CABALVER=head
    else
        CABALVER=1.18
    fi
    retry sudo add-apt-repository -y ppa:hvr/ghc
    retry sudo apt-get update
    retry sudo apt-get install ghc-$GHCVER cabal-install-$CABALVER happy-1.19.4 alex-3.1.3
    export PATH=/opt/ghc/$GHCVER/bin:/opt/cabal/$CABALVER/bin:/opt/happy/1.19.4/bin:/opt/alex/3.1.3/bin:/home/travis/.cabal/bin:$PATH
    sudo /opt/ghc/$GHCVER/bin/ghc-pkg expose binary # on GHC 7.2 it is installed, but not exposed
fi

retry cabal update
retry cabal install --only-dependencies --enable-tests
retry git clone https://github.com/ndmitchell/neil
(cd neil && retry cabal install --flags=small)
if [ -e travis.hs ]; then
    # ensure that reinstalling this package won't break the test script
    mkdir travis
    ghc --make travis.hs -outputdir travis -o travis/travis
fi
neil test --install
if [ -e travis.hs ]; then
    travis/travis
fi
git diff --exit-code # check regenerating doesn't change anything
