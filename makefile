# ════════════════ Paths / artefacts ═════════════════════════════════
APK_OUT_RELEASE := frontend\build\app\outputs\flutter-apk\app-release.apk
APK_OUT_DEBUG   := frontend\build\app\outputs\flutter-apk\app-debug.apk

# ════════════════ Phony targets ═════════════════════════════════════
.PHONY: up build-release build-debug \
        install-release install-debug \
        full-release debug-run clean

# ────────────────────────────────────────────────────────────────────
# 1) Bring backend + DB up (detached)
up:
	docker compose up -d backend db

# ────────────────────────────────────────────────────────────────────
# 2) Build APKs natively (requires Flutter SDK on host)
build-release:
	cd frontend && flutter clean && flutter pub get && flutter build apk --release

build-debug:
	cd frontend && flutter clean && flutter pub get && flutter build apk --debug

# ────────────────────────────────────────────────────────────────────
# 3) Install APKs on attached device / emulator
install-release: $(APK_OUT_RELEASE)
	adb devices | findstr /C:"device" >nul || (echo ❌ No device/emulator & exit /b 1)
	adb install -r $(APK_OUT_RELEASE)

install-debug: $(APK_OUT_DEBUG)
	adb devices | findstr /C:"device" >nul || (echo ❌ No device/emulator & exit /b 1)
	adb install -r $(APK_OUT_DEBUG)

# Build *and* install release in one go
full-release: build-release install-release

# ────────────────────────────────────────────────────────────────────
# 4) Live debug / break-points (runs on host, hot-reload enabled)
debug-run: up
	@echo Launching Flutter in DEBUG mode...
	adb start-server
	adb devices | findstr /C:"device" >nul || (echo ❌ No device/emulator & exit /b 1)
	cd frontend && flutter pub get && flutter run -d emulator-5554

# ────────────────────────────────────────────────────────────────────
# 5) Clean all Flutter build artefacts
clean:
	cd frontend && flutter clean
