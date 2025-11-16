import axios from 'axios';
import { CONFIG } from "./config/config";
import fs from 'fs';
import path from 'path';

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

// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер
// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер
// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер// мені похер

export async function decryptionMsgServer(dataToSend: { encrypted: string }, userId: string): Promise<any> {
  try {
    const response: any = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}decrypt_message_server`, { 
      data: dataToSend, privateKeyPem: getCyptoKey(userId, "private") 
    }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}

export function getCyptoKey(userId: string, type: string): string {
  const dir = path.join(process.cwd(), `keys/${userId}/${type}.pem`);
  const publicKey = fs.readFileSync(dir, 'utf-8');
  return publicKey;
}