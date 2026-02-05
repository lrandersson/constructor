from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .jinja import render_template


@dataclass(frozen=True)
class TemplateFile:
    """A specification for a single Jinja template to an output file."""

    name: str
    src: Path
    dst: Path


def render_template_files(
    files: list[TemplateFile], context: Mapping[str, Any], line_ending="\r\n"
) -> None:
    for f in files:
        if not f.src.exists():
            raise FileNotFoundError(f.src)
        rendered = render_template(f.src.read_text(encoding="utf-8"), **context)
        f.dst.parent.mkdir(parents=True, exist_ok=True)
        f.dst.write_text(rendered, encoding="utf-8", newline=line_ending)
