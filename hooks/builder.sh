#!/bin/sh
# /usr/local/etc/poudriere.d/hooks/builder.sh

status="${1}"
id="${2}"
mntpath="${3}"
ref=$(dirname ${mntpath})/ref

# Sets that require ISO or nullfs mounts.
readonly mount_sets="workstation"

for st in ${mount_sets}; do
	if [ "${SETNAME}" = "${st}" ]; then
		if [ "${status}" = "start" ]; then
			# null mount directories mounted in reference jail.
			if [ -d ${mntpath}/mnt ]; then
				for p in ${mntpath}/mnt/*
				do
					p=$(basename ${p})
					mount -t nullfs -o ro ${ref}/mnt/${p} \
						${mntpath}/mnt/${p}
					done
			fi
		elif [ "${status}" = "stop" ]
		then
			# NOTE:  runs prior to the start and not after.  Bug?
		fi
	fi
done
