import axios from "axios";
import { CONFIG } from "../utils/config/config";

export async function uploadAvatar(base64String: string): Promise<string> {
  const matches = base64String.match(/^data:(.+);base64,(.+)$/);
  if (!matches) throw new Error("Invalid base64 string");

  try {
    const response = await axios.post(`${CONFIG.MICROSERVICES_DATA}upload_avatar_base64`, {
      avatar: base64String
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    return response.data.url;
  } catch (error) {
    console.error('Error uploading avatar:', error);
    return "";
  }
}

export async function uploadFile(base64String: string, name: string): Promise<string> {
  const matches = base64String.match(/^data:(.+);base64,(.+)$/);
  if (!matches) throw new Error("Invalid base64 string");

  try {
    const response = await axios.post(`${CONFIG.MICROSERVICES_DATA}upload_file_base64`, {
      file: base64String,
      name: name
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    return response.data.url;
  } catch (error) {
    console.error('Error uploading avatar:', error);
    return "";
  }
}
