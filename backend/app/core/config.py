from pydantic_settings import BaseSettings
from typing import List
import os
from pathlib import Path


class Settings(BaseSettings):
    
    # Database
    DATABASE_URL: str
    
    # JWT Authentication
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60
    
    # Security
    BCRYPT_ROUNDS: int = 12
    
    # Application
    APP_NAME: str = "Godavari Ghaatu E-Commerce"
    DEBUG: bool = False  # ← Changed to False for production
    API_V1_STR: str = "/api/v1"
    
    # CORS - Updated to support multiple origins
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:3001"
    
    UPI_ID: str = "jonadaraju147@ibl"
    UPI_NAME: str = "Godavari Ghaatu"
    
    @property
    def cors_origins(self) -> List[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'
        case_sensitive = True


# Create settings instance
settings = Settings()