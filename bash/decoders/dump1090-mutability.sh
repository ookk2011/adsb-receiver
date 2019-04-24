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
# Copyright (c) 2015-2019, Joseph A. Prochazka                                      #
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

function dump1090_dialogs() {

    # Begin displaying dialogs.
    if [ "${DUMP1090[installed]}" == 'false' ] || [ "${DUMP1090[upgradeable]}" == "true" ] ; then
        if [ "${DUMP1090[installed]}" == 'false' ] ; then

            # This would be a clean installation of dump1090-mutability.
            DUMP1090_DO_INSTALL_TITLE='Install dump1090-mutability'
            DUMP1090_DO_INSTALL_MESSAGE="It has been noted in dump1090-mutability's README.md that \"This fork sees very little maintenance and is really only here for historical reasons.\"Dump1090 is a Mode-S decoder specifically designed for RTL-SDR devices.\n\nDump1090-mutability is a fork of MalcolmRobb's version of Dump1090 that adds new functionality and is designed to be built as a Debian/Raspbian package.\n\n  https://github.com/mutability/dump1090\n\nContinue setup by installing dump1090-mutability?"
        else

            # Dump1090-mutability is currently installed.
            DUMP1090_DO_INSTALL_TITLE='Recompile and install dump1090-mutability.'
            DUMP1090_DO_INSTALL_MESSAGE="It has been noted in dump1090-mutability's README.md that \"This fork sees very little maintenance and is really only here for historical reasons.\"\n\nSince the release of v1.14 no other dump1090-mutability releases have been made. However, development did continue but the version was frozen at v1.15~dev. This being said there is no way to confirm the installed version has been built on the latest available source code. The best way to ensure you are using the most resent version of dump1090-mutability is to occassionally download then rempile and install the latest source code.\n\nWould you like to recompile and install dump1090-mutability?"
        fi

        dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_DO_INSTALL_TITLE" --yesno "$DUMP1090_DO_INSTALL_MESSAGE" 0 0
        case $? in
            0) DUMP1090[do_install]='true' ;;
            1) DUMP1090[do_install]='false' ;;
            255) exit 1 ;;
        esac
    fi

    # Dump1090 is required at this time so if the user decided not to install dump1090-mutability exit the script.
    if [ "${DUMP1090[installed]}" == 'false' ] && [ "${DUMP1090[do_install]}" == 'false' ] ; then
        echo -e "${COLOR_RED}Dump1090 is required in order to continue installation.${COLOR_LIGHT_GRAY}"
        exit 1
    fi

    # Ask for receiver latitude.
    RECEIVER_LATITUDE_TITLE='Receiver Latitude'
    RECEIVER_LATITUDE_MESSAGE="Enter your receiver's latitude.\n(Example: XX.XXXXXXX)"
    RECEIVER[latitude]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$RECEIVER_LATITUDE_TITLE" --inputbox "$RECEIVER_LATITUDE_MESSAGE" 0 0 "${RECEIVER[latitude]}" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    # Ask for receiver longitude.
    RECEIVER_LONGITUDE_TITLE='Receiver Longitude'
    RECEIVER_LONGITUDE_MESSAGE="Enter your receeiver's longitude.\n(Example: XX.XXXXXXX)"
    RECEIVER[longitude]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$RECEIVER_LONGITUDE_TITLE" --inputbox "$RECEIVER_LONGITUDE_MESSAGE" 0 0 "${RECEIVER[longitude]}" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    # Ask what the max range for dump1090 should be set to.
    DUMP1090_MAX_RANGE_TITLE='Dump1090-mutability Maximum Range'
    DUMP1090_MAX_RANGE_MESSAGE="The dump1090-mutability default maximum range value of 300 nmi (~550km) has been reported to be below what is possible under the right conditions. This value should be increased to 360 nmi (~660 km) to match the value used by the dump1090-fa fork."
    if [ -z $DUMP1090[max_range] ] ; then
        DUMP1090[max_range]='360'
    fi
    DUMP1090[max_range]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_MAX_RANGE_TITLE" --inputbox "$DUMP1090_MAX_RANGE_MESSAGE" 0 0 "${DUMP1090[max_range]}" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    # Ask what the default unit of measurment used by dump1090 should be.
    DUMP1090_UNIT_OF_MEASURE_TITLE='Select Dump1090 Unit of Measure'
    DUMP1090_UNIT_OF_MEASURE_MESSAGE='Please select the unit of measure to be used by dump1090-mutability.'
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_UNIT_OF_MEASURE_TITLE" --yes-button "Imperial" --no-button "Metric" --yesno "${DUMP1090[unit_of_measure]}" 7 60
    case $? in
        0) DUMP1090[unit_of_measure]='imperial' ;;
        1) DUMP1090[unit_of_measure]='metric' ;;
        255) exit 1 ;;
    esac

    # Ask if dump1090 should listen on all IP addresses instead of only 127.0.0.1.
    DUMP1090_BIND_ALL_IPS_TITLE='Bind dump1090-mutability To All IP Addresses'
    DUMP1090_BIND_ALL_IPS_MESSAGE="By default dump1090-mutability is bound only to the local loopback IP address(s) for security reasons. However some people wish to make dump1090-mutability's data accessable externally by other devices. To allow this dump1090-mutability can be configured to listen on all IP addresses bound to this device. It is recommended that unless you plan to access this device from an external source that dump1090-mutability remain bound only to the local loopback IP address(s).\n\nWould you like dump1090-mutability to listen on all IP addesses?"
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_BIND_ALL_IPS_TITLE" --yesno "$DUMP1090_BIND_ALL_IPS_MESSAGE" 0 0
    case $? in
        0) DUMP1090[bind_all_ips]='true' ;;
        1) DUMP1090[bind_all_ips]='false' ;;
        255) exit 1 ;;
    esac

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

    if [ "${HEYWHATSTHAT[add]}" == 'true' ] ; then
        HEYWHATSTHAT_PANARAMA_ID_TITLE='Heywhatsthat.com Panorama ID'
        HEYWHATSTHAT_PANARAMA_ID_MESSAGE="Enter your Heywhatsthat.com panorama ID."
        HEYWHATSTHAT[panarama_id]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "HEYWHATSTHAT_PANARAMA_ID_TITLE" --inputbox "$HEYWHATSTHAT_PANARAMA_ID_MESSAGE" 0 0 --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi

        HEYWHATSTHAT_RING_ONE_ALTITUDE_TITLE='Heywhatsthat.com First Ring Altitude'
        HEYWHATSTHAT_RING_ONE_ALTITUDE_MESSAGE="Enter the first ring's altitude in meters.\n(default 3048 meters or 10000 feet)"
        if [ -z ${HEYWHATSTHAT[ring_one_altitude]} ] ; then
            HEYWHATSTHAT[ring_one_altitude]='3048'
        fi
        HEYWHATSTHAT[ring_one_altitude]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_RING_ONE_ALTITUDE_TITLE" --inputbox "$HEYWHATSTHAT_RING_ONE_ALTITUDE_MESSAGE" 0 0 "${HEYWHATSTHAT[ring_one_altitude]}" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi

        HEYWHATSTHAT_RING_TWO_ALTITUDE_TITLE='Heywhatsthat.com Second Ring Altitude'
        HEYWHATSTHAT_RING_TWO_ALTITUDE_MESSAGE="Enter the second ring's altitude in meters.\n(default 12192 meters or 40000 feet)"
        if [ -z ${HEYWHATSTHAT[ring_two_altitude]} ] ; then
            HEYWHATSTHAT[ring_two_altitude]='12192'
        fi
        HEYWHATSTHAT[ring_two_altitude]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_RING_TWO_ALTITUDE_TITLE" --inputbox "$HEYWHATSTHAT_RING_TWO_ALTITUDE_MESSAGE" 0 0 "${HEYWHATSTHAT[ring_two_altitude]}" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi
    fi

    # Ask for a Bing Maps API key if the user wishes to enable Bing Maps.
    BING_MAPS_API_KEY_TITLE='Bing Maps API Key'
    BING_MAPS_API_KEY_MESSAGE="Provide a Bing Maps API key here to enable the Bing imagery layer within the dump1090-mutability map, you can obtain a free key at the following website:\n\n  https://www.bingmapsportal.com/\n\nProviding a Bing Maps API key is not required to continue."
    BING[maps_api_key]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$BING_MAPS_API_KEY_TITLE" --inputbox "$BING_MAPS_API_KEY_MESSAGE" 0 0 "${BING[maps_api_key]}" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi
}

## SETUP

function dump1090_setup() {

    echo -e "\n${COLOR_LIGHT_GREEN}------------------------"
    echo ' Setting up dump1090-fa'
    echo -e " ------------------------\n"

    # Install required Debian packages if they are not already installed.
    echo -e "${COLOR_BLUE}Installing any missing required packages.${COLOR_LIGHT_GRAY}\n"
    CheckPackage debhelper
    CheckPackage librtlsdr-dev
    CheckPackage libusb-1.0-0-dev
    CheckPackage pkg-config
    CheckPackage adduser
    CheckPackage lighttpd

    if [ -d ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090 ] && [ -d ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090/.git ] ; then

        # Update the local dump1090 git repository.
        echo -e "${COLOR_BLUE}Entering the dump1090 git repository directory..."
        cd ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090 2>&1
        echo -e "Updating the local dump1090 git repository...${COLOR_LIGHT_GRAY}\n"
        git pull
    else

        # Download the dump1090 git repository.
        echo -e "${COLOR_BLUE}Creating the dump1090-mutability build directory...${COLOR_LIGHT_GRAY}\n"
        mkdir -vp ${RECEIVER_BUILD_DIRECTORY}/dump1090-mutability
        echo -e "\n${COLOR_BLUE}Entering the dump1090-mutability build directory..."
        cd ${RECEIVER_BUILD_DIRECTORY}/dump1090-mutability
        echo -e "Cloning the dump1090 git repository locally...${COLOR_LIGHT_GRAY}\n"
        git clone https://github.com/mutability/dump1090.git 2>&1
        echo -e "\n${COLOR_BLUE}Entering the dump1090 git repository...${COLOR_LIGHT_GRAY}"
        cd ${RECEIVER_BUILD_DIRECTORY}/dump1090-mutability/dump1090
    fi

    # Build the dump1090-mutability Debian package.
    echo -e "${COLOR_BLUE}Building the dump1090-mutability Debian package...${COLOR_LIGHT_GRAY}\n"
    dpkg-buildpackage -b

    # Check that the dump1090-mutability Debian package was built successfully.
    if [ ! -f dump1090-mutability_1.15~dev_*.deb ] ; then
        # If the dump1090-mutability Debian package was not built exit the script.
        echo -e "\n${COLOR_RED}The dump1090-mutability Debian package was not built successfully.${COLOR_LIGHT_GRAY}"
        exit 1
    fi

    # Install the dump1090-mutability Debian package.
    echo -e "\n${COLOR_BLUE}Installing the dump1090-mutability Debian package...${COLOR_LIGHT_GRAY}\n"
    sudo dpkg -i dump1090-mutability_1.15~dev_*.deb
    echo ''

    # Check that the dump1090-mutability Debian package was installed.
    echo -e "${COLOR_BLUE}Checking that the dump1090-mutability Debian package was installed successfully...${COLOR_LIGHT_GRAY}"
    if [ $(dpkg-query -W -f='${STATUS}' dump1090-mutability 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
        # If the dump1090-mutability package could not be installed halt setup.
        echo -e "\n${COLOR_RED}The dump1090-mutability Debian package was not installed successfully.${COLOR_LIGHT_GRAY}"
        exit 1
    fi

    # Write the supplied latitude and longitude values to the dump1090-mutability configuration file if it is different from current setting.
    CURRENT_LATITUDE=`GetConfig "LAT" "/etc/default/dump1090-mutability"`
    if [ "${RECEIVER[latitude]}" != "$CURRENT_LATITUDE" ] ; then
        echo -e "${COLOR_BLUE}Setting the receiver's latitude to ${RECEIVER[latitude]}...${COLOR_LIGHT_GRAY}"
        ChangeConfig "LAT" "${RECEIVER[latitude]}" "/etc/default/dump1090-mutability"
    fi
    CURRENT_LONGITUDE=`GetConfig "LON" "/etc/default/dump1090-mutability"`
    if [ "${RECEIVER[longitude]}" != "$CURRENT_LONGITUDE" ] ; then
        echo -e "Setting the receiver's longitude to ${RECEIVER[longitude]}...${COLOR_LIGHT_GRAY}"
        ChangeConfig "LON" "${RECEIVER[longitude]}" "/etc/default/dump1090-mutability"
    fi

    # Write the supplied latitude and longitude values to the dump1090-mutability config.js file if it is different from current setting.
    CURRENT_JS_LATITUDE=`GetConfig "DefaultCenterLat" "/usr/share/dump1090-mutability/html/config.js"`
    if [ "${RECEIVER[latitude]}" != "$CURRENT_JS_LATITUDE" ] ; then
         echo -e "${COLOR_BLUE}Setting the receiver's latitude in config.js to ${RECEIVER[latitude]}...${COLOR_LIGHT_GRAY}"
        ChangeConfig "DefaultCenterLat" "${RECEIVER[latitude]}" "/usr/share/dump1090-mutability/html/config.js"
    fi
    CURRENT_JS_LONGITUDE=`GetConfig "DefaultCenterLon" "/usr/share/dump1090-mutability/html/config.js"`
    if [ "${RECEIVER[longitude]}" != "$CURRENT_JS_LONGITUDE" ] ; then
        echo -e "Setting the receiver's longitude in config.js to ${RECEIVER[longitude]}...${COLOR_LIGHT_GRAY}"
        ChangeConfig "DefaultCenterLon" "${RECEIVER[longitude]}" "/usr/share/dump1090-mutability/html/config.js"
    fi

    # Bind dump1090-mutability to all ip addresses if this was a wanted action.
    if [ "${DUMP1090[bind_all_ips]}" == "true" ] ; then
        echo -e "${COLOR_BLUE}Binding dump1090-mutability to all available IP addresses...${COLOR_LIGHT_GRAY}"
        CommentConfig "NET_BIND_ADDRESS" "/etc/default/dump1090-mutability"
    else
        echo -e "${COLOR_BLUE}Binding dump1090-mutability to the local IP address only...${COLOR_LIGHT_GRAY}"
        UncommentConfig "NET_BIND_ADDRESS" "/etc/default/dump1090-mutability"
        ChangeConfig "NET_BIND_ADDRESS" "127.0.0.1" "/etc/default/dump1090-mutability"
    fi

    # Change the maximum range at which dump1090-mutability will work at.
    CURRENT_MAX_RANGE=`GetConfig "MAX_RANGE" "/etc/default/dump1090-mutability"`
    if [ "${DUMP1090[max_range]}" != "$CURRENT_MAX_RANGE" ]] ; then
        echo -e "${COLOR_BLUE}Setting the maximum range which dump1090-mutability works with to ${DUMP1090[max_range]}...${COLOR_LIGHT_GRAY}"
        ChangeConfig "MAX_RANGE" "${DUMP1090[max_range]}" "/etc/default/dump1090-mutability"
    fi

    # Set the unit of measurement dump1090-mutability uses to the one chosen by the user.
    if [ "${DUMP1090[unit_of_measurment]}" == "metric" ] ; then
        echo -e "\e[94m  Setting dump1090-mutability unit of measurement to Metric...\e[97m"
        ChangeConfig "Metric" "true;" "/usr/share/dump1090-mutability/html/config.js"
    else
        echo -e "${COLOR_BLUE}Setting dump1090-mutability's unit of measurement to Imperial...${COLOR_LIGHT_GRAY}"
        ChangeConfig "Metric" "false;" "/usr/share/dump1090-mutability/html/config.js"
    fi

    # Set the Bing Maps API key in the dump1090-mutability config.js file.
    CURRENT_BING_MAPS_API_KEY=`GetConfig "BingMapsAPIKey" "/usr/share/dump1090-mutability/html/config.js"`
    if [ "${BING[maps_api_key]}" != "$CURRENT_BING_MAPS_API_KEY" ] ; then
        echo -e "${COLOR_BLUE}Writing Bing Maps API key to the dump1090-mutability config.js file...${COLOR_LIGHT_GRAY}"
        sudo ChangeConfig "BingMapsAPIKey" "$BING_MAPS_API_KEY" "/usr/share/dump1090-mutability/html/config.js"
    fi

    # Download Heywhatsthat.com maximum range rings JSON file.
    if [ "$HEYWHATSTHAT[add]" == 'true' ] ; then
        echo -e "${COLOR_BLUE}Downloading heywhatsthat.com JSON data pertaining to the supplied panorama ID...${COLOR_LIGHT_GRAY}\n"
        sudo wget -O /usr/share/dump1090-mutability/html/upintheair.json "http://www.heywhatsthat.com/api/upintheair.json?id=${HEYWHATSTHAT[panarama_id]}&refraction=0.25&alts=${HEYWHATSTHAT[ring_one_altitude]},${HEYWHATSTHAT[ring_two_altitude]}"
        echo ''
    fi

    # Start/restart the dump1090-mutability process.
    if [[ "`sudo systemctl status dump1090-mutability 2>&1 | egrep -c "Active: active (running)"`" -gt 0 ]] ; then
        echo -e "${COLOR_BLUE}Restarting the dump1090-mutability service...${COLOR_LIGHT_GRAY}\n"
        sudo systemctl restart dump1090-mutability
    else
        echo -e "${COLOR_BLUE}Starting the dump1090-mutability service...${COLOR_LIGHT_GRAY}\n"
        sudo systemctl start dump1090-mutability
    fi

    # Return to the project root directory.
    echo -e "${COLOR_BLUE}Entering the ADS-B Receiver Project root directory..."
    cd $PROJECT_ROOT_DIRECTORY

    echo -e "\n${COLOR_LIGHT_GREEN}------------------------------------"
    echo ' Dump1090-mutability setup complete.'
    echo -e " ------------------------------------\n${COLOR_LIGHT_GRAY}"
}
