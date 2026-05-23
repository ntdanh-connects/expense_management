# Cấp quyền thực thi cho script: chmod +x run_build.sh
rm pubspec.lock
fvm flutter clean && fvm flutter pub get
fvm flutter packages pub run build_runner build --delete-conflicting-outputs