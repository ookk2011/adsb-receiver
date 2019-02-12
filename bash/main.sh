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

DUMP_1090_FORK
INSTALL_PORTAL
WEB_SERVER
SAVE_FLIGHT_DATA
DATABASE_ENGINE
MYSQL_HOSTNAME
MYSQL_ROOT_LOGIN
MYSQL_ROOT_PASSWORD1
MYSQL_ROOT_PASSWORD2
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD1
MYSQL_PASSWORD2

## WELCOME DIALOG

WELCOME_TITLE='Welcome'
WELCOME_MESSAGE="Welcome,\n\nThe goal of the ADS-B Receiver Project to simplify the software setup process required to run a new ADS-B receiver utilizing a RTL-SDR dongle to receive ADS-B signals from aircraft. This allows those intrested in setting up their own reciever to do so quickly and easily with only a basic knowledge of Linux and the various software packages available.\n\nTo learn more about the project please visit one of the projects official websites.\n\nProject Homepage: https://www.adsbreceiver.net.\nGitHub Repository: https://github.com/jprochazka/adsb-receiver\n\nGood hunting!"
dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_MESSAGE" 0 0

## DUMP 1090 DIALOGS

DUMP_1090_TITLE='Choose Dump 1090 fork'
DUMP_1090_MESSAGE="Dump 1090 is a Mode S decoder designed for RTL-SDR devices.\n\nOver time there have been multiple forks of the original some of the more popular and requested ones are available for in installation. Please choose the fork which you wish to install."
DUMP_1090_FORK=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DUMP_1090_TITLE" --radiolist "$DUMP_1090_MESSAGE" 0 0 0 "mutability" "Dump 1090 (Mutability)" on)
RESULT=$?
if [ $RESULT -eq 255 ] || [ $RESULT -eq 1 ] ; then
    exit 1
fi

## PORTAL DIALOGS

# Ask if the portal is to be installed.
INSTALL_PORTAL_TITLE='The ADS-B Receiver Project Portal'
INSTALL_PORTAL_MESSAGE="The ADS-B Receiver Project Portal\n\nWould you like to install the portal?"
dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$INSTALL_PORTAL_TITLE" --yesno "$INSTALL_PORTAL_MESSAGE" 0 0
case $? in
    0) INSTALL_PORTAL="true";;
    1) INSTALL_PORTAL="false";;
    255) exit 1;;
esac

if [ "INSTALL_PORTAL" == "true" ] ; then

    # Choose webserver which will be used.
    WEB_SERVER_TITLE='Web Server'
    WEB_SERVER_MESSAGE='Choose the webserver to use to serve the portal pages.'
    WEB_SERVER=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$WEB_SERVER_TITLE" --radiolist "$WEB_SERVER_MESSAGE" 0 0 0 "nginx" "Nginx" on "lighttpd" "Lighttpd" off)

    # Choose whether or not to save flight data.
    SAVE_FLIGHT_DATA_TITLE='Enable Historical Flight Data Collection'
    SAVE_FLIGHT_DATA_MESSAGE='The portal can be configured to save data pertaining to each flight the ADS-B receiver gathers. By saving this data you can search for and view past flights your receiver had tracked.\n\nIMPORTANT:\nIt is highly recommended you answer no if this device uses an SD cards for data storage. It is recommended you not enable this feature on under powered devices as well.\n\nWould you like to save flight data?'
    dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "SAVE_FLIGHT_DATA_TITLE" --yesno "SAVE_FLIGHT_DATA_MESSAGE" 0 0
    case $? in
        0) SAVE_FLIGHT_DATA="true";;
        1) SAVE_FLIGHT_DATA="false";;
    255) exit 1;;

    if [ "SAVE_FLIGHT_DATA" == "true" ] ; then

        # Choose a database engine.
        DATABASE_ENGINE='Choose a Database Engine'
        DATABASE_ENGINE='Which database engine would you like to save historical flight data to?'
        DATABASE_ENGINE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$DATABASE_ENGINE_TITLE" --radiolist "$DATABASE_ENGINE_MESSAGE" 0 0 0 "sqlite" "SQLite" on "mysql" "MySQL (MariaDB)" off)

        if [ "$DATABASE_ENGINE" == "mysql" ] ; then

            # Ask for the MySQL database server's hostname.
            MYSQL_HOSTNAME_TITLE='Enter the MySQL or MariaDB Hostname'
            MYSQL_HOSTNAME_MESSAGE='Enter the hostname of the MySQL database server you will use to store historical flight data.\n\nIf set to localhost MySQL or MariaDB will be installed be installed on this device and configured automatically. If a remote database server is to be used it is required that the database and a user already exist on said server.'
            while [ -z $MYSQL_HOSTNAME ] ; do
                MYSQL_HOSTNAME=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_HOSTNAME_TITLE" --backtitle "$PROJECT_TITLE" --inputbox "$MYSQL_HOSTNAME_MESSAGE" 0 0)
                MYSQL_HOSTNAME_TITLE='Enter the MySQL or MariaDB Hostname [REQUIRED]'
            done

            if [ "$MYSQL_HOSTNAME" == "localhost" ] || [ "$MYSQL_HOSTNAME" == "127.0.0.1" ] || [ "$MYSQL_HOSTNAME" == "::1" ] ; then

                # Ask for the MySQL or MariaDB database root or account with create database and user permissions login."
                MYSQL_ROOT_LOGIN_TITLE='Supply MySQL/MariaDB Root or Administrator Login'
                MYSQL_ROOT_LOGIN_MESSAGE='Supply either the root user login or the login for a user capable of creating databases and adding users to MySQL or MariaDB.'
                while [ -z $MYSQL_ROOT_LOGIN ] ; do
                    MYSQL_ROOT_LOGIN=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_ROOT_LOGIN_TITLE" --backtitle "$PROJECT_TITLE" --inputbox "$MYSQL_ROOT_LOGIN_MESSAGE" 0 0)
                    MYSQL_ROOT_LOGIN_TITLE='Supply MySQL/MariaDB Root or Administrator Login [REQUIRED]'
                done

                while [ "$MYSQL_ROOT_PASSWORD1" != "$MYSQL_ROOT_PASSWORD2" ] && [ -z $MYSQL_ROOT_PASSWORD1 ] || [ -z $MYSQL_ROOT_PASSWORD2 ] ; do

                    # Ask for the MySQL or MariaDB database root or account with create database and user permissions password."
                    MYSQL_ROOT_PASSWORD1_TITLE='Supply MySQL/MariaDB Root or Administrator Password'
                    MYSQL_ROOT_PASSWORD1_MESSAGE="Supply the password for the $MYSQL_ROOT_LOGIN user."
                    while [ -z $MYSQL_ROOT_PASSWORD1 ] ; do
                        MYSQL_ROOT_PASSWORD1=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_ROOT_PASSWORD1_TITLE" --backtitle "$PROJECT_TITLE" --passwordbox "$MYSQL_ROOT_PASSWORD1_MESSAGE" 0 0)
                        MYSQL_ROOT_PASSWORD1_TITLE='Supply MySQL/MariaDB Root or Administrator Password [REQUIRED]'
                    done

                    # Ask for the MySQL or MariaDB database root or account with create database and user permissions password again."
                    MYSQL_ROOT_PASSWORD2_TITLE='Repeat MySQL/MariaDB Root or Administrator Password'
                    MYSQL_ROOT_PASSWORD2_MESSAGE="Repeat the password for the $MYSQL_ROOT_LOGIN user."
                    while [ -z $MYSQL_ROOT_PASSWORD2 ] ; do
                        MYSQL_ROOT_PASSWORD2=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_ROOT_PASSWORD2_TITLE" --backtitle "$PROJECT_TITLE" --passwordbox "$MYSQL_ROOT_PASSWORD2_MESSAGE" 0 0)
                        MYSQL_ROOT_PASSWORD2_TITLE='Repeat MySQL/MariaDB Root or Administrator Password [REQUIRED]'
                    done
                done
            fi

            # Ask for the name of the database where historical data will be saved.
            MYSQL_DATABASE_TITLE=''
            MYSQL_DATABASE_MESSAGE=''
            while [ -z $MYSQL_USER_DATABASE ] ; do
                MYSQL_DATABASE=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_DATABASE_TITLE" --backtitle "$PROJECT_TITLE" --inputbox "$MYSQL_DATABASE_MESSAGE" 0 0)
                MYSQL_DATABASE_MESSAGE=' [REQUIRED]'
            done

            # Ask for the login to be used to add and access historial data.
            MYSQL_LOGIN_TITLE=''
            MYSQL_LOGIN_MESSAGE=''
            while [ -z $MYSQL_USER_LOGIN ] ; do
                MYSQL_LOGIN=$(dialog --keep-tite --backtitle "$PROJECT_TITLE" --title "$MYSQL_LOGIN_TITLE" --backtitle "$PROJECT_TITLE" --inputbox "$MYSQL_LOGIN_MESSAGE" 0 0)
                MYSQL_LOGIN_MESSAGE=' [REQUIRED]'
            done

            while [ "$MYSQL_PASSWORD1" != "$MYSQL_PASSWORD2" ] && [ -z $MYSQL_PASSWORD1 ] || [ -z $MYSQL_PASSWORD2 ] ; do

                # Ask for the login to be used to add and access historial data again.
                MYSQL_PASSWORD1_TITLE=''
                MYSQL_PASSWORD1_MESSAGE=''
                while [ -z $MYSQL_USER_PASSWORD1 ] ; do
                    MYSQL_USER_PASSWORD1
                    MYSQL_PASSWORD1_MESSAGE=' [REQUIRED]'
                done

                # Ask for the password for the login to be used to add and access historical data.
                MYSQL_PASSWORD2_TITLE=''
                MYSQL_PASSWORD2_MESSAGE=''
                while [ -z $MYSQL_USER_PASSWORD2 ] ; do
                    MYSQL_PASSWORD2
                    MYSQL_PASSWORD2_MESSAGE=' [REQUIRED]'
                done
            done

            # If this is a remote MySQL or MariaDB server attempt to connect to it.

        fi
    fi
fi

exit 0
