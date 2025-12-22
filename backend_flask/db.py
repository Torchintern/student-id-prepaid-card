import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Harshith@799",
    database="student_card_db"
)

cursor = db.cursor(dictionary=True)
