import axios from 'axios';
import { CONFIG } from "./config/config";
import fs from 'fs';
import path from 'path';

export default class CryptoFunc {
  public static async decryptionMsg(dataToSend: { encrypted: string }): Promise<any> {
    try {
      const response: any = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}decrypt`, { data: dataToSend }, {
        headers: { 'Content-Type': 'application/json' }
      });

      return response.data.message;
    } catch (error) {
      throw error;
    }
  }

  public static async encryptionMsg(key: string, dataToSend: string): Promise<any> {
    try {
      const response: any = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}encryption`, { key: key, data: dataToSend }, {
        headers: { 'Content-Type': 'application/json' }
      });

      return response.data.message;
    } catch (error) {
      throw error;
    }
  }

  public static async decryptionMsgServer(dataToSend: { encrypted: string }, userId: string): Promise<any> {
    try {
      const response: any = await axios.post(`${CONFIG.MICROSERVICES_CRYPTO}decrypt_message_server`, {
        data: dataToSend, privateKeyPem: CryptoFunc.getCyptoKey(userId, "private")
      }, {
        headers: { 'Content-Type': 'application/json' }
      });

      return response.data.message;
    } catch (error) {
      throw error;
    }
  }

  private static getCyptoKey(userId: string, type: string): string {
    const dir = path.join(process.cwd(), `keys/${userId}/${type}.pem`);
    const publicKey = fs.readFileSync(dir, 'utf-8');
    return publicKey;
  }
}
