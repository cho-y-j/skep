# SKEP Flutter App - Quick Start Guide

## 📋 Prerequisites

- Flutter 3.19+ ([Install](https://flutter.dev/docs/get-started/install))
- Dart 3.x (comes with Flutter)
- API Gateway running on `http://localhost:8080`
- Optional: Firebase project for push notifications

## 🚀 Quick Setup (5 minutes)

### 1. Install Dependencies
```bash
cd skep_app
flutter pub get
```

### 2. Run on Web (Development)
```bash
flutter run -d chrome
```

### 3. Login with Test Credentials
- **URL**: http://localhost:54389 (or shown in terminal)
- **Email**: test@example.com
- **Password**: password123

## 🏗️ Project Structure at a Glance

```
lib/
├── main.dart              ← Entry point
├── app.dart               ← App configuration
├── core/                  ← Shared code
│   ├── constants/         ← Colors, styles, API endpoints
│   ├── network/           ← HTTP client (Dio)
│   ├── storage/           ← Secure token storage
│   ├── utils/             ← Date, location helpers
│   └── widgets/           ← Reusable UI components
├── features/              ← Feature modules
│   ├── auth/              ← Login & registration
│   ├── dashboard/         ← Role-based dashboards
│   ├── dispatch/          ← Work records with NFC & GPS
│   ├── inspection/        ← Safety inspections
│   └── location/          ← Live location map
└── router/                ← Navigation (GoRouter)
```

## 🔑 Key Files to Know

| File | Purpose |
|------|---------|
| `lib/core/constants/api_endpoints.dart` | API configuration |
| `lib/core/constants/app_colors.dart` | Theme colors |
| `lib/router/app_router.dart` | Navigation & routing |
| `lib/features/auth/bloc/auth_bloc.dart` | Authentication logic |
| `pubspec.yaml` | Dependencies |

## 🎯 Main Features

### ✅ Implemented
1. **Authentication**
   - Login/registration
   - JWT token management
   - Automatic token refresh

2. **Role-Based Dashboards**
   - Admin dashboard
   - Supplier dashboard
   - BP company dashboard

3. **Work Records**
   - GPS check-in
   - NFC scanning
   - Work timer
   - Status tracking

4. **Safety Inspections**
   - NFC-triggered workflow
   - Sequential item checking
   - Photo attachment
   - GPS validation

5. **Live Location Tracking**
   - OpenStreetMap integration
   - Real-time WebSocket updates
   - Worker markers with status

## 🔧 Configuration

### API Endpoints
Edit `lib/core/constants/api_endpoints.dart`:
```dart
static const String baseUrl = 'http://localhost:8080';
```

### Colors & Typography
- Colors: `lib/core/constants/app_colors.dart`
- Fonts: `lib/core/constants/app_text_styles.dart`

### Firebase (Optional)
Update `lib/firebase_options.dart` with your Firebase credentials:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  // ...
);
```

## 📱 Running on Different Platforms

### Web
```bash
flutter run -d chrome
```

### iOS
```bash
flutter run -d ios
```

### Android
```bash
flutter run -d android
```

## 🏗️ Building for Production

### Web
```bash
flutter build web --release
# Output: build/web/
```

### iOS
```bash
flutter build ios --release
# Output: build/ios/Release-iphoneos/
```

### Android
```bash
# APK
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

# App Bundle (Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

## 🐳 Docker Deployment

### Build
```bash
docker build -t skep-app .
```

### Run
```bash
docker run -p 80:80 skep-app
# Access: http://localhost
```

### Docker Compose (Full Stack)
```bash
docker-compose up -d
# Access:
# - Frontend: http://localhost
# - pgAdmin: http://localhost:5050
# - API: http://localhost:8080
```

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Build Runner (for code generation)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🐛 Troubleshooting

### Issue: "Could not connect to API Gateway"
**Solution**: Ensure API Gateway is running on port 8080
```bash
# Check if port is in use
lsof -i :8080
```

### Issue: "NFC not working on web"
**Solution**: NFC only works on physical iOS/Android devices

### Issue: "Location permission denied"
**Solution**: Grant location permission in app settings or use simulator with location enabled

### Issue: "WebSocket connection failed"
**Solution**: Check firewall allows WebSocket connections to port 8080

### Clean Build Cache
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
```

## 📚 Code Examples

### Adding a New BLoC Event
```dart
// lib/features/myfeature/bloc/myfeature_event.dart
class MyEvent extends MyFeatureEvent {
  final String data;
  const MyEvent({required this.data});

  @override
  List<Object?> get props => [data];
}
```

### Using BLoC in UI
```dart
BlocBuilder<MyBloc, MyState>(
  builder: (context, state) {
    if (state is MyLoading) {
      return CircularProgressIndicator();
    }
    if (state is MyLoaded) {
      return Text(state.data);
    }
    return SizedBox.shrink();
  },
);
```

### Making API Calls
```dart
final dioClient = context.read<DioClient>();
final response = await dioClient.get<Map<String, dynamic>>(
  '/api/endpoint',
);
```

## 📖 Documentation

- **Full README**: See `README.md`
- **Implementation Details**: See `IMPLEMENTATION_SUMMARY.md`
- **API Docs**: Check backend API documentation
- **Flutter Docs**: https://flutter.dev/docs

## 🚢 Deployment Checklist

- [ ] Update API endpoints for production
- [ ] Configure Firebase credentials
- [ ] Update app bundle ID (iOS/Android)
- [ ] Enable HTTPS/SSL
- [ ] Configure proper CORS headers
- [ ] Set up CI/CD pipeline
- [ ] Test on actual devices
- [ ] Update App Store/Play Store metadata
- [ ] Configure push notifications
- [ ] Set up monitoring and analytics

## 📞 Support

For issues:
1. Check the README.md
2. Check Dart console for errors
3. Check network tab in Chrome DevTools
4. Review API logs

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Pattern](https://bloclibrary.dev)
- [GoRouter Guide](https://pub.dev/packages/go_router)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Flutter Map](https://pub.dev/packages/flutter_map)

## 📝 Notes

- All code follows BLoC pattern for state management
- API client automatically adds JWT tokens to requests
- Tokens are automatically refreshed on 401 responses
- Tokens stored in secure storage (encrypted)
- Web app supports SPA routing with Nginx
- Full Docker stack includes database and Redis

---

**Happy Coding! 🎉**

For detailed information, see `README.md` and `IMPLEMENTATION_SUMMARY.md`
