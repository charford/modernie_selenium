#!/bin/bash

# Debug
#set -x
#set -e

script=$0

source config.sh

# Intention - create a script where you can run along the lines of:
#  run.sh ie8 on xp
# Possibly making the OS optional

list_vms() {
  VBoxManage list vms |grep "IE" |grep "Win" |sed 's/"//g' |awk '{print "run.sh " $1 " on " $3}'
}

show_help() {
  echo "Usage: $script <browser> on <operating system>"
  echo "e.g. $script IE8 on Win7"
  echo "Also:";
  echo "  $script help"; echo "    This message"
  echo "  $script list"; echo "    List all combos of browser and OS"
}


# Basic-Checks.
if [ "${1}" = "help" -o "${1}" = "--help" ]; then
  show_help
  exit 0
fi

if [ "${1}" = "list" ]; then
  list_vms
  exit 0
fi

if [ -z "${1}" ]; then
  echo "Browser is missing..."
  show_help
  exit 1
fi

if [ -z "${3}" ]; then
  echo "OS is missing..."
  exit 1
fi

if [ ! $(which VBoxManage) ]; then
  echo "VBoxManage not found..."
  exit 1
fi

if [ "${USER}" != "${vbox_user}" ]; then
  echo "This script must be run by user \'${vbox_user}\'..."
  exit 1
fi

vm_name="${1} - ${3}"
VBoxManage list vms | grep -e "${vm_name}" >/dev/null 2>&1
if [ $? -eq 1 ] ; then
  echo "VM ${vm_name} not found..."
  exit 1
fi

fatal=False
error=False
warning=False


copyto() {
  # $1 = filename, $2 = source directory, $3 destination directory
  if [ ! -f "${2}${1}" ]
  then
    echo "Local file '${2}${1}' doesn't exist"
  fi
  execute "VBoxManage guestcontrol \"${vm_name}\" copyto \"${2}${1}\" \"${3}${1}\" --username 'IEUser' --password 'Passw0rd!'"
}


# Reset VM's /etc/hosts file
set_network_config() {
  # Create a hosts file
  ifconfig en0 | grep "inet " |awk '{print $2 " hubhost"}' > /tmp/hosts
  # Send it to the VM
  copyto hosts /tmp/ "C:/Windows/System32/drivers/etc/hosts"
}


# Loop VBoxManage guestcontrol commands as they are unreliable.
execute() {
  counter=0
  while [ $counter -lt 10 ]; do

    echo "Running $@"
    bash -c "$@"

    if [ "$?" = "0" ]; then
      guestcontrol_error=0
      break
    else
      guestcontrol_error=1
    fi
    let counter=counter+1
    sleep 10
  done

  if [ "$guestcontrol_error" = "0" ]; then
    return 0
  else
    chk skip 1 "Error running $@"
  fi
}

# Write Logfile and STDOUT.
log() {
  echo ${1} | tee -a "${log_path}${vm_pretty_name}.log"
}

# Error-Handling.
chk() {
  if [ "${2}" != "0" ]; then
    if [ "${1}" = "fatal" ]; then
      log "[FATAL] ${3}"
      fatal=True
      exit ${2}
    fi
    if [ "${1}" = "skip" ]; then
      log "[WARNING] ${3}"
      warning=True
    fi
    if [ "${1}" = "error" ]; then
      log "[ERROR] ${3}"
      error=True
    fi
  else
    log "[OK]"
  fi
}

# Check if the VM is still running.
check_shutdown() {
  counter=0
  echo -n "Waiting for shutdown"
  while $(VBoxManage showvminfo "${vm_name}" | grep -q 'running'); do
    echo -n "."
    sleep 1
    let counter=counter+1
    if [ ${counter} -ge 120 ]; then
      chk skip 1 "Unable to shutdown/restart..."
      break
    fi
  done
  echo ""
  waiting 5
}

# Print some dots.
waiting() {
  counter=0
  echo -n "Waiting ${1} seconds"
  while [ ${counter} -lt ${1} ]; do
    echo -n "."
    let counter=counter+1
    sleep 1
  done
  echo ""
}

# Start the VM; Wait some seconds afterwards to give the VM time to start up completely.
start_vm() {
  log "Starting VM ${vm_name}..."
  VBoxManage startvm "${vm_name}"
  #--type headless
  chk fatal $? "Could not start VM"
  waiting 60
  set_network_config
}

# Reboot the VM; Ensure to wait some time after sending the reboot-Command so that the machine can start up before other actions will applied.
# shutdown.exe is used because VBox ACPI-Functions are sometimes unreliable with XP-VMs.
reboot_vm() {
  log "Rebooting..."
  execute "VBoxManage guestcontrol \"${vm_name}\" execute --image C:/Windows/system32/shutdown.exe --username 'IEUser' --password 'Passw0rd!' -- /t 5 /r /f"
  chk skip $? "Could not reboot"
  waiting 90
}

# Shutdown the VM and control the success via showvminfo; shutdown.exe is used because VBox ACPI-Functions are sometimes unreliable with XP-VMs.
shutdown_vm() {
  log "Shutting down..."
  execute "VBoxManage guestcontrol \"${vm_name}\" execute --image C:/Windows/system32/shutdown.exe --username 'IEUser' --password 'Passw0rd!' -- /t 5 /s /f"
  chk skip $? "Could not shut down"
  check_shutdown
}

start_vm
