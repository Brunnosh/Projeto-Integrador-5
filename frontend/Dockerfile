# Usa uma imagem base do Flutter para web
FROM flutter/flutter:stable

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos do projeto Flutter
COPY . .

# Executa o build para web
RUN flutter build web --release

# Usa um servidor web leve para servir os arquivos buildados
FROM nginx:alpine

# Remove a configuração padrão do nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copia a configuração do nginx para servir o build do Flutter
COPY nginx.conf /etc/nginx/conf.d

# Copia os arquivos buildados do Flutter para a pasta de arquivos do nginx
COPY --from=0 /app/build/web /usr/share/nginx/html

# Expõe a porta 80 para acesso
EXPOSE 80

# Comando para iniciar o nginx
CMD ["nginx", "-g", "daemon off;"]