import mysql.connector

def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Harshith@799",
        database="student_id_db"
    )
