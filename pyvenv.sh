#!/usr/bin/env bash

# Copyright (C) 2023 HeziCyan <hezicyan@gmail.com>
# Licensed under the GNU General Public License version 3 (the License).
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.html for a copy.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License or any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.

################################################################################
#                                                                              #
# This is a script used to find all python virtual environments under current  #
# folder (not recursive) and activate one of them.                             #
#                                                                              #
# Install:                                                                     #
#   Copy the contents of this file to `~/.bashrc` (or `~/.zshrc` etc.) or      #
#   source this file in `~/.bashrc`, then restart your shell.                  #
#   DO NOT JUST RUN THIS FILE.                                                 #
#                                                                              #
# Usage:                                                                       #
#   Enter your project, and simply type `pyvenv`, and press enter.             #
#   If there's only one virtual environment in your project, this script will  #
#     automatically activate it or deactivate it.                              #
#   Otherwise, this script will provide a select box for you to choose one to  #
#     activate, use "j/k", "C-n/C-p" or arrow keys to navigate, and enter or   #
#     space to confirm.                                                        #
#                                                                              #
# Acknowledgement:                                                             #
#   Select box is based on https://askubuntu.com/a/1716                        #
#                                                                              #
################################################################################

function _select_option {
  # little helpers for terminal print control and key input
  ESC=$(printf "\033")
  # shellcheck disable=SC1087,SC2059
  cursor_blink_on() { printf "$ESC[?25h"; }
  # shellcheck disable=SC1087,SC2059
  cursor_blink_off() { printf "$ESC[?25l"; }
  # shellcheck disable=SC1087,SC2059
  cursor_to() { printf "$ESC[$1;${2:-1}H"; }
  # shellcheck disable=SC1087,SC2059
  print_option() { printf "   $1 "; }
  # shellcheck disable=SC1087,SC2059
  print_selected() { printf "  $ESC[7m $1 $ESC[27m"; }
  get_cursor_row() {
    # shellcheck disable=SC2034
    IFS=';' read -sdRr -p $'\E[6n' ROW COL
    echo "${ROW#*[}"
  }
  key_input() {
    IFS= read -sr -n1 key 2>/dev/null >&2
    if [[ $key = $'\E' ]]; then
      read -sr -n2 key 2>/dev/null >&2
      if [[ $key = "[A" ]]; then echo up; fi
      if [[ $key = "[B" ]]; then echo down; fi
    else
      if [[ $key = "k" ]] || [[ $key = $'\020' ]]; then echo up; fi
      if [[ $key = "j" ]] || [[ $key = $'\016' ]]; then echo down; fi
      if [[ $key = " " ]]; then echo enter; fi
      if [[ $key = "" ]]; then echo enter; fi
    fi
  }

  # initially print empty new lines (scroll down if at bottom of screen)
  for opt; do printf "\n"; done

  # determine current screen position for overwriting the options
  local -r lastrow="$(get_cursor_row)"
  local -r startrow="$((lastrow - $#))"

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
  cursor_blink_off

  local selected=0
  while true; do
    # print options by overwriting the last lines
    local idx=0
    for opt; do
      cursor_to $((startrow + idx))
      if [ $idx -eq $selected ]; then
        print_selected "$opt"
      else
        print_option "$opt"
      fi
      ((idx++))
    done

    # user key control
    case $(key_input) in
    enter) break ;;
    up)
      ((selected--))
      if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi
      ;;
    down)
      ((selected++))
      if [ $selected -ge $# ]; then selected=0; fi
      ;;
    esac
  done

  # cursor position back to normal
  cursor_to "$lastrow"
  printf "\n"
  cursor_blink_on

  return $selected
}

function pyvenv() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NOCOLOR='\033[0m'

  local venvs
  venvs=$(find . -maxdepth 3 -wholename "*/bin/python")
  IFS=$'\n' read -d '' -r -a venvs <<<"$venvs"
  local list=("${venvs[@]}")
  for ((i = 0; i < ${#list[@]}; ++i)); do
    path=${list[i]}
    list[i]="$path ($($path "--version"))"
  done

  local len=${#venvs[@]}
  if [[ $len = "0" ]]; then
    # shellcheck disable=SC1087,SC2059
    printf "$RED[FAILED]$NOCOLOR No Python interpreter detected.\n"
    return
  fi

  if command -v deactivate &>/dev/null; then
    local invenv=1
  else
    local invenv=0
  fi

  if [[ $len = "1" ]]; then
    if [[ $invenv = 1 ]]; then
      local -r selected=$len
    else
      local -r selected=0
    fi
  else
    if [[ $invenv = 1 ]]; then
      list=("${list[@]}" "Deactivate")
    fi
    echo "$len Python interpreters detected, please choose one of them:"
    echo ""
    _select_option "${list[@]}"
    local -r selected=$?
  fi

  if [[ $selected = "$len" ]]; then
    deactivate
    # shellcheck disable=SC1087,SC2059
    printf "$GREEN[SUCCESS]$NOCOLOR Virtual environment deactivated!\n"
  else
    local -r path="$(dirname "${venvs[$selected]}")/activate"
    # shellcheck disable=SC1090
    source "$path"
    # shellcheck disable=SC1087,SC2059
    printf "$GREEN[SUCCESS]$NOCOLOR ${venvs[$selected]} activated!\n"
  fi
}
