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

## DIALOGS

function dump978_dialogs() {

    if [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/dump978" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2text" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2esnt" ] && [ -f "${PROJECT_BUILD_DIRECTORY}/dump978/uat2json" ] ; then

        # Get the Dump1090 device setting from the Dump1090 configuration file.
        case "${DUMP1090[fork]}" in
            'dump1090-mutability') DUMP1090_DEVICE_ID=`GetConfig "DEVICE" "/etc/default/dump1090-mutability"` ;;
            'dump1090-fa') DUMP1090_DEVICE_ID=`GetConfig "DEVICE" "/etc/default/dump1090-fa"` ;;
            'dump1090-hptoa') DUMP1090_DEVICE_ID=`GetConfig "DEVICE" "/etc/default/dump1090-hptoa"` ;;
        esac

        # Get existing settings from the startup line in /etc/rc.local.
        DUMP978_DEVICE_ID=$(grep -n '/dump978' /etc/rc.local | grep -oP "(?<=-d ).*?(?= -f)")
        DUMP978_SAMPLERATE=$(grep -n '/dump978' /etc/rc.local | grep -oP "(?<=-s ).*?(?= -g)")
        DUMP978_GAIN=$(grep -n '/dump978' /etc/rc.local | grep -oP "(?<=-g ).*?(?= -)")
    fi

    # Begin displaying dialogs.
    if [ "${DUMP978[installed]}" == 'false' ] || [ "${DUMP978[upgradeable]}" == "true" ] ; then
        if [ "${DUMP978[installed]}" == 'false' ] ; then

            # This would be a clean installation of dump1090-fa.
            DUMP978_DO_INSTALL_TITLE='Install dump978-fa'
            DUMP978_DO_INSTALL_MESSAGE="Dump978 is an experimental demodulator/decoder for 978MHz UAT signals. More information on Dump978 can be found at the following address.\n\nhttps://github.com/flightaware/dump978"
        else

            # Dump1090-fa is currently installed.
            DUMP978_DO_INSTALL_TITLE='Recompile and configure dump978-fa.'
            DUMP978_DO_INSTALL_MESSAGE="It appears that Dump978 has already been compiled on this device. Being Dump978 is not versioned it is impossible to tell if you are actually running the latest available code. By continuing your local Dump978 git source code repository will be updated and the binaries recompiled using the latest source code."
        fi

        dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP978_DO_INSTALL_TITLE" --yesno "$DUMP978_DO_INSTALL_MESSAGE" 0 0
        case $? in
            0) DUMP978_DO_INSTALL='true' ;;
            1) DUMP978_DO_INSTALL='false' ;;
            255) exit 1 ;;
        esac
    fi

    DUMP1090_DEVICE_ID_TITLE='Dump1090 RTL-SDR Device'
    DUMP1090_DEVICE_ID_MESSAGE="Enter the RTL-SDR device index or serial number to be used by dump1090."
    if [ -z $DUMP1090_DEVICE_ID ] ; then
        $DUMP1090_DEVICE_ID='0'
    fi
    DUMP1090_DEVICE_ID=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_DEVICE_ID_TITLE" --inputbox "$DUMP1090_DEVICE_ID_MESSAGE" 0 0 "$DUMP1090_DEVICE_ID" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    DUMP978_DEVICE_ID_TITLE='Dump978 RTL-SDR Device'
    DUMP978_DEVICE_ID_MESSAGE="Enter the RTL-SDR device index or serial number to be used by dump978."
    if [ -z $DUMP978_DEVICE_ID ] ; then
        $DUMP978_DEVICE_ID='1'
    fi
    DUMP978_DEVICE_ID=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP978_DEVICE_ID_TITLE" --inputbox "$DUMP978_DEVICE_ID_MESSAGE" 0 0 "$DUMP978_DEVICE_ID" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    DUMP978_SAMPLERATE_TITLE='Dump978 RTL-SDR Samplerate'
    DUMP978_SAMPLERATE_MESSAGE="Enter the samplerate at which to run dump978."
    if [ -z $DUMP978_SAMPLERATE ] ; then
        $DUMP978_SAMPLERATE='2083334'
    fi
    DUMP978_SAMPLERATE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP978_SAMPLERATE_TITLE" --inputbox "$DUMP978_SAMPLERATE_MESSAGE" 0 0 "$DUMP978_SAMPLERATE" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    DUMP978_GAIN_TITLE='Dump978 RTL-SDR Gain'
    DUMP978_GAIN_MESSAGE="Enter the RTL-SDR gain in dB."
    if [ -z $DUMP978_GAIN ] ; then
        $DUMP978_GAIN='48'
    fi
    DUMP978_GAIN=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP978_GAIN_TITLE" --inputbox "$DUMP978_GAIN_MESSAGE" 0 0 "$DUMP978_GAIN" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    # Return the collected data.
    DUMP978[do_install]=$DUMP978_DO_INSTALL
    DUMP978[device_id]=$DUMP978_DEVICE_ID
    DUMP978[samplerate]=$DUMP978_SAMPLERATE
    DUMP978[gain]=$DUMP978_GAIN
    DUMP978[esnt_dest_addr]=$DUMP978_ESNT_DEST_ADDR
    DUMP978[json_dir]=$DUMP978_JSON_DIR
    dump978[log_messages]=$DUMP978_LOG_MESSAGES
    DUMP1090[device_id]=$DUMP1090_DEVICE_ID
}
