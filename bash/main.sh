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

## DECLARE ARRAYS

declare -A RECEIVER
declare -A DUMP1090
declare -A DUMP978
declare -A HEYWHATSTHAT
declare -A BING

export RECEIVER
export DUMP1090
export DUMP978
export HEYWHATSTHAT
export BING

## SOURCE EXTERNAL SCRIPTS

source ${PROJECT_BASH_DIRECTORY}/checks.sh
source ${PROJECT_BASH_DIRECTORY}/variables.sh
source ${PROJECT_BASH_DIRECTORY}/functions.sh

## WELCOME DIALOG

WELCOME_TITLE='Welcome'
WELCOME_MESSAGE="Welcome,\n\nThe goal of the ADS-B Receiver Project to simplify the software setup process required to run a new ADS-B receiver utilizing a RTL-SDR dongle to receive ADS-B signals from aircraft. This allows those intrested in setting up their own reciever to do so quickly and easily with only a basic knowledge of Linux and the various software packages available.\n\nTo learn more about the project please visit one of the projects official websites.\n\nProject Homepage: https://www.adsbreceiver.net.\nGitHub Repository: https://github.com/jprochazka/adsb-receiver\n\nGood hunting!"
dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_MESSAGE" 0 0
if [ $? -eq 255 ] ; then
    exit 1
fi

## DUMP1090

# Check the status of Dump1090.
dump1090_status

if [ "${DUMP1090[installed]}" == 'false' ] ; then

    # Have the user choose which Dump1090 fork to install.
    DUMP1090_FORK_TITLE='Choose Dump1090 Fork'
    DUMP1090_FORK_MESSAGE="Dump1090 is a Mode S decoder designed for RTL-SDR devices.\n\nOver time there have been multiple forks of the original. Some of the more popular and requested ones are available for installation using this setup process.\n\nPlease choose the fork which you wish to install."
    DUMP1090[fork]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP1090_FORK_TITLE" --radiolist "$DUMP1090_FORK_MESSAGE" 0 0 0 \
                    "dump1090-mutability" "(Mutability)" on \
                    "dump1090-fa" "(FlightAware)" off \
                    "dump1090-hptoa" "(OpenSky Network)" off --output-fd 1)
    RESULT=$?
    if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
        exit 1
    fi
fi

# TODO:
# Ask user if they wish to reinstall/reconfigure dump1090 if it is already installed.

case ${DUMP1090[fork]} in
    'dump1090-mutability') source ${PROJECT_BASH_DIRECTORY}/decoders/dump1090-mutability.sh ;;
    'dump1090-fa') source ${PROJECT_BASH_DIRECTORY}/decoders/dump1090-fa.sh ;;
    'dump1090-hptoa') source ${PROJECT_BASH_DIRECTORY}/decoders/dump1090-hptoa.sh ;;
esac

# Display the proper Dump1090 setup dialogs.
dump1090_dialogs

## DUMP978

# Check the status of Dump978.
dump978_status

if [ "${DUMP978[installed]}" == 'false' ] ; then

    # Ask user if they wish to install dump978 if it is not already installed.
    DUMP978_DO_INSTALL_TITLE="Install Dump978"
    DUMP978_DO_INSTALL_MESSAGE="Dump978 is a demodulator/decoder for 978MHz UAT signals. In order to install and use Dump978 you will need to have two physical RTL-SDR USB dongles available. One for Dump1090 and the other for Dump978.\n\nWould you like to install dump978?"
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "DUMP978_DO_INSTALL_MESSAGE" --defaultno --yesno "$DUMP978_DO_INSTALL_MESSAGE" 0 0
    case $? in
        0) DUMP978[do_install]='true' ;;
        1) DUMP978[do_install]='false' ;;
        255) exit 1 ;;
    esac

    if [ "${DUMP978[do_install]}" == 'true' ] ; then

        # Have the user choose which Dump978 fork to install.
        DUMP978_FORK_TITLE='Choose Dump978 Fork'
        DUMP978_FORK_MESSAGE=""
        DUMP978[fork]=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP978_FORK_TITLE" --radiolist "$DUMP978_FORK_MESSAGE" 0 0 0 \
                        "dump978-mutability" "(Mutability)" off \
                        "dump978-fa" "(FlightAware)" off  --output-fd 1)
        RESULT=$?
        if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
            exit 1
        fi

        case ${DUMP978[fork]} in
            'dump978-mutability') source ${PROJECT_BASH_DIRECTORY}/decoders/dump978-mutability.sh ;;
            'dump978-fa') source ${PROJECT_BASH_DIRECTORY}/decoders/dump978-fa.sh ;;
        esac

        # Display the proper Dump1090 setup dialogs.
        dump978_dialogs
    fi
fi

# Display array contents during development.
echo ''
echo ''
echo 'RECEIVER ARRAY'
echo "  latitude: ${RECEIVER[latitude]}"
echo "  longitude: ${RECEIVER[longitude]}"
echo ''
echo 'DUMP1090 ARRAY'
echo "  installed: ${DUMP1090[installed]}"
echo "  fork: ${DUMP1090[fork]}"
echo "  upgradeable: ${DUMP1090[upgradeable]}"
echo "  do_install: ${DUMP1090[do_install]}"
echo "  device_id: ${DUMP1090[device_id]}"
echo "  bind_all_ips: ${DUMP1090[bind_all_ips]}"
echo "  max_range: ${DUMP1090[max_range]}"
echo "  unit_of_measure: ${DUMP1090[unit_of_measurment]}"
echo ''
echo 'DUMP978 ARRAY'
echo "  installed: ${DUMP978[installed]}"
echo "  fork: ${DUMP978[fork]}"
echo "  upgradeable: ${DUMP978[upgradeable]}"
echo "  do_install: ${DUMP978[do_install]}"
echo "  device_id: ${DUMP978[device_id]}"
echo "  samplerate: ${DUMP978[samplerate]}"
echo "  gain: ${DUMP978[gain]}"
echo ''
echo 'HAYWHATSTHAT ARRAY'
echo "  add: ${HEYWHATSTHAT[add]}"
echo "  panarama_id: ${HEYWHATSTHAT[panarama_id]}"
echo "  ring_one_altitude: ${HEYWHATSTHAT[ring_one_altitude]}"
echo "  ring_two_altitude: ${HEYWHATSTHAT[ring_two_altitude]}"
echo ''
echo 'BING ARRAY'
echo "  maps_api_key: ${BING[maps_api_key]}"


unset RECEIVER
unset DUMP1090
unset DUMP978
unset HEYWHATSTHAT
unset BING

# STOPPING HERE FOR TESTING PURPOSES
exit 0



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

if [ "$PLANEFINDER_CLIENT_INSTALLED" == 'false' ] || [ "$PLANEFINDER_CLIENT_UPGRADEABLE" == 'true' ] ; then
    if [ "$PLANEFINDER_CLIENT_INSTALLED" == 'false' ] ; then
        PLANEFINDER_CLIENT_OPTION='Planefinder Client'
    fi
    if [ "$PLANEFINDER_CLIENT_UPGRADEABLE" == 'true' ] ; then
        PLANEFINDER_CLIENT_OPTION='Planefinder Client (UPGRADE)'
    fi
    FEEDER_OPTIONS=("${FEEDER_OPTIONS[@]}" "${PLANEFINDER_CLIENT_OPTION}" '' OFF)
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
