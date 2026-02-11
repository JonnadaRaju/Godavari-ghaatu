import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

try:
    # Try with postgres user
    conn = psycopg2.connect(
        dbname="rajudb",
        user="raju",
        password="6014",  
        host="localhost",
        port="5432"
    )
    
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cursor = conn.cursor()
    
    # Create database
    cursor.execute(sql.SQL("CREATE DATABASE {}").format(
        sql.Identifier("rajudb")
    ))
    
    print("Database 'rajudb' created successfully!")
    
    cursor.close()
    conn.close()
    
except psycopg2.errors.DuplicateDatabase:
    print("Database 'rajudb' already exists!")
    
except Exception as e:
    print(f"Error: {e}")
    print("\nTrying with user 'raju' and password '6014'...")
    
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user="raju",
            password="6014",
            host="localhost",
            port="5432"
        )
        
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        cursor.execute(sql.SQL("CREATE DATABASE {}").format(
            sql.Identifier("rajudb")
        ))
        
        print("✅ Database 'rajudb' created successfully with user 'raju'!")
        
        cursor.close()
        conn.close()
        
    except Exception as e2:
        print(f"Error: {e2}")
        print("\n Please use pgAdmin to create the database manually.")