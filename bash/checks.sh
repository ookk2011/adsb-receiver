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

## CHECK DUMP1090

function dump1090_status() {

    # Set default variable.
    DUMP1090[installed]='false'
    DUMP1090[upgradeable]='false'

    # Build an array containing all the supported dump1090 packages.
    SUPPORTED_DUMP1090_FORKS=('dump1090-mutability' 'dump1090-fa' 'dump1090-hptoa')

    # Determine if a Dump1090 fork is currently installed and if so which one it is.
    for FORK in "${SUPPORTED_DUMP1090_FORKS[@]}"
    do
        if [ $(dpkg-query -W -f='${STATUS}' $FORK 2>/dev/null | grep -c 'ok installed') -eq 1 ] ; then
            DUMP1090[installed]='true'
            DUMP1090[fork]=$FORK
            break
        fi
    done

    # If a Dump1090 fork is installed check if an upgrade is available.
    if [ "${DUMP1090[installed]}" == 'true' ] ; then
        case $DUMP1090[fork] in
            'dump1090-mutability'|'dump1090-hptoa')

                # Dump1090-Mutability
                # -------------------
                # Version 1.15~dev is the most current version and is still being maintained and continues to be updated however no new releases are being made.
                # This being said there is no real way to tell if a new version is available so we will automatically set this package to be upgradeable.

                # Dump1090-HPTOA
                # --------------
                # Dump1090-hptoa is handled the same way being there have yet to be any real release made yet.

                DUMP1090[upgradeable]='true'
                ;;
            'dump1090-fa')
                # Check if a new version of dump1090-fa is available.
                if [ $(sudo dpkg -s dump1090-fa 2>/dev/null | grep -c "Version: ${CURRENT_DUMP1090_FA_VERSION}") ] ; then
                    DUMP1090[upgradeable]='true'
                fi
                ;;
        esac
    fi
}

## CHECK DUMP1090

function dump978_status() {

    # Set default variable.
    DUMP978[installed]='false'
    DUMP978[upgradeable]='false'

    # Check if the Dump978 binaries are present.
    if [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/dump978" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2text" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2esnt" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2json" ] ; then
        # It appears Dump978 has been compiled and since Dump978 is not versioned the upgrade option should be made available.
        DUMP978[installed]='true'
        DUMP978[upgradeable]='true'
    fi
}
