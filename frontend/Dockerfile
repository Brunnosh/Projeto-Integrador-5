# Usa uma imagem base do Flutter para web
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS build

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos do projeto Flutter
COPY . .

# Certifica que o gradle está em formato unix/apk/web 
RUN apt-get update && apt-get install -y dos2unix \
 && dos2unix android/gradlew \
 && chmod +x android/gradlew

 RUN rm -f android/local.properties

# Executa o build para web/android
RUN flutter pub get \
 && flutter build apk --release