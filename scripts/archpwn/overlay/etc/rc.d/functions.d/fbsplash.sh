# fbsplash function.d script #
# Author: Greg Helton <gt@fallendusk.org> #

# Who is calling? #
CALLER=$0

# splash stuff #
. /etc/conf.d/fbsplash.conf
. /sbin/splash-functions.sh

# Redefine the stat functions #
stat_bkgd() {
	printf "${C_OTHER}${PREFIX_REG} ${C_MAIN}${1}${C_CLEAR} "
	deltext
	printf "    ${C_BKGD}bkgd${C_OTHER}${C_CLEAR}  "
}

stat_busy() {
	printf "${C_OTHER}${PREFIX_REG} ${C_MAIN}${1}${C_CLEAR} "
	printf "${SAVE_POSITION}"
 	deltext
	printf "     ${C_BUSY}..${C_OTHER}${C_CLEAR}   "
	# This checks to see if we just brought up the lo interface in rc.sysinit #
	# if so, start the progress bar #
	if [ "${1}" == 'Bringing up loopback interface' ]; then
		splash rc_init
	fi
        # Load variables #
        var_load STEP_NR MAX_STEPS RC_MULTI RC_SYSINIT RC_SHUTDOWN
        # Only update the splash progress if we're in sysinit, multi, or shutdown. #
        if [[ ${SPLASH_RC_MULTI}  == 1 || ${SPLASH_RC_SYSINIT} == 1 || ${SPLASH_RC_SHUTDOWN} == 1 ]]; then
                ((SPLASH_STEP_NR++))
                SPLASH_PROGRESS=$((100*${SPLASH_STEP_NR}/${SPLASH_MAX_STEPS}))
                SPLASH_CURRENT_PROGRESS=${SPLASH_PROGRESS}
                splash_update_progress ${SPLASH_PROGRESS}
                var_save STEP_NR CURRENT_PROGRESS
        fi
	if [ ${SPLASH_RC_SHUTDOWN} == 1 ]; then
		save_shutdown_steps
	fi

}

stat_done() {
	deltext
    printf "    ${C_DONE}done${C_OTHER}${C_CLEAR}  \n"
}

stat_fail() {
	deltext
	printf "    ${C_FAIL}fail${C_OTHER}${C_CLEAR}  \n"
    if [[ ${SPLASH_RC_SYSINIT} == 1 || ${SPLASH_RC_SHUTDOWN} == 1 ]]; then
        splash_verbose
    fi
}

start_daemon() {
	/etc/rc.d/$1 start
}

# rc.sysinit #
if [ $CALLER == '/etc/rc.sysinit' ]; then
	splash_cache_prep
	SPLASH_MAX_STEPS=$(load_boot_steps)
	SPLASH_STEP_NR=0
	SPLASH_RC_MULTI=0
	SPLASH_RC_SYSINIT=1
	SPLASH_RC_SHUTDOWN=0
	var_save MAX_STEPS STEP_NR RC_MULTI RC_SYSINIT RC_SHUTDOWN
fi

# rc.multi #
if [ $CALLER == '/etc/rc.multi' ]; then
	SPLASH_RC_MULTI=1
	SPLASH_RC_SYSINIT=0
	var_save RC_MULTI RC_SYSINIT
fi

# rc.shutdown #
if [ $CALLER == '/etc/rc.shutdown' ]; then
	splash_cache_prep
	SPLASH_MAX_STEPS=$(load_shutdown_steps)
	SPLASH_SHUTDOWN_STEPS=1
	SPLASH_STEP_NR=0
	SPLASH_RC_MULTI=0
	SPLASH_RC_SYSINIT=0
	SPLASH_RC_SHUTDOWN=1
	var_save MAX_STEPS STEP_NR RC_MULTI RC_SYSINIT RC_SHUTDOWN DAEMON_STEPS
	splash rc_init
fi

