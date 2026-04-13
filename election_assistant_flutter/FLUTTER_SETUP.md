# Fix: "flutter is not recognized"

Flutter is either **not installed** or **not on your PATH**. Fix it using one of the options below.

---

## Option 1: Install Flutter (if you haven’t)

1. **Download** the Flutter SDK for Windows:  
   https://docs.flutter.dev/get-started/install/windows  
   (Stable ZIP, e.g. “flutter_windows_x.x.x-stable.zip”.)

2. **Extract** the ZIP to a folder **without spaces**, for example:
   - `C:\flutter`
   - or `C:\src\flutter`
   - or `D:\flutter`

3. **Add Flutter to PATH** (use your actual path):
   - Press **Win + R**, type `sysdm.cpl`, Enter.
   - **Advanced** tab → **Environment Variables**.
   - Under **User variables** (or **System variables**), select **Path** → **Edit** → **New**.
   - Add: `C:\flutter\bin` (or `C:\src\flutter\bin` — the folder that contains `flutter.bat`).
   - OK out of all dialogs.

4. **Restart** PowerShell (or Terminal), then run:
   ```powershell
   flutter doctor
   ```

---

## Option 2: Flutter already installed but not on PATH

If Flutter is already installed (e.g. via VS Code Flutter extension or manual extract), you only need to add its `bin` folder to PATH.

1. Find where `flutter.bat` lives, for example:
   - `C:\flutter\bin`
   - `C:\src\flutter\bin`
   - `%USERPROFILE%\flutter\bin`

2. Add that folder to PATH (same steps as in Option 1, step 3).

3. **Temporary fix** (current PowerShell session only):
   ```powershell
   $env:Path += ";C:\flutter\bin"
   ```
   Replace `C:\flutter\bin` with your actual path. Then run:
   ```powershell
   flutter create . --project-name election_assistant
   ```

---

## Option 3: Use Flutter via VS Code / Cursor

If you use the **Flutter extension** in VS Code or Cursor, it may have installed Flutter in a custom location. Check:

- Extension settings for “Flutter SDK path”.
- Or run in the integrated terminal (sometimes the extension adds Flutter to that terminal’s PATH):
  ```powershell
  flutter create . --project-name election_assistant
  ```

---

## Verify

In a **new** PowerShell window:

```powershell
cd "D:\election-assistant (1)\election_assistant_flutter"
flutter --version
flutter create . --project-name election_assistant
```

If `flutter --version` works, PATH is set correctly.
