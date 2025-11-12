from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "FastAPI Application"
    api_version: str = "v1"
    debug: bool = True
    datebase_url: str = "sqlite:///./test.db"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
