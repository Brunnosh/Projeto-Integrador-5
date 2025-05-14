# 💰 **MyWallet - Projeto-Integrador-5**
**SUA PLATAFORMA DE GESTÃO FINANCEIRA PESSOAL**

---

## 👥 **Integrantes do grupo**
- Bruno Tasso Savoia RA: 22000354
- Gabriel Padreca Nicoletti RA: 20013009
- Vitor Hugo Amaro Aristides RA: 20018040
- Luan de Campos Ferreira RA: 23005247
- Nicole Silvestrini Garrio RA: 23009486

---

## 🚀 Como rodar o projeto

### ✅ Pré-requisitos
Antes de rodar o projeto, certifique-se de ter instalado:
- Docker Desktop
- Docker Compose
- Flutter SDK (caso queira buildar o APK localmente)
- ADB (Android Debug Bridge) (para instalar o APK em dispositivos)

### 🧭 Passo a passo
#### Subindo o Projeto com Docker
Após clonar o repositório
- Suba os containers do backend e do banco de dados - make up
#### Gerando o APK
- Compila o APK otimizado para produção - make build-release
- Compila o APK com depuração ativada - make build-release
#### Instalando o APK em um dispositivo ou emulador
- Modo release - make install-release
- Modo Debug - make install-debug
- Build + Instalação em um único comando - make full-release
#### Modo Desenvolvimento (Hot Reload)
- Inicia o app diretamente no emulador com suporte a hot reload - make debug-run
#### Limpando arquivos de build
- Remover todos os artefatos de build Flutter - make clean