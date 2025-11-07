import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { encryptionMsg, decryptionMsg } from '../utils/cryptoFunc';
import { getMongoClient } from '../utils/getMongoClient';
import { transforUser, safeParseJSON } from '../utils/utils'
import { CONFIG } from "../config";

export async function loginHandler(req: Request, res: Response): Promise<void> {
  const { data, key, type } = req.body;

  try {
    if (!data || !key || !type) {
      res.status(400).json({ code: 0, error: 'error_params' });
      return;
    }

    const decrypted: any = await decryptionMsg(data);
    const parsed: LoginData = safeParseJSON(decrypted);
    const name = parsed.name;
    const password = parsed.password;

    const client = await getMongoClient();
    const db = client.db('users');

    const collections = await db.listCollections().toArray();
    let foundUser: any = null;
    let userCollectionName: string | null = null;

    for (const col of collections) {
      const collection = db.collection<{ _id: string; [key: string]: any }>(col.name);
      const config = await collection.findOne({ _id: 'config' });

      if (config && config.name === name && config.password === password) {
          foundUser = { ...config };
          userCollectionName = col.name;
          break;
      }
    }

    if (!foundUser || !userCollectionName) {
      res.status(404).json({ code: 0, error: 'user_none' });
      return;
    }

    foundUser._id = foundUser.id;
    delete foundUser.id;

    const token = jwt.sign({ userId: foundUser._id }, CONFIG.SECRET_KEY, { expiresIn: '1d' });

    const jwtCollection = db.collection<{ _id: string; token: string[] }>(userCollectionName);
    const jwtDoc = await jwtCollection.findOne({ _id: 'jwt' });

    if (jwtDoc) {
      await jwtCollection.updateOne({ _id: 'jwt' }, { $push: { token } });
    } else {
      await jwtCollection.insertOne({ _id: 'jwt', token: [token] });
    }

    const responsePayload = JSON.stringify({
      token: token,
      user: JSON.stringify(transforUser(foundUser), null, 2)
    });

    const encrypted = await encryptionMsg(key, responsePayload);
    res.json({ code: 1, data: encrypted });
  } catch (err) {
    console.log(err)
    res.status(500).json({ code: 0, error: 'error_server' });
  }
}
