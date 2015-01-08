#!/bin/bash


start_vms() {
  # Send it to the VM
  VBoxManage list vms |grep "IE" |grep "Win" |sed 's/"//g' |awk '{print $1 " - " $3 }' | while read vm_name
  do
    VBoxManage list runningvms | grep "$vm_name" >/dev/null

    #echo "$vm_name '$?'"
    if [ $? -eq 0 ]
    then
      echo "$vm_name is already running"
    else
      echo "Starting $vm_name"
      VBoxManage startvm "$vm_name"
    fi
  done
}

stop_vms() {
  # Send it to the VM
  VBoxManage list runningvms |grep "IE" |grep "Win" |sed 's/"//g' |awk '{print $1 " - " $3 }' | while read vm_name
  do
    echo $vm_name
    VBoxManage guestcontrol "${vm_name}" execute --image "C:/Windows/system32/shutdown.exe" --username 'IEUser' --password 'Passw0rd!' -- /t 5 /s /f
  done
}

reboot_vms() {
  # Send it to the VM
  VBoxManage list runningvms |grep "IE" |grep "Win" |sed 's/"//g' |awk '{print $1 " - " $3 }' | while read vm_name
  do
    VBoxManage guestcontrol "${vm_name}" execute --image "C:/Windows/system32/shutdown.exe" --username 'IEUser' --password 'Passw0rd!' -- /t 5 /r /f
  done
}

list_vms() {
  # Send it to the VM
  VBoxManage list vms |grep "IE" |grep "Win" |sed 's/"//g' |awk '{print $1 " - " $3 }' | while read vm_name
  do
    VBoxManage list runningvms | grep "$vm_name" >/dev/null

    #echo "$vm_name '$?'"
    if [ $? -eq 0 ]
    then
      echo "'$vm_name' - running"
    else
      echo "'$vm_name' - stopped"
    fi
  done
}

update_hub_ip() {
  # Create a hosts file
  ifconfig en0 | grep "inet " |awk '{print $2 " hubhost"}' > /tmp/hosts
  VBoxManage list runningvms |grep "IE" |grep "Win" |sed 's/"//g' |awk '{print $1 " - " $3 }' | while read vm_name
  do
    VBoxManage guestcontrol "${vm_name}" copyto "/tmp/hosts" "C:/Windows/System32/drivers/etc/hosts" --username 'IEUser' --password 'Passw0rd!'
    VBoxManage guestcontrol "${vm_name}" execute --image "C:/Windows/system32/shutdown.exe" --username 'IEUser' --password 'Passw0rd!' -- /t 5 /r /f
  done
}

case "$1" in
  start)
    start_vms
    ;;
  stop)
    stop_vms
    ;;
  reboot)
    reboot_vms
    ;;
  list)
    list_vms
    ;;
  update_hosts)
    update_hub_ip
    ;;
  *)
    echo "$0 start|stop|reboot|list|update_hosts"
    echo
    echo "update_hosts updates the hosts file to have this machine's IP address as the hub's IP"
    exit 1
esac
