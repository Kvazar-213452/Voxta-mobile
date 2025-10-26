import { MongoClient } from "mongodb";

const uri: string = process.env.MONGODB_URI ?? "mongodb://localhost:27017";
const client: MongoClient = new MongoClient(uri);
let connected: boolean = false;

export async function getMongoClient(): Promise<MongoClient> {
  if (!connected) {
    await client.connect();
    connected = true;
    console.log("MongoDB connected");
  }
  return client;
}
