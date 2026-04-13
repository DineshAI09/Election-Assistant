# Step-by-step: Run Election Assistant Flutter app in CMD

Follow these steps in **Command Prompt (CMD)** or **PowerShell**. Use a terminal where Flutter is installed and on your PATH.

---

## Step 1: Open Command Prompt

- Press **Win + R**, type **cmd**, press **Enter**  
  **OR**
- In Cursor/VS Code: **Terminal → New Terminal**

---

## Step 2: Go to the Flutter project folder

```cmd
cd /d "D:\election-assistant (1)\election_assistant_flutter"
```

*(Use your actual path if the project is somewhere else.)*

---

## Step 3: Check Flutter

```cmd
flutter --version
```

- If you see a version number, continue.  
- If you see *"flutter is not recognized"*, add Flutter to your PATH (see **FLUTTER_SETUP.md**) and open a **new** CMD window, then repeat from Step 1.

---

## Step 4: Create Android/iOS project files (first time only)

Run this **once** if the folder does **not** already contain `android` and `ios` folders:

```cmd
flutter create . --project-name election_assistant
```

---

## Step 5: Get dependencies

```cmd
flutter pub get
```

---

## Step 6: (Optional) Start the backend server

If you want answers from the Node server (instead of only offline mode):

1. Open a **second** CMD window.
2. Go to the **main** project folder (where `server.js` is):

   ```cmd
   cd /d "D:\election-assistant (1)\election-assistant"
   node server.js
   ```

3. Leave this window open. The server runs on port 5000.

*(If you skip this, the app still runs and uses on-device answers.)*

---

## Step 7: Run the app

In the **first** CMD window (inside `election_assistant_flutter`), run:

```cmd
flutter run
```

- If you have an **Android emulator** or **phone** connected (USB debugging on), Flutter will ask you to pick a device and then launch the app.
- If no device is found, start an emulator from Android Studio first, or connect a phone, then run `flutter run` again.

---

## Quick copy-paste (all in one)

After opening CMD and making sure Flutter works:

```cmd
cd /d "D:\election-assistant (1)\election_assistant_flutter"
flutter create . --project-name election_assistant
flutter pub get
flutter run
```

*(Run `flutter create` only once; after that you can use only `flutter pub get` and `flutter run`.)*

---

## Build APK (optional)

To create an APK file instead of running on a device:

```cmd
cd /d "D:\election-assistant (1)\election_assistant_flutter"
flutter build apk
```

The APK will be at:  
`build\app\outputs\flutter-apk\app-release.apk`
