from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

PROJECT_ROOT = Path(__file__).parent.parent
ENV_FILE_PATH = PROJECT_ROOT / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=ENV_FILE_PATH, env_file_encoding="utf-8")

    DAB_API_URL: str
    SECRET_USER_AGENT: str
    PRIVATE_EMAIL: str
    PRIVATE_PASSWORD: str


settings = Settings()
