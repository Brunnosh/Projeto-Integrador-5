# Where the built APK will land (and be pulled from)
APK_OUTPUT_DIR  := apk_output
APK_OUTPUT_PATH := $(APK_OUTPUT_DIR)/app-release.apk

.PHONY: build-apk install-apk full-install clean

build-apk:
	if not exist $(APK_OUTPUT_DIR) mkdir $(APK_OUTPUT_DIR)
	docker compose up -d backend db
	docker compose run --rm apk_builder

install-apk:
	if not exist $(APK_OUTPUT_PATH) ( \
		echo ❌ APK not found && exit /b 1 \
	)
	adb devices | findstr /C:"device" >nul || ( \
		echo ❌ No device/emulator online && exit /b 1 \
	)
	adb install -r $(APK_OUTPUT_PATH)

full-install: build-apk install-apk

clean:
	if exist $(APK_OUTPUT_DIR) rmdir /s /q $(APK_OUTPUT_DIR)