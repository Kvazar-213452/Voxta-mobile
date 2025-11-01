import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { encryptionMsg, decryptionMsg } from '../utils/cryptoFunc';
import { getMongoClient } from '../models/getMongoClient';
import { transforUser, safeParseJSON } from '../utils/utils'
import { CONFIG } from "../config";

export async function getInfoToJwtHandler(req: Request, res: Response): Promise<void> {
  const { data, key, type } = req.body;

  try {
    if (!data || !key || !type) {
      res.status(400).json({ code: 0, error: 'error_params' });
      return;
    }

    const decrypted = await decryptionMsg(data);
    const parsed = safeParseJSON(decrypted);
    const jwtToken = parsed.jwt;
    const id = parsed.id;

    if (!jwtToken || !id) {
      res.json({ code: 0, data: 'no data' });
      return;
    }

    const decoded = jwt.verify(jwtToken, CONFIG.SECRET_KEY) as { userId: string };

    if (decoded.userId !== id) {
      res.json({ code: 0, data: 'error jwt no user' });
      return;
    }

    const client = await getMongoClient();
    const db = client.db('users');
    const collection = db.collection<UserConfig>(id);

    const config = await collection.findOne({ _id: 'config' });
    if (!config) {
      res.json({ code: 0, data: 'error user not found' });
      return;
    }

    const foundUser: any = {...config};
    foundUser._id = foundUser.id;
    delete foundUser.id;

    const jwtCollection = db.collection<JWTDocument>(id);
    const jwtDoc = await jwtCollection.findOne({ _id: 'jwt' });
    const userTokens: string[] = jwtDoc?.token ?? [];

    if (!userTokens.includes(jwtToken)) {
      res.json({ code: 0, data: 'error jwt not found' });
      return;
    }

    const dataToEncrypt = JSON.stringify(transforUser(foundUser));
    const json = await encryptionMsg(key, dataToEncrypt);

    res.json({ code: 1, data: json });
  } catch (e) {
    console.error('getInfoToJwtHandler error:', e);
    res.json({ code: 0, data: 'error jwt' });
  }
}

