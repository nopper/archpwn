# Distributed under the terms of the GNU General Public License

#                                                            #
# /sbin/splash-functions-arch.sh                             #
#                                                            #
# ArchLinux specific splash functions for fbsplash           #
#                                                            #
# Author: Kurt J. Bosch <kjb-temp-2009 at alpenjodel dot de> #
# Based on the work of:                                      #
#         Greg Helton <gt at fallendusk dot org>             #
#         Michal Januszewski <spock at gentoo dot org>       #
# and others.                                                #
#                                                            #

####
####  Extra ArchLinux specific event functions beside splash()
####

# args: sysinit|boot|shutdown
#
# Initialize ArchLinux specific variables and the tmpfs to be ready to run
# splash rc_init and any theme hooks
#
# ### WORKAROUND ### fbcondecor restart: errors about missing silent icons
#                  # with theme using symlinks created by hook script
#                ### All this is done even when verbose mode is required.
#                
splash_pre_init() {
	export SPLASH_MESSAGE
	export SPLASH_MSGLOG_BUSY
	export SPLASH_MSGLOG_DONE
	export SPLASH_MSGLOG_FAIL
	export SPLASH_VERBOSE_ON_ERRORS
	export splash_step=0
	export splash_steps=1
	export splash_runlevel_msg="${SPLASH_BOOT_MESSAGE}"
	case ${1}
	in boot )
		read -r splash_step  < "${spl_cachedir}"/var_steps_sysinit
		read -r splash_steps < "${spl_cachedir}"/var_steps
		return
	;; sysinit )
		# don't prepare the cache on shutdown - we keep it at boot
		splash_cache_prep_real
	esac
	rm -f "${spl_cachedir}"/step\ *
	rm -f "${spl_cachedir}"/done_*
	rm -f "${spl_cachedir}"/fail_*
	: > "${spl_cachedir}/stat_log"
	splash_steps=0
	if [ "${1}" = shutdown ]; then
		# list daemons and count steps
		splash_steps=$( splash_svclist_init stop )
		if [ "${RUNLEVEL}" = 6 ]
		then	splash_runlevel_msg="${SPLASH_REBOOT_MESSAGE}"
		else	splash_runlevel_msg="${SPLASH_SHUTDOWN_MESSAGE}"
		fi
	fi
	# find stat_busy message texts in rc.${1}
	# strip any ':' and variable parts behind
	# replace all '/' by '_'
	local stat_re='^([^#]*[[:space:]]+)?(stat_busy|status)[[:space:]]+"([^":]+)(:[^"]*)?"([[:space:]].*|$)'
	local msgs_file="${spl_cachedir}/busy_msgs_${1}"
	grep -E "${stat_re}" "/etc/rc.${1}" | \
	sed -r -e "s,${stat_re},\3," -e "s,/,_,g" > "${msgs_file}"
	# count steps and write step numbers to files for lookup
	exec 3<"${msgs_file}"
	local msg
	while read -r -u 3 msg ; do
		(( splash_steps++ ))
		echo ${splash_steps} >"${spl_cachedir}/rc_step ${msg}"
	done
	exec 3<&-
	if [ "${1}" = sysinit ]; then
		# save count for rc.multi (calling this with 'boot')
		echo ${splash_steps} > "${spl_cachedir}/var_steps_sysinit"
		# list daemons and count steps
		local count
		splash_fbsplash_missing=0
		count=$( splash_svclist_init start ) || splash_fbsplash_missing=1
		splash_steps=$(( splash_steps + count ))
		echo ${splash_steps} > "${spl_cachedir}/var_steps"
	fi
}

splash_stat_busy() {
	if [[ ${RUNLEVEL} == [S06] ]]; then
		# lookup step number
		local msg=${splash_busy_msg%%:*} # strip variable part
		local file="${spl_cachedir}/rc_step ${msg/\//_}"
		if [ -e "${file}" ]; then
			local step
			read -r step < "${file}"
			[ "${step}" -gt "${splash_step}" ] && splash_step=${step}
		fi
	fi
	(
		splash_set_eval_vars
		splash_eval_log "${SPLASH_MSGLOG_BUSY}"
		[ -n "${SPLASH_MESSAGE}" ] && splash_comm_send \
			"set message $( splash_get_boot_message )"
	)
	# doing the repaint neccessary for the messages
	# only on stat_busy and on exit_silent to be faster
	splash_comm_send repaint
}

# args: start|stop
splash_stat_fail() {
	if [[ ${RUNLEVEL} == [S06] ]]; then
		splash_update_progress
	else # [2-5]
		# Notify the daemon about service action failure
		# This also updates progress and runs any theme hooks.
		# Do this here in case the daemon script is started by another
		# daemon script directly (not using start_daemon).
		splash svc_${1}_failed "${splash_script}"
	fi
	[ "${SPLASH_VERBOSE_ON_ERRORS}" = yes ] && splash critical
	# notification about overall failure
	splash_svc_update fbsplash-dummy svc_${1}_failed
	# update splash log
	( splash_set_eval_vars; splash_eval_log "${SPLASH_MSGLOG_FAIL}" )
	# save status
	splash_have_cache || return 0
	touch "${spl_cachedir}/fail_${splash_script}"
	touch "${spl_cachedir}/fail_fbsplash-dummy"
}

splash_stat_done() {
	[[ ${RUNLEVEL} == [S06] ]] && splash_update_progress
	( splash_set_eval_vars; splash_eval_log "${SPLASH_MSGLOG_DONE}" )
}

# args:  start|stop <daemon>
#
# Increment step count and notify the daemon
# We count daemons instead of stat_busys because there can be many of them
# contained in one single daemon script. (nfs-server)
#
# For backgrounded daemons this should be called from within a subshell,
# since we don't count them.
#
splash_pre_daemon() {
	# don't count any second tries from rc.shutdown
	if [ ${1} = start ]; then
		(( splash_step++ ))
	elif ! [ -e "${spl_cachedir}/done_${2}" -o \
	         -e "${spl_cachedir}/fail_${2}" ]; then
		(( splash_step++ ))
	fi
	splash svc_${1} "${2}"
}

# args: start|stop <daemon>
#
# Notify the daemon about service action success
# This also updates progress and runs any theme hooks.
#
splash_post_daemon() {
	[ -e "${spl_cachedir}/fail_${2}" ] && return
	if [ ${1} = start ]; then
		splash svc_started "${2}"
	else
		splash svc_stopped "${2}"
	fi
	# save status
	splash_have_cache && touch "${spl_cachedir}/done_${2}"
}

splash_restart() {
	# don't restart if we're already kicked to the verbose console
	[ "${SPLASH_MODE_REQ}" = silent -a \
	  "$( fgconsole )" = "${SPLASH_TTY}" ] || return 0
	splash_have_daemon && return
	splash rc_init shutdown
}

####
####  Hook-functions overriding those from splash-functions.sh
####

# args: <internal_runlevel> <runlevel>
#
# This function is called when an 'rc_init' event takes place,
# i.e. when the runlevel is changed.
#
splash_init() {
	[ "${SPLASH_MODE_REQ}" = silent ] || return 0
	local was_silent=1
	[ "$( ${spl_bindir}/fgconsole )" = "${SPLASH_TTY}" ] || was_silent=0
	case "${1}"
	in sysinit )
		splash_real_stat_busy "Starting Fbsplash Daemon"
		if [ ${splash_fbsplash_missing} = 1 ]; then
			stat_append " - 'fbsplash' not in DAEMONS or backgrounded !"
			splash_real_stat_fail
			return 1
		fi
	;; shutdown )
		: # may already have pending stat_busy on console (restart)
	;; * )
		return 0
	esac
	## start the daemon
	(
		splash_set_eval_vars
		# initial progress in case of restart
		splash_set_progress
		export PROGRESS
		splash_start
	)
	if [ "${1}" = sysinit ]; then
		if ! splash_have_daemon; then
			splash_real_stat_fail
			return 1
		fi
		splash_real_stat_done
	else
		if ! splash_have_daemon; then
			return 1
		fi
		### WORKAROUND ### icons not painted
		[ ${was_silent} = 0 ] && [[ "${SPLASH_EFFECTS}" == *fadein* ]] && sleep 3
	fi
	## replay any early stuff we missed on sysinit or in case of restart on shutdown
	local action done
	if [ "${1}" = sysinit ]; then
		action=start
		done=started
	else
		action=stop
		done=stopped
	fi
	# notification about overall job started
	splash svc_${action} fbsplash-dummy
	# replay daemons done
	for file in "${spl_cachedir}"/done_* ; do
		splash svc_${done} ${file##*/done_}
	done
	# replay daemons failed
	for file in "${spl_cachedir}"/fail_* ; do
		splash svc_${action}_failed ${file##*/fail_}
	done
	# replay log messages
	while read -r line ; do
		splash_comm_send "log ${line}"
	done < "${spl_cachedir}"/stat_log
	splash_comm_send repaint
}

# args: <svc>
#
# This function is called whenever the progress variable should be
# updated.  It should recalculate the progress and send it to the
# splash daemon.
splash_update_progress() {
	# ignore if bkgd daemon - might go backward
	[ "${splash_step}" = "-1" ] && return
	local PROGRESS
	splash_set_progress
	splash_comm_send "progress ${PROGRESS}"
	splash_comm_send paint
}

# args: <runlevel>|kill
#
# This function is called when an 'rc_exit' event takes place.
splash_exit() {
	if [[ "${1}" == [06] ]]; then
		# overall success notification
		[ -e "${spl_cachedir}/fail_fbsplash-dummy" ] ||
			splash_svc_update fbsplash-dummy svc_stopped
		# final message
		splash_comm_send "set message $(
			splash_echo "${splash_runlevel_msg}"
		)"
		splash_comm_send repaint
	elif [ "${1}" != kill ]; then
		# force progress to 100%
		splash_step=${splash_steps}
		splash_update_progress
		# overall success notification
		[ -e "${spl_cachedir}/fail_fbsplash-dummy" ] ||
			splash_svc_update fbsplash-dummy svc_started
		# booted message
		splash_comm_send "set message $( 
			splash_set_eval_vars
			BUSY_MSG=""
			RUNLEVEL_MSG="${splash_runlevel_msg}"
			SCRIPT=""
			eval msg=\"${SPLASH_MESSAGE_BOOTED}\"
			splash_echo "${msg}"
		)"
		splash_comm_send repaint
	fi
	if splash_have_daemon; then
		splash_real_stat_busy "Stopping Fbsplash Daemon"
		if [ "${1}" != kill ]; then
			# send exit command
			if [[ "${1}" == [06] || "${SPLASH_STAY_SILENT}" = yes ]]
			then	splash_comm_send "exit staysilent"
			else	splash_comm_send "exit"
			fi
			# give the daemon some time for painting
			local -i i timeout=2
			[[ "${SPLASH_EFFECTS}" == *fadeout* ]] && timeout+=5
			for (( i=0; i<timeout*10; i++ )) ; do
				splash_have_daemon || break
				sleep 0.1
			done
		fi
		# be sure to get rid of the daemon
		killall -q -w -9 "${spl_daemon##*/}"
		if splash_have_daemon
		then	splash_real_stat_fail
		else	splash_real_stat_done
		fi
	fi
	# Don't do splash_cache_cleanup on boot
	# because fbcondecor restart would show errors about missing silent icons
	# with themes using symlinks created by hook script.
	# Don't do splash_cache_cleanup on shutdown
	# because we have no rw FS to copy stuff to.
}

####
####  Additional functions overriding or replacing those from splash-functions.sh
####

# avoid multiple mounts
splash_cache_prep() {
	: # do nothing when called from elsewhere
}

# print nice stat messages to the console
splash_cache_prep_real() {
	splash_real_stat_busy "Mounting Fbsplash Cache Filesystem"
	# Mount an in-RAM filesystem at spl_cachedir
	mount -ns -t "${spl_cachetype}" cachedir "${spl_cachedir}" \
		-o rw,mode=0644,size="${spl_cachesize}"k
	local retval=$?
	if [ ${retval} -ne 0 ]; then
		splash_real_stat_fail
		splash_verbose
		return "${retval}"
	fi
	splash_real_stat_done
}

if [ -n "${SPLASH_MESSAGE}" ]; then

	# This is called when the splash daemon is started and when the
	# message needs to be updated.
	#
	# provide messages in a more informative way
	splash_get_boot_message() {
		local msg
		eval msg=\"${SPLASH_MESSAGE}\"
		splash_echo "${msg}"
	}
fi

# args: <svc> <action>
#
# This is called on svc_started or svc_stopped events.
#
# don't write uggly generic log messages
splash_svc() {
	if [ "${2}" = start ]; then
		splash_svc_update "${1}" svc_started
		if [ "${1}" = "gpm" ]; then
			splash_comm_send "set gpm"
			splash_comm_send repaint
		fi
	else
		splash_svc_update "${1}" svc_stopped
	fi
	splash_update_progress "${1}"
}

# args: <svc> <action>
#
# This is called on svc_start_failed or svc_stopp_failed events.
#
# don't write uggly generic log messages
splash_svc_fail() {
	if [ "${SPLASH_VERBOSE_ON_ERRORS}" = yes ]; then
		splash_verbose
		return 1
	fi
	splash_svc_update "${1}" svc_${2}_failed
	splash_update_progress "${1}"
}

# Sends data to the splash FIFO after making sure there's someone
# alive on the other end to receive it.
#
# don't try to use /usr/bin/basename
splash_comm_send() {
	if [ -z "`pidof ${spl_daemon##*/}`" ]; then
		return 1
	else
		splash_profile "comm $*"
		echo "$*" > "${spl_fifo}" &
	fi
}

# Returns the current splash mode.
# Needed for the svc_input stuff. The upstream version seems to be broken.
splash_get_mode() {
	local ctty="$( fgconsole )"
	if [ "${ctty}" = "${SPLASH_TTY}" ]; then
		echo "silent"
	else
		if [ -z "$(${spl_decor} -c getstate --tty=${ctty} 2>/dev/null | grep off)" ]; then
			echo "verbose"
		else
			echo "off"
		fi
	fi
}

####
####  Misc. functions - also useful for theme hook scripts
####

# args: <type>
#
# Counterpart to splash_svclist_get found in splash-functions.sh
# 
# This is also usefull for the rc_init-pre theme hook to get an updated
# daemons list whenever the splash daemon is restarted.
#
# type  - meaning
# -----------------
# start - bootup
# stop  - shutdown
#
# create the services/daemons list
# echo the daemons count
# at bootup: return 1 if fbsplash is missing in DAEMONS
splash_svclist_init() {
	splash_have_cache || return 2
	local retval=0
	local count=0
	local daemon
	if [ ${1} = start ]; then
		retval=1
		for daemon in "${DAEMONS[@]}"; do
			[ "$daemon" = "${daemon#!}" -a \
			  "$daemon" = "${daemon#@}" ] || continue
			(( count++ ))
			echo $daemon
			if [ "$daemon" = fbsplash ]; then
				retval=0
				break
			fi
		done
	else
		for daemon in $(/bin/ls -1t /var/run/daemons); do
			(( count++ ))
			echo $daemon
		done
	fi > "${spl_cachedir}"/svcs_${1}
	echo ${count}
	return ${retval}
}

splash_have_daemon() {
	[ -n "$( pidof "${spl_daemon##*/}" )" ]
}

splash_have_cache() {
	# don't try to use /proc here !
	# don't try to use tools from /usr here !
	[ -w "${spl_cachedir}" ]
}

export -f splash_svclist_init
export -f splash_have_daemon
export -f splash_have_cache

####
####  Internal functions
####

# set variables needed for eval SPLASH_MESSAGE and SPLASH_MSGLOG_*
splash_set_eval_vars() {
	BUSY_MSG="${splash_busy_msg}"
	SCRIPT="${splash_script}"
	STEP="${splash_step}"
	STEPS="${splash_steps}"
	PROGRESS=\$progress # the splash daemon knows this
	RUNLEVEL_MSG="${splash_runlevel_msg}"
}

# calculate and set PROGRESS
splash_set_progress() {
	PROGRESS=65535 # 100%
	[ "${splash_step}" -lt "${splash_steps}" ] && \
		PROGRESS=$(( PROGRESS * ${splash_step} / ${splash_steps} ))
}

# arg: <splash_msglog>
#
# add a line to the message log
splash_eval_log() {
	[ -z "${1}" ] && return
	local msg
	eval msg=\"${1}\"
	splash_comm_send "log ${msg}"
	# save log lines for defered start or restart
	splash_have_cache && echo "${msg}" >> "${spl_cachedir}/stat_log"
}

####
####  Workaround functions
####

# args: <msg>
#
# ### WORKAROUND ### # blank message string killing the splash daemon
#
splash_echo() {
	if [ -z "${1%% }" ]
	then	echo $'\302\240' # UTF-8 no-break space
	else	echo "${1}"
	fi
}

# EOF #
