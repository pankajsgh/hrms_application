# HRMS: Human Resource Management System (Flutter, Windows + macOS)

Offline desktop HRMS with a local SQLite database and role-based login.

## First run
```bash
cd hrms
flutter config --enable-windows-desktop   # or --enable-macos-desktop on a Mac
flutter create --platforms=windows,macos .
flutter pub get
flutter run -d windows                     # or: flutter run -d macos
```
Sign in with **admin / admin123**. You must set a new password on first sign-in.
Run `flutter create` only once, it adds the `windows/` and `macos/` folders.

### macOS only: allow file dialogs
In both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`
add inside `<dict>`:
```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```
(needed for Save dialogs, CSV/PDF export and document upload)

## Roles
| Feature | Admin | HR | Manager | Employee |
|---|---|---|---|---|
| Dashboard | all | all | team | own |
| Employees (add/edit, salary) | yes | yes | - | - |
| Attendance: own check in/out | yes | yes | yes | yes |
| Attendance: daily register | edit | edit | view team | - |
| Leave: apply, balances | yes | yes | yes | yes |
| Leave: approve | all | all | team | - |
| Leave types and holidays | yes | yes | - | - |
| Payroll: run, export | yes | yes | - | - |
| Payslips (PDF) | own + all | own + all | own | own |
| Recruitment | yes | yes | - | - |
| Performance: goals | all | all | team | own |
| Performance: reviews | write all | write all | write team | read own |
| Documents | all | all | team | own |
| Reports (CSV) | yes | yes | - | - |
| Users and access | yes | - | - | - |

## How things work
- **Attendance**: statuses are Present, Half Day, Leave, Unpaid Leave, Absent. Approved leave
  automatically writes Leave/Unpaid Leave on each working day.
- **Working days**: Monday to Friday, excluding holidays you add. Weekdays with no record count
  as absent.
- **Payroll**: gross = (basic + HRA + allowances) x paid days / working days.
  PF = PF% x prorated basic. Net = gross - PF - other deduction. Run it after the month ends.
- **Leave balance**: paid leave types are limited to days per year (pending requests reserve days).
- **Passwords**: stored salted and hashed (SHA-256). New or reset passwords must be changed at next sign-in.

## Data location
- Windows: `%APPDATA%\<company>\hrms\hrms.db` (via the app support folder)
- macOS: `~/Library/Application Support/<bundle id>/hrms.db`
- Uploaded documents are copied into a `documents` folder next to the database.
Back up by copying those files.

## Customise
- Company name on login and payslips: `kCompany` in `lib/core/ui.dart`
- Currency symbol: `money()` in `lib/core/common.dart` and `_rs()` in `lib/core/payslip.dart`

## Troubleshooting
- If `flutter pub get` complains about `sqlite3_flutter_libs`, delete that line from `pubspec.yaml`
  (macOS works without it; Windows needs it or a `sqlite3.dll` next to the exe).
- This is a single-computer app. For many users on many computers you would need a server database.
