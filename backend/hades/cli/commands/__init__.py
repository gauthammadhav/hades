"""HADES CLI commands package."""

from hades.cli.commands.detect import detect_command
from hades.cli.commands.init import init_command
from hades.cli.commands.watch import watch_command

__all__ = ["detect_command", "init_command", "watch_command"]

