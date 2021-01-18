#!/bin/sh
# /usr/local/etc/poudriere.d/hooks/jail.sh

status="${1}"

# ISO's to mount from a central location to the master mount directory for all
# jails to access.
readonly ISO_DIR=/usr/ports/distfiles/ISO
readonly ISOs="NWN-diamond.iso SSAM-TSE.iso UT.iso"
readonly master_mnt=${MASTERMNT}/mnt

# Sets that require ISO or nullfs mounts.
readonly mount_sets="workstation"

# Package directories from other jails to mount.  Useful when building amd64
# packages from i386 packages (i.e., i386-wine[-devel]).
readonly pkg_jails="fbsd12-i386-default-i386-wine"

# Create md mounted ISO.
mdmount() {
	local iso_file=${ISO_DIR}/${1}
	local iso_mnt=${master_mnt}/${1}
	if [ -e ${iso_file} ]
	then
		mkdir ${iso_mnt}
		mount -t cd9660 /dev/$(mdconfig ${iso_file}) ${iso_mnt}
	fi
}

# Mount host directory into master_mnt directory for the builder.sh hook to
# include.
nullmount() {
	local pkg_dir="${PACKAGES_ROOT}/../${1}/All"
	local null_mnt="${master_mnt}/${1}"
	if [ -d ${pkg_dir} ]
	then
		mkdir -p ${null_mnt}
		mount -t nullfs -o ro ${pkg_dir} ${null_mnt}
	fi
}

# Destroy md mounted ISO.
umdmount() {
	# In case there are multiple md devices pointing to the file, use the
	# last one in the list.
	local iso_file=${ISO_DIR}/${1}
	local md_dev=$(mdconfig -l -f ${iso_file} | awk '{print $NF}')
	if [ -n "${md_dev}" ]
	then
		md_dev="/dev/${md_dev}"
		iso_mnt=$(mount -t cd9660 | grep "^${md_dev} " | cut -d' ' -f3)
		umount ${md_dev}
		mdconfig -d -u ${md_dev}
		rmdir ${iso_mnt}
	fi
}

# Unmount null host directory from master_mnt directory
unullmount() {
	local null_mnt="${master_mnt}/${1}"
	if [ -d ${null_mnt} ]
	then
		umount ${null_mnt}
		rmdir ${null_mnt}
	fi
}

# Mount or unmount images into jail for sets that need them.
for st in ${mount_sets}; do
	if [ "${SETNAME}" = "${st}" ]; then
		if [ "${status}" = "start" ]; then
			for iso in ${ISOs}; do
				mdmount ${iso}
			done
			for pj in ${pkg_jails}; do
				nullmount ${pj}
			done
		elif [ "${status}" = "stop" ]; then
			for pj in ${pkg_jails}; do
				unullmount ${pj}
			done
			for iso in ${ISOs}; do
				umdmount ${iso}
			done
		fi
	fi
done
