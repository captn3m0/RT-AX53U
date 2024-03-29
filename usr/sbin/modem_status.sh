#!/bin/sh
# $1: action.
# environment variable: unit - modem unit.
# echo "This is a script to get the modem status."


if [ -z "$unit" ] || [ "$unit" -eq "0" ]; then
	prefix="usb_modem_"
else
	prefix="usb_modem${unit}_"
fi

model=`nvram get productid`
act_node1="${prefix}act_int"
act_node2="${prefix}act_bulk"
modem_act_path=`nvram get ${prefix}act_path`
modem_model=`nvram get modem_model`
modem_type=`nvram get ${prefix}act_type`
modem_vid=`nvram get ${prefix}act_vid`
modem_pid=`nvram get ${prefix}act_pid`
modem_dev=`nvram get ${prefix}act_dev`
modem_pdp=`nvram get modem_pdp`
modem_reg_time=`nvram get modem_reg_time`
modem_mode=`nvram get modem_mode`
wandog_interval=`nvram get wandog_interval`
sim_order=`nvram get modem_sim_order`

usb_gobi2=`nvram get usb_gobi2`

usb_path1_manufacturer=`nvram get usb_path1_manufacturer`

stop_lock=`nvram get stop_atlock`
if [ -n "$stop_lock" ] && [ "$stop_lock" -eq "1" ]; then
	at_lock=""
else
	at_lock="flock -x /tmp/at_cmd_lock"
fi

modem_data_orig=`nvram get modem_data_orig`
if [ -z "$modem_data_orig" ]; then
	modem_data_orig=0
fi

jffs_dir="/jffs"

if [ "$wandog_interval" == "" -o "$wandog_interval" == "0" ]; then
	wandog_interval=5
fi


_find_usb3_path(){
	all_paths=`nvram get xhci_ports`

	count=1
	for path in $all_paths; do
		len=${#path}
		target=`echo $1 |head -c $len`
		if [ "$target" == "$path" ]; then
			echo "$count"
			return
		fi

		count=`expr $count + 1`
	done

	echo "-1"
}

_find_usb2_path(){
	all_paths=`nvram get ehci_ports`

	count=1
	for path in $all_paths; do
		len=${#path}
		target=`echo $1 |head -c $len`
		if [ "$target" == "$path" ]; then
			echo "$count"
			return
		fi

		count=`expr $count + 1`
	done

	echo "-1"
}

_find_usb1_path(){
	all_paths=`nvram get ohci_ports`

	count=1
	for path in $all_paths; do
		len=${#path}
		target=`echo $1 |head -c $len`
		if [ "$target" == "$path" ]; then
			echo "$count"
			return
		fi

		count=`expr $count + 1`
	done

	echo "-1"
}

_find_usb_path(){
	ret=`_find_usb3_path "$1"`
	if [ "$ret" == "-1" ]; then
		ret=`_find_usb2_path "$1"`
		if [ "$ret" == "-1" ]; then
			ret=`_find_usb1_path "$1"`
		fi
	fi

	echo "$ret"
}

# $1: ifname.
_get_qcqmi_by_usbnet(){
	rp1=`readlink -f /sys/class/net/$1/device 2>/dev/null`
	if [ -z "$rp1" ]; then
		echo ""
		return
	fi

	rp2=
	i=0
	while [ $i -lt 10 ]; do
		rp2=`readlink -f /sys/class/GobiQMI/qcqmi$i/device 2>/dev/null`
		if [ -z "$rp2" ]; then
			i=`expr $i + 1`
			continue
		fi

		if [ "$rp1" == "$rp2" ]; then
			echo "qcqmi$i"
			return
		fi

		i=`expr $i + 1`
	done

	echo ""
}

# $1: VID, $2: PID.
_get_gobi_device(){
	if [ -z "$1" ] || [ -z "$2" ]; then
		echo "0"
		return
	fi

	if [ "$1" == "1478" ] && [ "$2" == "36901" -o "$2" == "36902" -o "$2" == "36903" ]; then
		echo "1"
		return
	fi

	echo "0"
}


if [ "$modem_type" == "" -o  "$modem_type" == "ecm" -o "$modem_type" == "rndis" -o "$modem_type" == "asix" -o "$modem_type" == "ncm" ] && [ "$modem_model" == "2" -a "$modem_type" != "ncm" ]; then
	exit 0
fi

act_node=
#modem_type=`nvram get ${prefix}act_type`
#if [ "$modem_type" == "tty" -o "$modem_type" == "mbim" ]; then
#	if [ "$modem_type" == "tty" -a "$modem_vid" == "6610" ]; then # e.q. ZTE MF637U
#		act_node=$act_node1
#	else
#		act_node=$act_node2
#	fi
#else
	act_node=$act_node1
#fi

modem_act_node=`nvram get $act_node`
if [ -z "$modem_act_node" ]; then
	/usr/sbin/find_modem_node.sh

	modem_act_node=`nvram get $act_node`
	if [ -z "$modem_act_node" ]; then
		echo "Can't get $act_node!"
		exit 1
	fi
fi

is_gobi=`_get_gobi_device $modem_vid $modem_pid`

if [ "$1" == "bytes" -o "$1" == "bytes-" ]; then
	if [ -z "$modem_dev" ]; then
		echo "2:Can't get the active network device of USB."
		exit 2
	fi

	if [ -z "$sim_order" ]; then
		echo "12:Fail to get the SIM order."
		exit 12
	fi

	if [ ! -d "$jffs_dir/sim/$sim_order" ]; then
		mkdir -p "$jffs_dir/sim/$sim_order"
	fi

	if [ "$modem_data_orig" == "1" ]; then
		rx_new=`cat "/sys/class/net/$modem_dev/statistics/rx_bytes" 2>/dev/null`
		tx_new=`cat "/sys/class/net/$modem_dev/statistics/tx_bytes" 2>/dev/null`
		echo "  rx_new=$rx_new."
		echo "  tx_new=$tx_new."

		if [ "$1" == "bytes" ]; then
			rx_old=`nvram get modem_bytes_rx`
			if [ -z "$rx_old" ]; then
				rx_old=0
			fi
			tx_old=`nvram get modem_bytes_tx`
			if [ -z "$tx_old" ]; then
				tx_old=0
			fi
			echo "  rx_old=$rx_old."
			echo "  tx_old=$tx_old."

			rx_reset=`nvram get modem_bytes_rx_reset`
			if [ -z "$rx_reset" ]; then
				rx_reset=0
			fi
			tx_reset=`nvram get modem_bytes_tx_reset`
			if [ -z "$tx_reset" ]; then
				tx_reset=0
			fi
			echo "rx_reset=$rx_reset."
			echo "tx_reset=$tx_reset."

			rx_now=`lplus $rx_old $rx_new`
			tx_now=`lplus $tx_old $tx_new`
			rx_now=`lminus $rx_now $rx_reset`
			tx_now=`lminus $tx_now $tx_reset`
			echo "  rx_now=$rx_now."
			echo "  tx_now=$tx_now."

			nvram set modem_bytes_rx=$rx_now
			nvram set modem_bytes_tx=$tx_now
		else
			rx_now=0
			tx_now=0
			nvram set modem_bytes_rx=$rx_now
			nvram set modem_bytes_tx=$tx_now
			data_start=`nvram get modem_bytes_data_start 2>/dev/null`
			if [ -n "$data_start" ]; then
				echo -n "$data_start" > "$jffs_dir/sim/$sim_order/modem_bytes_data_start"
			fi
		fi

		nvram set modem_bytes_rx_reset=$rx_new
		nvram set modem_bytes_tx_reset=$tx_new
		echo "set rx_reset=$rx_new."
		echo "set tx_reset=$tx_new."
	else
		if [ "$1" == "bytes" ]; then
			/sbin/modem_data -o $sim_order -u
		else
			/sbin/modem_data -o $sim_order -r
		fi
	fi

	echo "done."
elif [ "$1" == "bytes+" ]; then
	if [ -z "$sim_order" ]; then
		echo "12:Fail to get the SIM order."
		exit 12
	fi

	if [ ! -d "$jffs_dir/sim/$sim_order" ]; then
		mkdir -p "$jffs_dir/sim/$sim_order"
	fi

	if [ "$modem_data_orig" == "1" ]; then
		rx_now=`nvram get modem_bytes_rx`
		tx_now=`nvram get modem_bytes_tx`
		echo -n "$rx_now" > "$jffs_dir/sim/$sim_order/modem_bytes_rx"
		echo -n "$tx_now" > "$jffs_dir/sim/$sim_order/modem_bytes_tx"
	else
		/sbin/modem_data -o $sim_order -s
	fi

	echo "done."
elif [ "$1" == "get_dataset" ]; then
	if [ -z "$sim_order" ]; then
		echo "12:Fail to get the SIM order."
		exit 12
	fi

	echo "Getting data setting..."

	if [ ! -d "$jffs_dir/sim/$sim_order" ]; then
		mkdir -p "$jffs_dir/sim/$sim_order"
	fi

	data_start=`cat "$jffs_dir/sim/$sim_order/modem_bytes_data_start" 2>/dev/null`
	data_cycle=`cat "$jffs_dir/sim/$sim_order/modem_bytes_data_cycle" 2>/dev/null`
	data_limit=`cat "$jffs_dir/sim/$sim_order/modem_bytes_data_limit" 2>/dev/null`
	data_warning=`cat "$jffs_dir/sim/$sim_order/modem_bytes_data_warning" 2>/dev/null`

	if [ -n "$data_start" ]; then
		nvram set modem_bytes_data_start=$data_start
	fi
	if [ -z "$data_cycle" ] || [ "$data_cycle" -lt 1 -o "$data_cycle" -gt 31 ]; then
		data_cycle=1
		echo -n "$data_cycle" > "$jffs_dir/sim/$sim_order/modem_bytes_data_cycle"
	fi
	nvram set modem_bytes_data_cycle=$data_cycle
	if [ -z "$data_limit" ]; then
		data_limit=0
		echo -n "$data_limit" > "$jffs_dir/sim/$sim_order/modem_bytes_data_limit"
	fi
	nvram set modem_bytes_data_limit=$data_limit
	if [ -z "$data_warning" ]; then
		data_warning=0
		echo -n "$data_warning" > "$jffs_dir/sim/$sim_order/modem_bytes_data_warning"
	fi
	nvram set modem_bytes_data_warning=$data_warning

	rx_now=`cat "$jffs_dir/sim/$sim_order/modem_bytes_rx" 2>/dev/null`
	tx_now=`cat "$jffs_dir/sim/$sim_order/modem_bytes_tx" 2>/dev/null`
	nvram set modem_bytes_rx=$rx_now
	nvram set modem_bytes_tx=$tx_now

	echo "done."
elif [ "$1" == "set_dataset" ]; then
	if [ -z "$sim_order" ]; then
		echo "12:Fail to get the SIM order."
		exit 12
	fi

	echo "Setting data setting..."

	if [ ! -d "$jffs_dir/sim/$sim_order" ]; then
		mkdir -p "$jffs_dir/sim/$sim_order"
	fi

	data_start=`nvram get modem_bytes_data_start 2>/dev/null`
	data_cycle=`nvram get modem_bytes_data_cycle 2>/dev/null`
	data_limit=`nvram get modem_bytes_data_limit 2>/dev/null`
	data_warning=`nvram get modem_bytes_data_warning 2>/dev/null`

	if [ -n "$data_start" ]; then
		echo -n "$data_start" > "$jffs_dir/sim/$sim_order/modem_bytes_data_start"
	fi
	if [ -z "$data_cycle" ] || [ "$data_cycle" -lt 1 -o "$data_cycle" -gt 31 ]; then
		data_cycle=1
		nvram set modem_bytes_data_cycle=$data_cycle
	fi
	echo -n "$data_cycle" > "$jffs_dir/sim/$sim_order/modem_bytes_data_cycle"
	if [ -z "$data_limit" ]; then
		data_limit=0
		nvram set modem_bytes_data_limit=$data_limit
	fi
	echo -n "$data_limit" > "$jffs_dir/sim/$sim_order/modem_bytes_data_limit"
	if [ -z "$data_warning" ]; then
		data_warning=0
		nvram set modem_bytes_data_warning=$data_warning
	fi
	echo -n "$data_warning" > "$jffs_dir/sim/$sim_order/modem_bytes_data_warning"

	echo "done."
elif [ "$1" == "sim" ]; then
	stop_sim=`nvram get stop_sim`
	if [ -n "$stop_sim" ] && [ "$stop_sim" -eq "1" ]; then
		echo "Skip to detect SIM..."
		exit 0
	fi

	modem_enable=`nvram get modem_enable`
	simdetect=`nvram get ${prefix}act_simdetect`
	if [ -z "$simdetect" ]; then
		/usr/sbin/modem_status.sh simdetect >&/dev/null
	fi

	cmee=`nvram get ${prefix}act_cmee`
	if [ "$modem_model" -eq "1" -a "$cmee" != "2" ]; then
		/usr/sbin/modem_status.sh cmee 2
	fi

	# check the SIM status.
	if [ "$modem_model" == "2" ]; then
		if [ -z "$2" ]; then
			wait_time=3
		else
			wait_time=$2
		fi
	else
		wait_time=1
	fi

	at_ret=`/usr/sbin/modem_at.sh '+CPIN?' $wait_time 2>&1`
	sim_inserted1=`echo -n "$at_ret" |grep ": READY" 2>/dev/null`
	sim_inserted2=`echo -n "$at_ret" |grep "SIM" |awk 'BEGIN{FS=": "}{print $2}' 2>/dev/null`
	sim_inserted3=`echo -n "$at_ret" |grep "+CME ERROR: " |awk 'BEGIN{FS=": "}{print $2}' 2>/dev/null`
	sim_inserted4=`echo -n "$sim_inserted2" |cut -c 1-3`
	if [ "$modem_enable" == "2" ]; then
		echo "Detected CDMA2000's SIM"
		act_sim=1
	elif [ -n "$sim_inserted1" ]; then
		echo "Got SIM."
		act_sim=1
	elif [ "$sim_inserted2" == "SIM PIN" ]; then
		echo "Need PIN."
		act_sim=2
	elif [ "$sim_inserted2" == "SIM PUK" ]; then
		echo "Need PUK."
		act_sim=3
	elif [ "$sim_inserted2" == "SIM PIN2" ]; then
		echo "Need PIN2."
		act_sim=4
	elif [ "$sim_inserted2" == "SIM PUK2" ]; then
		echo "Need PUK2."
		act_sim=5
	elif [ "$sim_inserted4" == "PH-" ]; then
		echo "Waiting..."
		act_sim=6
	elif [ "$sim_inserted3" != "" ]; then
		if [ "$sim_inserted3" == "SIM not inserted" ]; then
			echo "SIM not inserted."
			act_sim=-1
		else
			echo "CME ERROR: $sim_inserted3"
			act_sim=-2
		fi
	else
		echo "No or unknown response."
		act_sim=-10
	fi

	act_sim_orig=`nvram get ${prefix}act_sim`
	if [ "$act_sim_orig" != "$act_sim" ]; then
		nvram set ${prefix}act_sim=$act_sim
	fi

	echo "done."
elif [ "$1" == "signal" ]; then
	stop_sig=`nvram get stop_sig`
	if [ -n "$stop_sig" ] && [ "$stop_sig" -eq "1" ]; then
		echo "Skip to detect signal..."
		exit 0
	fi

	if [ "$modem_model" == "2" ]; then
		wait_time=3
	else
		wait_time=1
	fi
	at_ret=`/usr/sbin/modem_at.sh '+CSQ' $wait_time 2>&1`
	ret=`echo -n "$at_ret" |grep "+CSQ: " |awk 'BEGIN{FS=": "}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to get the signal from $modem_act_node."
		exit 3
	fi

	signal=
	if [ $ret -eq 99 ]; then
		# not known or not detectable.
		signal=-1
	elif [ $ret -le 1 ]; then
		# almost no signal.
		signal=0
	elif [ $ret -le 9 ]; then
		# Marginal.
		signal=1
	elif [ $ret -le 14 ]; then
		# OK.
		signal=2
	elif [ $ret -le 19 ]; then
		# Good.
		signal=3
	elif [ $ret -le 30 ]; then
		# Excellent.
		signal=4
	elif [ $ret -eq 31 ]; then
		# Full.
		signal=5
	else
		echo "Can't identify the signal strength: $ret."
		exit 4
	fi

	echo "signal=$signal."

	nvram set ${prefix}act_signal=$signal

	echo "done."
elif [ "$1" == "fullsignal" ]; then
	if [ "$modem_model" -eq "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+qeng="servingcell"' 1 2>&1`
		fullstr=`echo -n "$at_ret" |grep "QENG: " |awk 'BEGIN{FS="servingcell\","}{print $2}' 2>/dev/null`
		if [ -z "$fullstr" ]; then
			echo "Fail to get the full signal information from $modem_act_node."
			exit 3
		fi

		mode=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $2}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`
		cellid=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $6}' 2>/dev/null`
		if [ "$mode" == "LTE" ]; then
			lac=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $12}' 2>/dev/null`
			rsrp=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $13}' 2>/dev/null`
			rsrq=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $14}' 2>/dev/null`
			rssi=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $15}' 2>/dev/null`
			sinr=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $16}' 2>/dev/null`
		else
			lac=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $5}' 2>/dev/null`
			rsrp=0
			rsrq=0
			rssi=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $10}' 2>/dev/null`
			sinr=0
		fi

		echo "mode=$mode."
		echo "cellid=$cellid."
		echo "lac=$lac."
		echo "rsrp=$rsrp."
		echo "rsrq=$rsrq."
		echo "rssi=$rssi."
		echo "sinr=$sinr."

		nvram set ${prefix}act_cellid=$cellid
		nvram set ${prefix}act_lac=$lac
		nvram set ${prefix}act_rsrp=$rsrp
		nvram set ${prefix}act_rsrq=$rsrq
		nvram set ${prefix}act_rssi=$rssi
		nvram set ${prefix}act_sinr=$sinr

		echo "done."
	elif [ "$modem_model" == "2" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+GTCCINFO?' 5 2>&1`
		fullstr=`echo -n "$at_ret" | grep "1," | head -n 1 2>/dev/null`
		if [ -z "$fullstr" ]; then
			echo "Fail to get the operation information from $modem_act_node."
			exit 3
		fi
		# mode: NONE, GSM, WCDMA, TDSCDMA, LTE, eMTC, NB-IoT, CDMA, EVDO
		mode=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		operation=
		if [ "$mode" == "1" ]; then
			operation="GSM"
		elif [ "$mode" == "2" ]; then
			operation="WCDMA"
		elif [ "$mode" == "3" ]; then
			operation="TDSCDMA"
		elif [ "$mode" == "4" ]; then
			operation="LTE"
		elif [ "$mode" == "5" ]; then
			operation="eMTC"
		elif [ "$mode" == "6" ]; then
			operation="NB-IoT"
		elif [ "$mode" == "7" ]; then
			operation="CDMA"
		elif [ "$mode" == "8" ]; then
			operation="EVDO"
		else
			echo "Invalid network"
			exit 6
		fi

		band=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $9}' 2>/dev/null`
		cellid=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $6}' 2>/dev/null`
		if [ "$mode" -eq "4" ] || [ "$mode" -eq "5" ] || [ "$mode" -eq "6" ]; then #LTE, eMTC, NB-IoT
			lac=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $5}' 2>/dev/null`
			rsrp=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $13}' 2>/dev/null`
			rsrq=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $14}' 2>/dev/null`
			if [ "$usb_path1_manufacturer" == "Fibocom" ]; then
				rsrp=$(($rsrp-141))
				rsrq=$(($rsrq/2-20))
			fi
			if [ "$mode" -eq "4" ]; then
				at_ret=`/usr/sbin/modem_at.sh +GTCAINFO? "$modem_reg_time" 2>&1`
				ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
				if [ -z "$ret" ]; then
					echo "Fail to get the CA band from $modem_act_node."
					exit 16
				fi
				rssi=`echo -n "$at_ret" |grep "PCC" |awk 'BEGIN{FS="SCC"}{print $1}' |awk 'BEGIN{FS=","}{print $9}' 2>/dev/null`
			else
				rssi=0
			fi
			sinr=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $11}' 2>/dev/null`
		elif [ "$mode" -eq "1" ]; then #GSM
			lac=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $5}' 2>/dev/null`
			rsrp=0
			rsrq=0
			rssi=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $23}' 2>/dev/null`
			sinr=0
		elif [ "$mode" -eq "2" ]; then #WCDMA
			lac=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $5}' 2>/dev/null`
			rsrp=0
			rsrq=0
			rssi=0
			sinr=0
		else
			lac=0
			rsrp=0
			rsrq=0
			rssi=0
			sinr=0
		fi

		echo "mode=$operation."
		echo "band=$band."
		echo "cellid=$cellid."
		echo "lac=$lac."
		echo "rsrp=$rsrp."
		echo "rsrq=$rsrq."
		echo "rssi=$rssi."
		echo "sinr=$sinr."

		#nvram set ${prefix}act_operation=$operation
		#nvram set ${prefix}act_band="BAND $band"
		nvram set ${prefix}act_cellid=$cellid
		nvram set ${prefix}act_lac=$lac
		nvram set ${prefix}act_rsrp=$rsrp
		nvram set ${prefix}act_rsrq=$rsrq
		nvram set ${prefix}act_rssi=$rssi
		nvram set ${prefix}act_sinr=$(($sinr/2))

		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+CGCELLI' 1 2>&1`
		fullstr=`echo -n $at_ret |grep "+CGCELLI:" |awk 'BEGIN{FS="CGCELLI:"}{print $2}' 2>/dev/null`
		if [ -z "$fullstr" ]; then
			echo "Fail to get the full signal information from $modem_act_node."
			exit 3
		fi

		plmn_end=`echo -n "$fullstr" |awk 'BEGIN{FS="PLMN:"}{print $2}' 2>/dev/null`
		reg_type=`echo -n "$plmn_end" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		reg_status=`echo -n "$plmn_end" |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`

		if [ "$reg_status" -eq "1" ]; then
			plmn_head=`echo -n "$fullstr" |awk 'BEGIN{FS="PLMN:"}{print $1}' 2>/dev/null`
			cellid=`echo -n "$plmn_head" |awk 'BEGIN{FS="Cell_ID:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`

			if [ "$reg_type" -eq "8" ]; then
				rsrq=`echo -n "$plmn_head" |awk 'BEGIN{FS="RSRQ:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
				rsrp=`echo -n "$plmn_head" |awk 'BEGIN{FS="RSRP:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
				lac=0
				rssi=`echo -n "$plmn_head" |awk 'BEGIN{FS="RSSI:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
				sinr=`echo -n "$plmn_head" |awk 'BEGIN{FS="SINR:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
			else
				rsrq=0
				rsrp=0
				lac=`echo -n "$plmn_head" |awk 'BEGIN{FS="LAC:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
				rssi=`echo -n "$plmn_end" |awk 'BEGIN{FS="RSSI:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
				sinr=0
			fi
		fi

		bearer_type=`echo -n "$plmn_end" |awk 'BEGIN{FS="BEARER:"}{print $2}' |awk 'BEGIN{FS=","}{print $1}' |awk '{print $1}' 2>/dev/null`

		operation=
		if [ "$bearer_type" == "0x01" ]; then
			operation=GPRS
		elif [ "$bearer_type" == "0x02" ]; then
			operation=EDGE
		elif [ "$bearer_type" == "0x03" ]; then
			operation=HSDPA
		elif [ "$bearer_type" == "0x04" ]; then
			operation=HSUPA
		elif [ "$bearer_type" == "0x05" ]; then
			operation=WCDMA
		elif [ "$bearer_type" == "0x06" ]; then
			operation=CDMA
		elif [ "$bearer_type" == "0x07" ]; then
			operation="EV-DO REV 0"
		elif [ "$bearer_type" == "0x08" ]; then
			operation="EV-DO REV A"
		elif [ "$bearer_type" == "0x09" ]; then
			operation=GSM
		elif [ "$bearer_type" == "0x0a" -o "$bearer_type" == "0x0A" ]; then
			operation="EV-DO REV B"
		elif [ "$bearer_type" == "0x0b" -o "$bearer_type" == "0x0B" ]; then
			operation=LTE
		elif [ "$bearer_type" == "0x0c" -o "$bearer_type" == "0x0C" ]; then
			operation="HSDPA+"
		elif [ "$bearer_type" == "0x0d" -o "$bearer_type" == "0x0D" ]; then
			operation="DC-HSDPA+"
		else
			echo "Can't identify the operation type: $bearer_type."
			exit 6
		fi

		signal=
		if [ $rssi -eq 99 ]; then
			# not known or not detectable.
			signal=-1
		elif [ $rssi -le -111 ]; then
			# almost no signal.
			signal=0
		elif [ $rssi -le -95 ]; then
			# Marginal.
			signal=1
		elif [ $rssi -le -85 ]; then
			# OK.
			signal=2
		elif [ $rssi -le -75 ]; then
			# Good.
			signal=3
		elif [ $rssi -le -53 ]; then
			# Excellent.
			signal=4
		elif [ $rssi -ge -51 ]; then
			# Full.
			signal=5
		else
			signal=0
		fi

		echo "cellid=$cellid."
		echo "lac=$lac."
		echo "rsrq=$rsrq."
		echo "rsrp=$rsrp."
		echo "rssi=$rssi."
		echo "sinr=$sinr."
		echo "reg_type=$reg_type."
		echo "operation=$operation."
		echo "signal=$signal."

		nvram set ${prefix}act_cellid=$cellid
		nvram set ${prefix}act_lac=$lac
		nvram set ${prefix}act_rsrq=$rsrq
		nvram set ${prefix}act_rsrp=$rsrp
		nvram set ${prefix}act_rssi=$rssi
		nvram set ${prefix}act_sinr=$sinr
		nvram set ${prefix}act_operation="$operation"
		nvram set ${prefix}act_signal=$signal

		echo "done."
	fi
elif [ "$1" == "operation" ]; then
	if [ "$modem_model" == "1" ]; then
		# QNWINFO: "FDD LTE","46692","LTE BAND 7",3400
		at_ret=`/usr/sbin/modem_at.sh '+QNWINFO' 1 2>&1`
		fullstr=`echo -n "$at_ret" |grep "QNWINFO: " |awk 'BEGIN{FS="QNWINFO: "}{print $2}' 2>/dev/null`
		if [ -z "$fullstr" ]; then
			echo "Fail to get the operation information from $modem_act_node."
			exit 3
		fi

		# operation: NONE, WCDMA, HSDPA, HSUPA, HSPA+, TDD LTE, FDD LTE
		operation=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $1}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`
		band=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $3}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`
		channel=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $4}' |awk 'BEGIN{FS=" "}{print $1}' 2>/dev/null`

		echo "operation=$operation."
		echo "band=$band."
		echo "channel=$channel."

		nvram set ${prefix}act_operation="$operation"
		nvram set ${prefix}act_band="$band"
		nvram set ${prefix}act_channel="$channel"

		lte=`echo -n "$band" |grep LTE`
		if [ -z "$lte" ]; then
			nvram set ${prefix}act_scc=
		fi

		echo "done."
	elif [ "$modem_model" == "2" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+GTCCINFO?' 5 2>&1`
		fullstr=`echo -n "$at_ret" | grep "1," | head -n 1 2>/dev/null`
		if [ -z "$fullstr" ]; then
			echo "Fail to get the operation information from $modem_act_node."
			exit 3
		fi
		# operation: NONE, GSM, WCDMA, TDSCDMA, LTE, eMTC, NB-IoT, CDMA, EVDO
		bearer_type=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		if [ -z "$bearer_type" ]; then
			echo "Fail to get the operation type from $modem_act_node."
			exit 5
		fi

		operation=
		if [ "$bearer_type" == "1" ]; then
			operation="GSM"
		elif [ "$bearer_type" == "2" ]; then
			operation="WCDMA"
		elif [ "$bearer_type" == "3" ]; then
			operation="TDSCDMA"
		elif [ "$bearer_type" == "4" ]; then
			operation="LTE"
		elif [ "$bearer_type" == "5" ]; then
			operation="eMTC"
		elif [ "$bearer_type" == "6" ]; then
			operation="NB-IoT"
		elif [ "$bearer_type" == "7" ]; then
			operation="CDMA"
		elif [ "$bearer_type" == "8" ]; then
			operation="EVDO"
		else
			echo "Invalid network"
			exit 6
		fi

		band=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $9}' 2>/dev/null`

		echo "operation=$operation."
		echo "band=$band."

		nvram set ${prefix}act_operation="$operation"
		nvram set ${prefix}act_band="BAND $band"

		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		stop_op=`nvram get stop_op`
		if [ -n "$stop_op" ] && [ "$stop_op" -eq "1" ]; then
			echo "Skip to detect operation..."
			exit 0
		fi

		at_ret=`/usr/sbin/modem_at.sh '$CBEARER' 2>&1`
		bearer_type=`echo -n $at_ret |grep 'BEARER:' |awk 'BEGIN{FS=":"}{print $2}' |awk '{print $1}' 2>/dev/null`
		if [ -z "$bearer_type" ]; then
			echo "Fail to get the operation type from $modem_act_node."
			exit 5
		fi

		operation=
		if [ "$bearer_type" == "0x01" ]; then
			operation=GPRS
		elif [ "$bearer_type" == "0x02" ]; then
			operation=EDGE
		elif [ "$bearer_type" == "0x03" ]; then
			operation=HSDPA
		elif [ "$bearer_type" == "0x04" ]; then
			operation=HSUPA
		elif [ "$bearer_type" == "0x05" ]; then
			operation=WCDMA
		elif [ "$bearer_type" == "0x06" ]; then
			operation=CDMA
		elif [ "$bearer_type" == "0x07" ]; then
			operation="EV-DO REV 0"
		elif [ "$bearer_type" == "0x08" ]; then
			operation="EV-DO REV A"
		elif [ "$bearer_type" == "0x09" ]; then
			operation=GSM
		elif [ "$bearer_type" == "0x0a" -o "$bearer_type" == "0x0A" ]; then
			operation="EV-DO REV B"
		elif [ "$bearer_type" == "0x0b" -o "$bearer_type" == "0x0B" ]; then
			operation=LTE
		elif [ "$bearer_type" == "0x0c" -o "$bearer_type" == "0x0C" ]; then
			operation="HSDPA+"
		elif [ "$bearer_type" == "0x0d" -o "$bearer_type" == "0x0D" ]; then
			operation="DC-HSDPA+"
		else
			echo "Can't identify the operation type: $bearer_type."
			exit 6
		fi

		echo "operation=$operation."

		nvram set ${prefix}act_operation="$operation"

		echo "done."
	fi
elif [ "$1" == "provider" ]; then
	if [ "$modem_model" == "1" ]; then
		# QNWINFO: "FDD LTE","46692","LTE BAND 7",3400
		at_ret=`/usr/sbin/modem_at.sh '+QSPN' 1 2>&1`
		fullstr=`echo -n "$at_ret" |grep "QSPN: " |awk 'BEGIN{FS="QSPN: "}{print $2}' 2>/dev/null`
		if [ -z "$fullstr" ]; then
			echo "Fail to get the provider information from $modem_act_node."
			exit 3
		fi

		isp_long=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $1}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`
		alphabet=`echo -n "$fullstr" |awk 'BEGIN{FS=","}{print $4}' 2>/dev/null`

		echo "provider=\"$isp_long\",$alphabet."

		nvram set ${prefix}act_provider="\"$isp_long\"",$alphabet

		echo "done."
	elif [ "$modem_model" == "2" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+COPS?' $modem_reg_time 2>&1`
		if [ -z "$at_ret" ]; then
			echo "Fail to get the provider information from $modem_act_node."
			exit 39
		fi

		isp_long=`echo -n "$at_ret" |grep '+COPS: ' |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`

		echo "provider=$isp_long."

		nvram set ${prefix}act_provider="$isp_long"

		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+CGNWS' 2>&1`
		at_cgnws=`echo -n $at_ret |grep "+CGNWS:" |awk 'BEGIN{FS=":"}{print $2}' 2>/dev/null`
		if [ -z "$at_cgnws" ]; then
			echo "Fail to get the CGNWS."
			exit 39
		fi

		isp_long=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $8}' 2>/dev/null`

		echo "provider=$isp_long."

		nvram set ${prefix}act_provider="$isp_long"

		echo "done."
	fi
elif [ "$1" == "setmode" ]; then
	if [ "$modem_model" == "1" ]; then
		mode=
		if [ "$2" == "0" ]; then	# Auto
			mode=0
		elif [ "$2" == "4" ]; then	# 4G only
			mode=3
		elif [ "$2" == "3" ]; then	# 3G only
			mode=2
		else
			echo "Can't identify the mode type: $2."
			exit 7
		fi

		at_ret=`/usr/sbin/modem_at.sh '+QCFG="NWSCANMODE",'$mode',1' 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the modem mode from $modem_act_node."
			exit 8
		fi

		echo "ret=$2."
		echo "mode=$mode."
		echo "done."
	elif [ "$modem_model" == "2" ]; then
		mode=
		if [ "$2" == "0" ]; then	# Auto
			mode=10
		elif [ "$2" == "4" ]; then	# 4G only
			mode=3
		elif [ "$2" == "3" ]; then	# 3G only
			mode=2
		else
			echo "Can't identify the mode type: $2."
			exit 7
		fi

		at_ret=`/usr/sbin/modem_at.sh '+GTRAT='$mode'' "$modem_reg_time" 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the modem mode from $modem_act_node."
			exit 8
		fi

		sleep 1
		if [ "$modem_model" == "2" ]; then
			at_ret=`/usr/sbin/modem_at.sh '+COPS=0' "180" 2>&1`
		else
			at_ret=`/usr/sbin/modem_at.sh '+COPS=0' "$modem_reg_time" 2>&1`
		fi

		ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set COPS=0 from $modem_act_node."
		fi

		echo "ret=$2."
		echo "mode=$mode."
		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		mode=
		if [ "$2" == "0" ]; then	# Auto
			mode=10
		elif [ "$2" == "43" ]; then	# 4G/3G
			mode=17
		elif [ "$2" == "4" ]; then	# 4G only
			mode=11
		elif [ "$2" == "3" ]; then	# 3G only
			mode=2
		elif [ "$2" == "2" ]; then	# 2G only
			mode=1
		else
			echo "Can't identify the mode type: $2."
			exit 7
		fi

		at_ret=`/usr/sbin/modem_at.sh '+CSETPREFNET='$mode 2>&1`
		ret=`echo -n "$at_ret" |grep '+CSETPREFNET=' |awk 'BEGIN{FS="="}{print $2}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the modem mode from $modem_act_node."
			exit 8
		fi

		echo "mode=$mode."
		echo "done."
	fi
elif [ "$1" == "getmode" ]; then
	if [ "$modem_model" == "1" ]; then
		mode=

		at_ret=`/usr/sbin/modem_at.sh '+QCFG="NWSCANMODE"' 2>&1`
		ret=`echo -n "$at_ret" |grep "QCFG: " |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the modem mode from $modem_act_node."
			exit 9
		elif [ "$ret" == "0" ]; then	# Auto
			mode=0
		elif [ "$ret" == "3" ]; then	# 4G only
			mode=4
		elif [ "$ret" == "2" ]; then	# 3G only
			mode=3
		else
			echo "Can't identify the mode type: $ret."
			exit 10
		fi

		echo "ret=$ret."
		echo "mode=$mode."
		echo "done."
	elif [ "$modem_model" == "2" ]; then
		mode=

		at_ret=`/usr/sbin/modem_at.sh '+GTRAT?' "$modem_reg_time" 2>&1`
		ret=`echo -n "$at_ret" |grep "GTRAT: " |awk 'BEGIN{FS=" "}{print $2}' |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the modem mode from $modem_act_node."
			exit 9
		elif [ "$ret" == "10" ]; then	# Auto
			mode=0
		elif [ "$ret" == "3" ]; then	# 4G only
			mode=4
		elif [ "$ret" == "2" ]; then	# 3G only
			mode=3
		else
			echo "Can't identify the mode type: $ret."
			exit 10
		fi

		echo "ret=$ret."
		echo "mode=$mode."
		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		mode=

		at_ret=`/usr/sbin/modem_at.sh '+CGETPREFNET' 2>&1`
		ret=`echo -n "$at_ret" |grep '+CGETPREFNET:' |awk 'BEGIN{FS=":"}{print $2}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the modem mode from $modem_act_node."
			exit 9
		elif [ "$ret" == "10" ]; then	# Auto
			mode=0
		elif [ "$ret" == "17" ]; then	# 4G/3G
			mode=43
		elif [ "$ret" == "11" ]; then	# 4G only
			mode=4
		elif [ "$ret" == "2" ]; then	# 3G only
			mode=3
		elif [ "$ret" == "1" ]; then	# 2G only
			mode=2
		else
			echo "Can't identify the mode type: $ret."
			exit 10
		fi

		echo "mode=$mode."
		echo "done."
	fi
elif [ "$1" == "imsi" ]; then
	at_ret=`/usr/sbin/modem_at.sh '+CIMI' 2>&1`
	ret=`echo -n "$at_ret" |grep "^[0-9].*$" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to get the IMSI from $modem_act_node."
		exit 11
	fi

	echo "imsi=$ret."

	nvram set ${prefix}act_imsi=$ret

	if [ "$is_gobi" -eq "1" ] || [ "$modem_model" == "1" ] || [ "$modem_model" == "2" ]; then
		sim_num=`nvram get modem_sim_num`
		if [ -z "$sim_num" ]; then
			sim_num=10
		fi

		nvram set modem_sim_order=-1
		i=1
		while [ $i -le $sim_num ]; do
			echo -n "check SIM($i)..."
			got_imsi=`nvram get modem_sim_imsi$i`

			if [ -z "$got_imsi" ]; then
				echo "Set SIM($i)."
				nvram set modem_sim_order=$i
				nvram set modem_sim_imsi${i}=$ret
				nvram commit
				break
			elif [ "$got_imsi" == "$ret" ]; then
				echo "Get SIM($i)."
				nvram set modem_sim_order=$i
				break
			fi

			i=`expr $i + 1`
		done
	fi

	echo "done."
elif [ "$1" == "imsi_del" ]; then
	if [ "$is_gobi" -eq "1" ] || [ "$modem_model" == "1" ] || [ "$modem_model" == "2" ]; then
		if [ -z "$2" ]; then
			echo "Usage: $0 $1 <SIM's order>"
			exit 11;
		fi

		echo "Delete SIM..."

		sim_num=`nvram get modem_sim_num`
		if [ -z "$sim_num" ]; then
			sim_num=10
		fi

		i=$2
		while [ $i -le $sim_num ]; do
			echo -n "check SIM($i)..."
			got_imsi=`nvram get modem_sim_imsi$i`

			if [ $i -eq $2 ]; then
				echo -n "Delete SIM($i)."
				got_imsi=""
				nvram set modem_sim_imsi$i=$got_imsi
				rm -rf "$jffs_dir/sim/$i"
			fi

			if [ -z "$got_imsi" ]; then
				j=`expr $i + 1`
				next_imsi=`nvram get modem_sim_imsi$j`
				if [ -n "$next_imsi" ]; then
					echo -n "Move SIM($j) to SIM($i)."
					nvram set modem_sim_imsi$i=$next_imsi
					mv "$jffs_dir/sim/$j" "$jffs_dir/sim/$i"
					nvram set modem_sim_imsi$j=
				fi
			fi

			echo ""

			i=`expr $i + 1`
		done
	fi

	echo "done."
elif [ "$1" == "imei" ]; then
	at_ret=`/usr/sbin/modem_at.sh '+CGSN' 1 2>&1`
	ret=`echo -n "$at_ret" |grep "^[0-9].*$" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to get the IMEI from $modem_act_node."
		exit 12
	fi

	echo "imei=$ret."

	nvram set ${prefix}act_imei=$ret

	echo "done."
elif [ "$1" == "iccid" ]; then
	if [ "$is_gobi" -eq "1" ] || [ "$modem_model" == "1" ] || [ "$modem_model" == "2" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+ICCID' 2>&1`
		ret=`echo -n "$at_ret" |grep "ICCID: " |awk 'BEGIN{FS="ICCID: "}{print $2}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the ICCID from $modem_act_node."
			exit 13
		fi

		echo "iccid=$ret."

		nvram set ${prefix}act_iccid=$ret

		echo "done."
	fi
elif [ "$1" == "rate" ]; then
	if [ "$modem_model" == "1" ]; then
		echo "Quectel Skip to do this."
	elif [ "$modem_model" == "2" ]; then
		echo "FG621 Skip to do this."
	elif [ "$is_gobi" -eq "1" ]; then
		qcqmi=`_get_qcqmi_by_usbnet $modem_dev 2>/dev/null`
		at_ret=`gobi_api $qcqmi rate |grep "Max Tx" 2>/dev/null`
		max_tx=`echo -n "$at_ret" |awk 'BEGIN{FS=","}{print $1}' |awk 'BEGIN{FS=" "}{print $3}' 2>/dev/null`
		max_rx=`echo -n "$at_ret" |awk 'BEGIN{FS=","}{print $2}' |awk 'BEGIN{FS=" "}{print $2}' |awk 'BEGIN{FS="."}{print $1}' 2>/dev/null`
		if [ -z "$max_tx" ] || [ -z "$max_rx" ]; then
			echo "Fail to get the rate from $modem_act_node."
			exit 14
		fi

		echo "max_tx=$max_tx."
		echo "max_rx=$max_rx."

		nvram set ${prefix}act_tx=$max_tx
		nvram set ${prefix}act_rx=$max_rx

		echo "done."
	fi
elif [ "$1" == "hwver" ]; then
	if [ "$modem_model" == "1" ] || [ "$modem_model" == "2" ]; then
		at_ret=`/usr/sbin/modem_at.sh I 1 2>&1 | grep "Revision:"`
		ver=`echo -n "$at_ret" |awk '{print $2}' 2>/dev/null`
		if [ -z "$ver" ]; then
			echo "Fail to get the hwver information from $modem_act_node."
			exit 3
		fi

		echo "hwver=$ver."

		nvram set ${prefix}act_hwver=$ver

		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '$HWVER' 1 2>&1`
		ret=`echo -n "$at_ret" |grep "^[0-9].*$" 2>/dev/null`
		if [ -z "$ret" ]; then
			nvram set ${prefix}act_hwver=
			echo "Fail to get the hardware version from $modem_act_node."
			exit 15
		fi

		echo "hwver=$ret."

		nvram set ${prefix}act_hwver=$ret

		echo "done."
	fi
elif [ "$1" == "swver" ]; then
	if [ "$is_gobi" -eq "1" ] || [ "$modem_model" == "1" ] || [ "$modem_model" == "2" ]; then
		if [ "$model" == "4G-AC53U" ] || [ "$model" == "4G-AC86U" ] || [ "$model" == "4G-AX56" ]; then
			at_ret=`/usr/sbin/modem_at.sh I 1 2>&1 | grep Revision:`
			ret=`echo -n "$at_ret" |awk '{print $2}' 2>/dev/null`
		else
			at_ret=`/usr/sbin/modem_at.sh I 1 2>&1`
			ret=`echo -n "$at_ret" |grep "^WW" 2>/dev/null`
		fi
		if [ -z "$ret" ]; then
			nvram set ${prefix}act_swver=
			echo "Fail to get the software version from $modem_act_node."
			exit 15
		fi

		echo "swver=$ret."

		nvram set ${prefix}act_swver=$ret

		echo "done."
	fi
elif [ "$1" == "caband" ]; then
	if [ "$modem_model" == "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh +QCAINFO 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the CA band from $modem_act_node."
			exit 16
		fi

		pcc_band=`echo -n "$at_ret" |grep "pcc" |awk 'BEGIN{FS=","}{print $4}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`
		scc_bands=`echo -n "$at_ret" |grep "scc" |awk 'BEGIN{FS=","}{print $4}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`
		scc_band=`echo -n "$scc_bands" |tr "\r\n" "," 2>/dev/null`

		echo "pcc=$pcc_band."
		echo "scc=$scc_band."

		nvram set ${prefix}act_pcc="$pcc_band"
		if [ -n "$scc_band" ]; then
			nvram set ${prefix}act_scc="$scc_band"
		fi

		echo "done."
	elif [ "$modem_model" == "2" ]; then
		at_ret=`/usr/sbin/modem_at.sh +GTCAINFO? "$modem_reg_time" 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the CA band from $modem_act_node."
			exit 16
		fi

		pcc_band=`echo -n "$at_ret" |grep "PCC" |awk 'BEGIN{FS="SCC"}{print $1}' |awk 'BEGIN{FS=","}{print $1}' |awk 'BEGIN{FS=":"}{print $2}' 2>/dev/null`
		scc_band=`echo -n "$at_ret" |grep "SCC" |awk 'BEGIN{FS="SCC"}{print $2}' |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`

		echo "pcc=$pcc_band."
		echo "scc=$scc_band."

		nvram set ${prefix}act_pcc="BAND $(($pcc_band-100))"
		if [ "$scc_band" == "100" ] || [ "$scc_band" == "" ]; then
			nvram set ${prefix}act_scc=""
		else
			nvram set ${prefix}act_scc="BAND $(($scc_band-100))"
		fi
		echo "done."
	fi
elif [ "$1" == "band" ]; then
	if [ "$modem_model" == "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+QCFG="band"' 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the band from $modem_act_node."
			exit 16
		fi

		ret=`echo -n "$at_ret" |grep '+QCFG: ' |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`

		echo "$ret"
	elif [ "$is_gobi" -eq "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '$CRFI' 2>&1`
		ret=`echo -n "$at_ret" |grep '$CRFI:' |awk 'BEGIN{FS=":"}{print $2}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the current band from $modem_act_node."
			exit 16
		fi

		echo "band=$ret."

		nvram set ${prefix}act_band="$ret"

		echo "done."
	fi
elif [ "$1" == "setband" ]; then
	if [ "$modem_model" == "1" ]; then
		nvram set freeze_duck=$wandog_interval
		echo -n "Setting Band..."

		if [ -z "$2" ] || [ "$2" == "auto" ]; then
			bandnum="2000001e0bb1f39df"
		else
			order=`echo -n $2 |awk 'BEGIN{FS="B"}{print $2}' 2>/dev/null`
			if [ "$order" -gt 0 ] 2>/dev/null; then
				echo "order=$order."
			else
				echo "$2 is not the correct band!!!"
				exit 16
			fi

			order=$((order-1))
			bandnum=`order $order`
		fi
		echo "bandnum=$bandnum"

		at_ret=`/usr/sbin/modem_at.sh '+QCFG="band",0,'$bandnum',0,1' 3 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the band from $modem_act_node."
			exit 16
		fi

		echo "done."
	elif [ "$modem_model" == "2" ]; then
		nvram set freeze_duck=$wandog_interval
		echo -n "Setting Band..."

		#AT+gtact?
		#+GTACT: 10,3,2,1,3,5,8,101,103,105,107,108,120,128,138,140,141
		#OK
		#
		#AT+gtact=?
		#+GTACT: (1,2,4,10),(2,3),(2,3),(),(1,3,5,8),(101,103,105,107,108,120,128,138,140,141),(),()
		#OK

		if [ -z "$2" ] || [ "$2" == "auto" ]; then
			order_3G=",1,3,5,8"
			order_LTE=",101,103,105,107,108,120,128,138,140,141"
		else
			order=`echo -n $2 |awk 'BEGIN{FS="B"}{print $2}' 2>/dev/null`
			if [ "$order" -gt 0 ] 2>/dev/null; then
				echo "order=$order."
			else
				echo "$2 is not the correct band!!!"
				exit 16
			fi
			order_LTE=",$((order+100))"
			order_3G=",$order"
		fi

		if [ "$modem_mode" == "4" ]; then #4G
			rat="2,,"
			bandnum="$rat$order_LTE"
		elif [ "$modem_mode" == "3" ]; then #3G
			rat="1,,"
			bandnum="$rat$order_3G"
		elif [ "$modem_mode" == "0" ]; then #auto
			rat="10,3,2"
			if [ "$order" == "7" ]; then
				order_3G=",1,3,5,8"
			fi
			bandnum="$rat$order_3G$order_LTE"
		fi
		echo "bandnum=$bandnum"

		at_ret=`/usr/sbin/modem_at.sh '+GTACT='$bandnum "$modem_reg_time" 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the band from $modem_act_node."
			exit 16
		fi

		at_ret=`/usr/sbin/modem_at.sh '+CFUN=0' 2>&1`
		ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "CFUN: Fail to set +CFUN=0."
		fi

		at_ret=`/usr/sbin/modem_at.sh '+CFUN=1' 2>&1`
		ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "CFUN: Fail to set +CFUN=1."
		fi

		at_ret=`/usr/sbin/modem_at.sh '+GTRNDIS=1,1' "$modem_reg_time" 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to start the network from $modem_act_node."
			exit 16
		fi

		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		echo -n "Setting Band..."

		path=`_find_usb_path "$modem_act_path"`
		modem_serial=`nvram get usb_path"$path"_serial`

		mode=11
		if [ "$2" == "B1" ]; then
			bandnum="0000000000000001"
		elif [ "$2" == "B3" ]; then
			bandnum="0000000000000004"
		elif [ "$2" == "B7" ]; then
			bandnum="0000000000000040"
		elif [ "$2" == "B20" ]; then
			bandnum="0000000000080000"
		elif [ "$2" == "B38" ]; then
			bandnum="0000002000000000"
		else # auto
			mode=10
			if [ "$modem_serial" == "ASKEYMDM9230" ]; then
				bandnum="0000002000080045"
			else
				bandnum="0000002000080044"
			fi
		fi

		at_ret=`/usr/sbin/modem_at.sh '$NV65633='$bandnum 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the band from $modem_act_node."
			exit 16
		fi

		at_ret=`/usr/sbin/modem_at.sh '+CSETPREFNET='$mode 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the band from $modem_act_node."
			exit 16
		fi

		at_ret=`/usr/sbin/modem_at.sh '+CFUN=1,1' 2>&1`
		ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to set the band from $modem_act_node."
			exit 16
		fi

		echo "done."
	fi
elif [ "$1" == "scan" ]; then
	echo "Start to scan the stations:"
	modem_roaming_scantime=`nvram get modem_roaming_scantime`
	modem_roaming_scanlist=`nvram get modem_roaming_scanlist`
	nvram set ${prefix}act_scanning=2
	at_ret=`/usr/sbin/modem_at.sh '+COPS=2' "$modem_reg_time" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`

	echo "Scanning the stations."
	at_ret=`/usr/sbin/modem_at.sh '+COPS=?' $modem_roaming_scantime 2>&1`
	ret=`echo -n "$at_ret" |grep '+COPS: ' |awk 'BEGIN{FS=": "}{print $2}' |awk 'BEGIN{FS=",,"}{print $1}' 2>/dev/null`
	echo "Finish the scan."
	nvram set ${prefix}act_scanning=1
	if [ -z "$ret" ]; then
		echo "17:Fail to scan the stations."
		nvram set ${prefix}act_scanning=0
		nvram set freeze_duck=$wandog_interval
		exit 17
	fi

	echo "Count the stations."
	num=`echo -n "$ret" |awk 'BEGIN{FS=")"}{print NF}' 2>/dev/null`
	if [ -z "$num" ]; then
		echo "18:Fail to count the stations."
		nvram set ${prefix}act_scanning=0
		nvram set freeze_duck=$wandog_interval
		exit 18
	fi

	echo "Work the list."
	list="["
	filter=""
	i=1
	while [ $i -lt $num ]; do
		str=`echo -n "$ret" |awk 'BEGIN{FS=")"}{print $'$i'}' |awk 'BEGIN{FS="("}{print $2}' 2>/dev/null`

		sta=`echo -n "$str" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		sta_code=`echo -n "$str" |awk 'BEGIN{FS=","}{print $4}' 2>/dev/null`
		sta_type_number=`echo -n "$str" |awk 'BEGIN{FS=","}{print $5}' 2>/dev/null`
		if [ "$sta_type_number" == "0" -o "$sta_type_number" == "1" -o "$sta_type_number" == "3" ]; then
			sta_type=2G
		elif [ "$sta_type_number" == "2" ]; then
			sta_type=3G
		elif [ "$sta_type_number" == "4" ]; then
			sta_type=HSDPA
		elif [ "$sta_type_number" == "5" ]; then
			sta_type=HSUPA
		elif [ "$sta_type_number" == "6" ]; then
			sta_type=H+
		elif [ "$sta_type_number" == "7" ]; then
			sta_type=4G
		else
			sta_type=unknown
		fi

		if [ "$list" != "[" ]; then
			list=$list",[$sta, $sta_code, \"$sta_type\"]"
		else
			list=$list"[$sta, $sta_code, \"$sta_type\"]"
		fi
		filter=$filter","$sta","

		i=`expr $i + 1`
	done
	list=$list"]"
	echo -n "$list" > $modem_roaming_scanlist
	nvram set ${prefix}act_scanning=0
	nvram set freeze_duck=$wandog_interval

	echo "done."
elif [ "$1" == "station" ]; then
	#/usr/sbin/modem_at.sh "+COPS=1,0,\"$2\"" "$modem_reg_time" 1,2>/dev/null
	#if [ $? -ne 0 ]; then
	wait_time1=`expr $wandog_interval + $wandog_interval`
	wait_time=`expr $wait_time1 + $modem_reg_time`
	nvram set freeze_duck=$wait_time
	#at_ret=`/usr/sbin/modem_at.sh '+COPS=1,0,"'$2'"' "$modem_reg_time" 2>&1`
	at_ret=`/usr/sbin/modem_at.sh +COPS=1,0,"$2" "$modem_reg_time" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "19:Fail to set the station: $2."
		exit 19
	fi

	echo "done."
elif [ "$1" == "simauth" ]; then
	if [ "$modem_model" == "1" ]; then
		nvram set ${prefix}act_auth=
		nvram set ${prefix}act_auth_pin=
		nvram set ${prefix}act_auth_puk=

		at_ret=`/usr/sbin/modem_at.sh '+CLCK="SC",2' 2>&1`
		ret=`echo -n "$at_ret" |grep "+CLCK: " 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "34:Fail to get PIN's lock status."
			exit 34
		fi

		pin_alive=`echo -n "$ret" |awk '{print $2}' 2>/dev/null`
		act_sim=`nvram get ${prefix}act_sim`
		if [ -z "$act_sim" ]; then
			/usr/sbin/mdoem_status.sh sim
			act_sim=`nvram get ${prefix}act_sim`
		fi

		at_ret=`/usr/sbin/modem_at.sh '+QPINC?' 1 2>&1`
		str=`echo -n "$at_ret" |grep "+QPINC: " 2>/dev/null`
		if [ -z "$str" ]; then
			echo "Fail to get the SIM status."
			exit 20
		fi

		SC_state=`echo -n "$str" |grep "SC" 2>/dev/null`
		SC_pin=`echo -n "$SC_state" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		SC_puk=`echo -n "$SC_state" |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`
		echo "SIM PIN count is $SC_pin, PUK count is $SC_puk."
		nvram set ${prefix}act_auth_pin=$SC_pin
		nvram set ${prefix}act_auth_puk=$SC_puk
		P2_state=`echo -n "$str" |grep "P2" 2>/dev/null`
		P2_pin=`echo -n "$P2_state" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		P2_puk=`echo -n "$P2_state" |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`
		echo "SIM PIN2 count is $P2_pin, PUK2 count is $P2_puk."

		if [ "$pin_alive" -eq "1" ]; then
			if [ "$act_sim" -gt "1" ]; then
				if [ "$SC_pin" -gt "0" ]; then
					echo "SIM auth state is ENABLED_NOT_VERIFIED."
					act_auth=1
				else
					echo "SIM auth state is BLOCKED."
					act_auth=4
				fi
			elif [ "$act_sim" -lt "0" ]; then
				echo "SIM auth state is UNKNOWN."
				act_auth=-1
			else
				echo "SIM auth state is ENABLED_VERIFIED."
				act_auth=2
			fi
		else
			echo "SIM auth state is DISABLED."
			act_auth=3
		fi
		nvram set ${prefix}act_auth=$act_auth

		echo "done."
	elif [ "$is_gobi" -eq "1" ]; then
		nvram set ${prefix}act_auth=
		nvram set ${prefix}act_auth_pin=
		nvram set ${prefix}act_auth_puk=

		at_ret=`/usr/sbin/modem_at.sh '+CPINR' 1 2>&1`
		str=`echo -n "$at_ret" |grep "+CPINR:" |awk 'BEGIN{FS=":"}{print $2}' 2>/dev/null`
		if [ -z "$str" ]; then
			echo "Fail to get the SIM status."
			exit 20
		fi

		ret=`echo -n "$str" |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the SIM auth state."
			exit 21
		fi
		nvram set ${prefix}act_auth=$ret
		if [ "$ret" == "1" ]; then
			echo "SIM auth state is ENABLED_NOT_VERIFIED."
		elif [ "$ret" == "2" ]; then
			echo "SIM auth state is ENABLED_VERIFIED."
		elif [ "$ret" == "3" ]; then
			echo "SIM auth state is DISABLED."
		elif [ "$ret" == "4" ]; then
			echo "SIM auth state is BLOCKED."
		elif [ "$ret" == "5" ]; then
			echo "SIM auth state is PERMANENTLY_BLOCKED."
		else
			echo "SIM auth state is UNKNOWN."
		fi

		ret=`echo -n "$str" |awk 'BEGIN{FS=","}{print $4}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the PIN retry."
			exit 22
		fi
		nvram set ${prefix}act_auth_pin=$ret
		echo "SIM PIN retry is $ret."

		ret=`echo -n "$str" |awk 'BEGIN{FS=","}{print $5}' 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "Fail to get the PUK retry."
			exit 23
		fi
		nvram set ${prefix}act_auth_puk=$ret

		echo "SIM PUK retry is $ret."
		echo "done."
	fi
elif [ "$1" == "simpin" ]; then
	if [ -z "$2" ]; then
		nvram set g3state_pin=2

		echo "24:Need to input the PIN code."
		exit 24
	fi

	nvram set g3state_pin=1
	at_ret=`/usr/sbin/modem_at.sh '+CPIN='\"$2\" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		nvram set g3err_pin=1

		echo "25:Fail to unlock the SIM: $2."
		exit 25
	fi

	nvram set g3err_pin=0
	echo "done."
elif [ "$1" == "simpuk" ]; then
	# $2: the original PUK. $3: the new PIN.
	if [ -z "$2" ]; then
		echo "26:Need to input the PUK code."
		exit 26
	elif [ -z "$3" ]; then
		echo "27:Need to input the new PIN code."
		exit 27
	fi

	at_ret=`/usr/sbin/modem_at.sh '+CPIN='\"$2\"','\"$3\" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "28:Fail to unlock the SIM PIN: $2."
		exit 28
	fi

	echo "done."
elif [ "$1" == "lockpin" ]; then
	# $2: 2, status; 1, lock; 0, unlock. $3: the original PIN.
	if [ -z "$2" ]; then
		echo "32:Decide to lock/unlock PIN."
		exit 32
	fi

	if [ "$2" != "2" -a -z "$3" ]; then
		echo "33:Need the PIN code."
		exit 33
	fi

	if [ "$modem_model" == "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+CLCK="SC",2' 2>&1`
		ret=`echo -n "$at_ret" |grep "+CLCK: " 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "34:Fail to get PIN's lock status."
			exit 34
		fi

		pin_alive=`echo -n "$ret" |awk '{print $2}' 2>/dev/null`

		if [ "$2" == "2" -o "$2" == "$pin_alive" ]; then
			echo "$pin_alive"
			echo "done."
			exit 0
		fi
	elif [ "$is_gobi" -eq "1" ]; then
		simauth=`nvram get ${prefix}act_auth`
		if [ "$simauth" == "1" ]; then
			echo "29:SIM need to input the PIN code first."
			exit 29
		elif [ "$simauth" == "4" -o "$simauth" == "5" ]; then # lock
			echo "30:SIM had been blocked."
			exit 30
		elif [ "$simauth" == "0" ]; then # lock
			echo "31:Can't get the SIM auth state."
			exit 31
		fi

		if [ "$2" == "1" -a "$simauth" == "1" ] || [ "$2" == "1" -a "$simauth" == "2" ] || [ "$2" == "0" -a "$simauth" == "3" ]; then # lock
			if [ "$simauth" == "1" -o "$simauth" == "2" ]; then
				echo "had locked."
			elif [ "$simauth" == "3" ]; then
				echo "had unlocked."
			fi

			echo "done."
			exit 0
		fi
	fi

	at_ret=`/usr/sbin/modem_at.sh '+CLCK="SC",'$2',"'$3'"' 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		if [ "$2" == "1" ]; then
			echo "34:Fail to lock PIN."
			exit 34
		else
			echo "35:Fail to unlock PIN."
			exit 35
		fi
	fi

	echo "done."
elif [ "$1" == "pwdpin" ]; then
	if [ -z "$2" ]; then
		echo "36:Need to input the original PIN code."
		exit 36
	elif [ -z "$3" ]; then
		echo "37:Need to input the new PIN code."
		exit 37
	fi

	at_ret=`/usr/sbin/modem_at.sh '+CPWD="SC",'$2','$3 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "38:Fail to change the PIN."
		exit 38
	fi

	echo "done."
elif [ "$1" == "gnws" ]; then
	if [ "$is_gobi" -eq "1" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+CGNWS' 2>&1`
		at_cgnws=`echo -n $at_ret |grep "+CGNWS:" |awk 'BEGIN{FS=":"}{print $2}' 2>/dev/null`
		if [ -z "$at_cgnws" ]; then
			echo "Fail to get the CGNWS."
			exit 39
		fi

		roaming=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $1}' 2>/dev/null`
		signal=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		reg_type=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`
		reg_state=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $4}' 2>/dev/null`
		mcc=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $5}' 2>/dev/null`
		mnc=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $6}' 2>/dev/null`
		spn=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $7}' 2>/dev/null`
		isp_long=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $8}' 2>/dev/null`
		isp_short=`echo -n "$at_cgnws" |awk 'BEGIN{FS=","}{print $9}' |awk 'BEGIN{FS=" "}{print $1}' 2>/dev/null`

		echo "   Roaming=$roaming."
		echo "    Signal=$signal."
		echo " REG. Type=$reg_type."
		echo "REG. State=$reg_state."
		echo "       MCC=$mcc."
		echo "       MNC=$mnc."
		echo "       SPN=$spn."
		echo "  ISP Long=$isp_long."
		echo " ISP Short=$isp_short."
		echo "done."
	fi
elif [ "$1" == "init_sms" ]; then
	nvram set freeze_duck=$wandog_interval

	if [ "$modem_model" == "1" ]; then
		at_ret=`/usr/sbin/modem_status.sh band 2>&1`

		if [ "$at_ret" == "0x2000001e0bb1e39df" ] || [ "$at_ret" == "0x2000001E0BB1E39DF" ]; then
			at_ret=`/usr/sbin/modem_status.sh setband 2>&1`
		fi
	fi

	at_ret=`/usr/sbin/modem_at.sh E1 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to enable echo mode."
		exit 0
	fi

	at_ret=`/usr/sbin/modem_at.sh +CMGF=1 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to set the Text mode."
		exit 0
	fi

	at_ret=`/usr/sbin/modem_at.sh +CSMP=17,167,0,8 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to set the unicode."
		exit 0
	fi

	at_ret=`/usr/sbin/modem_at.sh +CSCS=\"UCS2\" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to set UCS2."
		exit 0
	fi

	at_ret=`/usr/sbin/modem_at.sh +CSDH=1 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to get the header values."
		exit 0
	fi

	at_ret=`/usr/sbin/modem_at.sh +CPMS=\"SM\",\"SM\",\"SM\" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
		echo "Fail to set SM as the preferred message storage."
		exit 0
	fi

	echo "done."
elif [ "$1" == "get_sms_number" ]; then
	nvram set freeze_duck=$wandog_interval

	at_ret=`/usr/sbin/modem_at.sh +CPMS? 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to delete the $2th message."
		exit 0
	fi

	sms_total=`echo -n "$at_ret" |grep "+CPMS: " |awk 'BEGIN{FS=" "}{print $2}' |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`
	if [ -z "$sms_total" ]; then
		echo "Fail to get the total message number."
		exit 0
	fi

	sms_num=`echo -n "$at_ret" |grep "+CPMS: " |awk 'BEGIN{FS=" "}{print $2}' |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
	if [ -z "$sms_num" ]; then
		echo "Fail to get the used message number."
		exit 0
	fi

	echo "sms_total=$sms_total"
	echo "sms_num=$sms_num"

	nvram set ${prefix}act_sms_total=$sms_total
	nvram set ${prefix}act_sms_num=$sms_num

	echo "done."
elif [ "$1" == "read_sms_all" ]; then
	# $2: saved file
	if [ "$modem_model" == "2" ]; then
		nvram set freeze_duck=$modem_reg_time
	else
		nvram set freeze_duck=$wandog_interval
	fi

	at_ret=`/usr/sbin/modem_at.sh +CMGL=\"ALL\" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to get the SMS list."
		exit 0
	fi

	if [ -n "$2" ]; then
		echo "$at_ret" > $2
	fi
	echo "----------"
	echo "$at_ret"
	echo "----------"

	echo "done."
elif [ "$1" == "read_sms_group" ]; then
	# $2: stat, $3: saved file
	nvram set freeze_duck=$wandog_interval

	at_ret=`/usr/sbin/modem_at.sh +CMGL="\"$2\"" 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to get the SMS list."
		exit 0
	fi

	if [ -n "$3" ]; then
		echo "$at_ret" > $3
	fi
	echo "----------"
	echo "$at_ret"
	echo "----------"

	echo "done."
elif [ "$1" == "send_sms" ]; then
	# $2: phone number, $3: sended message.
	if [ -z "$2" -o -z "$3" ]; then
		echo "41:Usage: $0 $1 <phone number> <sended message>"
		exit 41
	fi

	nvram set ret_sms_send=0

	if [ "$modem_model" == "2" ]; then # for FIBOCOM FG621
		wait_time1=$modem_reg_time
		wait_time=`expr $wait_time1 + 10`
		nvram set freeze_duck=$wait_time
		i=0;
		while [ $i -lt $wait_time ]; do
			at_run=`ps |grep modem_ |wc -l`
			echo "at_run=$at_run"
			if [ $at_run -le 3 ]; then
				nvram set freeze_duck=$wait_time
				break
			fi

			sleep 1
			i=`expr $i + 1`
			nvram set freeze_duck=$wait_time1
		done

		at_ret=`/usr/sbin/modem_at.sh +CMGS=\"$2\" "$modem_reg_time" 2>&1`
		ret=`echo -n $at_ret |grep ">" 2>/dev/null`
		if [ -z "$ret" ]; then
			nvram set ret_sms_send=-1

			echo "42:Fail to execute +CMGS."
			nvram set freeze_duck=$wait_time
			at_ret=`$at_lock chat -t $wait_time1 -e '' "^z" OK >> /dev/$modem_act_node < /dev/$modem_act_node`
			ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
			if [ -z "$ret" ]; then
				nvram set freeze_duck=$wait_time
			fi
			exit 42
		fi

		nvram set freeze_duck=$wait_time
		$at_lock chat -t $wait_time1 -e '' "$3^z" OK >> /dev/$modem_act_node < /dev/$modem_act_node 2>/tmp/ret_sms.log
		ret=`grep "OK" /tmp/ret_sms.log 2>/dev/null`
		if [ -z "$ret" ]; then
			nvram set ret_sms_send=-2

			echo "43:Fail to send the message: $3."
			nvram set freeze_duck=$wait_time
			at_ret=`$at_lock chat -t $wait_time1 -e '' "^z" OK >> /dev/$modem_act_node < /dev/$modem_act_node`
			ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
			if [ -z "$ret" ]; then
				nvram set freeze_duck=$wait_time
			fi
			exit 43
		fi
	else
		wait_time1=`expr $wandog_interval + $wandog_interval`
		wait_time=`expr $wait_time1 + 10`
		nvram set freeze_duck=$wait_time
		i=0;
		while [ $i -lt $wait_time ]; do
			at_run=`ps |grep modem_ |wc -l`
			echo "at_run=$at_run"
			if [ $at_run -le 3 ]; then
				nvram set freeze_duck=$wait_time1
				break
			fi

			sleep 1
			i=`expr $i + 1`
			nvram set freeze_duck=$wait_time1
		done

		at_ret=`/usr/sbin/modem_at.sh +CMGS=\"$2\" 2>&1`
		ret=`echo -n $at_ret |grep ">" 2>/dev/null`
		if [ -z "$ret" ]; then
			nvram set ret_sms_send=-1

			echo "42:Fail to execute +CMGS."
			exit 42
		fi

		nvram set freeze_duck=$wait_time1
		$at_lock chat -t $wait_time1 -e '' "$3^z" OK >> /dev/$modem_act_node < /dev/$modem_act_node 2>/tmp/ret_sms.log
		ret=`grep "OK" /tmp/ret_sms.log 2>/dev/null`
		if [ -z "$ret" ]; then
			nvram set ret_sms_send=-2

			echo "43:Fail to send the message: $3."
			exit 43
		fi
	fi

	nvram set ret_sms_send=1

	echo "done."
elif [ "$1" == "store_sms" ]; then
	# $2: phone number, $3: sended message.
	if [ -z "$2" -o -z "$3" ]; then
		echo "41:Usage: $0 $1 <phone number> <sended message>"
		exit 41
	fi

	nvram set ret_sms_store=0

	wait_time1=`expr $wandog_interval + $wandog_interval`
	wait_time=`expr $wait_time1 + 10`
	nvram set freeze_duck=$wait_time
	i=0;
	while [ $i -lt $wait_time ]; do
		at_run=`ps |grep modem_ |wc -l`
		echo "at_run=$at_run"
		if [ $at_run -le 3 ]; then
			nvram set freeze_duck=$wait_time1
			break
		fi

		sleep 1
		i=`expr $i + 1`
		nvram set freeze_duck=$wait_time1
	done

	at_ret=`/usr/sbin/modem_at.sh +CMGW=\"$2\" 2>&1`
	ret=`echo -n $at_ret |grep ">" 2>/dev/null`
	if [ -z "$ret" ]; then
		nvram set ret_sms_store=-1

		echo "42:Fail to execute +CMGS."
		exit 42
	fi

	nvram set freeze_duck=$wait_time1
	$at_lock chat -t $wait_time1 -e '' "$3^z" OK >> /dev/$modem_act_node < /dev/$modem_act_node 2>/tmp/ret_sms.log
	ret=`grep "OK" /tmp/ret_sms.log 2>/dev/null`
	if [ -z "$ret" ]; then
		nvram set ret_sms_store=-2

		echo "43:Fail to send the message: $3."
		exit 43
	fi

	nvram set ret_sms_store=1

	echo "done."
elif [ "$1" == "send_stored_sms" ]; then
	# $2: the index of messages

	if [ -z "$2" ]; then
		echo "Usage: $0 $1 <the index of messages>"
		exit 0
	fi

	nvram set ret_sms_send=0

	nvram set freeze_duck=$wandog_interval

	at_ret=`/usr/sbin/modem_at.sh +CMSS=$2 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		nvram set ret_sms_send=-2

		echo "Fail to delete the $2th message."
		exit 0
	fi

	nvram set ret_sms_send=1

	echo "done."
elif [ "$1" == "del_sms" ]; then
	# $2: the index of messages

	if [ -z "$2" ]; then
		echo "Usage: $0 $1 <the index of messages>"
		exit 0
	fi

	nvram set freeze_duck=$wandog_interval

	at_ret=`/usr/sbin/modem_at.sh +CMGD=$2 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to delete the $2th message."
		exit 0
	fi

	echo "done."
elif [ "$1" == "del_sms_all" ]; then
	nvram set freeze_duck=$wandog_interval

	at_ret=`/usr/sbin/modem_at.sh +CMGD=0,4 2>&1`
	ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "Fail to delete all messages."
		exit 0
	fi

	echo "done."
elif [ "$1" == "simdetect" ]; then
	if [ "$modem_model" == "1" ]; then
		# $2: 0: disable, 1: enable.
		at_ret=`/usr/sbin/modem_at.sh '+QSIMDET?' 2>&1`
		ret=`echo -n "$at_ret" |grep "+QSIMDET: " 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "44:Fail to get the value of SIM detect."
			exit 44
		fi

		current=`echo -n "$ret" |awk '{print $2}' |awk 'BEGIN{FS=","}{print $1}'`

		if [ -z "$2" ]; then
			echo "Quectel: get the SIM detect settting: $current"
			nvram set ${prefix}act_simdetect=$current
		elif [ "$2" == "1" -a "$current" == "0" ] || [ "$2" == "0" -a "$current" == "1" ]; then
			at_ret=`/usr/sbin/modem_at.sh '+QSIMDET='$2',1' 2>&1`
			ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
			if [ -z "$ret" ]; then
				echo "45:Fail to set the SIM detect to be $2."
				exit 45
			fi
			nvram set ${prefix}act_simdetect=$2

			at_ret=`/usr/sbin/modem_at.sh '+CFUN=1,1' 2>&1`
		fi

		echo "done."
	elif [ "$is_gobi" -eq "1" ] && [ "$usb_gobi2" != "1" ]; then
		# $2: 0: disable, 1: enable.
		at_ret=`/usr/sbin/modem_at.sh '$NV70210' 2>&1`
		ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "44:Fail to get the value of SIM detect."
			exit 44
		fi

		current=`echo -n $at_ret |awk '{print $2}'`

		if [ -z "$2" ]; then
			echo "$current"
			nvram set ${prefix}act_simdetect=$current
		elif [ "$2" == "1" -a "$current" == "0" ] || [ "$2" == "0" -a "$current" == "1" ]; then
			at_ret=`/usr/sbin/modem_at.sh '$NV70210='$2 2>&1`
			ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
			if [ -z "$ret" ]; then
				echo "45:Fail to set the SIM detect to be $2."
				exit 45
			fi
			nvram set ${prefix}act_simdetect=$2

			# Use reboot to replace this.
			#at_ret=`/usr/sbin/modem_at.sh '+CFUN=1,1' 2>&1`
			#ret=`echo -n $at_ret |grep "OK" 2>/dev/null`
			#if [ -z "$ret" ]; then
			#	echo "45:Fail to reset the Gobi."
			#	exit 46
			#fi
		fi

		echo "done."
	fi
elif [ "$1" == "number" ]; then
	at_ret=`/usr/sbin/modem_at.sh '+CNUM' 2>&1`
	ret=`echo -n "$at_ret" |grep "+CNUM: " 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "47:Fail to get the Phone number from $modem_act_node."
		exit 47
	fi

	number=`echo -n "$ret" |awk 'BEGIN{FS=":"}{print $2}' |awk 'BEGIN{FS=","}{print $2}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`

	echo "number=$number."

	nvram set ${prefix}act_num=$number

	echo "done."
elif [ "$1" == "smsc" ]; then
	at_ret=`/usr/sbin/modem_at.sh '+CSCA?' 1 2>&1`
	ret=`echo -n "$at_ret" |grep "+CSCA: " 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "48:Fail to get the SMSC from $modem_act_node."
		exit 48
	fi

	smsc=`echo -n "$ret" |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`

	echo "smsc=$smsc."

	nvram set ${prefix}act_smsc=$smsc

	echo "done."
elif [ "$1" == "ip" ]; then
	if [ "$is_gobi" -eq "1" ] || [ "$modem_model" == "1" ] || [ "$modem_model" == "2" ]; then
		ip=
		ipv6=
		if [ "$modem_model" == "2" ]; then
			wait_time=3
		else
			wait_time=1
		fi
		if [ "$modem_model" == "2" ]; then
			at_ret=`/usr/sbin/modem_at.sh '+CEREG?' $wait_time 2>&1`
			ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
			if [ -z "$ret" ]; then
				echo "49: Fail to get the CEREG from $modem_act_node."
				exit 49
			fi
			at_ret=`/usr/sbin/modem_at.sh '+GTRNDIS?' $wait_time 2>&1`
			ret=`echo -n "$at_ret" |grep "+GTRNDIS: 1,1" 2>/dev/null`
			if [ -z "$ret" ]; then
				echo "Fail to get the GTRNDIS from $modem_act_node. Try to re-connect"
				at_ret=`/usr/sbin/modem_at.sh '+GTRNDIS=1,1' "$modem_reg_time" 2>&1`
				ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
				if [ -z "$ret" ]; then
					echo "50: Fail to re-connect the network from $modem_act_node."
					exit 50
				fi
			fi
		fi

		at_ret=`/usr/sbin/modem_at.sh '+CGPADDR=1' $wait_time 2>&1`
		ret=`echo -n "$at_ret" |grep "+CGPADDR: 1," 2>/dev/null`
		if [ -z "$ret" ]; then
			echo "48:Fail to get the CGPADDR from $modem_act_node."
			exit 48
		fi

		if [ "$modem_pdp" != "2" ]; then
			if [ "$modem_model" == "1" ] || [ "$modem_model" == "2" ]; then
				ip=`echo -n "$ret" |awk 'BEGIN{FS=","}{print $2}' |awk 'BEGIN{FS="\""}{print $2}' 2>/dev/null`
			else
				ip=`echo -n "$ret" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
			fi
		fi

		if [ "$modem_pdp" == "2" ]; then
			ipv6=`echo -n "$ret" |awk 'BEGIN{FS=","}{print $2}' 2>/dev/null`
		elif [ "$modem_pdp" == "3" ]; then
			ipv6=`echo -n "$ret" |awk 'BEGIN{FS=","}{print $3}' 2>/dev/null`
		fi

		echo "ip=$ip."
		echo "ipv6=$ipv6."

		nvram set ${prefix}act_ip=$ip
		nvram set ${prefix}act_ipv6=$ipv6

		echo "done."
	fi
elif [ "$1" == "cmee" ]; then
	at_ret=`/usr/sbin/modem_at.sh '+CMEE?' 2>&1`
	ret=`echo -n "$at_ret" |grep "+CMEE: " 2>/dev/null`
	if [ -z "$ret" ]; then
		echo "44:Fail to get CMEE from $modem_act_node."
		exit 44
	fi

	current=`echo -n "$ret" |awk '{print $2}'`

	if [ -z "$2" ]; then
		echo "$current"
		nvram set ${prefix}act_cmee=$current
	else
		if [ "$2" != "$current" ]; then
			at_ret=`/usr/sbin/modem_at.sh '+CMEE='$2 2>&1`
			ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
			if [ -z "$ret" ]; then
				echo "45:Fail to set CMEE to be $2."
				exit 45
			fi
		fi

		nvram set ${prefix}act_cmee=$2
	fi

	echo "done."
elif [ "$1" == "reconnect" ]; then
	if [ "$modem_model" == "2" ]; then
		at_ret=`/usr/sbin/modem_at.sh '+GTRNDIS?' "$modem_reg_time" 2>&1`
		#echo $at_ret >> /tmp/syslog.log
		ret=`echo -n "$at_ret" |grep "GTRNDIS: 1," |awk 'BEGIN{FS=","}{print $3}' |awk 'BEGIN{RS="\""}{print $1}' | grep "\." 2>/dev/null`
		#echo "ret="$ret
		if [ -z "$ret" ]; then
			echo "excute disconnect to connect script..."
			at_ret=`/usr/sbin/modem_at.sh '+CEREG?' $wait_time 2>&1`
			ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
			if [ -z "$ret" ]; then
				echo "49: Fail to get the CEREG from $modem_act_node."
				exit 49
			fi
			at_ret=`/usr/sbin/modem_at.sh '+GTRNDIS?' $wait_time 2>&1`
			ret=`echo -n "$at_ret" |grep "+GTRNDIS: 1,1" 2>/dev/null`
			if [ -z "$ret" ]; then
				echo "Fail to get the GTRNDIS from $modem_act_node. Try to re-connect"
				at_ret=`/usr/sbin/modem_at.sh '+GTRNDIS=1,1' "$modem_reg_time" 2>&1`
				ret=`echo -n "$at_ret" |grep "OK" 2>/dev/null`
				if [ -z "$ret" ]; then
					echo "50: Fail to re-connect the network from $modem_act_node."
					exit 50
				fi
			fi
		fi
	fi
	echo "done."
fi
