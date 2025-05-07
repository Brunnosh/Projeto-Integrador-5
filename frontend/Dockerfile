# Usa uma imagem base do Flutter para web
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS build

WORKDIR /app

# Copy Flutter project
COPY . .

# Fix Windows line-endings and make gradlew executable
RUN apt-get update && apt-get install -y dos2unix \
 && dos2unix android/gradlew \
 && chmod +x android/gradlew \
 && rm -f android/local.properties

# Build release APK
RUN flutter pub get && flutter build apk --release