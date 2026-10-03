#!/usr/bin/env python3
"""Link explicitly selected dotfiles; never install software or execute configs."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parents[1]


def relative_path(value):
    path = Path(value)
    if path.is_absolute() or not path.parts or '..' in path.parts:
        raise ValueError(f'Expected a relative path without ..: {value}')
    return path


def check_parents(target, home):
    # Do not accidentally write through a symlink into the repo or elsewhere.
    for parent in target.parents:
        if parent == home:
            break
        if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
            raise ValueError(f'Unsafe destination parent: {parent}')


def correct_link(target, source):
    return target.is_symlink() and target.resolve() == source.resolve()


def install_tools(mise, home, packages, checks):
    """Use the linked global config, away from any caller's project configs."""
    env = dict(os.environ)
    env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'),
               MISE_GLOBAL_CONFIG_FILE=str(home / '.config/mise/config.toml'))
    for key in ('MISE_CONFIG_FILE', 'MISE_ENV', 'MISE_OVERRIDE_CONFIG_FILENAMES',
                'MISE_NO_CONFIG', 'MISE_TOOL_VERSIONS_FILENAME'):
        env.pop(key, None)
    # A neutral working directory prevents installing the caller's project tools.
    with tempfile.TemporaryDirectory(prefix='dotfiles-mise-') as directory:
        print('INSTALL tools from the linked global mise config', flush=True)
        subprocess.run([mise, 'install'], cwd=directory, env=env, check=True)
        result = subprocess.run([mise, 'bin-paths'], cwd=directory, env=env,
                                check=True, capture_output=True, text=True)
    # The parent shell cannot acquire a new PATH from this child process.
    # Check the installed tools using mise's active bin paths as well as PATH.
    path = os.pathsep.join([*result.stdout.splitlines(), os.environ.get('PATH', '')])
    print('VERIFY dependencies after tool installation', flush=True)
    verify_dependencies(packages, checks, home, search_path=path)
    print('If tools are not on your shell PATH, activate mise or restart your shell.')


def verify_dependencies(packages, checks, home, search_path=None):
    """Advisory only: never install software or stop deployment."""
    missing = 0
    for package in packages:
        requirements = checks.get(package, {})
        for executable, reason in requirements.get('executables', {}).items():
            available = (shutil.which(executable) if search_path is None
                         else shutil.which(executable, path=search_path))
            if available is None:
                print(f'WARNING [{package}] Missing executable on PATH: '
                      f'{executable} — {reason}', file=sys.stderr)
                missing += 1
        # Paths are relative to the destination home (not the repository).
        for value, reason in requirements.get('paths', {}).items():
            path = home / relative_path(value)
            if not path.exists():
                print(f'WARNING [{package}] Missing path: {path} — {reason}',
                      file=sys.stderr)
                missing += 1
    if missing:
        print('Dependency warnings are advisory; deployment will continue. '
              'Nothing will be installed by these checks.', file=sys.stderr)
    return missing


def main():
    parser = argparse.ArgumentParser(
        description='Preview symlinks by default. Use --apply to make changes. '
                    'Conflicting files are moved to ~/.local/state/dotfiles/backups/. '
                    'Edit links.json to add mappings and checks.json for dependency warnings. '
                    'Tools are installed only with --apply --install-tools.'
    )
    parser.add_argument('packages', nargs='*', help='Packages to link (explicit selection required)')
    parser.add_argument('--all', action='store_true', help='Select every package')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true', help='Create links and back up conflicts')
    mode.add_argument('--dry-run', action='store_true', help='Preview only (the default)')
    parser.add_argument('--install-tools', action='store_true',
                        help='Run mise install after linking (requires --apply and mise selection)')
    parser.add_argument('--list', action='store_true', help='List available packages')
    parser.add_argument('--home', type=Path, default=Path.home(), help='Destination home (for testing)')
    args = parser.parse_args()
    manifest = json.loads((REPO / 'links.json').read_text())
    if args.list:
        print('\n'.join(manifest))
        return
    if args.all and args.packages:
        parser.error('Use either package names or --all, not both')
    packages = list(manifest) if args.all else list(dict.fromkeys(args.packages))
    if not packages:
        parser.error('Select packages, or use --list / --all')
    unknown = set(packages) - manifest.keys()
    if unknown:
        parser.error(f'Unknown packages: {", ".join(sorted(unknown))}')
    mise = None
    if args.install_tools:
        if not args.apply or 'mise' not in packages:
            parser.error('--install-tools requires --apply and the mise package (or --all)')
        mise = shutil.which('mise')
        if mise is None:
            raise ValueError('--install-tools requires mise on PATH; no files were changed')
    home = args.home.expanduser().resolve()
    if not home.is_dir():
        raise ValueError(f'Destination home must already exist: {home}')

    checks = json.loads((REPO / 'checks.json').read_text())
    verify_dependencies(packages, checks, home)

    # Preflight every source and destination before making any changes.
    links = []
    for package in packages:
        for entry in manifest[package]:
            source = REPO / relative_path(entry['source'])
            target = home / relative_path(entry['target'])
            if not source.exists():
                raise ValueError(f'Missing source: {source}')
            if entry.get('mode', 'link') == 'files':
                if not source.is_dir():
                    raise ValueError(f'Expected source directory: {source}')
                links.extend((child, target / child.relative_to(source))
                             for child in sorted(source.rglob('*')) if child.is_file())
            elif entry.get('mode', 'link') == 'link':
                links.append((source, target))
            else:
                raise ValueError(f'Unknown mapping mode: {entry["mode"]}')
    targets = [target for _, target in links]
    if len(set(targets)) != len(targets):
        raise ValueError('Duplicate destinations in links.json')
    for target in targets:
        check_parents(target, home)
        if any(parent in targets for parent in target.parents):
            raise ValueError(f'Overlapping destinations: {target}')

    backup_root = home / '.local/state/dotfiles/backups'
    check_parents(backup_root / 'placeholder', home)
    backup_dir = backup_root / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')

    def backup(path):
        destination = backup_dir / path.relative_to(home)
        backup_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(path), str(destination))
        print(f'BACKUP {path} -> {destination}')
        return destination

    print('APPLY' if args.apply else 'DRY RUN (no files will be changed)')
    for source, target in links:
        if correct_link(target, source):
            print(f'OK     {target}')
            continue
        conflict = os.path.lexists(target)
        print(f'{"REPLACE" if conflict else "LINK"} {target} -> {source}')
        if not args.apply:
            continue
        check_parents(target, home)
        saved = backup(target) if conflict else None
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(source, target_is_directory=source.is_dir())
        except OSError:
            if saved is not None and not os.path.lexists(target):
                shutil.move(str(saved), str(target))
            raise
    if args.install_tools:
        try:
            install_tools(mise, home, packages, checks)
        except subprocess.CalledProcessError as error:
            raise ValueError('Mise tool installation/verification failed. '
                             'Linked configs and backups were kept; fix the error and rerun.') from error
    print('Done. Application reloads are separate steps.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError) as error:
        print(f'Error: {error}', file=sys.stderr)
        sys.exit(1)
