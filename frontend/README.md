# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



## Como Emular um Celular

Este guia pressupõe que seu ambiente Flutter esteja completamente atualizado em sua máquina.

---

### Passo 1: Requisitos para Emular

Para verificar o que falta em seu ambiente Flutter, digite no terminal:

```bash
flutter doctor
```

* É **necessário** ter o Android Studio baixado em sua máquina.
* É **necessário** ter criado um dispositivo virtual (AVD) com, no mínimo, a API 29. Isso pode ser feito diretamente pelo terminal ou pelo Android Studio.

---

### Passo 2: Verificação do Dispositivo

No terminal, a partir da pasta raiz do seu projeto, digite:

 ```bash
flutter emulators
```
Este comando listará os dispositivos disponíveis para emulação. 
Seu dispositivo móvel criado no Android Studio deverá aparecer aqui.

---

### Passo 3: Escolha um Dispositivo

No terminal, digite:

```bash
flutter emulators --launch
```
O emulador do dispositivo móvel será aberto e uma mensagem de autorização irá aparecer; clique em "**Allow**".

---

### Passo 4: Rodando a Aplicação no Emulador

Agora, basta digitar`flutter run` no terminal:

```bash
flutter run
```
 Seu aplicativo deverá ser executado no emulador.