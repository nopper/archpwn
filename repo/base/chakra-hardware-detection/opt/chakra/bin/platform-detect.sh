#!/bin/sh -e

#. /etc/rc.d/functions

usage () {
    echo "Usage: $0 [-h|--help|-v|--verbose]"
    echo ""
    echo "  -h | --help      print this help"
    echo "  -v | --verbose   be verbose (messages go to STDOUT)"
    echo "  -V | --version   print version information"
    echo ""
    echo " Possible return values:"
    echo "  0  most likely running on a laptop"
    echo "  1  most likely NOT running on a laptop"
    echo "  2  called with unknown option, -h, --help, -V or --version"
}

# Check wether we were asked to be verbose

if [ "$1" != "" ]; then
    case "$1" in
        "-v"|"--verbose")
            PRINTIT="echo"
            ;;
        "-V"|"--version")
            echo "Version: @VERSION@"
            exit 2
            ;;
        "-h"|"--help")
            usage
            exit 2
            ;;
        *)
            echo "UNKNOWN OPTION: $1"
            usage
            exit 2
            ;;
    esac
fi

# Are we a mac?
if test -d /proc/pmu; then
        batteries=$(grep Battery /proc/pmu/info | cut -f2 -d:)
        if test "$batteries" -ne 0; then
            #printhl "This machine seems to be a laptop computer (Mac batteries found)"
            exit 0
        fi
        exit 1
fi

if [ -r /dev/mem -a -x /usr/sbin/dmidecode ]; then
        # dmidecode to grab the Chassis type
        dmitype=$(dmidecode --string chassis-type)

        if test "$dmitype" = "Notebook" || test "$dmitype" = "Portable"; then
            #printhl "This machine seems to be a laptop computer (dmidecode returned $dmitype)"
            exit 0
        fi

        # turn back on for debugging
        #echo "$dmitype"
fi

# check for any ACPI batteries
/sbin/modprobe battery 2> /dev/null || true
if [ -d /sys/class/power_supply ]; then
	if grep -q Battery /sys/class/power_supply/*/type 2>/dev/null; then
            #printhl "This machine seems to be a laptop computer (ACPI batteries found)"
            exit 0
	fi
fi
# old interface:
if [ -d /proc/acpi/battery ]; then
        results=`find /proc/acpi/battery -mindepth 1 -type d`
        if [ ! -z "$results" ]; then
            #printhl "This machine seems to be a laptop computer (ACPI batteries found)"
            exit 0
        fi
fi


# check for APM batteries. This sucks, because we'll only get a valid response
# if the laptop has a battery fitted at the time
if [ -f /proc/apm ]; then
    battery=`awk '{print $6}' </proc/apm`
    if [ "$battery" != "0xff" ] && [ "$battery" != "0x80" ]; then
       #printhl "This machine seems to be a laptop computer (APM batteries found)"
        exit 0
    fi
fi

#printhl "This machine seems to be a desktop computer"
exit 1
