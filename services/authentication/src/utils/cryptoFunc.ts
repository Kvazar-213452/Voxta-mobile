import axios from 'axios';
import { CONFIG } from "../config";

export async function decryptionMsg(dataToSend: { encrypted: string }): Promise<any> {
  try {
    const response: any = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}decrypt`, { data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}

export async function encryptionMsg(key: string, dataToSend: string ): Promise<any> {
  try {
    const response: any = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}encryption`, { key: key, data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}
