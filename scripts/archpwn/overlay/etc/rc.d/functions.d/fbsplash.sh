# Distributed under the terms of the GNU General Public License

#                                                            #
# /etc/rc.d/functions.d/fbsplash.sh                          #
#                                                            #
# ArchLinux initscript hooks for fbsplash                    #
#                                                            #
# Author: Kurt J. Bosch <kjb-temp-2009 at alpenjodel dot de> #
# Based on the work of:                                      #
#         Greg Helton <gt at fallendusk dot org>             #
#         Thomas Baechler <thomas at archlinux dot org>      #
#         Aaron Griffin <aaron at archlinux dot org>         #
# and others.                                                #
#                                                            #

. /etc/conf.d/fbsplash
. /sbin/splash-functions.sh

####
####  Functions cloned from initscripts
####

splash_real_stat_bkgd() {
	printf "${C_OTHER}${PREFIX_REG} ${C_MAIN}${1}${C_CLEAR} "
	deltext
	printf "    ${C_BKGD}bkgd${C_OTHER}${C_CLEAR}  "
}

splash_real_stat_busy() {
	printf "${C_OTHER}${PREFIX_REG} ${C_MAIN}${1}${C_CLEAR} "
	printf "${SAVE_POSITION}"
 	deltext
	printf "     ${C_BUSY}..${C_OTHER}${C_CLEAR}   "
}

splash_real_stat_fail() {
	deltext
	printf "    ${C_FAIL}fail${C_OTHER}${C_CLEAR}  \n"
}

splash_real_stat_done() {
	deltext
    printf "    ${C_DONE}done${C_OTHER}${C_CLEAR}  \n"
}

case "${PREVLEVEL}_${RUNLEVEL}"
in [NS]_[S2-5] )
	splash_action=start
;; [2-5]_[06] )
	splash_action=stop
;; *)
	return
esac

####
####  Hook-functions overriding those from initscripts
####  (and some init commands)
####

stat_busy() {
	# start the daemon when devices are ready and fadein from initcpio finished
	if [ "${splash_sysinit_stage}" = 1 ] && [ -z "$( pidof fbcondecor_helper )" ]; then
		splash rc_init sysinit
		splash_sysinit_stage=2
	fi
	splash_real_stat_busy "${1}"
	splash_busy_msg="${1}"
	splash_stat_busy
	if [ "${1}" = "Sending SIGTERM To Processes" ]; then
		(	trap : SIGTERM
			while splash_have_daemon ; do sleep .25 ; done
			splash_restart
		) &
	fi
}

stat_fail() {
	splash_real_stat_fail
	splash_stat_fail  ${splash_action}
}

stat_done() {
	splash_real_stat_done
	splash_stat_done
	case "${splash_busy_msg}"
	in "Starting UDev Daemon" | "Using static /dev filesystem" )
		splash_setup force # get configuration from /proc/cmdline
		[ "${SPLASH_MODE_REQ}" = silent ] || return 0
		# prepare devices needed to start the splash daemon
		if /bin/pidof -o %PPID /sbin/udevd >/dev/null; then
			splash_real_stat_busy "Loading UDev uevents needed for Fbsplash"
			udevstart="$(/bin/date +%s%0N)"
			/sbin/udevadm trigger --subsystem-match=tty \
				--subsystem-match=graphics --subsystem-match=input
			/sbin/udevadm settle
			splash_real_stat_done
			udevend="$(/bin/date +%s%0N)"
			printhl "   UDev uevent processing time: $((($udevend-$udevstart)/1000000))ms"
		else
### TODO ### - Is there a way to get the keyboard event dev ?
			splash_real_stat_busy "Creating device nodes needed for Fbsplash"
			/bin/mknod -m 660 /dev/fb0 c 29 0
			/bin/chgrp video /dev/fb0
			/bin/mknod -m 620 /dev/tty0 c 4 0
			if [ "${SPLASH_TTY}" -gt 0 ]; then
				/bin/mknod -m 620 /dev/tty${SPLASH_TTY} c 4 ${SPLASH_TTY}
				/bin/chgrp tty /dev/tty${SPLASH_TTY}
			fi
			/bin/mknod -m 666 /dev/tty c 5 0
			/bin/chgrp tty /dev/tty
			splash_real_stat_done
		fi
		splash_sysinit_stage=1
### WORKAROUND ### # setfonts destroying the splash
		CONSOLEFONT=""
	;; "Sending SIGKILL To Processes" )
		splash_restart
	;; "Remounting Root Filesystem Read-only" )
		splash rc_exit
	esac
}

start_daemon() {
	splash_pre_daemon start $1
	local splash_input=0
	if [ "${1}" = "net-profiles" ]; then
		local net
		for net in "${NETWORKS[@]}"; do
			[ "${net}" = "menu" ] || continue
			splash_input=1
			break
		done
	fi
	[ ${splash_input} = 1 ] && splash svc_input_begin $1
	/etc/rc.d/$1 start
	[ ${splash_input} = 1 ] && splash svc_input_end $1
	splash_post_daemon start $1
	
	[ "${1}" = fbsplash ] || return 0
	# stop the daemon
	splash rc_exit
# ### WORKAROUND ### # setfonts destroying the splash
	# Defere setfont stuff to the point where the splash daemon finished.
	# This code was copied from /etc/rc.sysinit from initscripts.
	if [ -n "$CONSOLEFONT" ]; then
		stat_busy "Loading Console Font: $CONSOLEFONT"
		#CONSOLEMAP in UTF-8 shouldn't be used
		if [ -n "$CONSOLEMAP" ] && echo "$LOCALE" | /bin/grep -qi utf ; then
			CONSOLEMAP=""
		fi
		for i in /dev/tty[0-9]*; do
			if [ -n "$CONSOLEMAP" ]; then
				/usr/bin/setfont -m $CONSOLEMAP $CONSOLEFONT -C ${i} >/dev/null 2>&1
			else
				/usr/bin/setfont $CONSOLEFONT -C ${i} >/dev/null 2>&1
			fi
		done
		if [ $? -ne 0 ]; then
			stat_fail
		else
			for i in /dev/tty[0-9]*; do
				printf "\e(K" > ${i}
			done
			# the $CONSOLE check helps us avoid this when running scripts from cron
			echo 'if [ "$CONSOLE" = "" -a "$TERM" = "linux" -a -t 1 ]; then printf "\e(K"; fi' >>/etc/profile.d/locale.sh
			stat_done
		fi
	fi
}

start_daemon_bkgd() {
	splash_real_stat_bkgd "Starting $1"
	(
		splash_pre_daemon start $1
		/etc/rc.d/$1 start 
		# don't update progress - might go backward
		splash_step=-1
		splash_post_daemon start $1
	) &>/dev/null &
}

stop_daemon() {
	splash_pre_daemon stop $1
	/etc/rc.d/$1 stop
	splash_post_daemon stop $1
}

splash_script_path="${splash_script_path:-${0}}"
splash_script="${splash_script_path##*/}"

case "${splash_script_path}"
in /etc/rc.sysinit )
	splash_pre_init sysinit
;; /etc/rc.multi )
	splash_pre_init boot
	splash rc_init boot
;; /etc/rc.shutdown )
	splash_pre_init shutdown
	splash rc_init shutdown
esac

# EOF #
