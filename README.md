# Student ID Prepaid Card System

A cross-platform application built using Flutter and Flask where
a college ID card works as a prepaid wallet with rewards, tiers,
split payments, and challenges.

## Tech Stack
- Flutter (Android + Web)
- Flask (Backend)
- MySQL (Database)

## Features
- OTP-based login & registration
- QR-based payments
- Split payments
- Rewards & tier system


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
