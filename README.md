<div align="center">
  <img src="https://img.icons8.com/color/120/000000/task-completed.png" alt="Tracking Task Logo" />
  
  # Tracking Task
  **A Premium Task Management & Tracking App built with Flutter & Firebase**

  <p align="center">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/Platform-Android_|_iOS-blue?style=for-the-badge" />
  </p>
</div>

---

## 📖 Overview
**Tracking Task** is a modern, high-performance task management application designed for individuals and teams to effectively organize, assign, and track daily tasks. Featuring a **premium dark-mode UI** built from scratch, the app offers seamless cloud synchronization, role-based access control, and rich data visualization.

---

## ✨ Key Features
- **🔐 Secure Authentication:** Seamless login and registration powered by Firebase Authentication.
- **👥 Role-Based Access Control (RBAC):**
  - **Admins:** Can create tasks, assign work to any intern/student, and oversee global progress.
  - **Interns/Students:** Have focused dashboards showing only tasks assigned to them.
- **⚡ Real-time Synchronization:** Tasks are stored in Cloud Firestore and instantly update across all devices without needing to refresh.
- **📊 Productivity Analytics:** Dedicated Stats screen offering a visual breakdown of Total, Pending, Active, and Completed tasks.
- **🎨 Premium UI/UX:** A carefully curated dark-theme featuring dynamic micro-animations, glassmorphism elements, and a rich color palette to provide a state-of-the-art user experience.
- **📅 Deadline Tracking:** Optional due-date assignments with formatted timeline displays.

---

## 🛠️ Technology Stack
- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend & Database:** [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore)
- **State Management:** `provider` (UserProvider, TaskProvider)
- **Design System:** Custom Dark Theme (`app_theme.dart`)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- An active Firebase Project

### Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/withshafan/task_tracking_app.git
   cd task_tracking_app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Head over to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
   - Register your Android and iOS applications.
   - Download the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in their respective directories.
   - Enable **Email/Password Authentication** in Firebase Auth.
   - Initialize **Firestore Database**.

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure
```text
lib/
├── models/         # Data models (Task, User)
├── providers/      # State management (TaskProvider, UserProvider)
├── repositories/   # Firebase data fetching and streaming
├── screens/        # Main UI screens (Home, Profile, Stats, Auth)
├── services/       # Core services (AuthService, UserService)
├── widgets/        # Reusable UI components (Task Cards, Bottom Sheets)
├── app_theme.dart  # Core design system and color palette
└── main.dart       # App entry point
```

---

## 📸 Screenshots
*(Coming Soon — Add your application screenshots here)*

<div align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Home+Screen" width="250" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Stats+Screen" width="250" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Profile+Screen" width="250" />
</div>

---

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/withshafan/task_tracking_app/issues).

---

<div align="center">
  <b>Built with ❤️ by withshafan</b><br>
  Tracking Task © 2026
</div>
