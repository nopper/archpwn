# ArchLinux specific splash functions #
# Author: Greg Helton <gt@fallendusk.org> #

splash_init() {
	splash_setup	
	splash_start
}

splash_exit() {
	splash_comm_send "exit"
	splash_cache_cleanup
}

splash_update_progress() {
	local PROGRESS
	PROGRESS=$(($1*65535/100))
	splash_comm_send "progress ${PROGRESS}"
	splash_comm_send "repaint"
}

var_save() {
for i in $@ ;
	do
		local var
		eval var=\$SPLASH_${i}
		echo "SPLASH_$i=$(echo ${var})" > ${spl_cachedir}/${i}
	done
}

var_load() {
for i in $@ ;
	do
		local var
		eval var=\$SPLASH_${i}
		if [[ -z "$(echo ${var})" && -f ${spl_cachedir}/${i} ]] ; then
			source ${spl_cachedir}/${i}
		fi
	done
}

save_boot_steps() {
	var_load STEP_NR
	echo $SPLASH_STEP_NR > /etc/conf.d/fbsplash.bootsteps
}

load_boot_steps() {
	BOOT_STEPS=$(cat /etc/conf.d/fbsplash.bootsteps)
	# Fail safe, so we don't divide by 0
	if [ $BOOT_STEPS = 0 ]; then
		BOOT_STEPS=1
	fi
	printf $BOOT_STEPS
}

save_shutdown_steps() {
	var_load SHUTDOWN_STEPS
	((SPLASH_SHUTDOWN_STEPS++))
	echo $SPLASH_SHUTDOWN_STEPS > /etc/conf.d/fbsplash.shutdownsteps
	var_save SHUTDOWN_STEPS
}

load_shutdown_steps() {
	SHUTDOWN_STEPS=$(cat /etc/conf.d/fbsplash.shutdownsteps)
	# Fail safe, so we don't divide by 0
	if [ $SHUTDOWN_STEPS = 0 ]; then
		SHUTDOWN_STEPS=1
	fi
	printf $SHUTDOWN_STEPS
}

# EOF #
