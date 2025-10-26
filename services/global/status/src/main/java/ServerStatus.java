package voxta.status;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.corundumstudio.socketio.*;
import com.corundumstudio.socketio.listener.*;
import io.github.cdimascio.dotenv.Dotenv;

import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

// ⡏⠉⠉⠉⠉⠉⠉⠋⠉⠉⠉⠉⠉⠉⠋⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠙⠉⠉⠉⠹
// ⡇⢸⣿⡟⠛⢿⣷⠀⢸⣿⡟⠛⢿⣷⡄⢸⣿⡇⠀⢸⣿⡇⢸⣿⡇⠀⢸⣿⡇⠀
// ⡇⢸⣿⣧⣤⣾⠿⠀⢸⣿⣇⣀⣸⡿⠃⢸⣿⡇⠀⢸⣿⡇⢸⣿⣇⣀⣸⣿⡇⠀
// ⡇⢸⣿⡏⠉⢹⣿⡆⢸⣿⡟⠛⢻⣷⡄⢸⣿⡇⠀⢸⣿⡇⢸⣿⡏⠉⢹⣿⡇⠀
// ⡇⢸⣿⣧⣤⣼⡿⠃⢸⣿⡇⠀⢸⣿⡇⠸⣿⣧⣤⣼⡿⠁⢸⣿⡇⠀⢸⣿⡇⠀
// ⣇⣀⣀⣀⣀⣀⣀⣄⣀⣀⣀⣀⣀⣀⣀⣠⣀⡈⠉⣁⣀⣄⣀⣀⣀⣠⣀⣀⣀⣰
// ⣇⣿⠘⣿⣿⣿⡿⡿⣟⣟⢟⢟⢝⠵⡝⣿⡿⢂⣼⣿⣷⣌⠩⡫⡻⣝⠹⢿⣿⣷
// ⡆⣿⣆⠱⣝⡵⣝⢅⠙⣿⢕⢕⢕⢕⢝⣥⢒⠅⣿⣿⣿⡿⣳⣌⠪⡪⣡⢑⢝⣇
// ⡆⣿⣿⣦⠹⣳⣳⣕⢅⠈⢗⢕⢕⢕⢕⢕⢈⢆⠟⠋⠉⠁⠉⠉⠁⠈⠼⢐⢕⢽
// ⡗⢰⣶⣶⣦⣝⢝⢕⢕⠅⡆⢕⢕⢕⢕⢕⣴⠏⣠⡶⠛⡉⡉⡛⢶⣦⡀⠐⣕⢕
// ⡝⡄⢻⢟⣿⣿⣷⣕⣕⣅⣿⣔⣕⣵⣵⣿⣿⢠⣿⢠⣮⡈⣌⠨⠅⠹⣷⡀⢱⢕
// ⡝⡵⠟⠈⢀⣀⣀⡀⠉⢿⣿⣿⣿⣿⣿⣿⣿⣼⣿⢈⡋⠴⢿⡟⣡⡇⣿⡇⡀⢕
// ⡝⠁⣠⣾⠟⡉⡉⡉⠻⣦⣻⣿⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣦⣥⣿⡇⡿⣰⢗⢄
// ⠁⢰⣿⡏⣴⣌⠈⣌⠡⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣬⣉⣉⣁⣄⢖⢕⢕⢕
// ⡀⢻⣿⡇⢙⠁⠴⢿⡟⣡⡆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣵⣵⣿
// ⡻⣄⣻⣿⣌⠘⢿⣷⣥⣿⠇⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
// ⣷⢄⠻⣿⣟⠿⠦⠍⠉⣡⣾⣿⣿⣿⣿⣿⣿⢸⣿⣦⠙⣿⣿⣿⣿⣿⣿⣿⣿⠟
// ⡕⡑⣑⣈⣻⢗⢟⢞⢝⣻⣿⣿⣿⣿⣿⣿⣿⠸⣿⠿⠃⣿⣿⣿⣿⣿⣿⡿⠁⣠
// ⡝⡵⡈⢟⢕⢕⢕⢕⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⠿⠋⣀⣈⠙
// ⡝⡵⡕⡀⠑⠳⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢉⡠⡲⡫⡪⡪⡣

public class ServerStatus {

    private static final Map<String, SocketIOClient> onlineUsers = new ConcurrentHashMap<>();
    private static final Map<SocketIOClient, String> clientTokens = new ConcurrentHashMap<>();

    public static void main(String[] args) {
        Dotenv dotenv = Dotenv.configure().ignoreIfMissing().load();
        String secret = dotenv.get("SECRET_KEY", "default-secret-key");
        int port = Integer.parseInt(dotenv.get("PORT", "3002"));
        Algorithm jwtAlgorithm = Algorithm.HMAC256(secret);

        Configuration config = new Configuration();
        config.setHostname("0.0.0.0");
        config.setPort(port);
        config.setOrigin("*");
        
        config.setAllowCustomRequests(true);
        config.setUpgradeTimeout(10000);
        config.setPingTimeout(5000);
        config.setPingInterval(25000);

        SocketIOServer server = new SocketIOServer(config);

        server.addConnectListener(client -> {
            System.out.println("Client connected: " + client.getSessionId());
        });

        server.addEventListener("authenticate", Map.class, (client, data, ackSender) -> {
            try {
                String token = (String) data.get("token");
                if (token == null || token.trim().isEmpty()) {
                    throw new RuntimeException("Token is required");
                }

                DecodedJWT decoded = JWT.require(jwtAlgorithm).build().verify(token);
                String userId = decoded.getClaim("userId").asString();
                
                if (userId == null || userId.trim().isEmpty()) {
                    throw new RuntimeException("Invalid user ID in token");
                }

                onlineUsers.entrySet().removeIf(entry -> entry.getValue().equals(client));
                
                onlineUsers.put(userId, client);
                clientTokens.put(client, token);
                client.set("userId", userId);
                client.set("authenticated", true);

                client.sendEvent("authenticated", Map.of(
                    "code", 1,
                    "status", "online"
                ));
                System.out.println("User authenticated: " + userId);
                
            } catch (Exception e) {
                System.err.println("Authentication failed: " + e.getMessage());
                client.sendEvent("authenticated", Map.of(
                    "code", 0,
                    "error", "authentication_failed"
                ));
                client.disconnect();
            }
        });

        server.addEventListener("get_status", Map.class, (client, data, ackSender) -> {
            try {
                Boolean isAuth = client.get("authenticated");
                if (isAuth == null || !isAuth) {
                    client.sendEvent("get_status_return", Map.of(
                        "code", 0,
                        "error", "not_authenticated",
                        "type", data.get("type")
                    ));
                    return;
                }

                String checkId = (String) data.get("id_user");
                if (checkId == null || checkId.trim().isEmpty()) {
                    client.sendEvent("get_status_return", Map.of(
                        "code", 0,
                        "error", "invalid_user_id",
                        "type", data.get("type")
                    ));
                    return;
                }

                String token = clientTokens.get(client);
                if (token != null) {
                    try {
                        JWT.require(jwtAlgorithm).build().verify(token);
                    } catch (Exception e) {
                        client.sendEvent("get_status_return", Map.of(
                            "code", 0,
                            "error", "token_expired",
                            "type", data.get("type")
                        ));
                        return;
                    }
                }

                boolean isOnline = onlineUsers.containsKey(checkId);
                client.sendEvent("get_status_return", Map.of(
                    "code", 1,
                    "status", isOnline ? "online" : "offline",
                    "type", data.get("type")
                ));
                
                System.out.println("Status check for user " + checkId + ": " + (isOnline ? "online" : "offline"));
                
            } catch (Exception e) {
                System.err.println("Error in get_status: " + e.getMessage());
                client.sendEvent("get_status_return", Map.of(
                    "code", 0,
                    "error", "server_error",
                    "type", data.get("type")
                ));
            }
        });

        server.addDisconnectListener(client -> {
            String userId = client.get("userId");
            if (userId != null) {
                onlineUsers.remove(userId);
                clientTokens.remove(client);
                System.out.println("User disconnected: " + userId);
            }
        });

        server.start();
        System.out.println("Socket.IO server started on port " + port);
        
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Shutting down server...");
            server.stop();
        }));
    }
}
