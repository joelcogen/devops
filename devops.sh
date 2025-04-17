#!/bin/bash -e

if [ -f "$(dirname "$0")/.env" ]; then
  source "$(dirname "$0")/.env"
fi

NAME=""
IP=""
USERNAME=""
PRIVATE_KEY_PATH=""
HOSTS=()
PREV_LINES=0

erase_lines() {
  for ((i=0; i<$PREV_LINES; i++)); do
    echo -en "\033[1A\033[K"
  done
  PREV_LINES=0
}

read_hosts() {
  HOSTS=()
  while IFS= read -r line; do
    if [[ $line == Host* ]]; then
      host=$(echo $line | cut -d " " -f 2)
      HOSTS+=("$host:")  # Add colon as a placeholder for IP
    elif [[ $line =~ ^[[:space:]]*HostName ]]; then
      hostname=$(echo $line | awk '{print $NF}')
      # Update the last element with the hostname
      last_index=$((${#HOSTS[@]} - 1))
      HOSTS[$last_index]="${HOSTS[$last_index]}$hostname"
    fi
  done < ~/.ssh/config
  HOSTS+=("+ Add a new host:")
}

read_host() {
  PRIVATE_KEY_PATH=''
  USERNAME=`whoami`
  in_current=false
  while IFS= read -r line; do
    if [[ $line == Host* ]]; then
      host=$(echo $line | cut -d " " -f 2)
      if [ "$host" == "$NAME" ]; then
        in_current=true
      else
        in_current=false
      fi
    elif [[ $line =~ ^[[:space:]]*User ]]; then
      hostname=$(echo $line | awk '{print $NF}')
      if [ "$in_current" = true ]; then
        USERNAME=$hostname
      fi
    elif [[ $line =~ ^[[:space:]]*IdentityFile ]]; then
      filepath=$(echo $line | awk '{print $NF}')
      if [ "$in_current" = true ]; then
        PRIVATE_KEY_PATH=$filepath
      fi
    fi
  done < ~/.ssh/config
}

choose_host() {
  read_hosts
  local selected=0
  local key=""

  while true; do
    erase_lines
    echo -e "\n\033[0;31mjole's devops script\033[0m"
    echo -e "\033[0;33m\nSelect host:\033[0m\n"

    for i in "${!HOSTS[@]}"; do
      IFS=':' read -r host ip <<< "${HOSTS[$i]}"
      if [ $i -eq $selected ]; then
        printf "\033[0;34m> %-30s %s\033[0m\n" "$host" "$ip"
      else
        printf "  %-30s %s\n" "$host" "$ip"
      fi
    done
    echo
    PREV_LINES=$(( ${#HOSTS[@]} + 6 ))

    read -rsn1 key

    case "$key" in
      A)
        # Up arrow
        ((selected--))
        if [ $selected -lt 0 ]; then
          selected=$((${#HOSTS[@]} - 1))
        fi
        ;;
      B)
        # Down arrow
        ((selected++))
        if [ $selected -ge ${#HOSTS[@]} ]; then
          selected=0
        fi
        ;;
      q)
        break
        ;;
      "")
        # Enter key
        IFS=':' read -r NAME IP <<< "${HOSTS[$selected]}"
        if [[ "${NAME}" = "+ Add a new host" ]]; then
          erase_lines
          add_to_local_config
          read_hosts
        else
          read_host
          display_menu
        fi
        ;;
    esac
  done
}

display_menu() {
  local options=("Connect..."
                "Check status"
                "Basic setup"
                "Install Docker"
                "Install Netdata agent"
                "Uninstall Netdata agent"
                "Install BetterStack (Vector/Docker)"
                "Open port..."
                "Test ports"
                "Add SSH key..."
                "Upgrade apt"
                "Back")
  local selected=0
  local key=""

  while true; do
    host_title
    echo -e "\033[0;33mSelect action:\033[0m\n"

    for i in "${!options[@]}"; do
      if [ $i -eq $selected ]; then
        echo -e "\033[0;34m> ${options[$i]}\033[0m"
      else
        echo "  ${options[$i]}"
      fi
    done
    echo

    PREV_LINES=$(( $PREV_LINES + 15 ))

    read -rsn1 key

    case "$key" in
      A)
        # Up arrow
        ((selected--))
        if [ $selected -lt 0 ]; then
          selected=$((${#options[@]} - 1))
        fi
        ;;
      B)
        # Down arrow
        ((selected++))
        if [ $selected -ge ${#options[@]} ]; then
          selected=0
        fi
        ;;
      q)
        break
        ;;
      "")
        # Enter key
        case $selected in
          0) host_title; display_menu_ssh;;
          1) host_title; check_status; finish;;
          2) host_title; basic_setup; finish;;
          3) host_title; install_docker; finish;;
          4) host_title; install_netdata; finish;;
          5) host_title; uninstall_netdata; finish;;
          6) host_title; install_betterstack; finish;;
          7) host_title; display_menu_ports;;
          8) host_title; test_ports;;
          9) host_title; display_menu_ssh_key;;
          10) host_title; upgrade_apt; finish;;
          11) break;;
        esac
        ;;
    esac
  done
}

finish() {
  echo -e "\n\033[0;33mPress any key to continue\033[0m"
  read -n 1 -s
  PREV_LINES=0
}

host_title() {
  erase_lines

  line_name="$NAME"
  line_hostname=""
  if [ -n "$IP" ]; then
    line_hostname="Hostname: $IP"
  fi
  line_user="User:     $USERNAME"
  line_identity=""
  if [ -n "$PRIVATE_KEY_PATH" ]; then
    line_identity="Identity: $PRIVATE_KEY_PATH"
  fi
  # get length of each line and find max
  max_length=0
  for line in "$line_name" "$line_hostname" "$line_user" "$line_identity"; do
    if [ ${#line} -gt $max_length ]; then
      max_length=${#line}
    fi
  done
  # make each line the same length
  line_name=$(printf '%-*s' $max_length "$line_name")
  line_hostname=$(printf '%-*s' $max_length "$line_hostname")
  line_user=$(printf '%-*s' $max_length "$line_user")
  line_identity=$(printf '%-*s' $max_length "$line_identity")
  # create line of dashes
  dashes=$(printf '%*s' $max_length '')
  dashes=${dashes// /-}

  echo -e "\n\033[0;31m| $line_name |\033[0m"
  echo -e "\033[0;31m|-$dashes-|\033[0m"
  if [ -n "$IP" ]; then
    echo -e "\033[0;31m| $line_hostname |\033[0m"
    PREV_LINES=$(( $PREV_LINES + 1 ))
  fi
  echo -e "\033[0;31m| $line_user |\033[0m"
  if [ -n "$PRIVATE_KEY_PATH" ]; then
    echo -e "\033[0;31m| $line_identity |\033[0m"
    PREV_LINES=$(( $PREV_LINES + 1 ))
  fi
  echo
  PREV_LINES=$(( $PREV_LINES + 5 ))
}

add_to_local_config() {
  echo -en "\033[0;33mName (*):    \033[0m"
  read NAME
  echo -en "\033[0;33mHostname:    \033[0m"
  read IP
  echo -en "\033[0;33mUser (*):    \033[0m"
  read USERNAME
  PRIVATE_KEY_PATH=""
  echo -en "\033[0;33mPrivate key: \033[0m"
  read PRIVATE_KEY_PATH
  local lines=2
  if [ -n "$PRIVATE_KEY_PATH" ]; then
    if [ ! -f $(eval echo "$PRIVATE_KEY_PATH") ]; then
      echo -e "\033[0;31mError: File not found at $PRIVATE_KEY_PATH\033[0m"
      NAME=""
      IP=""
      finish
      return
    fi
    if ! ssh-keygen -l -f $(eval echo "$PRIVATE_KEY_PATH") &>/dev/null; then
      echo -e "\033[0;31mError: Invalid SSH private key file\033[0m"
      NAME=""
      IP=""
      finish
      return
    fi
  fi
  echo "Host $NAME" >> ~/.ssh/config
  if [ -n "$IP" ]; then
    echo "  HostName $IP" >> ~/.ssh/config
    lines+=1
  fi 
  echo "  User $USERNAME" >> ~/.ssh/config
  if [ -n "$PRIVATE_KEY_PATH" ]; then
    echo "  IdentityFile $PRIVATE_KEY_PATH" >> ~/.ssh/config
    lines+=1
  fi
  echo -e "\033[0;32m$(tail -n$lines ~/.ssh/config)\033[0m"
  finish
  display_menu
}

check_status() {
  # SSH
  echo -e "\033[0;33m⏱ SSH root\033[0m"
  if ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=5 root@$NAME "exit" &> /dev/null; then
    echo -en "\033[1A\033[K"
    echo -e "\033[0;32m✔ SSH root\033[0m"
  else
    echo -en "\033[1A\033[K"
    echo -e "\033[0;31m✘ SSH root\033[0m"
    return
  fi
  echo -e "\033[0;33m⏱ SSH $USERNAME\033[0m"
  if ssh -o BatchMode=yes -o ConnectTimeout=5 $NAME "exit" &> /dev/null; then
    echo -en "\033[1A\033[K"
    echo -e "\033[0;32m✔ SSH $USERNAME\033[0m"
  else
    echo -en "\033[1A\033[K"
    echo -e "\033[0;31m✘ SSH $USERNAME\033[0m"
  fi

  # UFW
  echo -e "\033[0;33m⏱ UFW\033[0m"
  ufw_output=$(ssh root@$NAME "ufw status verbose")
  if echo "$ufw_output" | grep -q "^Status: active"; then
    echo -en "\033[1A\033[K"
    echo -en "\033[0;32m✔ UFW\033[0m"
    if echo "$ufw_output" | grep -q "^Default: deny (incoming)"; then
      echo -e "\033[0;32m  ✔ Default: deny incoming\033[0m"
    else
      echo -e "\033[0;31m  ✘ Default: deny incoming\033[0m"
    fi
    echo "$ufw_output" | sed '1,/^--  /d'
  else
    echo -en "\033[1A\033[K"
    echo -e "\033[0;31m✘ UFW\033[0m"
  fi

  # Docker
  echo -e "\033[0;33m⏱ Docker\033[0m"
  docker_output=$(ssh root@$NAME "docker -v" 2>/dev/null) || docker_output=""
  if echo "$docker_output" | grep -q "Docker version"; then
    echo -en "\033[1A\033[K"
    echo -e "\033[0;32m✔ Docker\033[0m"

    echo -e "\033[0;33m⏱ ufw-docker\033[0m"
    ufwdocker_output=$(ssh root@$NAME "ufw-docker check" 2>/dev/null) || ufwdocker_output=""
    if [ -n "$ufwdocker_output" ]; then
      echo -en "\033[1A\033[K"
      echo -e "\033[0;32m✔ ufw-docker\033[0m"
    else
      echo -en "\033[1A\033[K"
      echo -e "\033[0;31m✘ ufw-docker\033[0m"
    fi
  else
    echo -en "\033[1A\033[K"
    echo -e "\033[0;31m✘ Docker\033[0m"
  fi

  # Netdata
  echo -e "\033[0;33m⏱ Netdata\033[0m"
  netdata_output=$(ssh root@$NAME "systemctl status netdata" 2>/dev/null) || netdata_output=""
  if echo "$netdata_output" | grep -q "Active: active"; then
    echo -en "\033[1A\033[K"
    echo -e "\033[0;32m✔ Netdata\033[0m"
  else
    echo -en "\033[1A\033[K"
    echo -e "\033[0;31m✘ Netdata\033[0m"
  fi
}

basic_setup() {
  # Setup UFW: Deny everything by default, allow SSH
  echo -e "\033[0;34m\n>>> UFW <<<\n\033[0m"
  ssh -o StrictHostKeyChecking=accept-new root@$NAME "ufw allow OpenSSH && \
    ufw default deny incoming && \
    ufw --force enable && \
    ufw status verbose"

  # Create user "app" without password, and add authorized keys
  echo -e "\033[0;34m>>> CREATE USER $USERNAME <<<\n\033[0m"
  ssh root@$NAME "id -u $USERNAME >/dev/null 2>&1 || adduser --gecos '' --disabled-password $USERNAME && \
    su $USERNAME -c 'mkdir ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys'"
  if [ -z "$PRIVATE_KEY_PATH" ]; then
    PRIVATE_KEY_PATH=~/.ssh/id_rsa
  fi
  scp $(eval echo "$PRIVATE_KEY_PATH").pub root@$NAME:/home/$USERNAME/.ssh/authorized_keys
  ssh root@$NAME "chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/authorized_keys && \
    su $USERNAME -c 'chmod 600 ~/.ssh/authorized_keys'"
  ssh $NAME "echo 'SSH connection successful'"

  # Allow low ports for app user, because Docker will run there and might need them
  echo -e "\033[0;34m\n>>> ALLOW LOW PORTS FOR USERS <<<\n\033[0m"
  ssh root@$NAME "echo 'net.ipv4.ip_unprivileged_port_start=80' >> /etc/sysctl.conf && \
    sysctl -p"
} 

install_docker() {
  # Install Docker
  echo -e "\033[0;34m\n>>> DOCKER <<<\n\033[0m"
  ssh root@$NAME "DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io > /dev/null && \
    usermod -a -G docker $USERNAME"
  ssh $NAME "docker -v"

  # Install UFW-Docker and allow in on br-+ (docker bridge interfaces created by Kamal)
  ssh root@$NAME "wget -O /usr/local/bin/ufw-docker https://raw.githubusercontent.com/chaifeng/ufw-docker/17e6047590e14d3ff1dc6c01f0b4755d115fc078/ufw-docker && \
    chmod +x /usr/local/bin/ufw-docker && \
    ufw-docker install && \
    ufw allow in on br-+ && \
    systemctl restart ufw"
}

install_netdata() {
  if [ -n "$NETDATA_DESTINATION" ] && [ -n "$NETDATA_API_KEY" ]; then
    echo -en "\033[0;33mNetdata destination (\033[0;37m$NETDATA_DESTINATION\033[0;33m): \033[0m"
    read NETDATA_DESTINATION_INPUT
    NETDATA_DESTINATION=${NETDATA_DESTINATION_INPUT:-$NETDATA_DESTINATION}
    echo -en "\033[0;33mNetdata api key (\033[0;37m$NETDATA_API_KEY\033[0;33m): \033[0m"
    read NETDATA_API_KEY_INPUT
    NETDATA_API_KEY=${NETDATA_API_KEY_INPUT:-$NETDATA_API_KEY}
  else
    echo -en "\033[0;33mNetdata destination: \033[0m"
    read NETDATA_DESTINATION
    echo -en "\033[0;33mNetdata api key: \033[0m"
    read NETDATA_API_KEY
  fi

  ssh root@$NAME "curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh && \
    DEBIAN_FRONTEND=noninteractive sh /tmp/netdata-kickstart.sh --stable-channel && \
    cd /etc/netdata 2>/dev/null || cd /opt/netdata/etc/netdata && \
    echo -e '[stream]\n    enabled = yes\n    destination = $NETDATA_DESTINATION:19999\n    api key = $NETDATA_API_KEY' > stream.conf && \
    cat stream.conf && \
    systemctl restart netdata"

  echo -e "NETDATA_DESTINATION=$NETDATA_DESTINATION\nNETDATA_API_KEY=$NETDATA_API_KEY\nBETTERSTACK_KEY=$BETTERSTACK_KEY" > "$(dirname "$0")/.env"
}

uninstall_netdata() {
  echo -e "\033[0;34m>>> UNINSTALLING NETDATA <<<\n\033[0m"
  ssh root@$NAME "systemctl stop netdata || true && \
    systemctl disable netdata || true && \
    apt-get remove -y --autoremove netdata && \
    rm -rf /etc/netdata /var/lib/netdata /var/cache/netdata /var/log/netdata /opt/netdata && \
    userdel netdata 2>/dev/null || true && \
    find / -name '*netdata*' -type d -exec rm -rf {} + 2>/dev/null || true && \
    dpkg-statoverride --list | grep netdata | awk '{print \$4}' | xargs -I {} dpkg-statoverride --remove {}"
}

install_betterstack() {
  if [ -n "$BETTERSTACK_KEY" ]; then
    echo -en "\033[0;33mBetterStack key (\033[0;37m$BETTERSTACK_KEY\033[0;33m): \033[0m"
    read BETTERSTACK_KEY_INPUT
    BETTERSTACK_KEY=${BETTERSTACK_KEY_INPUT:-$BETTERSTACK_KEY}
  else
    echo -en "\033[0;33mBetterStack key: \033[0m"
    read BETTERSTACK_KEY
  fi

  ssh root@$NAME "curl -sSL https://telemetry.betterstack.com/setup-vector/docker/$BETTERSTACK_KEY -o /tmp/setup-vector.sh && \
    echo \n | bash /tmp/setup-vector.sh && \
    usermod -a -G docker vector || true && \
    systemctl restart vector"

  echo -e "REBOOT_REQUIRED=\$([ -f /var/run/reboot-required ] && echo 'REBOOT REQUIRED' || (UPDATES=\$(apt-get upgrade -s | grep '^Inst' | cut -d' ' -f2); [ -z "\$UPDATES" ] && echo 'UP TO DATE' || echo 'UPDATES AVAILABLE'))\ncurl -X POST https://in.logs.betterstack.com -H 'Authorization: Bearer $BETTERSTACK_KEY' -H 'Content-Type: application/json' -d \"{\\\"message\\\":\\\"\$REBOOT_REQUIRED\\\",\\\"updates_required\\\":\\\"\$REBOOT_REQUIRED\\\",\\\"docker\\\":{\\\"host\\\":\\\"\$(hostname)\\\"}}\"" > "$(dirname "$0")/reboot_required.sh"
  scp "$(dirname "$0")/reboot_required.sh" root@$NAME:/root/reboot_required.sh
  rm "$(dirname "$0")/reboot_required.sh"
  ssh root@$NAME "chmod +x /root/reboot_required.sh && \
    /root/reboot_required.sh && \
    (crontab -l 2>/dev/null; echo '0 0 * * 0 /root/reboot_required.sh') | crontab -"

  echo -e "NETDATA_DESTINATION=$NETDATA_DESTINATION\nNETDATA_API_KEY=$NETDATA_API_KEY\nBETTERSTACK_KEY=$BETTERSTACK_KEY" > "$(dirname "$0")/.env"
}

test_ports() {
  local ports=(22 80 443 3000 5432 6379 19999)
  local ip_to_test=$IP
  if [ -z "$ip_to_test" ]; then
    ip_to_test=$NAME
  fi
  for port in "${ports[@]}"; do
    nc -zG2 $ip_to_test $port &> /dev/null && echo -e "\033[0;32m$port: open\033[0m" || echo -e "\033[0;31m$port: closed\033[0m"
  done

  while true; do
    echo -en "\n\033[0;33mOther port (or press Enter to finish): \033[0m"
    read additional_port
    if [ -z "$additional_port" ]; then
      break
    fi
    nc -zG2 $IP $additional_port &> /dev/null && echo -e "\033[0;32m$additional_port: open\033[0m" || echo -e "\033[0;31m$additional_port: closed\033[0m"
  done

  PREV_LINES=0
}

display_menu_ports() {
  local options=("On host" "On container" "Back")
  local selected=0
  local key=""

  while true; do
    host_title
    echo -e "\033[0;33mSelect action:\033[0m\n"

    for i in "${!options[@]}"; do
      if [ $i -eq $selected ]; then
        echo -e "\033[0;34m> ${options[$i]}\033[0m"
      else
        echo "  ${options[$i]}"
      fi
    done
    echo

    PREV_LINES=$(( $PREV_LINES + 6 ))

    read -rsn1 key

    case "$key" in
      A)
        # Up arrow
        ((selected--))
        if [ $selected -lt 0 ]; then
          selected=$((${#options[@]} - 1))
        fi
        ;;
      B)
        # Down arrow
        ((selected++))
        if [ $selected -ge ${#options[@]} ]; then
          selected=0
        fi
        ;;
      q)
        break
        ;;
      "")
        # Enter key
        case $selected in
          0) host_title; open_host_port; finish;;
          1) host_title; open_container_port; finish;;
          2) break;;
        esac
        ;;
    esac
  done
}

open_host_port() {
  echo -en "\033[0;33mPort: \033[0m"
  read port
  ssh root@$NAME "ufw allow $port && ufw status"
}

open_container_port() {
  echo -e "\033[0;33m⏱ Listing containers...\033[0m"

  local options=()
  while IFS= read -r line; do
    options+=("$line")
  done < <(ssh $NAME "docker ps --format '{{.Names}}'")
  local selected=0
  local key=""

  while true; do
    host_title
    echo -e "\033[0;33mSelect container:\033[0m\n"

    for i in "${!options[@]}"; do
      if [ $i -eq $selected ]; then
        echo -e "\033[0;34m> ${options[$i]}\033[0m"
      else
        echo "  ${options[$i]}"
      fi
      PREV_LINES=$(( $PREV_LINES + 1 ))
    done
    PREV_LINES=$(( $PREV_LINES + 3 ))

    echo
    read -rsn1 key

    case "$key" in
      A)
        # Up arrow
        ((selected--))
        if [ $selected -lt 0 ]; then
          selected=$((${#options[@]} - 1))
        fi
        ;;
      B)
        # Down arrow
        ((selected++))
        if [ $selected -ge ${#options[@]} ]; then
          selected=0
        fi
        ;;
      q)
        break
        ;;
      "")
        # Enter key
        container="${options[$selected]}"
        echo -en "\033[0;33mPort: \033[0m"
        read port
        ssh root@$NAME "ufw-docker allow $container $port/tcp && ufw status"
        break
        ;;
    esac
  done
}

display_menu_ssh(){
  local options=("$USERNAME" "root" "Back")
  local selected=0
  local key=""

  while true; do
    host_title
    echo -e "\033[0;33mSelect user:\033[0m\n"

    for i in "${!options[@]}"; do
      if [ $i -eq $selected ]; then
        echo -e "\033[0;34m> ${options[$i]}\033[0m"
      else
        echo "  ${options[$i]}"
      fi
    done
    echo

    PREV_LINES=$(( $PREV_LINES + 6 ))

    read -rsn1 key

    case "$key" in
      A)
        # Up arrow
        ((selected--))
        if [ $selected -lt 0 ]; then
          selected=$((${#options[@]} - 1))
        fi
        ;;
      B)
        # Down arrow
        ((selected++))
        if [ $selected -ge ${#options[@]} ]; then
          selected=0
        fi
        ;;
      q)
        break
        ;;
      "")
        # Enter key
        case $selected in
          0) host_title; ssh $NAME; break;;
          1) host_title; ssh root@$NAME; break;;
          2) break;;
        esac
        ;;
    esac
  done
}

display_menu_ssh_key(){
  local options=("$USERNAME" "root" "Back")
  local selected=0
  local key=""

  while true; do
    host_title
    echo -e "\033[0;33mSelect user:\033[0m\n"

    for i in "${!options[@]}"; do
      if [ $i -eq $selected ]; then
        echo -e "\033[0;34m> ${options[$i]}\033[0m"
      else
        echo "  ${options[$i]}"
      fi
    done
    echo

    PREV_LINES=$(( $PREV_LINES + 6 ))

    read -rsn1 key

    case "$key" in
      A)
        # Up arrow
        ((selected--))
        if [ $selected -lt 0 ]; then
          selected=$((${#options[@]} - 1))
        fi
        ;;
      B)
        # Down arrow
        ((selected++))
        if [ $selected -ge ${#options[@]} ]; then
          selected=0
        fi
        ;;
      q)
        break
        ;;
      "")
        # Enter key
        if [ $selected -eq 2 ]; then
          break
        fi

        echo -en "\033[0;33mPublic key path: \033[0m"
        read public_key_path
        if [ ! -f "$public_key_path" ]; then
          echo -e "\033[0;31mError: File not found at $public_key_path\033[0m"
          finish
          break
        fi
        if ! ssh-keygen -l -f "$public_key_path" &>/dev/null; then
          echo -e "\033[0;31mError: Invalid SSH public key file\033[0m"
          finish
          break
        fi
        case $selected in
          0) host_title; ssh-copy-id -i "$public_key_path" $USERNAME@$NAME && ssh -q -i "$public_key_path" $NAME "echo 'SSH connection successful'"; finish; break;;
          1) host_title; ssh-copy-id -i "$public_key_path" root@$NAME && ssh -q -i "$public_key_path" root@$NAME "echo 'SSH connection successful'"; finish; break;;
        esac
        ;;
    esac
  done
}

upgrade_apt() {
  echo -e "\033[0;34mRunning containers:\033[0m"
  local CONTAINERS=$(ssh -o StrictHostKeyChecking=accept-new root@$NAME "docker ps --format '{{.Names}}'")
  echo "$CONTAINERS"

  echo -e "\033[0;34mUpgrading...\033[0m"
  ssh root@$NAME "DEBIAN_FRONTEND=noninteractive apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y"

  if ssh root@$NAME "[ -f /var/run/reboot-required ] && reboot"; then
    echo -e "\033[0;34mWaiting for server to reboot...\033[0m"
    sleep 5
    local OK=false
    while ! $OK; do
      sleep 5
      ssh root@$NAME "echo 'OK'" && OK=true
    done
  else
    echo "No reboot needed"
  fi

  echo -e "\033[0;34mRunning containers after upgrade:\033[0m"
  local NEW_CONTAINERS=$(ssh root@$NAME "docker ps --format '{{.Names}}'")
  echo "$NEW_CONTAINERS"
  if [ "$NEW_CONTAINERS" != "$CONTAINERS" ]; then
    echo -e "\033[0;31mWarning: Container list changed after reboot!\033[0m"
    echo -e "\033[0;31mBefore:\n$CONTAINERS\033[0m"
    echo -e "\033[0;31mAfter:\n$NEW_CONTAINERS\033[0m"
  else
    echo -e "\n\033[0;32mSuccess\033[0m"
  fi
}

choose_host