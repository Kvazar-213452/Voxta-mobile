import axios from 'axios';

export async function decryptionMsg(dataToSend: { encrypted: string }, type: string): Promise<any> {
  try {
    let url;
    if (type == "mobile") {
      url = "http://localhost:8000/crypto";
    }

    const response: any = await axios.post(`${url}/decrypt`, { data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}

export async function encryptionMsg(key: string, dataToSend: string, type: string ): Promise<any> {
  try {
    let url;
    if (type == "mobile") {
      url = "http://localhost:8000/crypto";
    }
    
    const response: any = await axios.post(`${url}/encryption`, { key: key, data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}
