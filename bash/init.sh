#!/bin/bash

#####################################################################################
#                            THE ADS-B RECEIVER PROJECT                             #
#####################################################################################
#                                                                                   #
# This script is not meant to be executed directly.                                 #
# Instead execute install.sh to begin the installation process.                     #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2015-2019 Joseph A. Prochazka                                       #
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy      #
# of this software and associated documentation files (the "Software"), to deal     #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
# copies of the Software, and to permit persons to whom the Software is             #
# furnished to do so, subject to the following conditions:                          #
#                                                                                   #
# The above copyright notice and this permission notice shall be included in all    #
# copies or substantial portions of the Software.                                   #
#                                                                                   #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     #
# SOFTWARE.                                                                         #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

DUMP_1090_FORKS=('dump1090-mutability' 'dump1090-fa')

DUMP_1090_INSTALLED='false'
DUMP_1090_UPGRADEABLE='false'

# Determine if a Dump 1090 fork is currently installed and if so which one it is.
for FORK in "${DUMP_1090_FORKS[@]}"
do
    if [ $(dpkg-query -W -f='${STATUS}' $FORK 2>/dev/null | grep -c "ok installed") -eq 1 ] ; then
        DUMP_1090_INSTALLED='true'
        DUMP_1090_INSTALLED_FORK=$FORK
    fi
fi

# If a Dump 1090 fork is installed check if an upgrade is available.
if [ "$DUMP_1090_INSTALLED" == 'true' ] ; then
    case $DUMP_1090_INSTALLED_FORK in
        'dump1090-mutability')
            DUMP_1090_UPGRADEABLE='true'
            ;;
        'dump1090-fa')
            if [ 'this' == 'that' ] ; then
                DUMP_1090_UPGRADEABLE='true'
            fi
            ;;
    esac
fi


DUMP_978_INSTALLED

