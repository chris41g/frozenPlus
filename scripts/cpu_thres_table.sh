#!/system/bin/sh
#
# cpu_thres_table.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#define variables
BUSYBOX=$(which busybox)
THRES_TABLE_PATH="/sys/devices/system/cpu/cpu0/cpufreq/cpu_thres_table"
OVER_CLOCK="false"
ERROR_MSG=
INDEX=
NEW_VALUE=
NEW_VALUES=

#functions
SHOW_HELP()
{
	echo "Usage:"
	echo "       : No args will display current values."
	echo "Example: cpu_thres_table.sh"
	echo "*"
	echo "all    : Set all values."
	echo "Format : cpu_thres_table.sh all \"LO HI, LO HI, LO HI...\""
	if [ "$OVER_CLOCK" = "true" ]; then
		echo "Example: cpu_thres_table.sh all \"55 90, 55 90, 55 90,"\
" 55 90, 55 90, 60 80, 60 80, 60 80, 60 80, 60 80, 60 80\""
	else
		echo "Example: cpu_thres_table.sh all \"55 90, 60 80, 60 80,"\
" 60 80, 60 80, 60 80, 60 80\""
	fi
	echo "*"
	echo "index  : Set a value by index."
	echo "Format : cpu_thres_table.sh index N \"LO HI\""
	echo "Example: cpu_thres_table.sh index 3 \"50 90\""
	echo "*"
	echo "-h     : Print this help info."
	echo "--help : Print this help info."
	echo "*"
	exit 1
}
SHOW_COMPLETED()
{
	echo "Script completed."
	exit
}
SHOW_ERROR()
{
	if [ -n "$ERROR_MSG" ] ; then
		echo "$ERROR_MSG"
	fi
}
CHECK_FOR_OVERCLOCK()
{
	local OVERCLOCK_TEST=$("$BUSYBOX" zcat "/proc/config.gz" | "$BUSYBOX" less | grep "CONFIG_MACH_S5PC110_ARIES_OC")
	if [ "$OVERCLOCK_TEST" = "CONFIG_MACH_S5PC110_ARIES_OC=y" ]; then
		OVER_CLOCK="true"
	fi
}
SHOW_TABLE_INFO()
{
	local TABLE_INFO=$(cat $THRES_TABLE_PATH)
	IFS=, read -a THRES_TABLE_ARRAY <<< "$TABLE_INFO"
	echo " LO HI - Frequency | Index"
	echo "------------------"
	if [ "$OVER_CLOCK" = "true" ]; then
		echo " ${THRES_TABLE_ARRAY[0]} - 1400 MHz | 0"
		echo "${THRES_TABLE_ARRAY[1]} - 1300 MHz | 1"
		echo "${THRES_TABLE_ARRAY[2]} - 1200 MHz | 2"
		echo "${THRES_TABLE_ARRAY[3]} - 1120 MHz | 3"
		echo "${THRES_TABLE_ARRAY[4]} - 1000 MHz | 4"
		echo "${THRES_TABLE_ARRAY[5]} - 900 MHz | 5"
		echo "${THRES_TABLE_ARRAY[6]} - 800 MHz | 6"
		echo "${THRES_TABLE_ARRAY[7]} - 600 MHz | 7"
		echo "${THRES_TABLE_ARRAY[8]} - 400 MHz | 8"
		echo "${THRES_TABLE_ARRAY[9]} - 200 MHz | 9"
		echo "${THRES_TABLE_ARRAY[10]} - 100 MHz | 10"
	else
		echo " ${THRES_TABLE_ARRAY[0]} - 1000 MHz | 0"
		echo "${THRES_TABLE_ARRAY[1]} - 900 MHz | 1"
		echo "${THRES_TABLE_ARRAY[2]} - 800 MHz | 2"
		echo "${THRES_TABLE_ARRAY[3]} - 600 MHz | 3"
		echo "${THRES_TABLE_ARRAY[4]} - 400 MHz | 4"
		echo "${THRES_TABLE_ARRAY[5]} - 200 MHz | 5"
		echo "${THRES_TABLE_ARRAY[6]} - 100 MHz | 6"
	fi
	echo "------------------"
	echo "\"$TABLE_INFO\""
	exit
}
SET_TABLE_VALUES()
{
	echo "Remember to allow permission with Superuser."
	ERROR_MSG=$(su -c "echo \"$NEW_VALUES\" > \"$THRES_TABLE_PATH\"")
	if [ -n "$ERROR_MSG" ]; then
		SHOW_ERROR
		SHOW_COMPLETED
	fi
}
SET_TABLE_INDEX_VALUE()
{
	if [ -z "$INDEX" ]; then
		ERROR_MSG="INDEX was empty."
		SHOW_ERROR
		SHOW_COMPLETED
	fi
		if [ -z "$NEW_VALUE" ]; then
		ERROR_MSG="NEW_VALUE was empty."
		SHOW_ERROR
		SHOW_COMPLETED
	fi
	local TABLE_INFO=$(cat $THRES_TABLE_PATH)
	IFS=, read -a THRES_TABLE_ARRAY <<< "$TABLE_INFO"
	if [ "$OVER_CLOCK" = "true" ]; then
		if [ $INDEX -ge "0" ] && [ $INDEX -lt "11" ]; then
			THRES_TABLE_ARRAY["$INDEX"]=$NEW_VALUE
			NEW_VALUES="${THRES_TABLE_ARRAY[0]},${THRES_TABLE_ARRAY[1]},${THRES_TABLE_ARRAY[2]}"
			NEW_VALUES="$NEW_VALUES,${THRES_TABLE_ARRAY[3]},${THRES_TABLE_ARRAY[4]},${THRES_TABLE_ARRAY[5]}"
			NEW_VALUES="$NEW_VALUES,${THRES_TABLE_ARRAY[6]},${THRES_TABLE_ARRAY[7]},${THRES_TABLE_ARRAY[8]}"
			NEW_VALUES="$NEW_VALUES,${THRES_TABLE_ARRAY[9]},${THRES_TABLE_ARRAY[10]}"
			SET_TABLE_VALUES
		else
			ERROR_MSG="INDEX out of range."
			SHOW_ERROR
			SHOW_COMPLETED
		fi
	else
		if [ $INDEX -ge "0" ] && [ $INDEX -lt "7" ]; then
			THRES_TABLE_ARRAY["$INDEX"]=$NEW_VALUE
			NEW_VALUES="${THRES_TABLE_ARRAY[0]},${THRES_TABLE_ARRAY[1]},${THRES_TABLE_ARRAY[2]}"
			NEW_VALUES="$NEW_VALUES,${THRES_TABLE_ARRAY[3]},${THRES_TABLE_ARRAY[4]},${THRES_TABLE_ARRAY[5]}"
			NEW_VALUES="$NEW_VALUES,${THRES_TABLE_ARRAY[6]}"
			SET_TABLE_VALUES
		else
			ERROR_MSG="INDEX out of range."
			SHOW_ERROR
			SHOW_COMPLETED
		fi
	fi
}

#main
CHECK_FOR_OVERCLOCK
if [ -z "$1" ]; then
	SHOW_TABLE_INFO
else
	if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
		SHOW_HELP
	fi
	if [ "$1" = "index" ]; then
		INDEX="$2"
		NEW_VALUE="$3"
		SET_TABLE_INDEX_VALUE
	else
		if [ "$1" = "all" ]; then
			NEW_VALUES="$2"
			SET_TABLE_VALUES
		else
			SHOW_TABLE_INFO
		fi
	fi
	SHOW_COMPLETED
fi

