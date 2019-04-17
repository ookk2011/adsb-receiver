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

function dialogs {

    # Assign parameters passed to this function to variables.
    DUMP1090_INSTALLED=$1
    UPGRADE_AVAILABLE=$2

    # Needs to return the following variables...
    # ------------------------------------------
    # INSTALL_DUMP1090
    # RECIEVER_LATITUDE
    # RECIEVER_LONGITUDE
    # DUMP1090_MAX_RANGE
    # DUMP1090_UNIT_OF_MEASURMENT
    # BIND_DUMP1090_TO_ALL_IP_ADDRESSES
    # ADD_HEYWHATSTHAT_RINGS
    # HEYWHATSTHAT_PANARAMA_ID
    # HEYWHATSTHAT_RING_ONE_ALTITUDE
    # HEYWHATSTHAT_RING_TWO_ALTITUDE
    # BING_MAPS_API_KEY

    if [ "$DUMP1090_INSTALLED" == 'false' ] || [ "$UPGRADE_AVAILABLE" == "true" ] ; then
        if [ "$DUMP1090_INSTALLED" == 'false' ] ; then

            # This would be a clean installation of dump1090-mutability.
            INSTALL_DUMP1090_TITLE='Install dump1090-mutability'
            INSTALL_DUMP1090_MESSAGE="It has been noted in dump1090-mutability's README.md that \"This fork sees very little maintenance and is really only here for historical reasons.\"Dump1090 is a Mode-S decoder specifically designed for RTL-SDR devices.\n\nDump1090-mutability is a fork of MalcolmRobb's version of Dump1090 that adds new functionality and is designed to be built as a Debian/Raspbian package.\n\n  https://github.com/mutability/dump1090\n\nContinue setup by installing dump1090-mutability?"
        else

            # Dump1090-mutability is currently installed.
            INSTALL_DUMP1090_TITLE='Recompile and install dump1090-mutability.'
            INSTALL_DUMP1090_MESSAGE="It has been noted in dump1090-mutability's README.md that \"This fork sees very little maintenance and is really only here for historical reasons.\"\n\nSince the release of v1.14 no other dump1090-mutability releases have been made. However, development did continue but the version was frozen at v1.15~dev. This being said there is no way to confirm the installed version has been built on the latest available source code. The best way to ensure you are using the most resent version of dump1090-mutability is to occassionally download then rempile and install the latest source code.\n\nWould you like to recompile and install dump1090-mutability?"
        fi

        dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$INSTALL_DUMP1090_TITLE" --yesno "$INSTALL_DUMP1090_MESSAGE" 0 0
        case $? in
            0) INSTALL_DUMP1090='true' ;;
            1) INSTALL_DUMP1090='false' ;;
            255) exit 1 ;;
        esac
    fi

    # Ask for receiver latitude.
    RECIEVER_LATITUDE_TITLE='Receiver Latitude'
    RECIEVER_LATITUDE_MESSAGE="Enter your receiver's latitude.\n(Example: XX.XXXXXXX)"
    while [ -z $RECIEVER_LATITUDE ] ; do
        RECIEVER_LATITUDE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$RECIEVER_LATITUDE_TITLE" --inputbox "$RECIEVER_LATITUDE_MESSAGE" 0 0 "$RECIEVER_LATITUDE" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi
        RECIEVER_LATITUDE_TITLE='Receiver Latitude [REQUIRED]'
    done

    # Ask for receiver longitude.
    RECIEVER_LONGITUDE_TITLE='Receiver Longitude'
    RECIEVER_LONGITUDE_MESSAGE="Enter your receeiver's longitude.\n(Example: XX.XXXXXXX)"
    while [ -z $RECIEVER_LONGITUDE ] ; do
        RECIEVER_LONGITUDE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$RECIEVER_LONGITUDE_TITLE" --inputbox "$RECIEVER_LONGITUDE_MESSAGE" 0 0 "$RECIEVER_LONGITUDE" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi
        RECIEVER_LONGITUDE_TITLE='Receiver Longitude [REQUIRED]'
    done

    # Ask what the max range for dump1090 should be set to.
    DUMP1090_MAX_RANGE_TITLE='Dump1090-mutability Maximum Range'
    DUMP1090_MAX_RANGE_MESSAGE="The dump1090-mutability default maximum range value of 300 nmi (~550km) has been reported to be below what is possible under the right conditions. This value should be increased to 360 nmi (~660 km) to match the value used by the dump1090-fa fork."
    while [ -z $DUMP1090_MAX_RANGE ] ; do
        DUMP1090_MAX_RANGE='360'
        DUMP1090_MAX_RANGE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_MAX_RANGE_TITLE" --inputbox "$DUMP1090_MAX_RANGE_MESSAGE" 0 0 "$DUMP1090_MAX_RANGE" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi
        RECIEVER_LATITUDE_TITLE='Dump1090-mutability Maximum Range [REQUIRED]'
    done

    # Ask what the default unit of measurment used by dump1090 should be.
    DUMP1090_UNIT_OF_MEASURMENT_TITLE='Select Dump1090 Unit of Measurement'
    DUMP1090_UNIT_OF_MEASURMENT_MESSAGE='Please select the unit of measurement to be used by dump1090-mutability.'
    dialog  --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_UNIT_OF_MEASURMENT_TITLE" --yes-button "Imperial" --no-button "Metric" --yesno "$DUMP1090_UNIT_OF_MEASURMENT_MESSAGE" 0 0
    case $? in
        0) DUMP1090_UNIT_OF_MEASURMENT='imperial' ;;
        1) DUMP1090_UNIT_OF_MEASURMENT='metric' ;;
        255) exit 1 ;;
    esac

    # Ask if dump1090 should listen on all IP addresses instead of only 127.0.0.1.
    BIND_DUMP1090_TO_ALL_IP_ADDRESSES_TITLE='Bind dump1090-mutability To All IP Addresses'
    BIND_DUMP1090_TO_ALL_IP_ADDRESSES_MESSAGE="By default dump1090-mutability is bound only to the local loopback IP address(s) for security reasons. However some people wish to make dump1090-mutability's data accessable externally by other devices. To allow this dump1090-mutability can be configured to listen on all IP addresses bound to this device. It is recommended that unless you plan to access this device from an external source that dump1090-mutability remain bound only to the local loopback IP address(s).\n\nWould you like dump1090-mutability to listen on all IP addesses?"
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$BIND_DUMP1090_TO_ALL_IP_ADDRESSES_TITLE" --yesno "$BIND_DUMP1090_TO_ALL_IP_ADDRESSES_MESSAGE" 0 0
    case $? in
        0) BIND_DUMP1090_TO_ALL_IP_ADDRESSES='true' ;;
        1) BIND_DUMP1090_TO_ALL_IP_ADDRESSES='false' ;;
        255) exit 1 ;;
    esac

    # Ask if heywhatsthat.com range rings should be added.
    HEYWHATSTHAT_ADD_TITLE='Heywhaststhat.com Maximum Range Rings'
    HEYWHATSTHAT_ADD_MESSAGE="Maximum range rings can be added to dump1090-mutability using data obtained from Heywhatsthat.com. In order to add these rings to your dump1090-mutability map you will first need to visit http://www.heywhatsthat.com and generate a new panorama centered on the location of your receiver. Once your panorama has been generated a link to the panorama will be displayed in the top left hand portion of the page. You will need the view id which is the series of letters and/or numbers after \"?view=\" in this URL.\n\nWould you like to add heywhatsthat.com maximum range rings to your map?"
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_ADD_TITLE" --defaultno --yesno "$HEYWHATSTHAT_ADD_MESSAGE" 0 0
    case $? in
        0) HEYWHATSTHAT_ADD='true' ;;
        1) HEYWHATSTHAT_ADD='false' ;;
        255) exit 1 ;;
    esac
    if [ "$HEYWHATSTHAT_ADD" == 'true' ] ; then
        HEYWHATSTHAT_PANARAMA_ID_TITLE='Heywhatsthat.com Panorama ID'
        HEYWHATSTHAT_PANARAMA_ID_MESSAGE="Enter your Heywhatsthat.com panorama ID."
        while [ -z $HEYWHATSTHAT_PANARAMA ] ; do
            HEYWHATSTHAT_PANARAMA=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "HEYWHATSTHAT_PANARAMA_TITLE" --inputbox "$HEYWHATSTHAT_PANARAMA_MESSAGE" 0 0 --output-fd 1)
            RESULT=$?
            if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
                exit 1
            fi
            HEYWHATSTHAT_PANARAMA_TITLE='Heywhatsthat.com Panorama ID [REQUIRED]'
        done

        HEYWHATSTHAT_RING_ONE_TITLE='Heywhatsthat.com First Ring Altitude'
        HEYWHATSTHAT_RING_ONE_MESSAGE="Enter the first ring's altitude in meters.\n(default 3048 meters or 10000 feet)"
        while [ -z $HEYWHATSTHAT_RING_ONE ] ; do
            HEYWHATSTHAT_RING_ONE='3048'
            HEYWHATSTHAT_RING_ONE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_RING_ONE_TITLE" --inputbox "$HEYWHATSTHAT_RING_ONE_MESSAGE" 0 0 "$HEYWHATSTHAT_RING_ONE" --output-fd 1)
            RESULT=$?
            if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
                exit 1
            fi
            HEYWHATSTHAT_RING_ONE_TITLE='Heywhatsthat.com First Ring Altitude [REQUIRED]'
        done

        HEYWHATSTHAT_RING_TWO_TITLE='Heywhatsthat.com Second Ring Altitude'
        HEYWHATSTHAT_RING_TWO_MESSAGE="Enter the second ring's altitude in meters.\n\(default 12192 meters or 40000 feet\)"
        while [ -z $HEYWHATSTHAT_RING_TWO ] ; do
            HEYWHATSTHAT_RING_TWO='12192'
            HEYWHATSTHAT_RING_TWO=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$HEYWHATSTHAT_RING_TWO_TITLE" --inputbox "$HEYWHATSTHAT_RING_TWO_MESSAGE" 0 0 "$HEYWHATSTHAT_RING_TWO" --output-fd 1)
            RESULT=$?
            if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
                exit 1
            fi
            HEYWHATSTHAT_RING_TWO_TITLE='Heywhatsthat.com First Ring Altitude [REQUIRED]'
        done
    fi

    # Ask for a Bing Maps API key if the user wishes to enable Bing Maps.
    BING_MAPS_API_KEY_TITLE='Bing Maps API Key'
    BING_MAPS_API_KEY_MESSAGE="Provide a Bing Maps API key here to enable the Bing imagery layer within the dump1090-mutability map, you can obtain a free key at the following website:\n\n  https://www.bingmapsportal.com/\n\nProviding a Bing Maps API key is not required to continue."
    BING_MAPS_API_KEY=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$BING_MAPS_API_KEY_TITLE" --inputbox "$BING_MAPS_API_KEY_MESSAGE" 0 0 --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi
}

## BEGIN SETUP

echo -e "\n${COLOR_LIGHT_GREEN}------------------------"
echo ' Setting up dump1090-fa'
echo -e " ------------------------\n"

## CHECK FOR PREREQUISITE PACKAGES

## CHECK FOR PREREQUISITE PACKAGES

echo -e "${COLOR_LIGHT_BLUE}Installing any missing required packages.${COLOR_LIGHT_GRAY}\n"

CheckPackage debhelper
CheckPackage librtlsdr-dev
CheckPackage libusb-1.0-0-dev
CheckPackage pkg-config
CheckPackage adduser
CheckPackage lighttpd

## DOWNLOAD OR UPDATE THE DUMP1090-MUTABILITY THE LOCAL GIT REPOSITORY

echo -e "\n${COLOR_LIGHT_BLUE}Preparing the dump1090-mutability Git repository.\n"
echo ""
if [ -d ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090 ] && [ -d ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090/.git ] ; then
    # A directory with a git repository containing the source code already exists.
    echo -e "${COLOR_BLUE}Entering the dump1090-mutability git repository directory..."
    cd ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090
    echo -e "Updating the local dump1090-mutability git repository...${COLOR_LIGHT_GRAY}\n"
    git pull
else
    # A directory containing the source code does not exist in the build directory.
    if [ ! -d ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability ] ; then
        echo -e "${COLOR_BLUE}Creating the dump1090-mutability build directory...${COLOR_LIGHT_GRAY}\n"
        mkdir -vp ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability
        echo ''
    fi
    echo -e "${COLOR_BLUE}Entering the dump1090-mutability build directory..."
    cd ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability
    echo -e "Cloning the dump1090-fa git repository locally...${COLOR_LIGHT_GRAY}\n"
    git clone https://github.com/mutability/dump1090.git
fi

## BUILD AND INSTALL THE DUMP1090-FA PACKAGE

# Build the dump1090-fa package.
echo -e "\n${COLOR_LIGHT_BLUE}Building and installing the dump1090-mutability package.\n"
if [ "$PWD" != "${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090" ] ; then
    echo -e "${COLOR_BLUE}Entering the dump1090-mutability git repository directory..."
    cd ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability/dump1090
fi
echo -e "Building the dump1090-mutability package...${COLOR_LIGHT_GRAY}\n"
dpkg-buildpackage -b
echo -e "\n${COLOR_BLUE}Entering the dump1090-mutability build directory..."
cd ${PROJECT_BUILD_DIRECTORY}/dump1090-mutability

# Prempt the dpkg question asking if the user would like dump1090 to start automatically.
if [[ ! "`sudo debconf-get-selections 2>/dev/null | grep "dump1090-mutability/auto-start" | awk '{print $4}'`" = "true" ]] ; then
    echo -e "${COLOR_BLUE}Configuring dump1090-mutability to start automatically...${COLOR_LIGHT_GRAY}\n"
    sudo debconf-set-selections -v <<< 'dump1090-mutability dump1090-mutability/auto-start boolean true'
fi

# Check that the dump1090-mutability package was built successfully.
if [ ! -f dump1090-mutability_1.15~dev_*.deb ] ; then
    # If the dump1090-mutability package was not built.
    echo "\n${COLOR_RED}The package dump1090-mutability was not built successfully.${COLOR_LIGHT_GRAY}"
    exit 1
fi

# Install the dump1090-mutability package.
echo -e "\n${COLOR_BLUE}Installing the dump1090-mutability package...${COLOR_LIGHT_GRAY}\n"
sudo dpkg -i dump1090-mutability_1.15~dev_*.deb
echo ''

# Check that the package was installed.
echo -e "${COLOR_BLUE}Checking that the dump1090-mutability package was installed successfully...${COLOR_LIGHT_GRAY}"
if [ $(dpkg-query -W -f='${STATUS}' dump1090-mutability 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    # If the dump1090-mutability package could not be installed halt setup.
    echo "\n${COLOR_RED}The package dump1090-mutability was not installed successfully.${COLOR_LIGHT_GRAY}"
    exit 1
fi

## COMPONENT POST INSTALL ACTIONS

# Save the receiver's latitude and longitude values to dump1090 configuration file if different from current setting.
CURRENT_LATITUDE=`GetConfig "LAT" "/etc/default/dump1090-mutability"`
if [ "$RECEIVER_LATITUDE" != "$CURRENT_LATITUDE" ] ; then
    echo -e "${COLOR_BLUE}Setting the receiver's latitude to ${RECEIVER_LATITUDE}...${COLOR_LIGHT_GRAY}"
    ChangeConfig "LAT" "$RECEIVER_LATITUDE" "/etc/default/dump1090-mutability"
fi
CURRENT_LONGITUDE=`GetConfig "LON" "/etc/default/dump1090-mutability"`
if [ "$RECEIVER_LONGITUDE" != "$CURRENT_LONGITUDE" ] ; then
    echo -e "Setting the receiver's longitude to ${RECEIVER_LONGITUDE}...${COLOR_LIGHT_GRAY}"
    ChangeConfig "LON" "$RECEIVER_LONGITUDE" "/etc/default/dump1090-mutability"
fi

# Save the receiver's latitude and longitude values to the dump1090-mutability config.js file if different from current setting.
CURRENT_JS_LATITUDE=`GetConfig "DefaultCenterLat" "/usr/share/dump1090-mutability/html/config.js"`
if [ "$RECEIVER_LATITUDE" != "$CURRENT_JS_LATITUDE" ] ; then
    echo -e "${COLOR_BLUE}Setting the receiver's latitude in config.js to ${RECEIVER_LATITUDE}...${COLOR_LIGHT_GRAY}"
    ChangeConfig "DefaultCenterLat" "$RECEIVER_LATITUDE" "/usr/share/dump1090-mutability/html/config.js"
fi
CURRENT_JS_LONGITUDE=`GetConfig "DefaultCenterLon" "/usr/share/dump1090-mutability/html/config.js"`
if [ "$RECEIVER_LONGITUDE" != "$CURRENT_JS_LONGITUDE" ] ; then
    echo -e "Setting the receiver's longitude in config.js to ${RECEIVER_LONGITUDE}...${COLOR_LIGHT_GRAY}"
    ChangeConfig "DefaultCenterLon" "$RECEIVER_LONGITUDE" "/usr/share/dump1090-mutability/html/config.js"
fi

# Bind dump1090-mutability to all ip addresses if this was a wanted action.
if [ "$DUMP1090_BIND_ALL_IPS" == "true" ] ; then
    echo -e "${COLOR_BLUE}Binding dump1090-mutability to all available IP addresses...${COLOR_LIGHT_GRAY}"
    CommentConfig "NET_BIND_ADDRESS" "/etc/default/dump1090-mutability"
else
    echo -e "${COLOR_BLUE}Binding dump1090-mutability to the local IP address only...${COLOR_LIGHT_GRAY}"
    UncommentConfig "NET_BIND_ADDRESS" "/etc/default/dump1090-mutability"
    ChangeConfig "NET_BIND_ADDRESS" "127.0.0.1" "/etc/default/dump1090-mutability"
fi

# Change the maximum range at which dump1090-mutability will work at.
CURRENT_MAX_RANGE=`GetConfig "MAX_RANGE" "/etc/default/dump1090-mutability"`
if [ "CURRENT_MAX_RANGE" != "$DUMP1090_MAX_RANGE" ]] ; then
    echo -e "${COLOR_BLUE}Setting the maximum range which dump1090-mutability works with to ${DUMP1090_MAX_RANGE}...${COLOR_LIGHT_GRAY}"
    ChangeConfig "MAX_RANGE" "${DUMP1090_MAX_RANGE}" "/etc/default/dump1090-mutability"
fi

# Set the unit of measurement dump1090-mutability uses to the one chosen by the user.
if [ "$DUMP1090_UNIT_OF_MEASUREMENT" == "metric" ] ; then
    echo -e "\e[94m  Setting dump1090-mutability unit of measurement to Metric...\e[97m"
    ChangeConfig "Metric" "true;" "/usr/share/dump1090-mutability/html/config.js"
else
    echo -e "${COLOR_BLUE}Setting dump1090-mutability's unit of measurement to Imperial...${COLOR_LIGHT_GRAY}"
    ChangeConfig "Metric" "false;" "/usr/share/dump1090-mutability/html/config.js"
fi

# Set the Bing Maps API key if one was supplied supplied.
if [ ! -z $BING_MAPS_API_KEY ] ; then
    CURRENT_BING_MAPS_API_KEY=`GetConfig "BingMapsAPIKey" "/usr/share/dump1090-fa/html/config.js"`
    if [ "$BING_MAPS_API_KEY" != "$CURRENT_BING_MAPS_API_KEY" ] ; then
        echo -e "${COLOR_BLUE}Writing Bing Maps API key to the dump1090-fa config.js file...${COLOR_LIGHT_GRAY}"
        sudo ChangeConfig "BingMapsAPIKey" "$BING_MAPS_API_KEY" "/usr/share/dump1090-fa/html/config.js"
    fi
fi

# Download Heywhatsthat.com maximum range rings JSON.
if [ "$ADD_HEYWHATSTHAT" == 'true' ] ; then
    echo -e "${COLOR_BLUE}Downloading heywhatsthat.com JSON data pertaining to the supplied panorama ID...${COLOR_LIGHT_GRAY}\n"
    sudo wget -O /usr/share/dump1090-fa/html/upintheair.json "http://www.heywhatsthat.com/api/upintheair.json?id=${HEYWHATSTHAT_PANARAMA_ID}&refraction=0.25&alts=${HEYWHATSTHAT_RING_ONE},${HEYWHATSTHAT_RING_TWO$
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

## SETUP COMPLETE

# Return to the project root directory.
echo -e "${COLOR_BLUE}Entering the ADS-B Receiver Project root directory..."
cd $PROJECT_ROOT_DIRECTORY

echo -e "\n${COLOR_LIGHT_GREEN}------------------------------------"
echo ' Dump1090-mutability setup complete.'
echo -e " ------------------------------------\n${COLOR_LIGHT_GRAY}"

exit 0
