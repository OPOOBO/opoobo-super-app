# OPOOBO One — Quick Commands

## Build APK for physical device (LAN)
```
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.4:8000/api/v1
```

## Start Laravel backend on LAN
```
cd ~/Documents/Projects/opoobo-backend
php artisan serve --host=0.0.0.0
```