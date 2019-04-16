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

source ${PROJECT_BASH_DIRECTORY}/variables.sh
source ${PROJECT_BASH_DIRECTORY}/functions.sh

## VARIABLES

#FEEDERS
#WEB_SERVER
#SAVE_FLIGHT_DATA
#DATABASE_ENGINE
#MYSQL_HOSTNAME
#MYSQL_ROOT_PASSWORD1
#MYSQL_ROOT_PASSWORD2
#MYSQL_DATABASE
#MYSQL_USER
#MYSQL_USER_PASSWORD1
#MYSQL_USER_PASSWORD2

## --------------
## WELCOME DIALOG

WELCOME_TITLE='Welcome'
WELCOME_MESSAGE="Welcome,\n\nThe goal of the ADS-B Receiver Project to simplify the software setup process required to run a new ADS-B receiver utilizing a RTL-SDR dongle to receive ADS-B signals from aircraft. This allows those intrested in setting up their own reciever to do so quickly and easily with only a basic knowledge of Linux and the various software packages available.\n\nTo learn more about the project please visit one of the projects official websites.\n\nProject Homepage: https://www.adsbreceiver.net.\nGitHub Repository: https://github.com/jprochazka/adsb-receiver\n\nGood hunting!"
dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_MESSAGE" 0 0
if [ $? -eq 255 ] ; then
    exit 1
fi

## ----------------
## DUMP1090 DIALOGS

if [ "$DUMP1090_INSTALLED" == 'true' ] && [ "$DUMP1090_FORK" == 'dump1090-mutability' ] && [ -s /etc/default/dump1090-mutability ] ; then
    # If dump1090-mutability selected or is already installed get variable values from its configuration file.
    RECIEVER_LATITUDE=`GetConfig "LAT" "/etc/default/dump1090-mutability"`
    RECEIVER_LONGITUDE=`GetConfig "LON" "/etc/default/dump1090-mutability"`
    BING_MAPS_API_KEY=`GetConfig "BingMapsAPIKey" "/usr/share/dump1090-mutability/html/config.js"`
fi

if [ "$DUMP1090_INSTALLED" == 'false' ] ; then

    # A fork of Dump1090 is not installed.

    DUMP1090_FORK_TITLE='Choose Dump1090 Fork'
    DUMP1090_FORK_MESSAGE="Dump1090 is a Mode S decoder designed for RTL-SDR devices.\n\nOver time there have been multiple forks of the original. Some of the more popular and requested ones are available for installation using this setup process.\n\nPlease choose the fork which you wish to install."
    DUMP1090_FORK=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_FORK_TITLE" --radiolist "$DUMP1090_FORK_MESSAGE" 0 0 0 \
                    "dump1090-mutability" "(Mutability)" on \
                    "dump1090-fa" "(FlightAware)" off \
                    "dump1090-hptoa" "(OpenSky Network)" off --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi

    # If dump1090-fa was selected inform the user PiAware will be installed as well.
    if [ "$DUMP1090_FORK" == 'dump1090-fa' ] ; then
        PIAWARE_REQUIRED_TITLE='PiAware Required'
        PIAWARE_REQUIRED_MESSAGE="Regarding the FlightAware fork of Dump1090...\n\nThe PiAware software package, which is used to forward ADS-B data to FlightAware, is required in order to use FlightAware's fork of Dump1090. For this reason PiAware will be installed automatically during the setup process."
        dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$PIAWARE_REQUIRED_TITLE" --msgbox "$PIAWARE_REQUIRED_MESSAGE" 0 0
        if [ $? -eq 255 ] ; then
            exit 1
        fi
    fi
else

    # A fork of Dump1090 is installed.

    # If an upgrade is available ask if the newer version should be installed.
    if [ "$DUMP1090_UPGRADEABLE" == 'true' ] ; then

        # Dump1090 (Mutability) new code is no longer versioned so a different question must be asked.
        if [ "$DUMP1090_FORK" == 'dump1090-mutability' ] || [ "$DUMP1090_FORK" == 'dump1090-hptoa'] ; then
            # If Dump1090 (Mutability) or Dump1090 (HPTOA) is installed ask if the user wants to build the current repository master branch contents.
            if [ "$DUMP1090_FORK" == 'dump1090-mutability' ] ; then
                UPGRADE_DUMP1090_TITLE='Update Dump1090 (Mutability)'
                UPGRADE_DUMP1090_MESSAGE="As of v1.15~dev the version number has not changed. However, the source code for the application continues to be worked on. If you wish the repository located locally on this device can be updated and recompiled to ensure you are running the Dump1090 (Mutability) with the latest changes.\n\nUpdate source code and recompile/install Dump1090 (Mutability)?"
            fi
            if [ "$DUMP1090_FORK" == 'dump1090-hptoa' ] ; then
                UPGRADE_DUMP1090_TITLE='Update Dump1090 (HPTOA)'
                UPGRADE_DUMP1090_MESSAGE="As of this moment there have been no releases made specifically for Dump1090 (HPTOA). However, the source code for the application may have changed but with no versioning it is hard to tell if these changes, if any, are reflected in the binaries currently compiled on your device. If you wish the repository located locally on this device can be updated and recompiled to ensure you are running the Dump1090 (HPTOA) with the latest changes.\n\nUpdate source code and recompile Dump1090 (HPTOA)?"
            fi
            dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$UPGRADE_DUMP1090_TITLE" --yesno "$UPGRADE_DUMP1090_MESSAGE" 0 0
            case $? in
                0) UPGRADE_DUMP1090='true' ;;
                1) UPGRADE_DUMP1090='false' ;;
                255) exit 1 ;;
            esac
        else
            # Ask if any other version of Dump1090 should be upgraded if a new version is available.
            UPGRADE_DUMP1090_TITLE='Update Dump1090 (FlightAware)'
            UPGRADE_DUMP1090_MESSAGE="A newer version of Dump1090 (FlightAware) is available.\n\nWould you like to upgrade Dump1090 (FlightAware) now?"
            dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$UPGRADE_DUMP1090_TITLE" --yesno "$UPGRADE_DUMP1090_MESSAGE" 0 0
            case $? in
                0) UPGRADE_DUMP1090='true' ;;
                1) UPGRADE_DUMP1090='false' ;;
                255) exit 1 ;;
            esac

        fi
    else

        # It appears Dump1090 is installed and up to date.
        DUMP1090_INSTALLED_TITLE='Dump1090 Installed'
        DUMP1090_INSTALLED_MESSAGE='Dump1090 appears to already be installed on this device and according to our records up to date.'
        dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_MESSAGE" 0 0
        if [ $? -eq 255 ] ; then
            exit 1
        fi
    fi
fi

# Ask for information needed to configure dump1090-mutability.
if [ "$DUMP1090_FORK" == 'dump1090-mutability' ] ; then

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

    DUMP1090_MAX_RANGE_TITLE='Dump1090-mutability Maximum Range'
    DUMP1090_MAX_RANGE_MESSAGE='The dump1090-mutability default maximum range value of 300 nmi (~550km) has been reported to be below what is possible under the right conditions, so this value will be increased to 360 nmi (~660 km) to match the value used by the dump1090-fa fork.'
    while [ -z $DUMP1090_MAX_RANGE ] ; do
        DUMP1090_MAX_RANGE='360'
        DUMP1090_MAX_RANGE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_MAX_RANGE_TITLE" --inputbox "$DUMP1090_MAX_RANGE_MESSAGE" 0 0 "$DUMP1090_MAX_RANGE" --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi
        RECIEVER_LATITUDE_TITLE='Dump1090-mutability Maximum Range [REQUIRED]'
    done

    BIND_DUMP1090_TO_ALL_IP_ADDRESSES_TITLE='Bind dump1090-mutability To All IP Addresses'
    BIND_DUMP1090_TO_ALL_IP_ADDRESSES_MESSAGE="By default dump1090-mutability is bound only to the local loopback IP address(s) for security reasons. However some people wish to make dump1090-mutability's data accessable externally by other devices. To allow this dump1090-mutability can be configured to listen on all IP addresses bound to this device. It is recommended that unless you plan to access this device from an external source that dump1090-mutability remain bound only to the local loopback IP address(s).\n\nWould you like dump1090-mutability to listen on all IP addesses?"
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$BIND_DUMP1090_TO_ALL_IP_ADDRESSES_TITLE" --yesno "$BIND_DUMP1090_TO_ALL_IP_ADDRESSES_MESSAGE" 0 0
    case $? in
        0) BIND_DUMP1090_TO_ALL_IP_ADDRESSES='true' ;;
        1) BIND_DUMP1090_TO_ALL_IP_ADDRESSES='false' ;;
        255) exit 1 ;;
    esac

    UNIT_OF_MEASURMENT_TITLE='Select Dump1090 Unit of Measurement'
    UNIT_OF_MEASURMENT_MESSAGE='Please select the unit of measurement to be used by dump1090-mutability.'
    dialog  --keep-tite --backtitle "$PROJECT_TITLE" --title "$UNIT_OF_MEASURMENT_TITLE" --yes-button "Imperial" --no-button "Metric" --yesno "$UNIT_OF_MEASURMENT_MESSAGE" 0 0
    case $? in
        0) UNIT_OF_MEASURMENT='imperial' ;;
        1) UNIT_OF_MEASURMENT='metric' ;;
        255) exit 1 ;;
    esac
fi

## ---------------
## DUMP978 DIALOGS

if [ "$DUMP978_INSTALLED" == 'false' ] ; then

    # Dump978 has not been compiled.

    INSTALL_DUMP978_TITLE='Install Dump978'
    INSTALL_DUMP978_MESSAGE="Dump978 is a decoder for 978MHz UAT signals.\n\nDump978 can be install installed in conjunction with Dump1090 as long as two separate RTL-SDR dongles are present on this device. If you only have a single RTL-SDR dongle installing Dump978 along with Dump1090 is not possible.\n\nWhould you like to install Dump978?"
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$INSTALL_DUMP978_TITLE" --defaultno --yesno "$INSTALL_DUMP978_MESSAGE" 0 0
    case $? in
        0) INSTALL_DUMP978='true' ;;
        1) INSTALL_DUMP978='false' ;;
        255) exit 1 ;;
    esac

    if [ "$INSTALL_DUMP978" == 'true' ] ; then

        # Ask which device should be assigned to Dump1090.
        DUMP1090_DEVICE_ID_TITLE='Dump1090 RTL-SDR Dongle Assignment'
        DUMP1090_DEVICE_ID_MESSAGE='Please supply the ID of the RTL-SDR dongle which will be used by Dump1090.'
        while [ -z $DUMP1090_DEVICE_ID ] ; do
            DUMP1090_DEVICE_ID='0'
            DUMP1090_DEVICE_ID=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_DEVICE_ID_TITLE" --inputbox "$DUMP1090_DEVICE_ID_MESSAGE" 0 0 "$DUMP1090_DEVICE_ID" --output-fd 1)
            RESULT=$?
            if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
                exit 1
            fi
            DUMP1090_DEVICE_ID_TITLE='Dump1090 RTL-SDR Dongle Assignment [REQUIRED]'
        done
        # Ask which device should be assigned to Dump978.
        DUMP978_DEVICE_ID_TITLE='Dump978 RTL-SDR Dongle Assignment'
        DUMP978_DEVICE_ID_MESSAGE='Please supply the ID of the RTL-SDR dongle which will be used by Dump978.'
        while [ -z $DUMP978_DEVICE_ID ] ; do
            DUMP978_DEVICE_ID='1'
            DUMP978_DEVICE_ID=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP978_DEVICE_ID_TITLE" --inputbox "$DUMP978_DEVICE_ID_MESSAGE" 0 0 "$DUMP978_DEVICE_ID" --output-fd 1)
            RESULT=$?
            if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
                exit 1
            fi
            DUMP978_DEVICE_ID_TITLE='Dump978 RTL-SDR Dongle Assignment [REQUIRED]'
        done
    fi
else

    # Dump978 has been compiled.

    UPGRADE_DUMP978_TITLE='Update Dump978'
    UPGRADE_DUMP978_MESSAGE="The source code for Dump978 rarely changes if at all. However, the local source code repository can be updated and the binaries recompiled if you wish to do so.\n\nWould you like to recompile the Dump978 binaries?" 0 0
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$UPGRADE_DUMP978_TITLE" --yesno "$UPGRADE_DUMP978_MESSAGE" 0 0
    case $? in
        0) UPGRADE_DUMP978='true' ;;
        1) UPGRADE_DUMP978='false' ;;
        255) exit 1 ;;
    esac
fi

## --------------
## FEEDER DIALOGS

# Build an array containing feeder installation/upgrade options.
declare array FEEDER_OPTIONS

# ADS-B Exchange
if [ "$ADSB_EXCHANGE_CONFIGURED" == 'false' ] || [ "$ADSB_EXCHANGE_MLAT_CLIENT_INSTALLED" == 'false' ] || [ "$ADSB_EXCHANGE_MLAT_CLIENT_UPGRADEABLE" == 'true' ] ; then
    if [ "$ADSB_EXCHANGE_CONFIGURED" == 'false' ] || [ "$ADSB_EXCHANGE_MLAT_CLIENT_INSTALLED" == 'false' ] ; then
        ADSB_EXCHANGE_FEEDER_OPTION='ADS-B Exchange'
    fi
    if [ "$ADSB_EXCHANGE_MLAT_CLIENT_UPGRADEABLE" == 'true' ] ; then
        ADSB_EXCHANGE_FEEDER_OPTION="${ADSB_EXCHANGE_MLAT_CLIENT_OPTION} \(UPGRADE\)"
    fi
    FEEDER_OPTIONS=("${FEEDER_OPTIONS[@]}" "${ADSB_EXCHANGE_FEEDER_OPTION}" '' OFF)
fi

# ADSBHub

if [ "$ADSBHUB_INSTALLED" == 'false' ] || [ "$ADSBHUB_CONFIGURED" == 'false' ] ; then
    ADSBHUB_OPTION='ADSBHub'
    FEEDER_OPTIONS=("${FEEDER_OPTIONS[@]}" "${ADSBHUB_OPTION}" '' OFF)
fi

# FR24Feed (flightradar24)
if [ "$FR24FEED_PACKAGE_INSTALLED" == 'false' ] || [ "$FR24FEED_PACKAGE_UPGRADEABLE" == 'true' ] ; then
    if [ "$FR24FEED_PACKAGE_INSTALLED" == 'false' ] ; then
        FR24FEED_OPTION='Flightradar24 FR24Feed'
    fi
    if [ "$FR24FEED_PACKAGE_UPGRADEABLE" == 'true' ] ; then
        FR24FEED_OPTION='Flightradar24 FR24Feed (UPGRADE)'
    fi
    FEEDER_OPTIONS=("${FEEDER_OPTIONS[@]}" "${FR24FEED_OPTION}" '' OFF)
fi


if [ "$OPENSKY_FEEDER_INSTALLED" == "false" ] ; then
    OPENSKY_OPTION='OpenSky Network Feeder'
    FEEDER_OPTIONS=("${FEEDER_OPTIONS[@]}" "${OPENSKY_OPTION}" '' OFF)
fi

# PiAware (FlightAware)
if [ "$PIAWARE_INSTALLED" == 'false' ] || [ "$PIAWARE_UPGRADEABLE" == 'true' ] ; then
    if [ "$PIAWARE_INSTALLED" == 'false' ] ; then
        PIAWARE_OPTION='FlightAware PiAware'
    fi
    if [ "$PIAWARE_UPGRADEABLE" == 'true' ] ; then
        PIAWARE_OPTION='FlightAware PiAware (UPGRADE)'
    fi
    FEEDER_OPTIONS=("${FEEDER_OPTIONS[@]}" "${PIAWARE_OPTION}" '' OFF)
fi

# Plane Finder ADS-B Client (planefinder)

if [ "PLANEFINDER_CLIENT_INSTALLED" == 'false' ] || [ "$PLANEFINDER_CLIENT_UPGRADEABLE" == 'true' ] ; then
    if [ "$PLANEFINDER_CLIENT_INSTALLED" == 'false' ] ; then
        PLANEFINDER_CLIENT_OPTION='Planefinder Client'
    fi
    if [ "$PLANEFINDER_CLIENT_UPGRADEABLE" == 'true' ] ; then
        PLANEFINDER_CLIENT_OPTION='Planefinder Client (UPGRADE)'
    fi
    FEEDER_OPTIONS=("${FEEDER_LIST[@]}" "${PLANEFINDER_CLIENT_OPTION}" '' OFF)
fi

# Display feeder options.
if [ ${#FEEDER_OPTIONS[@]} -ne 0 ] ; then
    # Display a list of feeder options for the user to choose from.
    FEEDERS_TITLE='Feeder Installation Options'
    FEEDERS_MESSAGE="The following feeder options are available for installation or upgrade.\nChoose the feeders you wish to install or upgrade."
    FEEDERS=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$FEEDERS_TITLE" --checklist "$FEEDERS_MESSAGE" 13 65 6 "${FEEDER_OPTIONS[@]}" --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi
else
    # There are no additional feeder options to choose from.
    NO_FEEDER_OPTIONS_TITLE='All Feeders Installed'
    NO_FEEDER_OPTIONS_MESSAGE='It appears that all the optional feeders available for installation by this script have been installed already.'
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$NO_FEEDER_OPTIONS_TITLE" --msgbox "$NO_FEEDER_OPTIONS_MESSAGE" 0 0
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi
fi

## PORTAL DIALOGS

# Ask if the portal is to be installed.
INSTALL_PORTAL_TITLE='The ADS-B Receiver Project Portal'
INSTALL_PORTAL_MESSAGE="The ADS-B Receiver Project Portal\n\nThe ADS-B Receiver Project Portal is a web based portal which can display position and other information pertaining to aircraft being tracked by your receiver. With the correct hardware in place you can also retain historical data of all aircraft tracked locally which you can reference at a later date.\n\nWould you like to install the portal?"
dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$INSTALL_PORTAL_TITLE" --yesno "$INSTALL_PORTAL_MESSAGE" 0 0
case $? in
    0) INSTALL_PORTAL='true' ;;
    1) INSTALL_PORTAL='false' ;;
    255) exit 1 ;;
esac

if [ "$INSTALL_PORTAL" == 'true' ] ; then

    # Choose webserver which will be used.

    WEB_SERVER_TITLE='Select The Web Server to Install'
    WEB_SERVER_MESSAGE='Please select one of the following lightwieght web servers you would like to use to host the portal.\n\nChoose which webserver you would like to use.'
    WEB_SERVER=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$WEB_SERVER_TITLE" --radiolist "$WEB_SERVER_MESSAGE" 0 0 0 \
                 "nginx" "Nginx" on \
                 "lighttpd" "lighthttpd" off --output-fd 1)
    if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
        exit 1
    fi



    # Ask if heywhatsthat.com range rings should be added.



    # Choose whether or not to save flight data.
    SAVE_FLIGHT_DATA_TITLE='Enable Historical Flight Data Collection'
    SAVE_FLIGHT_DATA_MESSAGE='The portal can be configured to save data pertaining to each flight the ADS-B receiver gathers. By saving this data you can search for and view past flights your receiver had tracked.\n\nIMPORTANT:\nIt is highly recommended you answer no if this device uses an SD cards for data storage. It is also recommended you not enable this feature on under powered devices as well.\n\nWould you like to save flight data?'
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$SAVE_FLIGHT_DATA_TITLE" --yesno "$SAVE_FLIGHT_DATA_MESSAGE" 0 0
    case $? in
        0) SAVE_FLIGHT_DATA='true';;
        1) SAVE_FLIGHT_DATA='false';;
        255) exit 1;;
    esac

    if [ "$SAVE_FLIGHT_DATA" == 'true' ] ; then

        # Choose a database engine.
        DATABASE_ENGINE_TITLE='Choose a Database Engine'
        DATABASE_ENGINE_MESSAGE='Which database engine would you like to save historical flight data to?'
        DATABASE_ENGINE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DATABASE_ENGINE_TITLE" --radiolist "$DATABASE_ENGINE_MESSAGE" 0 0 0 \
                          "sqlite" "SQLite" on \
                          "mysql" "MySQL/MariaDB" off --output-fd 1)
        if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
            exit 1
        fi

        if [ "$DATABASE_ENGINE" == "mysql" ] ; then

            # Ask for the MySQL database server's hostname.
            MYSQL_HOSTNAME_TITLE='Enter the MySQL/MariaDB Server Hostname'
            MYSQL_HOSTNAME_MESSAGE='Enter the hostname of the MySQL/MariaDB database server you will use to store historical flight data.\n\nIf set to localhost MySQL or MariaDB will be installed on this device and configured automatically. If this is a remote MySQL/MariaDB server the database and a user must already exist on said server.'
            while [ -z $MYSQL_HOSTNAME ] ; do
                MYSQL_HOSTNAME=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_HOSTNAME_TITLE" --inputbox "$MYSQL_HOSTNAME_MESSAGE" 0 0 "localhost" --output-fd 1)
                if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
                    exit 1
                fi
                MYSQL_HOSTNAME_TITLE='Enter the MySQL/MariaDB Hostname [REQUIRED]'
            done

            if [ "$MYSQL_HOSTNAME" == "localhost" ] || [ "$MYSQL_HOSTNAME" == "127.0.0.1" ] || [ "$MYSQL_HOSTNAME" == "::1" ] ; then

                # Ask for the passwword to be set for the root user on the MySQL or MariaDB database server."
                while [ "$MYSQL_ROOT_PASSWORD1" != "$MYSQL_ROOT_PASSWORD2" ] || [ -z $MYSQL_ROOT_PASSWORD1 ] || [ -z $MYSQL_ROOT_PASSWORD2 ] ; do

                    # Make sure that the MYSQL_ROOT_PASSWORD1 and MYSQL_ROOT_PASSWORD2 variables are unset so that dialogs are shown.
                    if [ ! -z $MYSQL_ROOT_PASSWORD1 ] ; then
                        unset MYSQL_ROOT_PASSWORD1
                    fi
                    if [ ! -z $MYSQL_ROOT_PASSWORD2 ] ; then
                        unset MYSQL_ROOT_PASSWORD2
                    fi

                    # Ask for the MySQL or MariaDB database root or account with create database and user permissions password.
                    MYSQL_ROOT_PASSWORD1_TITLE='Supply MySQL/MariaDB Root Password'
                    MYSQL_ROOT_PASSWORD1_MESSAGE="Supply a password to be used for the root user."
                    while [ -z $MYSQL_ROOT_PASSWORD1 ] ; do
                        MYSQL_ROOT_PASSWORD1=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_ROOT_PASSWORD1_TITLE" --backtitle "$PROJECT_TITLE" --passwordbox "$MYSQL_ROOT_PASSWORD1_MESSAGE" 0 0 --output-fd 1)
                        if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
                            exit 1
                        fi
                        MYSQL_ROOT_PASSWORD1_TITLE='Supply MySQL/MariaDB Root Password [REQUIRED]'
                    done

                    # Ask to repeat the MySQL or MariaDB database root or account with create database and user permissions password.
                    MYSQL_ROOT_PASSWORD2_TITLE='Repeat MySQL/MariaDB Root Password'
                    MYSQL_ROOT_PASSWORD2_MESSAGE="Repeat the password to be used for the root user."
                    while [ -z $MYSQL_ROOT_PASSWORD2 ] ; do
                        MYSQL_ROOT_PASSWORD2=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_ROOT_PASSWORD2_TITLE" --backtitle "$PROJECT_TITLE" --passwordbox "$MYSQL_ROOT_PASSWORD2_MESSAGE" 0 0 --output-fd 1)
                        if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
                            exit 1
                        fi
                        MYSQL_ROOT_PASSWORD2_TITLE='Repeat MySQL/MariaDB Root Password [REQUIRED]'
                    done
                done
            fi

            # Ask for the name of the database to be used within the MySQL/MariaDB database.
            MYSQL_DATABASE_TITLE='MySQL/MariaDB Database Name'
            MYSQL_DATABASE_MESSAGE='Please supply the name of the database which will be used to store your receivers historical flight tracking data.'
            while [ -z $MYSQL_DATABASE ] ; do
                MYSQL_DATABASE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_DATABASE_TITLE" --inputbox "$MYSQL_DATABASE_MESSAGE" 0 0 --output-fd 1)
                if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
                    exit 1
                fi
                MYSQL_DATABASE_MESSAGE='MySQL/MariaDB Database Name [REQUIRED]'
            done

            # Ask for the user name with access to the MySQL/MariaDB database.
            MYSQL_USER_TITLE='MySQL/MariaDB Database User Name'
            MYSQL_USER_MESSAGE='Supply the name of the user which has permission to use this database.'
            while [ -z $MYSQL_USER ] ; do
                MYSQL_USER=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_USER_TITLE" --inputbox "$MYSQL_USER_MESSAGE" 0 0 --output-fd 1)
                if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
                    exit 1
                fi
                MYSQL_USER_MESSAGE='MySQL/MariaDB Database User Name [REQUIRED]'
            done

            while [ "$MYSQL_PASSWORD1" != "$MYSQL_PASSWORD2" ] && [ -z $MYSQL_PASSWORD1 ] || [ -z $MYSQL_PASSWORD2 ] ; do

                # Make sure that the MYSQL_PASSWORD1 and MYSQL_PASSWORD2 variables are unset so that dialogs are shown.
                if [ ! -z $MYSQL_PASSWORD1 ] ; then
                    unset MYSQL_USER_PASSWORD1
                fi
                if [ ! -z $MYSQL_PASSWORD2 ] ; then
                    unset MYSQL_USER_PASSWORD2
                fi

                # Ask for the password for the login to be used to access the MySQL/MariaDB database.
                while [ -z $MYSQL_USER_PASSWORD1 ] ; do
                    MYSQL_USER_PASSWORD1_TITLE='MySQL/MariaDB Database User Password'
                    MYSQL_USER_PASSWORD1_MESSAGE="Enter the database user's password."
                    MYSQL_USER_PASSWORD1=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_USER_PASSWORD1_TITLE" --backtitle "$PROJECT_TITLE" --passwordbox "$MYSQL_USER_PASSWORD1_MESSAGE" 0 0 --output-fd 1)
                    if [ $? -eq 255 ] || [ $? -eq 1 ] ; then
                        exit 1
                    fi
                    MYSQL_USER_PASSWORD1_MESSAGE='MySQL/MariaDB Database User Password [REQUIRED]'
                done

                # Ask to repeat the password for the login to be used to access the MySQL/MariaDB database.
                MYSQL_USER_PASSWORD2_TITLE='Repeat MySQL/MariaDB Database User Password'
                MYSQL_USER_PASSWORD2_MESSAGE="Repeat the database user's password."
                while [ -z $MYSQL_USER_PASSWORD2 ] ; do
                    MYSQL_USER_PASSWORD2=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_USER_PASSWORD2_TITLE" --backtitle "$PROJECT_TITLE" --passwordbox "$MYSQL_USER_PASSWORD2_MESSAGE" 0 0 --output-fd 1)
                    RESULT=$?
                    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
                        exit 1
                    fi
                    MYSQL_PASSWORD2_MESSAGE='Repeat MySQL/MariaDB Database User Password [REQUIRED]'
                done
            done
        fi
    fi
fi

## EXTRAS DIALOGS

exit 0
