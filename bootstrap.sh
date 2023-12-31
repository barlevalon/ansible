#!/usr/bin/env bash
set -euo pipefail

check_os() {
  OS="$(uname)"
  case "$OS" in
    'Darwin')
      OS='Mac'
      echo "Running on $OS".
      ;;
    *)
      echo "Unsupported OS: $OS"
      exit 1
      ;;
  esac
  echo "$OS"
}

install_package() {
  local package=$1
  gum spin --spinner line --title "Installing $package" -- brew install "$package"
  echo "[$(pprint ✓)] $package"
}

spin() {
  if [[ $1 == --* ]]; then
    local option="$1"
    local title="$2"
    local command="${@:3}"
  else
    local option=""
    local title="$1"
    local command="${@:2}"
  fi
  gum spin $option --spinner line --title "$title" -- $command
}

pprint() {
  gum style --foreground 212 "$@"
}

checkmark() {
  echo "[$(pprint ✓)] $@"
}

bootstrap() {
  echo "Bootstrapping..."
  echo
  brew -v &> /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew install gum --HEAD &> /dev/null
  checkmark "homebrew"
  checkmark "gum"
}

clone_ansible_repo() {
  if [ ! -d ~/personal/ansible ]; then
    spin "Cloning ansible repo" git clone https://github.com/barlevalon/ansible ~/personal/ansible
  else
    spin "Updating ansible repo" git -C ~/personal/ansible pull --rebase --autostash
  fi
  checkmark "ansible repo"
}

run_ansible() {
  cd ~/personal/ansible
  spin "Installing ansible dependencies" ansible-galaxy install -r requirements.yaml
  checkmark "ansible dependencies"
  export ANSIBLE_LOCALHOST_WARNING=False
  export ANSIBLE_INVENTORY_UNPARSED_WARNING=False
  ansible-playbook -K playbook.yaml
}

# Main
OS=$(check_os)
bootstrap
install_package ansible
clone_ansible_repo
run_ansible
echo
checkmark "Done!"
