#!/bin/bash
# short: Setup VSCode for use with WebHare

set -eo pipefail

confirm_or_abort()
{
  echo "[setup-vscode]" "$@" "Fix this? [Y/N]"
  read -r ANSWER
  if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
    echo "Aborting then..."
    exit 0
  fi
}

if ! [ -d "/Applications/Visual Studio Code.app/" ]; then
  confirm_or_abort "VSCode does not appear to be installed."
  echo "[setup-vscode] Installing vscode"
  brew install --cask visual-studio-code
fi

if ! [ -d "$HOME/projects/webhare-language-vscode" ]; then
  confirm_or_abort "Checkout webhare-language-vscode"
  mkdir -p "$HOME/projects"
  load_forgeroot
  echo "[setup-vscode] Installing vscode"
  git clone "${WHRUNKIT_FORGEROOT}/lsp/webhare-language-vscode.git" "$HOME/projects/webhare-language-vscode"
fi

if ! hash -r code ; then
  echo "[setup-vscode] Cannot find 'code' in the path. Looks like VSCode isn't fully configured yet, not sure how to continue"
  exit 1
fi

if ! code --list-extensions|grep -q '^webhare.webhare-language-vscode$' ; then
  confirm_or_abort "Installing the webhare.webhare-language-vscode extension" #TODO: does this trouble development on the module? then we need to offer a way to explicitly prevent this with a config file but the default should be to install
  "$HOME/projects/webhare-language-vscode/bin/installlocal.sh"
fi

echo "[setup-vscode] It looks like everything is installed"
