#! /usr/bin/env python3

""" Link dotfiles to real files, and create backups in ~/.backup folder """

import os
import shutil
from os.path import expanduser

HOME = expanduser("~")
REPO_PATH = f"{HOME}/.local/dotfiles"


def backup_and_link(source: str, target: str):
    target_base = target.replace(f"{HOME}/", "")
    backup_location = f"{HOME}/.backup/{target_base}"

    print(f"""Linking {source} towards {target},
            backing up in {backup_location}""")

    if os.path.isfile(backup_location) or os.path.isdir(backup_location):
        shutil.rmtree(backup_location)

    if os.path.islink(target):
        real_target = os.path.realpath(target)
        shutil.move(real_target, backup_location)
        os.remove(target)

    shutil.move(target, backup_location)
    os.symlink(source, target)


def main():
    # Do whole folders first
    backup_and_link(f"{REPO_PATH}/kde4", f"{HOME}/.kde4")
    backup_and_link(f"{REPO_PATH}/tmux.conf", f"{HOME}/.tmux.conf")


if __name__ == "__main__":
    main()
