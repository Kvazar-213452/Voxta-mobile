import crypto from 'crypto';
import fs from 'fs';

interface EncryptedData {
  key: string;
  data: string;
}

// Генерація RSA ключів
export const generateKeyPair = (): void => {
  const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 4096,
    publicKeyEncoding: {
      type: 'pkcs1',
      format: 'pem'
    },
    privateKeyEncoding: {
      type: 'pkcs8',
      format: 'pem'
    }
  });

  fs.writeFileSync('public_key.pem', publicKey);
  fs.writeFileSync('private_key.pem', privateKey);
};

// Парсинг PEM ключа
const parsePublicKey = (pemKey: string): crypto.KeyObject => {
  const cleanKey = pemKey
    .replace(/-----BEGIN RSA PUBLIC KEY-----/g, '')
    .replace(/-----END RSA PUBLIC KEY-----/g, '')
    .replace(/-----BEGIN PUBLIC KEY-----/g, '')
    .replace(/-----END PUBLIC KEY-----/g, '')
    .replace(/\n/g, '')
    .replace(/\r/g, '')
    .replace(/\s/g, '');

  // Спроба декодувати base64
  try {
    const keyBuffer = Buffer.from(cleanKey, 'base64');
    
    // Спроба створити ключ як PKCS1
    try {
      return crypto.createPublicKey({
        key: Buffer.concat([
          Buffer.from('-----BEGIN RSA PUBLIC KEY-----\n'),
          Buffer.from(cleanKey.match(/.{1,64}/g)?.join('\n') || ''),
          Buffer.from('\n-----END RSA PUBLIC KEY-----')
        ]),
        format: 'pem',
        type: 'pkcs1'
      });
    } catch {
      // Якщо не вийшло PKCS1, спробувати SPKI
      return crypto.createPublicKey({
        key: Buffer.concat([
          Buffer.from('-----BEGIN PUBLIC KEY-----\n'),
          Buffer.from(cleanKey.match(/.{1,64}/g)?.join('\n') || ''),
          Buffer.from('\n-----END PUBLIC KEY-----')
        ]),
        format: 'pem',
        type: 'spki'
      });
    }
  } catch (error) {
    // Якщо вже в правильному форматі
    try {
      return crypto.createPublicKey({
        key: pemKey,
        format: 'pem'
      });
    } catch {
      throw new Error('Неможливо розпарсити публічний ключ');
    }
  }
};

// Шифрування повідомлення
export const encryptMessage = (publicRsaKey: string, message: string): EncryptedData => {
  // Генерація AES ключа (256 біт)
  const aesKey = crypto.randomBytes(32);
  
  // Генерація nonce (12 байт для GCM)
  const nonce = crypto.randomBytes(12);
  
  // Шифрування повідомлення за допомогою AES-256-GCM
  const cipher = crypto.createCipheriv('aes-256-gcm', aesKey, nonce);
  
  const encryptedMessage = Buffer.concat([
    cipher.update(message, 'utf8'),
    cipher.final()
  ]);
  
  const authTag = cipher.getAuthTag();
  
  // Шифрування AES ключа за допомогою RSA-OAEP
  const publicKey = parsePublicKey(publicRsaKey);
  
  const encryptedKey = crypto.publicEncrypt(
    {
      key: publicKey,
      padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
      oaepHash: 'sha1'
    },
    aesKey
  );
  
  // Формування результату
  const data = `${nonce.toString('base64')}.${authTag.toString('base64')}.${encryptedMessage.toString('base64')}`;
  
  return {
    key: encryptedKey.toString('base64'),
    data
  };
};

// Розшифрування повідомлення
export const decryptMessage = (encryptedData: EncryptedData): string => {
  try {
    // Читання приватного ключа
    const privateKeyPem = fs.readFileSync('private_key.pem', 'utf-8');
    const privateKey = crypto.createPrivateKey({
      key: privateKeyPem,
      format: 'pem',
      type: 'pkcs8'
    });
    
    // Розшифрування AES ключа за допомогою RSA-OAEP
    const encryptedKeyBuffer = Buffer.from(encryptedData.key, 'base64');
    
    let aesKey: Buffer;
    try {
      // Спроба з SHA-256
      aesKey = crypto.privateDecrypt(
        {
          key: privateKey,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256'
        },
        encryptedKeyBuffer
      );
    } catch {
      // Якщо не вийшло, спробувати SHA-1
      aesKey = crypto.privateDecrypt(
        {
          key: privateKey,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha1'
        },
        encryptedKeyBuffer
      );
    }
    
    // Розбір зашифрованих даних
    const parts = encryptedData.data.split('.');
    if (parts.length !== 3) {
      throw new Error('Неправильний формат зашифрованих даних');
    }
    
    const nonce = Buffer.from(parts[0], 'base64');
    const authTag = Buffer.from(parts[1], 'base64');
    const encryptedMessage = Buffer.from(parts[2], 'base64');
    
    // Перевірка розмірів
    if (nonce.length !== 12) {
      throw new Error('Неправильний розмір nonce');
    }
    if (authTag.length !== 16) {
      throw new Error('Неправильний розмір auth tag');
    }
    
    // Розшифрування повідомлення за допомогою AES-256-GCM
    const decipher = crypto.createDecipheriv('aes-256-gcm', aesKey, nonce);
    decipher.setAuthTag(authTag);
    
    const decryptedMessage = Buffer.concat([
      decipher.update(encryptedMessage),
      decipher.final()
    ]);
    
    return decryptedMessage.toString('utf8');
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Невідома помилка';
    throw new Error(`Помилка розшифрування: ${errorMessage}`);
  }
};