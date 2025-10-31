import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

interface ConfigResponse {
  status: number;
  config: any;
}

export let CONFIG: any = null;

export let CONFIG_MAIN: any | null = null;
export let CONFIG_DB: any | null = null;
export let CONFIG_API: any | null = null;

export async function loadConfig(name: string = process.env.NAME || ""): Promise<void> {
  try {
    const response = await axios.post<ConfigResponse>(
      `${process.env.API_MAIN}api/get_config`,
      { name: name },
      { headers: { "Content-Type": "application/json" } }
    );

    if (response.data.status !== 1) {
      throw new Error("Failed to load config: invalid status");
    }

    if (name === "GLOBAL_DB") {
      CONFIG_DB = response.data.config;
    } else if (name === "GLOBAL_URL") {
      CONFIG_API = response.data.config;
    } else if (name === process.env.NAME) {
      CONFIG_MAIN = response.data.config;
    }

  } catch (err) {
    console.error("Error loading config:");
    throw err;
  }
}

export function rebuildConfig() {
  CONFIG = {
    ...(CONFIG_MAIN || {}),
    ...(CONFIG_DB || {}),
    ...(CONFIG_API || {}),
  };
}
