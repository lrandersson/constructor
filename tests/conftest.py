import os
import subprocess
import sys
from pathlib import Path

import pytest

REPO_DIR = Path(__file__).parent.parent

def _platform_installer_types() -> list[str]:
    """Return the installer type suffixes available on the current platform."""
    if sys.platform.startswith("win"):
        return ["exe"]
    elif sys.platform == "darwin":
        return ["sh", "pkg"]
    else:
        return ["sh"]

ALL_INSTALLER_TYPES = _platform_installer_types()


def pytest_generate_tests(metafunc):
    """
    Automatically parametrize any test that declares an ``installer_type``
    fixture argument.

    If the test is decorated with ``@pytest.mark.installer_types("pkg", ...)``
    the parametrization is restricted to those types (intersected with what is
    available on the current platform).  Without the marker all platform types
    are used.

    Note: this hook lives here for colocation with the tests; it should be
    moved to ``conftest.py`` if this file grows or the hook is needed elsewhere.
    """
    if "installer_type" not in metafunc.fixturenames:
        return

    marker = metafunc.definition.get_closest_marker("installer_types")
    if marker:
        requested = list(marker.args)  # marker.args is already the tuple of strings
        types = [t for t in requested if t in ALL_INSTALLER_TYPES]
        if not types:
            pytest.skip(
                f"No applicable installer types for this platform "
                f"(requested: {requested}, available: {ALL_INSTALLER_TYPES})"
            )
    else:
        types = ALL_INSTALLER_TYPES

    metafunc.parametrize("installer_type", types)

@pytest.fixture
def self_signed_application_certificate_macos(tmp_path):
    p = subprocess.run(
        ["security", "list-keychains", "-d", "user"],
        capture_output=True,
        text=True,
    )
    current_keychains = [keychain.strip(' "') for keychain in p.stdout.split("\n") if keychain]
    cert_root = tmp_path / "certs"
    cert_root.mkdir(parents=True, exist_ok=True)
    notarization_identity = "testapplication"
    notarization_identity_password = "5678"
    keychain_password = "abcd"
    env = os.environ.copy()
    env.update(
        {
            "APPLICATION_SIGNING_ID": notarization_identity,
            "APPLICATION_SIGNING_PASSWORD": notarization_identity_password,
            "KEYCHAIN_PASSWORD": keychain_password,
            "ROOT_DIR": str(cert_root),
        }
    )
    p = subprocess.run(
        ["bash", REPO_DIR / "scripts" / "create_self_signed_certificates_macos.sh"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    yield notarization_identity
    # Clean up
    subprocess.run(["security", "list-keychains", "-d", "user", "-s", *current_keychains])
