import axios from 'axios';

export async function decryptionMsg(dataToSend: { encrypted: string }, type: string) {
  try {
    let url;
    if (type == "mobile") {
      url = "http://localhost:3062";
    } else {
      url = "http://localhost:4001";
    }

    const response: any = await axios.post(`${url}/decrypt`, { data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}

export async function encryptionMsg(key: string, dataToSend: string, type: string ) {
  try {
    let url;
    if (type == "mobile") {
      url = "http://localhost:3062";
    } else {
      url = "http://localhost:4001";
    }

    const response: any = await axios.post(`${url}/encryption`, { key: key, data: dataToSend }, {
      headers: {'Content-Type': 'application/json'}
    });

    return response.data.message;
  } catch (error) {
    throw error;
  }
}
