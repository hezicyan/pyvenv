## Description

This is a script used to find all python virtual environments under current
folder (not recursive) and activate one of them.

## Install

Copy the contents of this file to `~/.bashrc` (or `~/.zshrc` etc.) or source
this file in `~/.bashrc`, then restart your shell.

**DO NOT JUST RUN THIS FILE.**

## Usage

Enter your project, and simply type `pyvenv`, and press enter.

If there's only one virtual environment in your project, this script will
automatically activate it or deactivate it.

Otherwise, this script will provide a select box for you to choose one to
activate, use "j/k", "C-n/C-p" or arrow keys to navigate, and enter or space to
confirm.

## Acknowledgement

Select box is based on [this answer](https://askubuntu.com/a/1716) by Dennis
Williamson.

## License

This program is licensed under the GNU General Public Lincese version 3.
