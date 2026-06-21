import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import util from '@ohos.util';

export class CryptoService {
  private static instance: CryptoService;
  private readonly KEY_LENGTH = 256;
  private readonly IV_LENGTH = 12;
  private readonly TAG_LENGTH = 16;

  static getInstance(): CryptoService {
    if (!CryptoService.instance) {
      CryptoService.instance = new CryptoService();
    }
    return CryptoService.instance;
  }

  async generateKey(): Promise<cryptoFramework.SymKey> {
    const generator = cryptoFramework.createSymKeyGenerator('AES256');
    return await generator.generateSymKey();
  }

  async encrypt(data: Uint8Array, key: cryptoFramework.SymKey, iv: Uint8Array): Promise<Uint8Array> {
    const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
    const gcmParams: cryptoFramework.GcmParamsSpec = {
      iv: { data: iv },
      aad: { data: new Uint8Array(0) },
      authTag: { data: new Uint8Array(0) },
      algName: 'GcmParamsSpec',
    };
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, gcmParams);
    const plainBlob: cryptoFramework.DataBlob = { data: data };
    const encrypted = await cipher.update(plainBlob);
    const authTag = await cipher.doFinal(null);
    const result = new Uint8Array(encrypted.data.length + authTag.data.length);
    result.set(encrypted.data);
    result.set(authTag.data, encrypted.data.length);
    return result;
  }

  async decrypt(encryptedData: Uint8Array, key: cryptoFramework.SymKey, iv: Uint8Array): Promise<Uint8Array> {
    const tagLength = this.TAG_LENGTH;
    const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
    const tagData = encryptedData.slice(encryptedData.length - tagLength);
    const gcmParams: cryptoFramework.GcmParamsSpec = {
      iv: { data: iv },
      aad: { data: new Uint8Array(0) },
      authTag: { data: tagData },
      algName: 'GcmParamsSpec',
    };
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, gcmParams);
    const encryptedBlob: cryptoFramework.DataBlob = { data: encryptedData.slice(0, encryptedData.length - tagLength) };
    const decrypted = await cipher.update(encryptedBlob);
    const finalResult = await cipher.doFinal(null);
    const result = new Uint8Array(decrypted.data.length + (finalResult ? finalResult.data.length : 0));
    result.set(decrypted.data);
    if (finalResult) {
      result.set(finalResult.data, decrypted.data.length);
    }
    return result;
  }

  async deriveKeyFromPassphrase(passphrase: string): Promise<cryptoFramework.SymKey> {
    // 用 SHA-256 哈希口令，取前 32 字节作为 AES-256 密钥
    const md = cryptoFramework.createMd('SHA256');
    const encoder = new util.TextEncoder();
    const passData = encoder.encode(passphrase);
    await md.update({ data: passData });
    const digest = await md.digest();
    const keyBytes = digest.data.slice(0, 32);

    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const symKey = symKeyGenerator.convertKey({ data: keyBytes });
    return symKey;
  }

  async generateIv(): Promise<Uint8Array> {
    const iv = new Uint8Array(this.IV_LENGTH);
    for (let i = 0; i < this.IV_LENGTH; i++) {
      iv[i] = Math.floor(Math.random() * 256);
    }
    return iv;
  }

  async hashFile(data: Uint8Array): Promise<string> {
    const md = cryptoFramework.createMd('SHA256');
    await md.update({ data: data });
    const digest = await md.digest();
    return this.bytesToHex(digest.data);
  }

  private bytesToHex(bytes: Uint8Array): string {
    let hex = '';
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0');
    }
    return hex;
  }
}
