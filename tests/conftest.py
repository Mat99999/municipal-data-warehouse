from pathlib import Path

import pytest

from municipal_dw.config import Settings


@pytest.fixture
def settings() -> Settings:
    return Settings(data_dir=Path("data"))
