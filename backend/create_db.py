import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get DATABASE_URL from .env
database_url = os.getenv("DATABASE_URL")

if not database_url:
    print("=" * 60)
    print("ERROR: DATABASE_URL not found in .env file!")
    print("=" * 60)
    print("\nPlease create a .env file in the backend folder with:")
    print("-" * 60)
    print("DATABASE_URL=postgresql://raju:6014@localhost:5432/rajudb")
    print("-" * 60)
    exit(1)

# Parse the DATABASE_URL
# Expected format: postgresql://username:password@host:port/dbname
try:
    # Remove the postgresql:// prefix
    url_without_prefix = database_url.replace("postgresql://", "")
    
    # Split into user:pass and host:port/db parts
    user_pass_part, host_db_part = url_without_prefix.split("@")
    
    # Extract username and password
    username, password = user_pass_part.split(":")
    
    # Extract host:port and dbname
    host_port_part, dbname = host_db_part.split("/")
    host, port = host_port_part.split(":")
    
    print("=" * 60)
    print("Database Creation Script")
    print("=" * 60)
    print(f"Database: {dbname}")
    print(f"Host: {host}:{port}")
    print(f"User: {username}")
    print("=" * 60)
    
except Exception as parse_error:
    print("=" * 60)
    print("ERROR: Could not parse DATABASE_URL")
    print("=" * 60)
    print(f"Error: {parse_error}")
    print("\nExpected format:")
    print("DATABASE_URL=postgresql://username:password@host:port/dbname")
    print("\nExample:")
    print("DATABASE_URL=postgresql://raju:6014@localhost:5433/rajudb")
    print("=" * 60)
    exit(1)

# Attempt 1: Try to connect to the target database directly
try:
    print(f"\nAttempt 1: Connecting to '{dbname}' database...")
    conn = psycopg2.connect(
        dbname=dbname,
        user=username,
        password=password,
        host=host,
        port=port
    )
    
    print(f"✅ Database '{dbname}' already exists and is accessible!")
    conn.close()
    exit(0)
    
except psycopg2.OperationalError:
    print(f"❌ Database '{dbname}' does not exist yet.")
    print(f"\nAttempt 2: Connecting to 'postgres' database to create '{dbname}'...")
    
    # Attempt 2: Connect to default 'postgres' database to create target database
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user=username,
            password=password,
            host=host,
            port=port
        )
        
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Create the database
        cursor.execute(sql.SQL("CREATE DATABASE {}").format(
            sql.Identifier(dbname)
        ))
        
        print(f"✅ Database '{dbname}' created successfully!")
        print("=" * 60)
        
        cursor.close()
        conn.close()
        
    except psycopg2.errors.DuplicateDatabase:
        print(f"✅ Database '{dbname}' already exists!")
        print("=" * 60)
        
    except psycopg2.OperationalError as op_error:
        print("\n" + "=" * 60)
        print("ERROR: Could not connect to PostgreSQL")
        print("=" * 60)
        print(f"Error: {op_error}")
        print("\nPossible solutions:")
        print("1. Ensure PostgreSQL is running")
        print("2. Check your DATABASE_URL credentials in .env")
        print("3. Verify PostgreSQL is listening on localhost:5432")
        print("4. Check if user has CREATE DATABASE privileges")
        print("\nOr create the database manually using pgAdmin:")
        print(f"   Right-click 'Databases' → Create → Database → Name: {dbname}")
        print("=" * 60)
        exit(1)
        
    except Exception as create_error:
        print("\n" + "=" * 60)
        print("ERROR: Failed to create database")
        print("=" * 60)
        print(f"Error: {create_error}")
        print("\nPlease create the database manually using pgAdmin")
        print("=" * 60)
        exit(1)

except Exception as unexpected_error:
    print("\n" + "=" * 60)
    print("ERROR: Unexpected error occurred")
    print("=" * 60)
    print(f"Error: {unexpected_error}")
    print("=" * 60)
    exit(1)