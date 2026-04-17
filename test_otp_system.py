#!/usr/bin/env python3
"""
Test script for OTP verification system
Run this to verify all components are working correctly
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import sys

# Database configuration
DB_NAME = "gspaces"
DB_USER = "sri"
DB_PASSWORD = "gspaces2025"
DB_HOST = "localhost"
DB_PORT = "5432"

def test_database_connection():
    """Test database connection"""
    print("1. Testing database connection...")
    try:
        conn = psycopg2.connect(
            database=DB_NAME, user=DB_USER, password=DB_PASSWORD,
            host=DB_HOST, port=DB_PORT
        )
        print("   ✅ Database connection successful")
        conn.close()
        return True
    except Exception as e:
        print(f"   ❌ Database connection failed: {e}")
        return False

def test_otp_table_exists():
    """Test if otp_verifications table exists"""
    print("\n2. Testing otp_verifications table...")
    try:
        conn = psycopg2.connect(
            database=DB_NAME, user=DB_USER, password=DB_PASSWORD,
            host=DB_HOST, port=DB_PORT
        )
        cur = conn.cursor()
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'otp_verifications'
            );
        """)
        exists = cur.fetchone()[0]
        
        if exists:
            print("   ✅ otp_verifications table exists")
            
            # Check table structure
            cur.execute("""
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = 'otp_verifications'
                ORDER BY ordinal_position;
            """)
            columns = cur.fetchall()
            print("   Table columns:")
            for col in columns:
                print(f"      - {col[0]}: {col[1]}")
            conn.close()
            return True
        else:
            print("   ❌ otp_verifications table does not exist")
            print("   Run: psql -U sri -d gspaces -f create_otp_table.sql")
            conn.close()
            return False
    except Exception as e:
        print(f"   ❌ Error checking table: {e}")
        return False

def test_users_table():
    """Test if users table exists"""
    print("\n3. Testing users table...")
    try:
        conn = psycopg2.connect(
            database=DB_NAME, user=DB_USER, password=DB_PASSWORD,
            host=DB_HOST, port=DB_PORT
        )
        cur = conn.cursor()
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'users'
            );
        """)
        exists = cur.fetchone()[0]
        
        if exists:
            print("   ✅ users table exists")
            conn.close()
            return True
        else:
            print("   ❌ users table does not exist")
            conn.close()
            return False
    except Exception as e:
        print(f"   ❌ Error checking users table: {e}")
        return False

def test_wallet_table():
    """Test if wallet table exists"""
    print("\n4. Testing wallet table...")
    try:
        conn = psycopg2.connect(
            database=DB_NAME, user=DB_USER, password=DB_PASSWORD,
            host=DB_HOST, port=DB_PORT
        )
        cur = conn.cursor()
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'wallet'
            );
        """)
        exists = cur.fetchone()[0]
        
        if exists:
            print("   ✅ wallet table exists (for signup bonus)")
            conn.close()
            return True
        else:
            print("   ⚠️  wallet table does not exist (signup bonus won't work)")
            conn.close()
            return False
    except Exception as e:
        print(f"   ❌ Error checking wallet table: {e}")
        return False

def test_template_files():
    """Test if required template files exist"""
    print("\n5. Testing template files...")
    import os
    
    templates = [
        'templates/login.html',
        'templates/verify_otp.html'
    ]
    
    all_exist = True
    for template in templates:
        if os.path.exists(template):
            print(f"   ✅ {template} exists")
        else:
            print(f"   ❌ {template} missing")
            all_exist = False
    
    return all_exist

def test_disposable_email_function():
    """Test disposable email detection"""
    print("\n6. Testing disposable email detection...")
    
    # Import the function from main.py
    sys.path.insert(0, '.')
    try:
        from main import is_disposable_email
        
        test_cases = [
            ('user@gmail.com', False, 'Valid email'),
            ('test@tempmail.com', True, 'Disposable email'),
            ('user@guerrillamail.com', True, 'Disposable email'),
            ('admin@company.com', False, 'Valid email'),
        ]
        
        all_passed = True
        for email, expected, description in test_cases:
            result = is_disposable_email(email)
            if result == expected:
                print(f"   ✅ {description}: {email} -> {result}")
            else:
                print(f"   ❌ {description}: {email} -> {result} (expected {expected})")
                all_passed = False
        
        return all_passed
    except Exception as e:
        print(f"   ❌ Error testing disposable email function: {e}")
        return False

def test_otp_generation():
    """Test OTP generation"""
    print("\n7. Testing OTP generation...")
    
    try:
        from main import generate_otp
        
        otp = generate_otp()
        
        if len(otp) == 6 and otp.isdigit():
            print(f"   ✅ OTP generated successfully: {otp}")
            return True
        else:
            print(f"   ❌ Invalid OTP format: {otp}")
            return False
    except Exception as e:
        print(f"   ❌ Error testing OTP generation: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("OTP VERIFICATION SYSTEM - TEST SUITE")
    print("=" * 60)
    
    results = []
    
    results.append(("Database Connection", test_database_connection()))
    results.append(("OTP Table", test_otp_table_exists()))
    results.append(("Users Table", test_users_table()))
    results.append(("Wallet Table", test_wallet_table()))
    results.append(("Template Files", test_template_files()))
    results.append(("Disposable Email Detection", test_disposable_email_function()))
    results.append(("OTP Generation", test_otp_generation()))
    
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print("\n" + "=" * 60)
    print(f"Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! OTP system is ready.")
        print("\nNext steps:")
        print("1. Start Flask app: python main.py")
        print("2. Navigate to signup page")
        print("3. Test complete signup flow with OTP verification")
    else:
        print("⚠️  Some tests failed. Please fix the issues above.")
    
    print("=" * 60)
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

# Made with Bob
