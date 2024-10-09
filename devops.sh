#!/bin/bash -e

if [ -f "$(dirname "$0")/.env" ]; then
  source "$(dirname "$0")/.env"
fi

USERNAME=${USERNAME:-"app"}
NAME=""
IP=""
HOSTS=()

read_hosts() {
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
  HOSTS+=("+ Add a new host:NEW")
}

choose_host() {
  read_hosts
  local selected=0
  local key=""

  while true; do
    clear
    echo -e "\033[0;31m   _       _      _           _                                           _       _   \033[0m"
    echo -e "\033[0;31m  (_)     | |    ( )         | |                                         (_)     | |  \033[0m"
    echo -e "\033[0;31m   _  ___ | | ___|/ ___    __| | _____   _____  _ __  ___   ___  ___ _ __ _ _ __ | |_ \033[0m"
    echo -e "\033[0;31m  | |/ _ \| |/ _ \ / __|  / _\` |/ _ \ \ / / _ \| '_ \/ __| / __|/ __| '__| | '_ \| __|\033[0m"
    echo -e "\033[0;31m  | | (_) | |  __/ \__ \ | (_| |  __/\ V / (_) | |_) \__ \ \__ \ (__| |  | | |_) | |_ \033[0m"
    echo -e "\033[0;31m  | |\___/|_|\___| |___/  \__,_|\___| \_/ \___/| .__/|___/ |___/\___|_|  |_| .__/ \__|\033[0m"
    echo -e "\033[0;31m _/ |                                          | |                         | |        \033[0m"
    echo -e "\033[0;31m|__/                                           |_|                         |_|        \033[0m"
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
      "")
        # Enter key
        IFS=':' read -r NAME IP <<< "${HOSTS[$selected]}"
        if [[ "${IP}" = "NEW" ]]; then
          clear
          add_to_local_config
          read_hosts
        else
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
                "Open port..."
                "Test ports"
                "Add SSH key..."
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
      "")
        # Enter key
        case $selected in
          0) host_title; display_menu_ssh;;
          1) host_title; check_status; finish;;
          2) host_title; basic_setup; finish;;
          3) host_title; install_docker; finish;;
          4) host_title; install_netdata; finish;;
          5) host_title; display_menu_ports;;
          6) host_title; test_ports;;
          7) host_title; display_menu_ssh_key;;
          8) break;;
        esac
        ;;
    esac
  done
}

finish() {
  echo -e "\n\033[0;33mPress any key to continue\033[0m"
  read -n 1 -s
}

host_title() {
  clear
  echo -e "\033[0;31m| $NAME\n| $IP\033[0m\n"
}

add_to_local_config() {
  echo -en "\033[0;33mName: \033[0m"
  read NAME
  echo -en "\033[0;33mIP:   \033[0m"
  read IP
  echo -en "\033[0;33mPrivate key (or press Enter for default): \033[0m"
  read PRIVATE_KEY_PATH
  if [ -n "$PRIVATE_KEY_PATH" ]; then
    if [ ! -f "$PRIVATE_KEY_PATH" ]; then
      echo -e "\033[0;31mError: File not found at $PRIVATE_KEY_PATH\033[0m"
      NAME=""
      IP=""
      finish
      return
    fi
    if ! ssh-keygen -l -f "$PRIVATE_KEY_PATH" &>/dev/null; then
      echo -e "\033[0;31mError: Invalid SSH private key file\033[0m"
      NAME=""
      IP=""
      finish
      return
    fi
    echo "Host $NAME
  HostName $IP
  User $USERNAME
  IdentityFile $PRIVATE_KEY_PATH" >> ~/.ssh/config
  else
    echo "Host $NAME
  HostName $IP
  User $USERNAME" >> ~/.ssh/config
  fi
  echo -e "\033[0;32m$(tail -n3 ~/.ssh/config)\033[0m"
  finish
  display_menu
}

check_status() {
  # SSH
  echo -e "\033[0;33m⏱ SSH root\033[0m"
  if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$NAME "exit" &> /dev/null; then
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
  ssh root@$NAME "adduser --gecos '' --disabled-password $USERNAME && \
    su $USERNAME -c 'mkdir ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys'"
  scp ~/.ssh/id_rsa.pub root@$NAME:/home/$USERNAME/.ssh/authorized_keys
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

  # Install UFW-Docker
  ssh root@$NAME "wget -O /usr/local/bin/ufw-docker https://raw.githubusercontent.com/chaifeng/ufw-docker/17e6047590e14d3ff1dc6c01f0b4755d115fc078/ufw-docker && \
    chmod +x /usr/local/bin/ufw-docker && \
    ufw-docker install && \
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

  ssh root@$NAME "DEBIAN_FRONTEND=noninteractive bash <(curl -Ss https://get.netdata.cloud/kickstart.sh) && \
    echo -e '[stream]\n    enabled = yes\n    destination = $NETDATA_DESTINATION:19999\n    api key = $NETDATA_API_KEY' > /etc/netdata/stream.conf && \
    cat /etc/netdata/stream.conf && \
    systemctl restart netdata"

  echo -e "NETDATA_DESTINATION=$NETDATA_DESTINATION\nNETDATA_API_KEY=$NETDATA_API_KEY" > "$(dirname "$0")/.env"
}

test_ports() {
  local ports=(22 80 443 3000 5432 6379 19999)
  for port in "${ports[@]}"; do
    nc -zG2 $IP $port &> /dev/null && echo -e "\033[0;32m$port: open\033[0m" || echo -e "\033[0;31m$port: closed\033[0m"
  done

  while true; do
    echo -en "\n\033[0;33mOther port (or press Enter to finish): \033[0m"
    read additional_port
    if [ -z "$additional_port" ]; then
      break
    fi
    nc -zG2 $IP $additional_port &> /dev/null && echo -e "\033[0;32m$additional_port: open\033[0m" || echo -e "\033[0;31m$additional_port: closed\033[0m"
  done
}

display_menu_ports() {
  local options=("On subnet" "On internet" "Back")
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
      "")
        # Enter key
        case $selected in
          0) host_title; open_subnet_port; finish;;
          1) host_title; open_internet_port; finish;;
          2) break;;
        esac
        ;;
    esac
  done
}

open_subnet_port() {
  echo -en "\033[0;33mPort: \033[0m"
  read port
  ssh root@$NAME "ufw allow from 10.0.0.0/24 to any port $port && ufw status"
}

open_internet_port() {
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
    done

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

choose_host