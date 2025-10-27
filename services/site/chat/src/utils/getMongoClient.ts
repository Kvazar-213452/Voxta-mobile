import { MongoClient } from "mongodb";

const uri = process.env.MONGODB_URI ?? "mongodb://localhost:27017";
const client = new MongoClient(uri);
let connected: boolean = false;

export async function getMongoClient(): Promise<MongoClient> {
  if (!connected) {
    await client.connect();
    connected = true;
    console.log("MongoDB connected");
  }
  return client;
}
