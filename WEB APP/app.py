from flask import Flask, render_template, request, redirect, session, flash, jsonify, url_for
import mysql.connector
from werkzeug.security import generate_password_hash, check_password_hash
from collections import defaultdict
from datetime import datetime
from flask_mail import Mail, Message
from functools import wraps
from mysql.connector import Error

app = Flask(__name__)
app.secret_key = 'your_secret_key'

# Flask-Mail Configuration
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 465
app.config['MAIL_USE_TLS'] = False
app.config['MAIL_USE_SSL'] = True
app.config['MAIL_USERNAME'] = 'your_email@gmail.com'
app.config['MAIL_PASSWORD'] = 'your_password'
app.config['MAIL_DEFAULT_SENDER'] = 'your_email@gmail.com'

mail = Mail(app)

# MySQL Database Connection
db = mysql.connector.connect(
    host="127.0.0.1",
    user="root",
    password="Groot",
    database="LabInventory"
)
cursor = db.cursor(dictionary=True)

# =======================
# Role-Based Access
# =======================
def role_required(*allowed_roles):
    def decorator(f):
        @wraps(f)
        def wrapped_function(*args, **kwargs):
            if 'role' not in session or session['role'] not in allowed_roles:
                flash("Access denied.")
                return redirect('/dashboard')
            return f(*args, **kwargs)
        return wrapped_function
    return decorator

# =======================
# Web App Routes
# =======================
@app.route('/logout')
def logout():
    session.clear()
    return redirect('/')

@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        cursor.execute("SELECT * FROM LabManager WHERE Contact = %s", (email,))
        manager = cursor.fetchone()
        if manager and check_password_hash(manager['Password'], password):
            session['manager_id'] = manager['ManagerID']
            session['role'] = manager['role']
            return redirect('/dashboard')
        else:
            return render_template('login.html', error="Invalid email or password.", show_modal=False)

    show_modal = request.args.get('show_register_modal') == 'true'
    return render_template('login.html', show_modal=show_modal)

@app.route('/register')
def register():
    return redirect('/')

@app.route('/dashboard')
def dashboard():
    if 'manager_id' not in session:
        return redirect('/')

    # --- Get filters from query params ---
    time_filter = request.args.get('time', 'All')
    status_filter = request.args.get('status', 'All')
    material_filter = request.args.get('material', 'All')

    current_date = datetime.now()
    conditions = []
    values = []

    # Time filter
    if time_filter == 'Today':
        conditions.append("DATE(bt.RequestDate) = CURDATE()")
    elif time_filter == 'This Week':
        conditions.append("YEARWEEK(bt.RequestDate, 1) = YEARWEEK(CURDATE(), 1)")
    elif time_filter == 'This Month':
        conditions.append("MONTH(bt.RequestDate) = MONTH(CURDATE()) AND YEAR(bt.RequestDate) = YEAR(CURDATE())")
    elif time_filter == 'This Year':
        conditions.append("YEAR(bt.RequestDate) = YEAR(CURDATE())")

    # Status filter with overdue exclusion
    if status_filter != 'All':
        if status_filter == 'Pending':
            conditions.append("(bt.Status = 'Pending' AND (bt.DueDate IS NULL OR bt.DueDate >= %s))")
            values.append(current_date)
        elif status_filter == 'Overdue':
            conditions.append("bt.Status = 'Pending' AND bt.DueDate < %s")
            values.append(current_date)
        else:
            conditions.append("bt.Status = %s")
            values.append(status_filter)

    # Material filter (requires join)
    material_join = ""
    if material_filter != 'All':
        material_join = """
        JOIN TransactionDetail td ON bt.TransactionID = td.TransactionID
        JOIN Material m ON td.MaterialID = m.MaterialID
        """
        conditions.append("m.Name = %s")
        values.append(material_filter)

    # --- Build query ---
    where_clause = "WHERE " + " AND ".join(conditions) if conditions else ""
    query = f"""
        SELECT bt.TransactionID, s.StudentID, s.Name AS StudentName, s.Course, s.Year,
               bt.Status, bt.RequestDate, bt.DueDate,
               CASE 
                   WHEN bt.Status = 'Pending' AND bt.DueDate < %s THEN 'Overdue'
                   ELSE bt.Status
               END AS FinalStatus
        FROM BorrowTransaction bt
        JOIN Student s ON bt.StudentID = s.StudentID
        {material_join}
        {where_clause}
        ORDER BY bt.RequestDate DESC
    """
    values.insert(0, current_date)  # For the CASE statement handling overdue status

    cursor.execute(query, tuple(values))
    transactions = cursor.fetchall()

    # Group by student
    students = {}
    for tx in transactions:
        sid = tx['StudentID']
        if sid not in students:
            students[sid] = {
                'name': tx['StudentName'],
                'course': tx['Course'],
                'year': tx['Year'],
                'transactions': []
            }
        students[sid]['transactions'].append(tx)

    # Get list of material names for the dropdown
    cursor.execute("SELECT DISTINCT Name FROM Material ORDER BY Name ASC")
    material_names = [row['Name'] for row in cursor.fetchall()]

    return render_template(
        'dashboard.html',
        students=students,
        material_names=material_names,
        selected_time=time_filter,
        selected_status=status_filter,
        selected_material=material_filter
    )

@app.route('/student_profile/<int:student_id>')
@role_required('Admin', 'LabManager')
def student_profile(student_id):
    cursor.execute("SELECT * FROM Student WHERE StudentID = %s", (student_id,))
    student = cursor.fetchone()

    cursor.execute("""
        SELECT bt.TransactionID,
               bt.RequestDate, 
               bt.DueDate,
               CASE 
                 WHEN bt.Status = 'Pending' AND bt.DueDate IS NOT NULL AND bt.DueDate < %s THEN 'Overdue'
                 ELSE bt.Status
               END AS Status,
               GROUP_CONCAT(m.Name SEPARATOR ', ') AS Materials
        FROM BorrowTransaction bt
        JOIN TransactionDetail td ON bt.TransactionID = td.TransactionID
        JOIN Material m ON td.MaterialID = m.MaterialID
        WHERE bt.StudentID = %s
        GROUP BY bt.TransactionID
        ORDER BY bt.RequestDate DESC
    """, (datetime.now(), student_id))
    transactions = cursor.fetchall()

    return render_template('student_profile.html', student=student, transactions=transactions)


@app.route('/transaction/<int:transaction_id>')
def transaction_details(transaction_id):
    if 'manager_id' not in session:
        return redirect('/')
    cursor.execute("""
        SELECT bt.TransactionID, s.Name AS StudentName, s.Course, s.Year,
               bt.Status, bt.RequestDate, bt.DueDate
        FROM BorrowTransaction bt
        JOIN Student s ON bt.StudentID = s.StudentID
        WHERE bt.TransactionID = %s
    """, (transaction_id,))
    transaction = cursor.fetchone()
    cursor.execute("""
        SELECT m.Name, td.Quantity
        FROM TransactionDetail td
        JOIN Material m ON td.MaterialID = m.MaterialID
        WHERE td.TransactionID = %s
    """, (transaction_id,))
    raw_items = cursor.fetchall()
    item_summary = defaultdict(int)
    for item in raw_items:
        item_summary[item['Name']] += item['Quantity']
    grouped_items = [{'Name': name, 'Quantity': qty} for name, qty in item_summary.items()]
    return render_template('transaction_detail.html', transaction=transaction, items=grouped_items)

@app.route('/materials', methods=['GET', 'POST'])
def materials():
    if 'manager_id' not in session:
        return redirect('/')

    if request.method == 'POST':
        name = request.form['name']
        desc = request.form['description']
        qty = int(request.form['quantity'])
        cursor.execute("INSERT INTO Material (Name, Description, StockQuantity) VALUES (%s, %s, %s)", (name, desc, qty))
        db.commit()
        return redirect('/materials')

    cursor.execute("""
    SELECT 
        m.MaterialID,
        m.Name,
        m.Description,
        m.StockQuantity,
        IFNULL(SUM(CASE 
            WHEN bt.Status = 'Approved' THEN td.Quantity 
            ELSE 0 END), 0) AS Borrowed
    FROM Material m
    LEFT JOIN TransactionDetail td ON m.MaterialID = td.MaterialID
    LEFT JOIN BorrowTransaction bt ON td.TransactionID = bt.TransactionID
    GROUP BY m.MaterialID
    ORDER BY m.MaterialID ASC
    """)
    materials = cursor.fetchall()

    return render_template('materials.html', materials=materials)


@app.route('/materials/increase/<int:material_id>')
def increase_material(material_id):
    cursor.execute("UPDATE Material SET StockQuantity = StockQuantity + 1 WHERE MaterialID = %s", (material_id,))
    db.commit()
    return redirect('/materials')

@app.route('/materials/decrease/<int:material_id>')
def decrease_material(material_id):
    cursor.execute("UPDATE Material SET StockQuantity = GREATEST(StockQuantity - 1, 0) WHERE MaterialID = %s", (material_id,))
    db.commit()
    return redirect('/materials')

@app.route('/materials/delete/<int:material_id>')
def delete_material(material_id):
    try:
        cursor.execute("DELETE FROM Material WHERE MaterialID = %s", (material_id,))
        db.commit()
        return redirect('/materials')
    except mysql.connector.Error as e:
        if e.errno == 1451:  # Foreign key constraint error
            return redirect('/materials?delete_error=true')
        else:
            raise  # Let other errors raise normally

@app.route('/approve/<int:transaction_id>', methods=['GET', 'POST'])
def approve(transaction_id):
    if 'manager_id' not in session:
        return redirect('/')

    if request.method == 'POST':
        due_date = request.form['due_date']
        due_time = request.form['due_time']
        full_due = f"{due_date} {due_time}"

        # 1. Approve the request and set due date
        cursor.execute("""
            UPDATE BorrowTransaction
            SET Status = 'Approved', DueDate = %s
            WHERE TransactionID = %s
        """, (full_due, transaction_id))

        # 2. Fetch borrowed items to deduct stock
        cursor.execute("""
            SELECT MaterialID, Quantity
            FROM TransactionDetail
            WHERE TransactionID = %s
        """, (transaction_id,))
        borrowed_items = cursor.fetchall()

        for item in borrowed_items:
            cursor.execute("""
                UPDATE Material
                SET StockQuantity = StockQuantity - %s
                WHERE MaterialID = %s
            """, (item['Quantity'], item['MaterialID']))

        # 3. Notify lab manager
        cursor.execute("INSERT INTO Notifications (Message) VALUES (%s)",
                       ("New borrow request approved!",))

        db.commit()
        return redirect('/dashboard')

    # If GET: Fetch items for review
    cursor.execute("""
        SELECT m.Name, td.Quantity
        FROM TransactionDetail td
        JOIN Material m ON td.MaterialID = m.MaterialID
        WHERE td.TransactionID = %s
    """, (transaction_id,))
    items = cursor.fetchall()

    return render_template('approve_due_date.html',
                           transaction_id=transaction_id,
                           items=items)

@app.route('/returned/<int:transaction_id>')
def returned(transaction_id):
    cursor.execute("SELECT MaterialID, Quantity FROM TransactionDetail WHERE TransactionID = %s", (transaction_id,))
    items = cursor.fetchall()
    for item in items:
        cursor.execute("UPDATE Material SET StockQuantity = StockQuantity + %s WHERE MaterialID = %s", (item['Quantity'], item['MaterialID']))
    cursor.execute("UPDATE BorrowTransaction SET Status = 'Returned' WHERE TransactionID = %s", (transaction_id,))
    db.commit()
    return redirect('/dashboard')

@app.route('/reject/<int:transaction_id>')
def reject(transaction_id):
    cursor.execute("UPDATE BorrowTransaction SET Status = 'Rejected' WHERE TransactionID = %s", (transaction_id,))
    db.commit()
    return redirect('/dashboard')

@app.route('/analytics')
def analytics():
    if 'manager_id' not in session:
        return redirect('/')
    cursor.execute("SELECT SUM(Quantity) AS TotalBorrowedItems FROM TransactionDetail")
    total_borrowed = cursor.fetchone()['TotalBorrowedItems']
    cursor.execute("""
        SELECT m.Name, SUM(td.Quantity) AS TotalQuantity
        FROM TransactionDetail td
        JOIN Material m ON td.MaterialID = m.MaterialID
        GROUP BY m.Name
        ORDER BY TotalQuantity DESC
        LIMIT 5
    """)
    most_borrowed = cursor.fetchall()
    cursor.execute("SELECT COUNT(*) AS ActiveRequests FROM BorrowTransaction WHERE Status = 'Pending'")
    active = cursor.fetchone()['ActiveRequests']
    cursor.execute("SELECT COUNT(*) AS ReturnedRequests FROM BorrowTransaction WHERE Status = 'Returned'")
    returned = cursor.fetchone()['ReturnedRequests']
    cursor.execute("""
        SELECT COUNT(*) AS MonthlyRequests
        FROM BorrowTransaction
        WHERE MONTH(RequestDate) = MONTH(CURDATE()) AND YEAR(RequestDate) = YEAR(CURDATE())
    """)
    monthly = cursor.fetchone()['MonthlyRequests']
    return render_template('analytics.html',
                           total_borrowed=total_borrowed,
                           most_borrowed_materials=most_borrowed,
                           active_requests=active,
                           returned_requests=returned,
                           monthly_requests=monthly)

@app.route('/overdue')
def overdue():
    if 'manager_id' not in session:
        return redirect('/')

    current_date = datetime.now()

    cursor.execute("""
        SELECT bt.TransactionID, s.Name AS StudentName, s.StudentID, bt.DueDate, m.Name AS MaterialName, td.Quantity
        FROM BorrowTransaction bt
        JOIN TransactionDetail td ON bt.TransactionID = td.TransactionID
        JOIN Material m ON td.MaterialID = m.MaterialID
        JOIN Student s ON bt.StudentID = s.StudentID
        WHERE bt.Status = 'Pending' AND bt.DueDate < %s
        ORDER BY bt.TransactionID
    """, (current_date,))

    raw_rows = cursor.fetchall()

    # Group materials per transaction
    grouped = {}
    for row in raw_rows:
        tx_id = row['TransactionID']
        if tx_id not in grouped:
            grouped[tx_id] = {
                'TransactionID': tx_id,
                'StudentName': row['StudentName'],
                'StudentID': row['StudentID'],
                'DueDate': row['DueDate'],
                'Items': defaultdict(int)
            }
        grouped[tx_id]['Items'][row['MaterialName']] += row['Quantity']

    overdue_transactions = list(grouped.values())

    return render_template('overdue.html', overdue_transactions=overdue_transactions)

@app.route('/notifications')
def notifications():
    if 'manager_id' not in session:
        return redirect('/')
    cursor.execute("SELECT * FROM Notifications WHERE ReadStatus = FALSE ORDER BY CreatedAt DESC")
    notifs = cursor.fetchall()
    return render_template('notifications.html', notifications=notifs)

@app.route('/mark_as_read/<int:notification_id>')
def mark_as_read(notification_id):
    cursor.execute("UPDATE Notifications SET ReadStatus = TRUE WHERE NotificationID = %s", (notification_id,))
    db.commit()
    return redirect('/notifications')

@app.route('/create_user', methods=['GET', 'POST'])
@role_required('Admin', 'LabManager')
def create_user():
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        course = request.form['course']
        year = request.form['year']
        password = request.form['password']
        confirm_password = request.form['confirm_password']

        if password != confirm_password:
            flash("Passwords do not match.", "danger")
            return redirect('/create_user')

        hashed_password = generate_password_hash(password)

        cursor.execute("""
            INSERT INTO Student (Name, Email, Course, Year, Password)
            VALUES (%s, %s, %s, %s, %s)
        """, (name, email, course, year, hashed_password))
        db.commit()

        flash("Student account created successfully.", "success")
        return redirect('/manage_accounts')

    return render_template('create_user.html')

@app.route('/manage_accounts')
@role_required('Admin', 'LabManager')
def manage_accounts():
    search_query = request.args.get('search', '').strip()

    if search_query:
        like_query = f"%{search_query}%"
        cursor.execute("SELECT * FROM Student WHERE Name LIKE %s OR Email LIKE %s", (like_query, like_query))
        users = cursor.fetchall()

        cursor.execute("SELECT * FROM LabManager WHERE Name LIKE %s OR Contact LIKE %s", (like_query, like_query))
        staff = cursor.fetchall()
    else:
        cursor.execute("SELECT * FROM Student")
        users = cursor.fetchall()

        cursor.execute("SELECT * FROM LabManager")
        staff = cursor.fetchall()

    return render_template('manage_accounts.html', users=users, staff=staff, search_query=search_query)


@app.route('/delete_user/<int:user_id>')
@role_required('Admin', 'LabManager')
def delete_user(user_id):
    cursor.execute("DELETE FROM Student WHERE StudentID = %s", (user_id,))
    db.commit()
    return redirect('/manage_accounts')

@app.route('/delete_lab_staff/<int:manager_id>')
@role_required('Admin')
def delete_lab_staff(manager_id):
    if session['manager_id'] == manager_id:
        flash("You cannot delete your own account.")
        return redirect('/manage_accounts')
    cursor.execute("DELETE FROM LabManager WHERE ManagerID = %s", (manager_id,))
    db.commit()
    return redirect('/manage_accounts')

@app.route('/create_lab_staff', methods=['GET', 'POST'])
@role_required('Admin')
def create_lab_staff():
    if request.method == 'POST':
        name = request.form['name']
        contact = request.form['contact']
        password = request.form['password']
        confirm_password = request.form['confirm_password']
        role = request.form['role']

        if password != confirm_password:
            flash("Passwords do not match.", "danger")
            return redirect('/create_lab_staff')

        hashed_password = generate_password_hash(password)
        cursor.execute("INSERT INTO LabManager (Name, Contact, Password, role) VALUES (%s, %s, %s, %s)", 
                       (name, contact, hashed_password, role))
        db.commit()
        return redirect('/manage_accounts')
    return render_template('create_lab_staff.html')

@app.route('/send_reminder/<int:transaction_id>')
def send_reminder(transaction_id):
    if 'manager_id' not in session:
        return redirect('/')

    # Fetch student info and all materials for this transaction
    cursor.execute("""
        SELECT s.StudentID, s.Email, s.Name, m.Name AS MaterialName, td.Quantity, bt.DueDate
        FROM BorrowTransaction bt
        JOIN Student s ON bt.StudentID = s.StudentID
        JOIN TransactionDetail td ON bt.TransactionID = td.TransactionID
        JOIN Material m ON td.MaterialID = m.MaterialID
        WHERE bt.TransactionID = %s
    """, (transaction_id,))
    rows = cursor.fetchall()

    if not rows:
        return "Transaction not found", 404

    student_id = rows[0]['StudentID']
    name = rows[0]['Name']
    due_date = rows[0]['DueDate']

    # Group item names by quantity
    from collections import defaultdict
    item_summary = defaultdict(int)
    for row in rows:
        item_summary[row['MaterialName']] += row['Quantity']

    # Format item list as: 2x Breadboard, 1x Multimeter
    item_list = ", ".join([f"{qty}x {item}" for item, qty in item_summary.items()])

    # Build message
    message = (
        f"Hello {name},\n\n"
        f"This is a reminder that the following items you borrowed are overdue:\n"
        f"{item_list}\n"
        f"Due Date: {due_date.strftime('%Y-%m-%d %H:%M') if due_date else 'N/A'}\n\n"
        f"Please return them as soon as possible. Thank you!"
    )

    # Insert into student notifications
    cursor.execute("""
        INSERT INTO StudentNotifications (StudentID, Message, CreatedAt, ReadStatus)
        VALUES (%s, %s, NOW(), FALSE)
    """, (student_id, message))
    db.commit()

    flash("Reminder sent to student successfully.", "info")
    return redirect('/overdue')


# =======================
# Mobile API Routes
# =======================

@app.route('/student_login', methods=['POST'])
def student_login():
    data = request.get_json()  # <- must be JSON
    email = data.get('email')
    password = data.get('password')

    cursor.execute("SELECT * FROM Student WHERE Email = %s", (email,))
    student = cursor.fetchone()

    if student and check_password_hash(student['Password'], password):
        return jsonify({'success': True, 'name': student['Name']}), 200

    return jsonify({'success': False, 'message': 'Invalid credentials'}), 401



@app.route('/student/<email>')
def get_student_info(email):
    cursor.execute("SELECT StudentID, Name, Course, Year FROM Student WHERE Email = %s", (email,))
    student = cursor.fetchone()
    if not student:
        return jsonify({'success': False}), 404

    student_id = student['StudentID']
    cursor.execute("""
        SELECT bt.TransactionID,
               CASE WHEN bt.Status = 'Pending' AND bt.DueDate < %s THEN 'Overdue' ELSE bt.Status END AS Status,
               bt.RequestDate, bt.DueDate
        FROM BorrowTransaction bt
        WHERE bt.StudentID = %s
        ORDER BY bt.RequestDate DESC
    """, (datetime.now(), student_id))
    transactions = cursor.fetchall()

    for tx in transactions:
        cursor.execute("""
            SELECT m.Name, td.Quantity
            FROM TransactionDetail td
            JOIN Material m ON td.MaterialID = m.MaterialID
            WHERE td.TransactionID = %s
        """, (tx['TransactionID'],))
        items = cursor.fetchall()

        grouped = defaultdict(int)
        for item in items:
            grouped[item['Name']] += item['Quantity']
        tx['Items'] = ', '.join(f"{qty}x {name}" for name, qty in grouped.items())

    has_overdue = any(tx['Status'] == 'Overdue' for tx in transactions)

    return jsonify({
        'success': True,
        'student': {
            'Name': student['Name'],
            'Course': student['Course'],
            'Year': student['Year']
        },
        'transactions': transactions,
        'has_overdue': has_overdue
    })
    
@app.route('/borrow_request', methods=['POST'])
def borrow_request():
    data = request.get_json()
    email = data['email']
    items = data['items']

    cursor.execute("SELECT StudentID FROM Student WHERE Email = %s", (email,))
    student = cursor.fetchone()

    if not student:
        return jsonify({'success': False, 'message': 'Student not found'}), 404

    student_id = student['StudentID']

    # 1. Validate stocks for all requested items
    for item in items:
        cursor.execute("SELECT StockQuantity FROM Material WHERE MaterialID = %s", (item['material_id'],))
        material = cursor.fetchone()

        if not material:
            return jsonify({'success': False, 'message': 'Material not found'}), 404

        if item['quantity'] > material['StockQuantity']:
            return jsonify({
                'success': False,
                'message': f"Not enough stock for material ID {item['material_id']}"
            }), 400

    # 2. Insert borrow transaction
    cursor.execute("INSERT INTO BorrowTransaction (StudentID, Status, RequestDate) VALUES (%s, 'Pending', NOW())", (student_id,))
    db.commit()
    transaction_id = cursor.lastrowid

    # 3. Insert transaction details
    for item in items:
        cursor.execute("""
            INSERT INTO TransactionDetail (TransactionID, MaterialID, Quantity)
            VALUES (%s, %s, %s)
        """, (transaction_id, item['material_id'], item['quantity']))

    # 4. Add student notification
    cursor.execute("""
        INSERT INTO StudentNotifications (StudentID, Message, CreatedAt, ReadStatus)
        VALUES (%s, %s, NOW(), FALSE)
    """, (student_id, 'Your borrow request has been submitted.'))

    db.commit()
    return jsonify({'success': True})


@app.route('/student_notifications/<email>')
def get_student_notifications(email):
    cursor.execute("SELECT StudentID FROM Student WHERE Email = %s", (email,))
    student = cursor.fetchone()
    if not student:
        return jsonify({'success': False}), 404
    student_id = student['StudentID']
    cursor.execute("""
        SELECT NotificationID, Message, CreatedAt, ReadStatus
        FROM StudentNotifications
        WHERE StudentID = %s
        ORDER BY CreatedAt DESC
    """, (student_id,))
    notifications = cursor.fetchall()
    return jsonify({'success': True, 'notifications': notifications})

@app.route('/mark_notification_read', methods=['POST'])
def mark_notification_read():
    data = request.get_json()
    notification_id = data.get('notification_id')
    cursor.execute("UPDATE StudentNotifications SET ReadStatus = TRUE WHERE NotificationID = %s", (notification_id,))
    db.commit()
    return jsonify({'success': True})

@app.route('/materials_available')
def materials_available():
    cursor.execute("""
        SELECT 
            m.MaterialID, 
            m.Name, 
            m.StockQuantity,
            IFNULL(SUM(CASE WHEN bt.Status = 'Approved' THEN td.Quantity ELSE 0 END), 0) AS Borrowed
        FROM Material m
        LEFT JOIN TransactionDetail td ON m.MaterialID = td.MaterialID
        LEFT JOIN BorrowTransaction bt ON td.TransactionID = bt.TransactionID
        GROUP BY m.MaterialID
        HAVING StockQuantity > Borrowed
    """)
    materials = cursor.fetchall()
    return jsonify(materials)

@app.route('/change_password', methods=['POST'])
def change_password():
    data = request.get_json()
    email = data['email']
    old_password = data['old_password']
    new_password = data['new_password']

    cursor.execute("SELECT Password FROM Student WHERE Email = %s", (email,))
    student = cursor.fetchone()

    if not student or not check_password_hash(student['Password'], old_password):
        return jsonify({'success': False, 'message': 'Incorrect current password'}), 401

    hashed_password = generate_password_hash(new_password)
    cursor.execute("UPDATE Student SET Password = %s WHERE Email = %s", (hashed_password, email))
    db.commit()
    return jsonify({'success': True, 'message': 'Password updated successfully'})

@app.route('/change_password', methods=['POST'])
def student_change_password():
    data = request.get_json()
    email = data.get('email')
    old_password = data.get('old_password')
    new_password = data.get('new_password')

    if not email or not old_password or not new_password:
        return jsonify({'success': False, 'message': 'Missing fields'}), 400

    cursor.execute("SELECT * FROM Student WHERE Email = %s", (email,))
    student = cursor.fetchone()

    if student and check_password_hash(student['Password'], old_password):
        hashed_password = generate_password_hash(new_password)
        cursor.execute("UPDATE Student SET Password = %s WHERE Email = %s", (hashed_password, email))
        db.commit()
        return jsonify({'success': True, 'message': 'Password updated successfully'}), 200
    else:
        return jsonify({'success': False, 'message': 'Old password is incorrect'}), 401


if __name__ == '__main__':
    app.run(debug=True)
