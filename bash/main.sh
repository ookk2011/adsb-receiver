#!/bin/bash

#####################################################################################
#                                  ADS-B RECEIVER                                   #
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

source ${PROJECT_BASH_DIRECTORY}/variables.sh
source ${PROJECT_BASH_DIRECTORY}/functions.sh

# Welcome Dialog
WELCOME_TITLE='Welcome'
WELCOME_MESSAGE="Welcome,\n\nThe goal of the ADS-B Receiver Project to simplify the software setup process required to run a new ADS-B receiver utilizing a RTL-SDR dongle to receive ADS-B signals from aircraft. This allows those intrested in setting up their own reciever to do so quickly and easily with only a basic knowledge of Linux and the various software packages available.\n\nTo learn more about the project please visit one of the projects official websites.\n\nProject Homepage: https://www.adsbreceiver.net.\nGitHub Repository: https://github.com/jprochazka/adsb-receiver\n\nGood hunting!"
dialog --stdout --keep-tite --backtitle "$PROJECT_TITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_MESSAGE" 0 0

# Dump 1090 Selection Dialog
DUMP_1090_TITLE='Choose Dump 1090 fork'
DUMP_1090_MESSAGE="Dump 1090 is a Mode S decoder designed for RTL-SDR devices.\n\nOver time there have been multiple forks of the original some of the more popular and requested ones are available for in installation. Please choose the fork which you wish to install."
DUMP_1090_FORK=$(dialog --stdout --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP_1090_TITLE" --radiolist "$DUMP_1090_MESSAGE" 0 0 0 "mutability" "Dump 1090 (Mutability)" on)
RESULT=$?
if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
    exit 1
fi

# Portal Installation Dialog
PORTAL_TITLE='The ADS-B Receiver Project Portal'
PORTAL_MESSAGE="The ADS-B Receiver Project Portal\n\nWould you like to install the portal?"
dialog --stdout --keep-tite --backtitle "$PROJECT_TITLE" --title "$PORTAL_TITLE" --yesno "$PORTAL_MESSAGE" 0 0
case $? in
    0) PORTAL_INSTALL="true";;
    1) PORTAL_INSTALL="false";;
    255) exit 1;;
esac

echo ''
echo 'RESULTS'
echo "Dump 1090 Fork: $DUMP_1090_FORK"
echo "Install Portal: $PORTAL_INSTALL"
echo ''

exit 0
