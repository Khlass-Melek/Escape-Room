
# Setup Guide for Escape Room Admin App

This guide will help you set up and run the Escape Room Admin application.

## Prerequisites

1.  **Flutter SDK**: Ensure you have Flutter installed.
    -   Open your terminal (PowerShell or Command Prompt).
    -   Run `flutter --version` to check your version.
    -   **Note:** I have modified `pubspec.yaml` to allow running with Flutter SDK `>=3.10.1` (which matches your current version).
    -   Long-term, it is recommended to upgrade to the latest stable version (`flutter upgrade`).

2.  **Verify Environment**:
    -   Run `flutter doctor` to check if there are any issues with your setup (e.g., missing Android Studio components or Visual Studio for Windows).

## Installation

1.  **Navigate to the project directory**:
    Open a terminal in the project folder:
    ```bash
    cd c:\Users\azizz\Downloads\Escape-Room-main
    ```

2.  **Install Dependencies**:
    Run the following command to download all the required libraries listed in `pubspec.yaml`:
    ```bash
    flutter pub get
    ```

## Running the App

You can run the app on different platforms depending on your setup.

### Run on Windows (Desktop)
If you are on Windows and have Visual Studio installed (with C++ workload), you can run the app as a native Windows application:
```bash
flutter run -d windows
```

### Run on Web (Chrome)
The easiest way to test the app without additional setup is usually via Chrome:
```bash
flutter run -d chrome
```

### Run on Android Emulator or Device
1.  Make sure an emulator is running or a device is connected.
2.  Run:
    ```bash
    flutter run
    ```
    (Select the device if prompted).

## Troubleshooting

-   **Version Mismatch**: If you see errors about SDK version, ensure you are running a supported Flutter version.
-   **Platform Not Found**: If `flutter run -d windows` fails, run `flutter config --enable-windows-desktop` to enable Windows support.
-   **Dependency Errors**: If `flutter pub get` fails, check if you need to run `flutter pub upgrade`.
