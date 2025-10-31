package voxta.status;

import io.github.cdimascio.dotenv.Dotenv;
import okhttp3.*;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class ConfigLoader {

    private static final OkHttpClient client = new OkHttpClient();
    private static final Dotenv dotenv;

    public static Map<String, Object> CONFIG = new HashMap<>();
    public static JSONObject CONFIG_MAIN = null;
    public static JSONObject CONFIG_DB = null;
    public static JSONObject CONFIG_API = null;

    private static final String API_MAIN;
    private static final String NAME;

    static {
        dotenv = Dotenv.configure()
                .ignoreIfMissing()
                .load();
        
        API_MAIN = dotenv.get("API_MAIN", System.getenv("API_MAIN"));
        NAME = dotenv.get("NAME", System.getenv("NAME"));
    }

    public static void loadConfig(String name) throws IOException {
        if (API_MAIN == null || API_MAIN.isEmpty()) {
            throw new IOException("API_MAIN environment variable is not set");
        }

        if (name == null || name.isEmpty()) {
            name = NAME != null ? NAME : "";
        }

        JSONObject json = new JSONObject();
        json.put("name", name);

        RequestBody body = RequestBody.create(
                json.toString(),
                MediaType.parse("application/json")
        );

        Request request = new Request.Builder()
                .url(API_MAIN + "api/get_config")
                .post(body)
                .header("Content-Type", "application/json")
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Failed to load config: HTTP " + response.code());
            }

            ResponseBody responseBody = response.body();
            if (responseBody == null) {
                throw new IOException("Empty response body");
            }

            String responseString = responseBody.string();
            JSONObject data = new JSONObject(responseString);

            int status = data.optInt("status", 0);
            if (status != 1) {
                throw new IOException("Failed to load config: invalid status");
            }

            JSONObject configData = data.getJSONObject("config");

            switch (name) {
                case "GLOBAL_DB":
                    CONFIG_DB = configData;
                    break;
                case "GLOBAL_URL":
                    CONFIG_API = configData;
                    break;
                default:
                    if (NAME != null && name.equals(NAME)) {
                        CONFIG_MAIN = configData;
                    }
                    break;
            }
        }
    }

    public static void rebuildConfig() {
        CONFIG.clear();

        if (CONFIG_MAIN != null) {
            Map<String, Object> mainMap = CONFIG_MAIN.toMap();
            if (mainMap != null) {
                CONFIG.putAll(mainMap);
            }
        }
        
        if (CONFIG_DB != null) {
            Map<String, Object> dbMap = CONFIG_DB.toMap();
            if (dbMap != null) {
                CONFIG.putAll(dbMap);
            }
        }
        
        if (CONFIG_API != null) {
            Map<String, Object> apiMap = CONFIG_API.toMap();
            if (apiMap != null) {
                CONFIG.putAll(apiMap);
            }
        }
    }

    public static void LoadCfg() {
        try {
            if (NAME == null || NAME.isEmpty()) {
                System.err.println("Warning: NAME environment variable is not set");
            }

            loadConfig("GLOBAL_URL");
            loadConfig("GLOBAL_DB");
            loadConfig(NAME);
            rebuildConfig();
        } catch (Exception e) {
            System.err.println("Failed to load configuration: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Configuration loading failed", e);
        }
    }
}