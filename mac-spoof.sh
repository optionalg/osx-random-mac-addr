#!/usr/bin/env bash -e
#!/bin/bash -e
## ugh, if using /bin/sh, you won't need "-e" on all the print

header=`cat <<zHEAD
Random MAC Address script for OSX \n
by @px \n
zHEAD`

## just some defaults
sleepDelay=1
## 6 too small, 13 is enough with zzz's
maxChecks=$((13+9))
VERIFIED=0
bogusMAC="fe:df:ed:fe:df:ed"
newMAC=${bogusMAC}
airportPREFIX="00:1F:F3"  #"00:1f:5b"

## should check for color safe term
## but for now empty works
if [[ ${TERM} =~ "color" ]]; then

  ## Fun Colors
  black='\E[30;47m'
  red=$(tput -T ${TERM} setaf 124)
  green=$(tput -T ${TERM} setaf 64)
  yellow=$(tput -T ${TERM} setaf 3)
  blue=$(tput -T ${TERM} setaf 33)
  magenta=$(tput -T ${TERM} setaf 5)
  cyan=$(tput -T ${TERM} setaf 37)
  white=$(tput -T ${TERM} setaf 254)
  ## Reset the color to the default
  RESET=$(tput -T ${TERM} sgr0)
fi

if [ -n ${TERM} ]; then
  ## normalize print with print based on the shell/BASH
  if [ ${BASH} = "/bin/bash" -o ${BASH} = "/usr/local/bin/bash" ]; then
    function print ()
    {
      echo -e $@
    }
  else
    function print ()
    {
      echo $@
    }
  fi

else
  function print ()
  {
    echo >/dev/null 2>/dev/null
  }
fi

help=`cat <<zHELP
${cyan}HELP${RESET}\n
Defaults: ${red}en1${RESET}\n
--------------------------\n
$ mac-spoof.sh -yes [en<01>]\n
zHELP`

## print the file header
print "${header}"

## Be sure the user wants to run this.
if [[ "${1}" != "-yes" ]]; then
  print "${help}"
  print "${red}Must include -yes${RESET}"
  exit 127
fi

#print $(id -u)
## WE NEED ROOT!
if [ "$(id -u)" != "0" ]; then
  print "${bold}${white}This script must be run as ${red}root${RESET}" 1>&2
  exit 255
fi


### Function Definitions

## add artifical sleep delay
function zzz ()
{
  delay=${1}
  delay=${delay:=${sleepDelay}}
  sleep $((${delay}))
}

## generate a mac address using openssl, and our airportPREFIX
function macgenerate ()
{
  macsegments=3
  ## Check for openssl
  if [ -x "`which openssl`" ];then
    print "Generating new ${blue}MAC${RESET} address via ${magenta}openssl${RESET}"
    ## node the colon: in the middle
    newMAC="${airportPREFIX}:"`openssl rand -hex ${macsegments} -rand /dev/urandom:/dev/random 2>/dev/null | sed 's/\(..\)/\1:/g; s/.$//' `

  elif [ ! -x "`which openssl`" ];then
    print "${red}Bogus MAC used"
    newMAC=${bogusMAC}
  elif [ -z "${newMAC}" ]; then
    print "${green}${newMAC}\t\t${cyan}New MAC${RESET}"
  fi
}


## setmac 
function macset ()
{
  int=${1}      ## Interface
  newMAC=${2}   ## new MAC Addr

  ## check for ifconfig being executable and in the path
  if [ -x `which ifconfig ` ]; then
    print "${cyan}Configuring ${yellow}${int} MAC\t\t${blue}${newMAC}${reset}"
    ## The interface has to be up otherwise we cannot configure the newMAC
    ifconfig ${int} up && \
      print "${blue}Interface up"
    ## and 
    ## Set the newMAC
    ifconfig ${int} ether ${newMAC}
    #zzz 
    return 0 
  else
    ## return 1 for problem
    return 127
  fi
}


function macget ()
{
  int=${1}
  int=${int:=${defaultINT}}
  print `ifconfig ${int} | \
    # grep for the ether line
  grep ether | \
    # cut the 2nd field, using ' ' as delimiter
  cut -f2 -d\ `
}

## verify mac
function macverify ()
{

  int=${1}
  newMAC=$(print ${2} | tr '[A-Z]' '[a-z]')   ## New MAC addr
  oldMAC=$(print ${3} | tr '[A-Z]' '[a-z]')   ## Old MAC addr

  ## Verify New MAC Addr
  VERIFY=$(macget ${int})

  ## the ,, is a bash 4.0 method for lower case output of a variable
  ## check if the new MAC matches current MAC, and current isn't oldMAC
  if [ "${VERIFY}" = "${newMAC}" -a ${VERIFY} != "${oldMAC}" ]; then
    #if [ "${VERIFY,,}" = "${newMAC,,}" -a ${VERIFY} != ${oldMAC} ]; then
    print "${green}New MAC Verified!\t\t${blue}${VERIFY}${RESET}"
    VERIFIED=1
    #return 0
  else
    print "${red}FAILED! ${int} ${VERIFY}${RESET}"
    #print "te${newMAC}st"
    #print "te${VERIFY}st"

    #return 127
  fi
}

wirelessState ()
{
  airportState=$(airport -I | grep "state:" | cut -f2 -d':' )
  #print "airportState \"${airportState}\""
}

function wirelessEnable ()
{
  wirelessState
  if [[ $(networksetup -getairportpower airport) =~ " Off" ]]; then
    print "${blue}Power On Wireless${RESET}"
    networksetup -setairportpower airport on
    #zzz 1
  else
    true
    #print "${blue}Wireless Already On${RESET}"
  fi
  wirelessState
  #zzz 
}

function wirelessDisable ()
{
  #wirelessState
  if [[ $(networksetup -getairportpower airport) =~ " On" ]]; then
    print "${red}Power Off Wireless${RESET}"
    networksetup -setairportpower airport off
    #zzz 1
  else
    true
    #print "${red}Wireless Already Off${RESET}"
  fi
  #zzz 
}

function wirelessDiss ()
{
  wirelessState
  if [[ ${airportState} =~ "running" ]]; then
    ## Dissassociate Wireless
    print "${red}Dissassociate Wireless${RESET}"
    airport -z 
    #zzz
  else
    if [[ $(networksetup -getairportnetwork airport) =~ "not associated" ]]; then
      true
      print "${red}Already Dissassociated${RESET}"
    else
      print "${red}Still Associated or something...${RESET}"
    fi
  fi
  #zzz
  wirelessState
}

function wirelessReset ()
{
  int=${1}

  ## check if we're working with the wifi device...
  if [ ${int} = ${defaultINT} ]; then

    ## see if airport is symlinked;
    ## the airport could be functionalized, but
    ## it's also nice to have airport available in the shell
    ## but it's a waste to do these if checks each time.
    if [ ! -L "`which airport`" ]; then
      ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/sbin/airport
      ## Check for airport being executable and in the path
    elif [ -x `which airport ` ]; then

      #if [ ${airportState} = " running" ];then
      #wirelessDiss
      #fi

      #while [ ${airportState} == " running" ]; do
      ## cycle be sure the network is enabled/ on
      #wirelessDisable ${int}
      wirelessEnable ${int}
      wirelessDiss ${int}
      #done
    fi
  fi
}


### BEGIN "MAIN"

## Set the interface to the first script argument
INT=${2}

## Default the en1, the default Wireless interface on OSX 10.6.x
## Wi-Fi on 10.7 and greater
defaultINT="en1"
INT=${INT:="${defaultINT}"}

print "${blue}Interface chosen:\t\t${yellow}${INT}${RESET}"
oldMAC=$(macget ${INT})

print "Current MAC is\t\t\t${blue}${oldMAC}${RESET}"
checks=1
until  [ ${VERIFIED} -eq 1 ]; do # ||  ${checks} -ge ${maxChecks} ]; do
  print "Check #${checks} verified? ${VERIFIED}"

  if [[ ${checks} -le 1 ]]; then
    macgenerate 
  fi
  ## check if airport is Off
  wirelessReset ${INT}
  zzz
  macset ${INT} ${newMAC}
  #zzz
  macverify ${INT} ${newMAC} ${oldMAC}

  if [[ ${VERIFIED} -eq 1 ]]; then
    ## everything is OK
    exit 0
  elif [[ ${checks} -ge ${maxChecks} ]]; then
    print "${red}Maximum Checks Reached ${checks}${RESET}"
    exit 255
  fi
  checks=$(( ${checks} + 1 ))
done

if [ ${VERIFIED} -eq 1 ]; then
  ## exit success
  exit 0
else
  ## exit with 1
  exit 1

fi
exit 1

