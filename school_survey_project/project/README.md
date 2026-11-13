# School Survey (EN / FR / AR)

## Get the APK without installing anything
1. Create a free account on https://github.com and make a new repository (private is fine).
2. Click "Add file" > "Upload files", drag in the CONTENTS of this folder (including the hidden `.github` folder), commit.
3. Open the "Actions" tab > "Build APK" > "Run workflow".
4. After ~5-8 minutes open the finished run and download `school-survey-apk` (a zip containing app-release.apk).
5. Copy app-release.apk to the phone, open it, allow "Install unknown apps" when asked.

## Build locally (optional)
flutter create --org com.school --project-name school_survey --platforms=android .
flutter pub get
flutter build apk --release
