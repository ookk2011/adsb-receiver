#!/bin/bash

#####################################################################################
#                            THE ADS-B RECEIVER PROJECT                             #
#####################################################################################
#                                                                                   #
#  A set of scripts created to automate the process of installing the software      #
#  needed to setup a Mode S decoder as well as feeders which are capable of         #
#  sharing your ADS-B results with many of the most popular ADS-B aggregate sites.  #
#                                                                                   #
#  Project Hosted On GitHub: https://github.com/jprochazka/adsb-receiver            #
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

## EXPORT VARIABLES

export DEVICE_CPU_ARCHITECTURE=`uname -m`
export DEVICE_OS_DISTRIBUTION=`. /etc/os-release; echo ${ID/*, /}`
export DEVICE_OS_RELEASE=`. /etc/os-release; echo ${VERSION_ID/*, /}`

export PROJECT_THIS_VERSION='3.0.0'
export PROJECT_BRANCH='3.0'
export PROJECT_ROOT_DIRECTORY="$PWD"
export PROJECT_BASH_DIRECTORY="${PWD}/bash"
export PROJECT_BUILD_DIRECTORY="${PWD}/build"
export PROJECT_TITLE="THE ADS-B RECIEVER PROJECT V${PROJECT_THIS_VERSION} INSTALLER"
export PROJECT_LOG_FILE="${PROJECT_ROOT_DIRECTORY}/logs/install_$(date +"%Y-%m-%d_%H-%M-%S").log"

export DUMP1090_FORK=''
export DUMP1090_INSTALLED='false'
export DUMP1090_UPGRADEABLE='false'
export DUMP1090_UPGRADE='false'
export DUMP1090_DEVICE_ID='0'

export DUMP978_INSTALLED='false'
export DUMP978_UPGRADEABLE='false'
export DUMP978_DEVICE_ID='1'

export ADSB_EXCHANGE_CONFIGURED='false'
export ADSB_EXCHANGE_MLAT_CLIENT_INSTALLED='false'
export ADSB_EXCHANGE_MLAT_CLIENT_UPGRADEABLE='false'

export PIAWARE_INSTALLED='false'
export PIAWARE_UPGRADEABLE='false'

export COLOR_BLUE='\e[0;34m'
export COLOR_GREEN='\e[0;32m'
export COLOR_LIGHT_BLUE='\e[1;34m'
export COLOR_LIGHT_GRAY='\e[0;37m'
export COLOR_LIGHT_GREEN='\e[1;32m'
export COLOR_PURPLE='\e[0;35m'
export COLOR_RED='\e[0;31m'
export COLOR_YELLOW='\e[1;33m'

# PuTTY does not display dialog borders properly when the locale is set to UTF-8. (This fixes the issue.)
export NCURSES_NO_UTF8_ACS=1

## SOURCE EXTERNAL SCRIPTS

source ${PROJECT_BASH_DIRECTORY}/functions.sh

## DISPLAY PROJECT TITLE AND VERSION

clear
echo -e "\n${COLOR_LIGHT_GREEN}---------------------------------------------"
echo -e " $PROJECT_TITLE"
echo -e "${COLOR_LIGHT_GREEN}---------------------------------------------\n"

## CHECK FOR REQUIRED PACKAGES

# Make sure that the packages needed in order fot the scripts to run properly are installed first.
echo -e "${COLOR_LIGHT_BLUE}Check for required packages.${COLOR_LIGHT_GRAY}\n"

# Check if apt update was ran successfully within the last hour or if the user specified the command should be ran.
if [ `stat -c %Y /var/cache/apt/pkgcache.bin` -lt $((`date +%s` - 3600)) ] || [ ! -z $FORCE_APT_UPDATE ] && [ "$FORCE_APT_UPDATE" == 'true' ] ; then
    # Run the apt update command.
    echo -e "${COLOR_BLUE}Updating apt package lists...${COLOR_LIGHT_GRAY}\n"
    sudo apt-get update
    echo ''
fi

if [ ! -z $EXECUTE_APT_UPGRADE ] && [ "$EXECUTE_APT_UPGRADE" == 'true' ] ; then
    # Run the apt upgrade command.
    echo -e "${COLOR_BLUE}Upgrading your system using apt...${COLOR_LIGHT_GRAY}\n"
    sudo apt-get -y upgrade
    echo ''
fi

# Check that any required packages are installed and if not install them.
CheckPackage bc
CheckPackage curl
CheckPackage dialog
CheckPackage git

## EXPORT REMAINING VARIABLES

# Variables get the current release version number from the Internet if possible..
export PROJECT_CURRENT_VERSION="$(curl -s -L https://www.adsbreceiver.net/latest.txt)" || PROJECT_CURRENT_VERSION='NA'

## FUNCTIONS

# This function displays the --help message.
function DisplayHelp() {
    echo "Usage: ${0} [OPTIONS] [ARGUMENTS]\n"
    echo ''
    echo 'Option        GNU long option        Meaning'
    echo '-a            --apt-update           Forces the apt update command to be ran.\n'
    echo '-b <BRANCH>   --branch=<BRANCH>      Specifies the repository branch to be used.'
    echo '-h            --help                 Shows this message.'
    echo '-u            --apt-upgrade          Executes the apt upgrade command during setup.'
}

## HANDLE ARGUMENTS

while [ $# -gt 0 ] ; do
    case "$1" in

        # Force the execution of the apt update command.
        -a|--apt-update)
            FORCE_APT_UPDATE='true'
            shift 1
            ;;

        # Use a branch other than the master branch.
        -b)
            ORIGINAL_BRANCH=$PROJECT_BRANCH
            PROJECT_BRANCH="$2"
            shift 2
            ;;
        --branch*)
            ORIGINAL_BRANCH=$PROJECT_BRANCH
            PROJECT_BRANCH=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift 1
            ;;

        # Display the help message and exit.
        -h|--help)
            DisplayHelp
            exit 0
            ;;

        # Execute the apt upgrade command.
        -u|--apt-upgrade)
            EXECUTE_APT_UPGRADE='true'
            shift 1
            ;;

    esac
done

## PREPARE REPOSITORY

# Checkout the repository branch to be used if it has not already been checked out.
echo -e "\n${COLOR_LIGHT_BLUE}Check that the ${PROJECT_BRANCH} branch is checked out.\n"
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
if [ "$PROJECT_BRANCH" != "$CURRENT_BRANCH" ] ; then
    echo -e "${COLOR_BLUE}Stashing files which have been changed...${COLOR_LIGHT_GRAY}\n"
    git stash
    echo -e "\n${COLOR_BLUE}Checking out the branch ${PROJECT_BRANCH}...${COLOR_LIGHT_GRAY}\n"
    git checkout $PROJECT_BRANCH
    echo -e "\n${COLOR_YELLOW}NOTICE: The branch named ${PROJECT_BRANCH} has been checked out."
    echo -e '        Setup will now exit to ensure you are running the latest version of this script.\n'
    echo -e "        Please restart setup using the following command.${COLOR_LIGHT_GRAY}\n"
    if [ -z $ORIGINAL_BRANCH ] && [ "$ORIGINAL_BRANCH" == "$PROJECT_BRANCH" ] ; then
        echo -e './install\n'
    else
        echo -e "./install -b $PROJECT_BRANCH\n"
    fi
    exit 0
else
    echo -e "${COLOR_BLUE}The ${PROJECT_BRANCH} is currently checked out.${COLOR_LIGHT_GRAY}\n"
fi

# Check if a newer release is available.
echo -e "${COLOR_LIGHT_BLUE}Check if a newer release is available.\n"
# Make sure we were able to retrieve the latest version from the Internet.
if [ "$RECIEVER_CURRENT_VERSION" != 'NA' ] ; then
    # Compare the current version with this version.
    if [ `printf '%s\n' "${PROJECT_CURRENT_VERSION}" | sort -V | head -n 1` != "${PROJECT_THIS_VERSION}" ] ; then
        # If a newer release is available ask if it should be downloaded.
        echo -e "${COLOR_YELLOW}NOTICE: A newer release is available.\n"
        while true
        do
            read -r -p "\n${COLOR_LIGHT_BLUE}Would you like to download the latest release? [y/n] ${COLOR_LIGHT_GRAY}" INPUT
            case "$INPUT" in

                # Update the local repository.
                [yY][eE][sS]|[yY])
                    echo -e "${COLOR_BLUE}Updating the repository to match the latest release.${COLOR_LIGHT_GRAY}\n"
                    if [ `git status | grep -c "untracked files present"` -gt 0 ] ; then
                        echo -e "${COLOR_YELLOW}NOTICE: Files not mathcing the original files have been detected."
                        echo -e "${COLOR_BLUE}Branching the repositories current state before fetching the repository...${COLOR_LIGHT_GRAY}"
                        git commit -a -m "Repositories state before updating to ."
                        git branch "backup-${CURRENT_BRANCH}-`date '+%Y-%m-%d %H:%M'`"
                    fi


                    git fetch --all
                    git reset --hard ${PROJECT_BRANCH}


                    echo -e "\n${COLOR_YELLOW}NOTICE: The branch named \"${PROJECT_BRANCH}\" has been checked out."
                    echo '        Setup will now exit to ensure you are running the latest version of this script.\n'
                    echo -e "        Please restart setup using the following command.${COLOR_LIGHT_GRAY}\n"
                    if [ -z $ORIGINAL_BRANCH ] && [ "$ORIGINAL_BRANCH" == "$PROJECT_BRANCH" ] ; then
                        echo './install\n'
                    else
                        echo "./install -b $PROJECT_BRANCH\n"
                    fi
                    ;;

                # Skip updating the local repository.
                [nN][oO]|[nN])
                    echo -e "${COLOR_YELLOW}WARNING: Continuing setup using older release...${COLOR_LIGHT_GRAY}"
                    ;;

                # The input supplied is invalid.
                *)
                    echo "${COLOR_YELLOW}WARNING: Invalid responce...${COLOR_LIGHT_GRAY}"
                    ;;

            esac
        done
    else
        echo -e "${COLOR_GREEN}You are using the most current version.${COLOR_LIGHT_GRAY}\n"
    fi
else
    # Unable to determine the latest release.
    echo -e "${COLOR_YELLOW}Unable to retrieve the latest release version.${COLOR_LIGHT_GRAY}\n"
fi

## EXECUTE THE MAIN SETUP SCRIPT

printf "${COLOR_PURPLE}Starting the setup process.${COLOR_LIGHT_GRAY}"
sleep 1

chmod +x ${PROJECT_BASH_DIRECTORY}/main.sh 2>&1 >/dev/null
${PROJECT_BASH_DIRECTORY}/main.sh

echo -e "${COLOR_PURPLE}Setup process complete.\n"

## CLEAN UP

echo -e "${COLOR_LIGHT_BLUE}Perform post setup clean up operations.\n"

# Clean up the log file generated by the setup process.
CleanLogFile $LOG_FILE
echo -e "${COLOR_BLUE}Log file was saved to ${LOG_FILE}."

# Set the exit messages before unsetting the color variables.
SETUP_COMPLETE_ERROR="\n${COLOR_RED}Setup halted due to errors.${COLOR_LIGHT_GRAY}\n"
SETUP_COMPLETE_SUCCESS="\n${COLOR_GREEN}Setup completed successfully.${COLOR_LIGHT_GRAY}\n"

# Unset any variables exported by this script.
echo -e "${COLOR_BLUE}Unsetting any exported variables pertaining to the setup process...${COLOR_LIGHT_GRAY}"

unset DEVICE_CPU_ARCHITECTURE
unset DEVICE_OS_DISTRIBUTION
unset DEVICE_OS_RELEASE

unset PROJECT_THIS_VERSION
unset PROJECT_CURRENT_VERSION
unset PROJECT_BRANCH
unset PROJECT_ROOT_DIRECTORY
unset PROJECT_BASH_DIRECTORY
unset PROJECT_BUILD_DIRECTORY
unset PROJECT_TITLE
unset PROJECT_LOG_FILE

unset DUMP1090_FORK
unset DUMP1090_INSTALLED
unset DUMP1090_UPGRADEABLE
unset DUMP1090_UPGRADE
unset DUMP1090_DEVICE_ID

unset DUMP978_INSTALLED
unset DUMP978_UPGRADEABLE
unset DUMP978_DEVICE_ID

unset PIAWARE_INSTALLED
unset PIAWARE_UPGRADEABLE

unset COLOR_BLUE
unset COLOR_GREEN
unset COLOR_LIGHT_BLUE
unset COLOR_LIGHT_GRAY
unset COLOR_LIGHT_GREEN
unset COLOR_PURPLE
unset COLOR_RED
unset COLOR_YELLOW

unset NCURSES_NO_UTF8_ACS

## EXIT

# Check if any errors were encountered by any of the child scripts.
if [ $? -ne 0 ] ; then
    echo -e "$SETUP_COMPLETE_ERROR"
    exit 1
else
    echo -e "$SETUP_COMPLETE_SUCCESS"
    exit 0
fi
