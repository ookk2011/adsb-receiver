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

## SOURCE EXTERNAL SCRIPTS

source ${PROJECT_BASH_DIRECTORY}/functions.sh

## DUMP1090 STATUS

SUPPORTED_DUMP1090_FORKS=('dump1090-mutability' 'dump1090-fa')

# Determine if a Dump1090 fork is currently installed and if so which one it is.
for FORK in "${SUPPORTED_DUMP1090_FORKS[@]}"
do
    if [ $(dpkg-query -W -f='${STATUS}' $FORK 2>/dev/null | grep -c 'ok installed') -eq 1 ] ; then
        DUMP1090_INSTALLED='true'
        DUMP1090_INSTALLED_FORK=$FORK
        break
    fi

    # Dump1090 HPTOA does not install as a deb package so we need to check for it differently.
    if [ "$DUMP1090_INSTALLED" == "false" ] ; then
        if [ -f  ${PROJECT_BUILD_DIRECTORY}/dump1090-hptoa/dump1090-hptoa/build/dump1090 ] && [ -f ${PROJECT_BUILD_DIRECTORY}/dump1090-hptoa/dump1090-hptoa/build/faup1090 ] && [ -f ${PROJECT_BUILD_DIRECTORY}/dump1090-hptoa/dump1090-hptoa/build/view1090 ] && [ -f /etc/init.d/dump1090 ] ; then
            DUMP1090_INSTALLED='true'
            DUMP1090_INSTALLED_FORK='dump1090-hptoa'
        fi
    fi
fi

# If a Dump1090 fork is installed check if an upgrade is available.
if [ "$DUMP1090_INSTALLED" == 'true' ] ; then
    case $DUMP1090_FORK in
        'dump1090-mutability'|'dump1090-hptoa')

            # Dump1090-Mutability
            # -------------------
            # Version 1.15~dev is the most current version and is still being maintained and continues to be updated however no new releases are being made.
            # This being said there is no real way to tell if a new version is available so we will automatically set this package to be upgradeable.

            # Dump1090-HPTOA
            # --------------
            # Dump1090-hptoa is handled the same way being there have yet to be any real release made yet.

            DUMP1090_UPGRADEABLE='true'

            # Assign variables which may be used during the installation process from the Dump1090 configuration if Dump1090 is installed.
            DUMP1090_DEVICE_ID=`GetConfig` 'DEVICE' '/etc/default/dump1090-mutability'`
            RECEIVER_LATITUDE=`GetConfig 'LAT' '/etc/default/dump1090-mutability'`
            RECEIVER_LONGITUDE=`GetConfig 'LON' '/etc/default/dump1090-mutability'`
            ;;
        'dump1090-fa')
            # Check if a new version of dump1090-fa is available.
            if [ $(sudo dpkg -s dump1090-fa 2>/dev/null | grep -c "Version: ${CURRENT_DUMP1090_FA_VERSION}") ] ; then
                DUMP1090_UPGRADEABLE='true'
            fi
            ;;
    esac
fi

## DUMP978 STATUS

DUMP978_INSTALLED='false'
DUMP978_UPGRADEABLE='false'

# Check if the Dump978 binaries are present.
if [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/dump978" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2text" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2esnt" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2json" ] ; then
    # It appears Dump978 has been compiled and since Dump978 is not versioned the upgrade option should be made available.
    DUMP978_INSTALLED='true'
    DUMP978_UPGRADEABLE='true'
    DUMP978_DEVICE_ID=`grep -n '/dump978' /etc/rc.local | grep -oP "(?<=-d ).*?(?= -f)"`
fi

## ADS-B EXCHANGE STATUS

ADSB_EXCHANGE_MLAT_CLIENT_INSTALLED='false'
ADSB_EXCHANGE_MLAT_CLIENT_UPGRADEABLE='false'

# Check if mlat-client is installed or if an upgrade is possible.
if [ $(dpkg-query -W -f='${STATUS}' mlat-client 2>/dev/null | grep -c "ok installed") -eq 1 ] && [ ] ; then
    ADSB_EXCHANGE_MLAT_CLIENT_INSTALLED='true'
    ADSB_EXCHANGE_MLAT_CLIENT_INSTALLED_VERSION=`sudo dpkg -s mlat-client | grep "^Version:" | awk '{print $2}'`
    if [ "$ADSB_EXCHANGE_MLAT_CLIENT_INSTALLED_VERSION" != "$CURRENT_ADSB_EXCHANGE_MLAT_CLIENT_VERSION" ] ; then
        ADSB_EXCHANGE_MLAT_CLIENT_UPGRADEABLE='true'
    fi
fi

ADSB_EXCHANGE_CONFIGURED='false'

# Check if ADS-B Exchange feed is configured.
if [ -f /etc/rc.local ] ; then
    ADSB_EXCHANGE_SOCAT_LINE="${PROJECT_BUILD_DIRECTORY}/adsbexchange/adsbexchange-socat_maint.sh &"
    ADSB_EXCHANGE_MLAT_LINE="${PROJECT_BUILD_DIRECTORY}/adsbexchange/adsbexchange-mlat_maint.sh &"
    if [ -z $(grep "$ADSB_EXCHANGE_SOCAT_LINE" /etc/rc.local) ] && [ -z $(grep "$ADSB_EXCHANGE_MLAT_LINE}" /etc/rc.local) ]; then
        ADSB_EXCHANGE_CONFIGURED='true'
    fi
fi

## ADSBHUB STATUS

ADSBHUB_INSTALLED='false'

# Check that the ADSBHub script is present on this device.
if [ -f ${PROJECT_BUILD_DIRECTORY}/adsbhub/adsbhub.sh ] ; then
    ADSBHUB_INSTALLED='true'
fi

ADSBHUB_CONFIGURED='false'

# Check if ADSBHub script exists and is configured properly.
if [ -f /etc/rc.local ] ; then
    ADSBHUB_START_UP_LINE="${PROJECT_BUILD_DIRECTORY}/adsbhub/adsbhub.sh &"
   if [ -z $(grep "$ADSBHUB_START_UP_LINE" /etc/rc.local) ] ; then
       ADSBHUB_CONFIGURED='true'
   fi
fi

## FR24FEED STATUS

FR24FEED_PACKAGE_INSTALLED='false'
FR24FEED_PACKAGE_UPGRADABLE='false'

# Check if Flightradar24 Feeder is installed.
if [ $(dpkg-query -W -f='${STATUS}' fr24feed 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    FR24FEED_PACKAGE_INSTALLED='true'

    # If this is an i386 or x86_64 device check to see if an update is available.
    if [ "$DEVICE_CPU_ARCHITECTURE" == 'i386' ] || [ "$DEVICE_CPU_ARCHITECTURE" == 'x86_64' ] ; then
        FR24FEED_PACKAGE_VERSION_I386=`sudo dpkg -s fr24feed | grep "^Version:" | awk '{print $2}'`
        if [ "$FR24FEED_PACKAGE_VERSION_I386" != "$CURRENT_FR24FEED_PACKAGE_VERSION_I386" ] ; then
            FR24FEED_PACKAGE_UPGRADEABLE='true'
        fi
    fi
fi

## OPENSKY FEEDER STATUS

OPENSKY_FEEDER_INSTALLED='false'

# Check if OpenSky Feeder is installed.
if [ $(dpkg-query -W -f='${STATUS}' opensky-feeder 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    OPENSKY_FEEDER_INSTALLED='true'
fi

## PIAWARE STATUS

PIAWARE_INSTALLED='false'
PIAWARE_UPGRADEABLE='false'

# Check if PiAware is installed and if an upgrade is available.
if [ $(dpkg-query -W -f='${STATUS}' piaware 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    PIAWARE_INSTALLED='true'
    PIAWARE_INSTALLED_VERSION=`sudo dpkg -s piaware | grep "^Version:" | awk '{print $2}'`
    if [ "$PIAWARE_INSTALLED_VERSION" != "$CURRENT_PIAWARE_VERSION" -eq 0 ] ; then
        PIAWARE_UPGRADEABLE='true'
    fi
fi

## PLANEFINDER CLIENT STATUS

PLANEFINDER_CLIENT_INSTALLED='false'
PLANEFINDER_CLIENT_UPGRADEABLE='false'

if [ $(dpkg-query -W -f='${STATUS}' pfclient 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    PLANEFINDER_CLIENT_INSTALLED='true'
    PLANEFINDER_CLIENT_INSTALLED_VERSION=`sudo dpkg -s pfclient | grep "^Version:" | awk '{print $2}'`

    # Determine which package architecture to use when installing the client if this is not a i386 compatable device.
    case $DEVICE_CPU_ARCHITECTURE in
        'armv7l'|'armv6l'|'aarch64')
            PLANEFINDER_CLIENT_ARCHITECTURE='armhf'

            # Check if there is an upgrade available for the armhf version of the software package.
            if [ "$PLANEFINDER_CLIENT_INSTALLED_VERSION" != "$CURRENT_PLANEFINDER_CLIENT_VERSION_ARMHF" ] ; then
                PLANEFINDER_CLIENT_UPGRADEABLE='true'
            fi
            ;;
        *)
            PLANEFINDER_CLIENT_ARCHITECTURE='i386'

            # Check if there is an upgrade available for the i386 version of the software package.
            if [ "$PLANEFINDER_CLIENT_INSTALLED_VERSION" != "$CURRENT_PLANEFINDER_CLIENT_VERSION_I386" ] ; then
                PLANEFINDER_CLIENT_UPGRADEABLE='true'
            fi
    esac
fi

## PORTAL STATUS

