import sys

import pytest

# winexe.py needs Pillow, which isn't installed on Linux. Skip this file there
# and only import winexe inside each test, so collection doesn't fail.
pytestmark = pytest.mark.skipif(sys.platform != "win32", reason="winexe is Windows-only")


@pytest.mark.parametrize(
    "platform,expected",
    [
        ("win-32", ("32-bit", 32)),
        ("win-64", ("64-bit", 64)),
        ("win-arm64", ("ARM64", 64)),
    ],
)
def test_parse_arch(platform, expected):
    from constructor.winexe import parse_arch

    assert parse_arch(platform) == expected


@pytest.mark.skipif(sys.platform != "win32", reason="Windows only")
def test_write_fix_launcher_acls_bat(tmp_path):
    """The script is static (no per-env content baked in), uses CRLF line endings,
    and takes icacls.exe's path plus a variable number of Scripts globs as args.
    """
    from constructor.winexe import write_fix_launcher_acls_bat

    write_fix_launcher_acls_bat(str(tmp_path))

    bat_file = tmp_path / "fix_launcher_acls.bat"
    assert bat_file.exists()

    content = bat_file.read_bytes().decode()
    assert content.count("\n") == content.count("\r\n"), "every line must end with CRLF"
    assert "SET ICACLS=%1" in content
    assert "SHIFT" in content
    assert "IF ERRORLEVEL 1" in content
    assert "EXIT /B %ERR%" in content
