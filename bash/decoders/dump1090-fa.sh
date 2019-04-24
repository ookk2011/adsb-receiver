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

function dump1090_dialogs {

    # Begin displaying dialogs.
    if [ "${DUMP1090[installed]}" == 'false' ] || [ "${DUMP1090[upgradeable]}" == "true" ] ; then
        if [ "${DUMP1090[installed]}" == 'false' ] ; then

            # This would be a clean installation of dump1090-fa.
            DUMP1090_DO_INSTALL_TITLE='Install dump1090-fa'
            DUMP1090_DO_INSTALL_MESSAGE="Dump 1090 is a Mode-S decoder specifically designed for RTL-SDR devices. Dump1090-fa is a fork of the dump1090-mutability version of dump1090 that is specifically designed for FlightAware's PiAware software.\n\nIn order to use this version of dump1090 FlightAware's PiAware software must be installed as well.\n\n  https://github.com/flightaware/dump1090\n\nContinue setup by installing dump1090-fa?"
        else

            # An upgrade is available for dump1090-fa.
            DUMP1090_DO_INSTALL_TITLE='Upgrade Available for Dump1090 (FlightAware)'
            DUMP1090_DO_INSTALL_MESSAGE="A newer version of Dump1090-fa is available.\n\nWould you like to upgrade Dump1090-fa now?"
        fi

        dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_DO_INSTALL_TITLE" --yesno "$DUMP1090_DO_INSTALL_MESSAGE" 0 0
        case $? in
            0) DUMP1090[do_install]='true' ;;
            1) DUMP1090[do_install]='false' ;;
            255) exit 1 ;;
        esac
    fi

    # Dump1090 is required at this time so if the user decided not to install dump1090-fa exit the script.
    if [ "${DUMP1090[installed]}" == 'false' ] && [ "${DUMP1090[do_install]}" == 'false' ] ; then
        echo -e "${COLOR_RED}Dump1090 is required in order to continue installation.${COLOR_LIGHT_GRAY}"
        exit 1
    fi

    # Display message stateing PiAware will be required.
    PIAWARE_REQUIRED_TITLE='PiAware Required'
    PIAWARE_REQUIRED_MESSAGE="Regarding the FlightAware fork of Dump1090...\n\nThe PiAware software package, which is used to forward ADS-B data to FlightAware, is required in order to use FlightAware's fork of Dump1090. For this reason PiAware will be installed automatically during the setup process."
    PIAWARE[do_install]='true'
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$PIAWARE_REQUIRED_TITLE" --msgbox "$PIAWARE_REQUIRED_MESSAGE" 0 0
    if [ $? -eq 255 ] ; then
        exit 1
    fi

    # Ask if heywhatsthat.com range rings should be added.
    if [ -f /usr/share/dump1090-mutability/html/upintheair.json ] ; then

        # Heywhatsthat.com range rings have already been added to the map.
        HEYWHATSTHAT_ADD_TITLE='Heywhaststhat.com Maximum Range Rings'
        HEYWHATSTHAT_ADD_MESSAGE="Heywhaststhat.com maximum range rings have already been added to dump1090-mutability. If you would like to do so you can upload a new copy of upintheair.json to replace the current copy. In order to do so you will first need to visit http://www.heywhatsthat.com and generate a new panorama centered on the location of your receiver. Once your panorama has been generated a link to the panorama will be displayed in the top left hand portion of the page. You will need the view id which is the series of letters and/or numbers after \"?view=\" in this URL.\n\nWould you like to update the heywhatsthat.com maximum range rings for your map?"
    else

        # Heywhatsthat.com range rings have not been added to the map.
        HEYWHATSTHAT_ADD_TITLE='Heywhaststhat.com Maximum Range Rings'
        HEYWHATSTHAT_ADD_MESSAGE="Maximum range rings can be added to dump1090-mutability using data obtained from Heywhatsthat.com. In order to add these rings to your dump1090-mutability map you will first need to visit http://www.heywhatsthat.com and generate a new panorama centered on the location of your receiver. Once your panorama has been generated a link to the panorama will be displayed in the top left hand portion of the page. You will need the view id which is the series of letters and/or numbers after \"?view=\" in this URL.\n\nWould you like to add heywhatsthat.com maximum range rings to your map?"
    fi

    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_ADD_TITLE" --defaultno --yesno "$HEYWHATSTHAT_ADD_MESSAGE" 0 0
    case $? in
        0) HEYWHATSTHAT[add]='true' ;;
        1) HEYWHATSTHAT[add]='false' ;;
        255) exit 1 ;;
    esac
    if [ "$ADD_HEYWHATSTHAT_RINGS" == 'true' ] ; then
        HEYWHATSTHAT_PANARAMA_ID_TITLE='Heywhatsthat.com Panorama ID'
        HEYWHATSTHAT_PANARAMA_ID_MESSAGE="Enter the Heywhatsthat.com ID for the panarama you generated on the website."
        HEYWHATSTHAT[panarama_id]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_PANARAMA_ID_TITLE" --inputbox "$HEYWHATSTHAT_PANARAMA_ID_MESSAGE" 9 50 --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi

        HEYWHATSTHAT_RING_ONE_ALTITUDE_TITLE='Heywhatsthat.com First Ring Altitude'
        HEYWHATSTHAT_RING_ONE_ALTITUDE_MESSAGE="Enter the first ring's altitude in meters.\n(default 3048 meters or 10000 feet)"
        if [ -z $HEYWHATSTHAT_RING_ONE_ALTITUDE ] ; then
            HEYWHATSTHAT[ring_one_altitude]='3048'
        fi
        HEYWHATSTHAT[ring_one_altitude]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_RING_ONE_ALTITUDE_TITLE" --inputbox "$HEYWHATSTHAT_RING_ONE_ALTITUDE_MESSAGE" 9 50 "${HEYWHATSTHAT[ring_one_altitude]}" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi

        HEYWHATSTHAT_RING_TWO_ALTITUDE_TITLE='Heywhatsthat.com Second Ring Altitude'
        HEYWHATSTHAT_RING_TWO_ALTITUDE_MESSAGE="Enter the second ring's altitude in meters.\n(default 12192 meters or 40000 feet)"
        if [ -z $HEYWHATSTHAT_RING_TWO ] ; then
            HEYWHATSTHAT[ring_two_altitude]='12192'
        fi
        HEYWHATSTHAT[ring_two_altitude]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_RING_TWO_ALTITUDE_TITLE" --inputbox "$HEYWHATSTHAT_RING_TWO_ALTITUDE_MESSAGE" 9 50 "${HEYWHATSTHAT[ring_two_altitude]}" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi
    fi

    # Ask for a Bing Maps API key if the user wishes to enable Bing Maps.
    BING_MAPS_API_KEY_TITLE='Bing Maps API Key'
    BING_MAPS_API_KEY_MESSAGE="Provide a Bing Maps API key here to enable the Bing imagery layer within the dump1090-fa map, you can obtain a free key at the following website:\n\n  https://www.bingmapsportal.com/\n\nProviding a Bing Maps API key is not required to continue."
    BING[maps_api_key]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$BING_MAPS_API_KEY_TITLE" --inputbox "${BING[maps_api_key]}" 0 0 --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi
}

## SETUP

function dump1090_setup {

    echo -e "\n${COLOR_LIGHT_GREEN}------------------------"
    echo ' Setting up dump1090-fa'
    echo -e " ------------------------\n"

    # Install required Debian packages if they are not already installed.
    echo -e "${COLOR_BLUE}Installing any missing required packages.${COLOR_LIGHT_GRAY}\n"
    CheckPackage debhelper
    CheckPackage librtlsdr-dev
    CheckPackage libusb-1.0-0-dev
    CheckPackage pkg-config
    CheckPackage dh-systemd
    CheckPackage libncurses5-dev
    CheckPackage libbladerf-dev
    CheckPackage libbladerf1
    CheckPackage adduser
    CheckPackage lighttpd

    if [ -d ${PROJECT_BUILD_DIRECTORY}/dump1090-fa/dump1090 ] && [ -d ${PROJECT_BUILD_DIRECTORY}/dump1090-fa/dump1090/.git ] ; then

        # Update the local dump1090 git repository.
        echo -e "${COLOR_BLUE}Entering the dump1090 git repository directory..."
        cd ${PROJECT_BUILD_DIRECTORY}/dump1090-fa/dump1090 2>&1
        echo -e "Updating the local dump1090 git repository...${COLOR_LIGHT_GRAY}\n"
        git pull
    else

        # Download the dump1090 git repository.
        echo -e "${COLOR_BLUE}Creating the dump1090-fa build directory...${COLOR_LIGHT_GRAY}\n"
        mkdir -vp ${RECEIVER_BUILD_DIRECTORY}/dump1090-fa
        echo -e "\n${COLOR_BLUE}Entering the dump1090-fa build directory..."
        cd ${RECEIVER_BUILD_DIRECTORY}/dump1090-fa
        echo -e "Cloning the dump1090 git repository locally...${COLOR_LIGHT_GRAY}\n"
        git clone https://github.com/flightaware/dump1090.git 2>&1
        echo -e "\n${COLOR_BLUE}Entering the dump1090 git repository...${COLOR_LIGHT_GRAY}"
        cd ${RECEIVER_BUILD_DIRECTORY}/dump1090-fa/dump1090
    fi

    # Build the dump1090-fa Debian package.
    echo -e "${COLOR_BLUE}Building the dump1090-fa Debian package...${COLOR_LIGHT_GRAY}\n"
    dpkg-buildpackage -b

    # Check that the dump1090-fa Debian package was built successfully.
    if [ ! -f dump1090-fa_${DUMP1090_FA_VERSION}_*.deb ] ; then
        # If the dump1090-fa package was not built exit the script.
        echo -e "\n${COLOR_RED}The dump1090-fa Debian package was not built successfully.${COLOR_LIGHT_GRAY}"
        exit 1
    fi

    # Install the dump1090-fa Debian package.
    echo -e "\n${COLOR_BLUE}Installing the dump1090-fa Debian package...${COLOR_LIGHT_GRAY}\n"
    sudo dpkg -i dump1090-fa_${DUMP1090_FA_VERSION}_*.deb
    echo ''

    # Check that the dump1090-fa Debian package was installed.
    echo -e "${COLOR_BLUE}Checking that the dump1090-fa Debian package was installed successfully...${COLOR_LIGHT_GRAY}"
    if [ $(dpkg-query -W -f='${STATUS}' dump1090-fa 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
        # If the dump1090-fa Debian package could not be installed halt setup.
        echo -e "\n${COLOR_RED}The dump1090-fa Debian package was not installed successfully.${COLOR_LIGHT_GRAY}"
        exit 1
    fi

    # Set the Bing Maps API key in the dump1090-fa config.js file.
    CURRENT_BING_MAPS_API_KEY=`GetConfig "BingMapsAPIKey" "/usr/share/dump1090-fa/html/config.js"`
    if [ "${BING[maps_api_key]}" != "$CURRENT_BING_MAPS_API_KEY" ] ; then
        echo -e "${COLOR_BLUE}Writing Bing Maps API key to the dump1090-fa config.js file...${COLOR_LIGHT_GRAY}"
        sudo ChangeConfig "BingMapsAPIKey" "$BING_MAPS_API_KEY" "/usr/share/dump1090-fa/html/config.js"
    fi

    # Download Heywhatsthat.com maximum range rings JSON file.
    if [ "$HEYWHATSTHAT[add]" == 'true' ] ; then
        echo -e "${COLOR_BLUE}Downloading heywhatsthat.com JSON data pertaining to the supplied panorama ID...${COLOR_LIGHT_GRAY}\n"
        sudo wget -O /usr/share/dump1090-fa/html/upintheair.json "http://www.heywhatsthat.com/api/upintheair.json?id=${HEYWHATSTHAT[panarama_id]}&refraction=0.25&alts=${HEYWHATSTHAT[ring_one_altitude]},${HEYWHATSTHAT[ring_two_altitude]}"
        echo ''
    fi

    # Return to the project root directory.
    echo -e "${COLOR_BLUE}Entering the ADS-B Receiver Project root directory..."
    cd $PROJECT_ROOT_DIRECTORY

    echo -e "\n${COLOR_LIGHT_GREEN}----------------------------"
    echo ' Dump1090-fa setup complete.'
    echo -e " ----------------------------\n${COLOR_LIGHT_GRAY}"
}
