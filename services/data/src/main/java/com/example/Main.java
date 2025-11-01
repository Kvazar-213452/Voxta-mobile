package com.example;

import io.javalin.json.JsonMapper;
import java.lang.reflect.Type;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import com.google.gson.Gson;

import io.javalin.Javalin;
import io.javalin.http.Context;
import io.javalin.http.staticfiles.Location;

public class Main {

    private static final Gson gson = new Gson();

    public static void main(String[] args) {
        ConfigLoader.LoadCfg();

        String hostname = (String) ConfigLoader.CONFIG.get("API");
        Object portObj = ConfigLoader.CONFIG.get("PORT");

        if (hostname == null || portObj == null) {
            throw new RuntimeException("API or PORT not found in config");
        }

        int port = portObj instanceof Integer ? (Integer) portObj : Integer.parseInt(portObj.toString());

        Path dataDir = Paths.get("data");
        try {
            Files.createDirectories(dataDir);
            System.out.println("Data directory created/verified: " + dataDir.toAbsolutePath());
        } catch (IOException e) {
            System.err.println("Failed to create data directory: " + e.getMessage());
            return;
        }

        Javalin app = Javalin.create(config -> {
            String absoluteDataPath = dataDir.toAbsolutePath().toString();

            config.staticFiles.add(absoluteDataPath, Location.EXTERNAL);

            config.plugins.enableCors(cors -> {
                cors.add(it -> {
                    it.anyHost();
                });
            });
            
            // Налаштування Gson як JSON mapper
            config.jsonMapper(new JsonMapper() {
                @Override
                public String toJsonString(Object obj, Type type) {
                    return gson.toJson(obj);
                }
                
                @Override
                public <T> T fromJsonString(String json, Type targetType) {
                    return gson.fromJson(json, targetType);
                }
            });
        }).start(hostname, port);

        app.get("/", ctx -> {
            ctx.result("Hello, Microservice on Java!");
        });

        app.post("/upload_avatar_base64", Main::uploadAvatarBase64);
        app.post("/upload_file_base64", Main::uploadFileBase64);

        System.out.printf("Server started on port %d%n", port);
    }

    private static void uploadAvatarBase64(Context ctx) {
        System.out.println("Received request to /upload_avatar_base64");

        AvatarRequest req;
        try {
            req = gson.fromJson(ctx.body(), AvatarRequest.class);
        } catch (Exception e) {
            System.out.printf("JSON decode error: %s%n", e.getMessage());
            ctx.status(400).result("Invalid JSON: " + e.getMessage());
            return;
        }

        if (req.avatar == null || req.avatar.isEmpty()) {
            System.out.println("Empty avatar data");
            ctx.status(400).result("No avatar data provided");
            return;
        }

        System.out.printf("Avatar data length: %d%n", req.avatar.length());

        String[] parts = req.avatar.split(",", 2);
        if (parts.length != 2) {
            System.out.printf("Invalid base64 format, parts: %d%n", parts.length);
            ctx.status(400).result("Invalid base64 format");
            return;
        }

        String mimeTypePart = parts[0];
        String base64Data = parts[1];

        System.out.printf("MIME type: %s%n", mimeTypePart);

        String extension;
        if (mimeTypePart.contains("jpeg") || mimeTypePart.contains("jpg")) {
            extension = ".jpg";
        } else if (mimeTypePart.contains("png")) {
            extension = ".png";
        } else if (mimeTypePart.contains("gif")) {
            extension = ".gif";
        } else {
            System.out.printf("Unsupported MIME type: %s%n", mimeTypePart);
            ctx.status(400).result("Unsupported image type");
            return;
        }

        byte[] imageData;
        try {
            imageData = Base64.getDecoder().decode(base64Data);
        } catch (IllegalArgumentException e) {
            System.out.printf("Base64 decode error: %s%n", e.getMessage());
            ctx.status(400).result("Failed to decode base64: " + e.getMessage());
            return;
        }

        System.out.printf("Decoded image size: %d bytes%n", imageData.length);

        Path avatarsDir = Paths.get("data/avatars");
        try {
            Files.createDirectories(avatarsDir);
        } catch (IOException e) {
            System.out.printf("Failed to create directory: %s%n", e.getMessage());
            ctx.status(500).result("Failed to create avatars directory");
            return;
        }

        String uniqueFileName = UUID.randomUUID().toString() + extension;
        Path filePath = avatarsDir.resolve(uniqueFileName);

        System.out.printf("Saving to: %s%n", filePath);

        try {
            Files.write(filePath, imageData);
        } catch (IOException e) {
            System.out.printf("Failed to write file: %s%n", e.getMessage());
            ctx.status(500).result("Failed to save avatar: " + e.getMessage());
            return;
        }

        String scheme = ctx.scheme();
        String avatarURL = String.format("%s://%s/avatars/%s", scheme, ctx.host(), uniqueFileName);

        System.out.printf("Avatar saved successfully: %s%n", avatarURL);

        Map<String, String> response = new HashMap<>();
        response.put("url", avatarURL);

        ctx.json(response);
    }

    private static void uploadFileBase64(Context ctx) {
        System.out.println("Received request to /upload_file_base64");

        FileRequest req;
        try {
            req = gson.fromJson(ctx.body(), FileRequest.class);
        } catch (Exception e) {
            System.out.printf("JSON decode error: %s%n", e.getMessage());
            ctx.status(400).result("Invalid JSON: " + e.getMessage());
            return;
        }

        if (req.file == null || req.file.isEmpty()) {
            System.out.println("Empty file data");
            ctx.status(400).result("No file data provided");
            return;
        }

        if (req.name == null || req.name.isEmpty()) {
            System.out.println("Empty file name");
            ctx.status(400).result("No file name provided");
            return;
        }

        String extension = "";
        int lastDot = req.name.lastIndexOf(".");
        if (lastDot != -1) {
            extension = req.name.substring(lastDot);
        }

        String base64Data;
        if (req.file.contains(",")) {
            String[] parts = req.file.split(",", 2);
            if (parts.length == 2) {
                base64Data = parts[1];
            } else {
                base64Data = req.file;
            }
        } else {
            base64Data = req.file;
        }

        byte[] fileData;
        try {
            fileData = Base64.getDecoder().decode(base64Data);
        } catch (IllegalArgumentException e) {
            System.out.printf("Base64 decode error: %s%n", e.getMessage());
            ctx.status(400).result("Failed to decode base64: " + e.getMessage());
            return;
        }

        Path fileDir = Paths.get("data/file");
        try {
            Files.createDirectories(fileDir);
        } catch (IOException e) {
            System.out.printf("Failed to create directory: %s%n", e.getMessage());
            ctx.status(500).result("Failed to create file directory");
            return;
        }

        String uniqueFileName = UUID.randomUUID().toString() + extension;
        Path filePath = fileDir.resolve(uniqueFileName);

        try {
            Files.write(filePath, fileData);
        } catch (IOException e) {
            System.out.printf("Failed to write file: %s%n", e.getMessage());
            ctx.status(500).result("Failed to save file: " + e.getMessage());
            return;
        }

        String scheme = ctx.scheme();
        String fileURL = String.format("%s://%s/file/%s", scheme, ctx.host(), uniqueFileName);

        System.out.printf("File saved successfully: %s%n", fileURL);

        Map<String, String> response = new HashMap<>();
        response.put("url", fileURL);

        ctx.json(response);
    }

    static class AvatarRequest {
        String avatar;
    }

    static class FileRequest {
        String file;
        String name;
    }
}