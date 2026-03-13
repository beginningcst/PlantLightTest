#include <stdint.h>
#include <stdlib.h>

#define HBFV_enc_buf_size(len) (((len)&(-16))+16)

int HBFV_encrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength);
int HBFV_decrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength);