import { cryptoFramework } from '@kit.CryptoArchitectureKit';

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
    const ivParam: cryptoFramework.DataBlob = { data: iv };
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, ivParam);
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
    const ivParam: cryptoFramework.DataBlob = { data: iv };
    const tagBlob: cryptoFramework.DataBlob = { data: encryptedData.slice(encryptedData.length - tagLength) };
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, ivParam, tagBlob);
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
