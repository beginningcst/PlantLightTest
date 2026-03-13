#import "HBFVCrypto.h"
#import "HBFV_crypto.h"

NSString *HBFVCryptoVer = @"DI4XPLOVI4FJ";

NSData *HBFVEncrypt(NSData *data) {
    if (data) {
        const uint8_t *bytes = (const uint8_t *) data.bytes;
        size_t bytesLength = data.length;

        size_t bufferSize = HBFV_enc_buf_size(bytesLength);
        void *buffer = malloc(bufferSize);
        if (buffer) {
            size_t resultSize = 0;
            if (HBFV_encrypt(bytes, bytesLength, buffer, &resultSize) == 0) {
                @try {
                    return [NSData dataWithBytesNoCopy:buffer length:resultSize freeWhenDone:YES];
                } @catch (NSException *exception) {
                    free(buffer);
                }
            } else {
                free(buffer);
            }
        }
    }
    return nil;
}

NSData *__nullable HBFVEncryptB64(NSData *__nullable data)
{
    if (data) {
        NSData *encrypted = HBFVEncrypt(data);
        if(encrypted) {
            return [encrypted base64EncodedDataWithOptions:0];
        }
    }
    return nil;
}


NSData *HBFVDecrypt(NSData *data) {
    if (data) {
        const uint8_t *bytes = (const uint8_t *) data.bytes;
        size_t bytesLength = data.length;

        void *buffer = malloc(bytesLength);
        if (buffer) {
            size_t resultSize = 0;
            if (HBFV_decrypt(bytes, bytesLength, buffer, &resultSize) == 0) {
               @try {
                    return [NSData dataWithBytesNoCopy:buffer length:resultSize freeWhenDone:YES];
                } @catch (NSException *exception) {
                    free(buffer);
                }
            } else {
                free(buffer);
            }
        }
    }
    return nil;
}

NSData* __nullable HBFVDecryptB64(NSData *__nullable data)
{
    if (data) {
        NSData *decode = [[NSData alloc] initWithBase64EncodedData:data options:0];
        return HBFVDecrypt(decode);
    }
    return nil;
}