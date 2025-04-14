import mysql.connector
from werkzeug.security import generate_password_hash

# 1. Connect to your database
db = mysql.connector.connect(
    host="127.0.0.1",
    user="root",
    password="Groot",  # Change if needed
    database="LabInventory"
)
cursor = db.cursor()

# 2. Define student emails and raw passwords
def add_student_passwords():
    students = [
        ("alice.dc@student.uc.edu.ph", "password123"),
        ("bryan.reyes@student.uc.edu.ph", "bryanpass"),
        ("cathy.torres@student.uc.edu.ph", "cathypass"),
    ]

    for email, raw_password in students:
        hashed = generate_password_hash(raw_password)
        cursor.execute("UPDATE Student SET Password = %s WHERE Email = %s", (hashed, email))

    db.commit()
    print("✅ Student passwords set successfully.")

# 3. Run the function
add_student_passwords()

# 4. Cleanup
cursor.close()
db.close()
