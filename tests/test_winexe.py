import pytest

from constructor.winexe import parse_arch


@pytest.mark.parametrize(
    "platform,expected",
    [
        ("win-32", ("32-bit", 32)),
        ("win-64", ("64-bit", 64)),
        ("win-arm64", ("ARM64", 64)),
    ],
)
def test_parse_arch(platform, expected):
    assert parse_arch(platform) == expected
