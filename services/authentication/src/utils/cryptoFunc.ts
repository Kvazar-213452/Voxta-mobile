import axios from 'axios';

export async function decryptionMsg(dataToSend: { encrypted: string }): Promise<any> {
  try {
    const response: any = await axios.post(`http://localhost:8000/crypto/decrypt`, { data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}

export async function encryptionMsg(key: string, dataToSend: string ): Promise<any> {
  try {
    const response: any = await axios.post(`http://localhost:8000/crypto/encryption`, { key: key, data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}
