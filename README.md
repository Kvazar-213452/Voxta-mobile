# Voxta mobile version

Voxta is a messaging platform that enables users to send files, photos, and text messages in a convenient and fast format. Built with a microservices architecture, it ensures scalability, stability, and ease of updating individual components.

## Tech Stack

### Backend Microservices

**Node.js**
- Authentication and authorization service
- Chat message processing service (sending, receiving, editing, deletion, real-time synchronization)
- Cryptographic service (encryption, decryption, key management)

**Java**
- Media content server (data server)
- File storage and management
- Image and media file processing

**Python**
- Central proxy server and API Gateway
- Request routing to internal microservices
- System configuration and monitoring
- Centralized logging
- Built with FastAPI + asyncio for efficient async processing

**MongoDB**
- Primary database
- Stores messages, user profiles, and system parameters

### Frontend

**Flutter**
- Cross-platform client application
- Supports Android, iOS, Web, and Desktop from a single codebase
- Real-time communication via REST API and WebSocket

**React.js + TypeScript**
- Official website
- Informational pages and basic browser actions

## Platform Availability

**Currently Available:**
- Android
- Windows

**Planned:**
- iOS
- macOS
- Linux

## Running the Application

To start Voxta, you need to run all microservices. **The main service must be started first**, followed by the other microservices.

1. Start the main service (Python proxy server)
2. Start the Node.js services (authentication, chat, cryptography)
3. Start the Java media server
4. Ensure MongoDB is running
5. Launch the Flutter client application

## Architecture

Voxta is built on microservices principles, where each component operates as an independent service. This architecture provides:

- Fast scalability without platform downtime
- Independent updates without interrupting users
- Easy deployment of new features
- Stable performance under high user load

```
class Config {
  static const String URL_SERVICES_CRYPTO =  "http://us1.bot-hosting.net:20787/crypto";
  static const String URL_SERVICES_AUNTIFICATION =  "http://us1.bot-hosting.net:20787/authentication";
  static const String URL_SERVICES_CHAT =  "http://prem-eu3.bot-hosting.net:21626";
  static const String URL_SERVICES_CHAT_SITE =  "https://voxta-app.wuaze.com/";
  static const String URL_SERVICES_DATA =  "http://fi10.bot-hosting.net:22161";

  static const String DEF_ICON_USER =  "https://icon-library.com/images/none-icon/none-icon-13.jpg";
}


class Config {
  static const String URL_SERVICES_CRYPTO =  "http://localhost:8000/crypto";
  static const String URL_SERVICES_AUNTIFICATION =  "http://localhost:8000/authentication";
  static const String URL_SERVICES_CHAT =  "http://localhost:3010";
  static const String URL_SERVICES_CHAT_SITE =  "http://localhost:5173/#/";
  static const String URL_SERVICES_DATA =  "http://localhost:3004";

  static const String DEF_ICON_USER =  "https://icon-library.com/images/none-icon/none-icon-13.jpg";
}
```
## 213452