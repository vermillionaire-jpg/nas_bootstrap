#!/usr/bin/env bash

DOTFILES_REPO="https://github.com/vermillionaire-jpg/dotfiles"
DOTFILES_DIR="$HOME/vcs/dotfiles"

echo
echo ">> Installing dotfiles from $DOTFILES_REPO..."

git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_DIR"
cp -r "$DOTFILES_DIR/." "$HOME/"
rm -rf "$DOTFILES_DIR"