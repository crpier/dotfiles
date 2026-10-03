"""Run with: python3 -m unittest discover -s tests -v"""

from contextlib import redirect_stderr
import io
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]


class DeployTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)

    def deploy(self, *args, success=True):
        result = subprocess.run(
            ['bash', str(REPO / 'deploy.sh'), '--home', str(self.home), *args],
            cwd='/', capture_output=True, text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def test_missing_executables_warn_in_both_modes_without_blocking(self):
        for mode in ('--dry-run', '--apply'):
            result = subprocess.run(
                [sys.executable, str(REPO / 'scripts/link_dotfiles.py'),
                 '--home', str(self.home), 'fish', mode],
                env={**os.environ, 'PATH': ''}, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('WARNING [fish] Missing executable on PATH: fish', result.stderr)
            self.assertIn('Nothing will be installed', result.stderr)
            if mode == '--dry-run':
                self.assertEqual(list(self.home.iterdir()), [])
            else:
                self.assertTrue((self.home / '.config/fish/config.fish').is_symlink())

    def test_checks_only_selected_packages_and_supports_paths(self):
        verify = runpy.run_path(str(REPO / 'scripts/link_dotfiles.py'))['verify_dependencies']
        checks = {
            'selected': {'executables': {'present': 'test tool'},
                         'paths': {'missing/file': 'test file'}},
            'unselected': {'executables': {'absent': 'do not check this'}},
        }
        output = io.StringIO()
        with patch('shutil.which', return_value='/usr/bin/present') as which, redirect_stderr(output):
            self.assertEqual(verify(['selected'], checks, self.home), 1)
        which.assert_called_once_with('present')
        self.assertIn('Missing path:', output.getvalue())
        self.assertNotIn('unselected', output.getvalue())
        (self.home / 'missing').mkdir()
        (self.home / 'missing/file').touch()
        output = io.StringIO()
        with patch('shutil.which', return_value='/usr/bin/present'), redirect_stderr(output):
            self.assertEqual(verify(['selected'], checks, self.home), 0)
        self.assertEqual(output.getvalue(), '')

    def test_install_tools_requires_apply_and_mise_selection(self):
        self.deploy('mise', '--install-tools', success=False)
        self.deploy('fish', '--apply', '--install-tools', success=False)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_install_tools_uses_neutral_directory_and_global_config(self):
        module = runpy.run_path(str(REPO / 'scripts/link_dotfiles.py'))
        install = module['install_tools']
        calls = []

        def run(command, **kwargs):
            calls.append((command, kwargs))
            self.assertTrue(Path(kwargs['cwd']).is_dir())
            self.assertNotEqual(Path(kwargs['cwd']), REPO)
            self.assertEqual(kwargs['env']['MISE_GLOBAL_CONFIG_FILE'],
                             str(self.home / '.config/mise/config.toml'))
            return subprocess.CompletedProcess(command, 0, stdout='/test/tool/bin\n')

        with patch('subprocess.run', side_effect=run), patch('shutil.which', return_value='/present'):
            install('/test/mise', self.home, ['mise'], {'mise': {'executables': {'mise': 'test'}}})
        self.assertEqual([call[0] for call in calls],
                         [['/test/mise', 'install'], ['/test/mise', 'bin-paths']])

    def test_install_tools_failure_keeps_linked_config(self):
        fake_bin = self.home / 'bin'
        fake_bin.mkdir()
        fake_mise = fake_bin / 'mise'
        fake_mise.write_text('#!/bin/sh\nexit 7\n')
        fake_mise.chmod(0o755)
        result = subprocess.run(
            [sys.executable, str(REPO / 'scripts/link_dotfiles.py'),
             '--home', str(self.home), 'mise', '--apply', '--install-tools'],
            env={**os.environ, 'PATH': str(fake_bin)}, capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Linked configs and backups were kept', result.stderr)
        self.assertTrue((self.home / '.config/mise/config.toml').is_symlink())

    def test_missing_mise_prevents_install_before_linking(self):
        result = subprocess.run(
            [sys.executable, str(REPO / 'scripts/link_dotfiles.py'),
             '--home', str(self.home), 'mise', '--apply', '--install-tools'],
            env={**os.environ, 'PATH': ''}, capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('requires mise on PATH', result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_dry_run_does_not_write(self):
        self.deploy('--all')
        self.assertEqual(list(self.home.iterdir()), [])

    def test_requires_selection_and_rejects_removed_packages(self):
        self.deploy(success=False)
        for package in ('unknown', 'kitty', 'tmux', 'ranger', 'gitconfig'):
            self.deploy('--apply', 'fish', package, success=False)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_apply_all_and_repeat_are_idempotent(self):
        self.deploy('--all', '--apply')
        skills = self.home / '.agents/skills/personal'
        extensions = self.home / '.pi/agent/extensions'
        self.assertEqual(skills.resolve(), REPO / 'agent/skills')
        self.assertEqual(extensions.resolve(), REPO / 'pi-extensions')
        self.assertTrue(skills.is_symlink())
        self.assertTrue(extensions.is_symlink())
        self.assertFalse((self.home / '.config/fish/fish_variables').exists())
        second = self.deploy('--all', '--apply')
        self.assertNotIn('BACKUP', second.stdout)
        self.assertFalse((self.home / '.gitconfig').exists())

    def test_backup_conflicting_file_and_preserve_other_files(self):
        directory = self.home / '.config/fish'
        directory.mkdir(parents=True)
        config = directory / 'config.fish'
        config.write_text('old configuration')
        extra = directory / 'fish_variables'
        extra.write_text('keep local state')
        self.deploy('fish', '--apply')
        self.assertTrue(config.is_symlink())
        self.assertEqual(extra.read_text(), 'keep local state')
        backups = list((self.home / '.local/state/dotfiles/backups').glob('*/.config/fish/config.fish'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'old configuration')

    def test_backup_broken_symlink(self):
        config = self.home / '.pi/agent/extensions'
        config.parent.mkdir(parents=True)
        config.symlink_to(self.home / 'missing')
        self.deploy('pi-extensions', '--apply')
        backups = list((self.home / '.local/state/dotfiles/backups').glob('*/.pi/agent/extensions'))
        self.assertEqual(len(backups), 1)
        self.assertTrue(backups[0].is_symlink())
        self.assertEqual(backups[0].readlink(), self.home / 'missing')

    def test_refuse_symlink_parent_before_any_changes(self):
        outside = self.home / 'outside'
        outside.mkdir()
        (self.home / '.config').symlink_to(outside)
        self.deploy('agent', 'fish', '--apply', success=False)
        self.assertFalse((self.home / '.agents').exists())
        self.assertEqual(list(outside.iterdir()), [])

    def test_directory_conflict_is_backed_up(self):
        extensions = self.home / '.pi/agent/extensions'
        extensions.mkdir(parents=True)
        (extensions / 'local.ts').write_text('old extension')
        self.deploy('pi-extensions', '--apply')
        self.assertTrue(extensions.is_symlink())
        backups = list((self.home / '.local/state/dotfiles/backups').glob('*/.pi/agent/extensions/local.ts'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'old extension')

    def test_omarchy_skills_and_git_config_are_untouched(self):
        skills = self.home / '.agents/skills'
        skills.mkdir(parents=True)
        (skills / 'omarchy').symlink_to('/usr/share/omarchy/default/agents/skills/omarchy')
        git_config = self.home / '.config/git/config'
        git_config.parent.mkdir(parents=True)
        git_config.write_text('existing git config')
        self.deploy('agent', 'fish', 'pi-extensions', '--apply')
        self.assertEqual((skills / 'omarchy').readlink(), Path('/usr/share/omarchy/default/agents/skills/omarchy'))
        self.assertEqual(git_config.read_text(), 'existing git config')
        self.assertFalse((self.home / '.config/extra.gitconfig').exists())


if __name__ == '__main__':
    unittest.main()
