# Student ID Prepaid Card System

A cross-platform application where a college student ID card functions
as both an identification card and a prepaid digital wallet.

Students can make payments, split expenses with friends, earn rewards,
unlock tiers, and receive freebies through weekly and monthly challenges.

---

## 🚀 Tech Stack

### Frontend
- Flutter (Android + Web)

### Backend
- Python (Flask)
- REST APIs
- JWT Authentication

### Database
- MySQL

---

## ✨ Core Features

- OTP-based registration & login using mobile number
- Role-based access (Student / Merchant / Admin)
- Prepaid wallet system
- QR-based payments
- Split payments with friends
- Reward points & tier system (Silver / Gold / Platinum)
- Weekly & monthly challenges
- Freebies & notifications

---

## 📁 Project Structure

student-id-prepaid-card/
├── frontend_flutter/ # Flutter application
├── backend_flask/ # Flask backend APIs
├── .gitignore # Git ignore rules
└── README.md # Project documentation

---

## 🛠️ Setup Instructions
### Backend (Flask)
```bash
cd backend_flask
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python app.py

### Frontend (Flutter)
cd frontend_flutter/student_id_app
flutter pub get
flutter run
