import { MongoClient } from "mongodb";
import { CONFIG } from "../utils/config/config";

let client: MongoClient | null = null;

export async function getMongoClient(): Promise<MongoClient> {
  if (!client) {
    client = new MongoClient(CONFIG.DB_MONGODB_URI);
    await client.connect();
    console.log("MongoDB connected");
  }
  return client;
}
