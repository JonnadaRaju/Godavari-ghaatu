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
    DEBUG: bool = True
    API_V1_STR: str = "/api/v1"
    
    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:3000"
    
    UPI_ID: str = "jonadaraju147@ibl"
    UPI_NAME: str = "Godavari Ghaatu"
    
    @property
    def cors_origins(self) -> List[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'
        case_sensitive = True
        
        # Add extra validation
        @classmethod
        def customise_sources(cls, init_settings, env_settings, file_secret_settings):
            return (
                init_settings,
                env_settings,
                file_secret_settings,
            )


# Create settings instance
try:
    settings = Settings()
except Exception as e:
    print("\n" + "="*80)
    print("ERROR: Could not load settings!")
    print("="*80)
    print(f"\nDetails: {str(e)}")
    print("\nPlease ensure you have created a .env file at:")
    print(f"  {os.path.join(os.getcwd(), '.env')}")
    print("\nThe .env file should contain:")
    print("-" * 40)
    print("""DATABASE_URL=postgresql://raju:6014@localhost:5432/rajudb
          
JWT_SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60
BCRYPT_ROUNDS=12
APP_NAME=Godavari Ghaatu E-Commerce
DEBUG=True
API_V1_STR=/api/v1
ALLOWED_ORIGINS=http://localhost:3000""")
    print("-" * 40)
    print("\n" + "="*80 + "\n")
    raise