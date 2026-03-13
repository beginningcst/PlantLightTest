#include "HBFV_crypto.h"
#include "HBFV_data.h"
#include <stdio.h>
#include <string.h>

inline static void HBFV_int32_to_int8(uint32_t a, uint8_t b[4]) {
    b[0] = (uint8_t) ((a >> 24) & 0xFF);
    b[1] = (uint8_t) ((a >> 16) & 0xFF);
    b[2] = (uint8_t) ((a >> 8) & 0xFF);
    b[3] = (uint8_t) (a & 0xFF);
}

uint8_t HBFV_gmult(uint8_t a, uint8_t b) {
    uint8_t idx = a % 16;
    return HBFV_gdata[a >> 4][idx][b][idx % 4];
}

void HBFV_coef_mult(uint8_t *a, uint8_t *b, uint8_t *d) {
	d[0] = HBFV_gmult(a[0],b[0])^HBFV_gmult(a[3],b[1])^HBFV_gmult(a[2],b[2])^HBFV_gmult(a[1],b[3]);
	d[1] = HBFV_gmult(a[1],b[0])^HBFV_gmult(a[0],b[1])^HBFV_gmult(a[3],b[2])^HBFV_gmult(a[2],b[3]);
	d[2] = HBFV_gmult(a[2],b[0])^HBFV_gmult(a[1],b[1])^HBFV_gmult(a[0],b[2])^HBFV_gmult(a[3],b[3]);
	d[3] = HBFV_gmult(a[3],b[0])^HBFV_gmult(a[2],b[1])^HBFV_gmult(a[1],b[2])^HBFV_gmult(a[0],b[3]);
}

uint8_t HBFV_xor(uint8_t idx) {
    uint8_t b1[4], b2[4];
    HBFV_int32_to_int8(HBFV_ix_data[0][14-idx%15][idx], b1);
    HBFV_int32_to_int8(HBFV_ix_data[1][idx%15][0xff-idx], b2);
    return HBFV_xor_data[b1[0]][b1[1]][b1[2]][b1[3]]^HBFV_xor_data[b2[0]][b2[1]][b2[2]][b2[3]];
}

void HBFV_ark(uint8_t *state, uint8_t r) {
	for (uint8_t c = 0; c < 4; c++) {
		state[0+c] = state[0+c]^HBFV_xor(16*r+4*c+0);
        state[4+c] = state[4+c]^HBFV_xor(16*r+4*c+1);
        state[8+c] = state[8+c]^HBFV_xor(16*r+4*c+2);
        state[12+c] = state[12+c]^HBFV_xor(16*r+4*c+3);
	}
}

void HBFV_mc(uint8_t *state, uint8_t inv) {
    uint8_t a[] = {inv?0x0e:0x02, inv?0x09:0x01,inv?0x0d:0x01, inv?0x0b:0x03};
	uint8_t i, j, col[4], res[4];
	for (j = 0; j < 4; j++) {
		for (i = 0; i < 4; i++) {
			col[i] = state[4*i+j];
		}
		HBFV_coef_mult(a, col, res);
		for (i = 0; i < 4; i++) {
			state[4*i+j] = res[i];
		}
	}
}

void HBFV_shift_rows(uint8_t *state, uint8_t inv) {
    uint8_t tmp[16];
    for (uint8_t i = 0; i < 16; i++) {
        tmp[i] = state[i];
    }
    for (uint8_t i = 0; i < 16; i++) {
        state[i] = tmp[inv?HBFV_inv_rows_shift[i]:HBFV_rows_shift[i]];
    }
}

void HBFV_sb(uint8_t *state, uint8_t inv) {
    for(uint8_t i = 0; i < 16; i++){
        uint8_t item = state[i];
        uint8_t tmp = item%(inv?3:2);
        state[i] = inv?HBFV_isdata[tmp][i][item][8+tmp]:HBFV_sdata[tmp][i][item][8-tmp];
    }
}

void HBFV_cipher(uint8_t *in, uint8_t *out) {
	uint8_t state[16];
	uint8_t r, i, j;
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
			state[4*i+j] = in[i+4*j];
		}
	}
	HBFV_ark(state, 0);
	for (r = 1; r < 10; r++) {
		HBFV_sb(state, 0);
        HBFV_shift_rows(state,0);
		HBFV_mc(state,0);
		HBFV_ark(state, r);
	}
    HBFV_sb(state, 0);
    HBFV_shift_rows(state,0);
    HBFV_ark(state, 10);
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
			out[i+4*j] = state[4*i+j];
		}
	}
}

void HBFV_inv_cipher(uint8_t *in, uint8_t *out) {
	uint8_t state[16];
    for (uint8_t i = 0; i < 4; i++) {
		for (uint8_t j = 0; j < 4; j++) {
			state[4*i+j] = in[i+4*j];
		}
	}
    HBFV_ark(state, 10);
	for (uint8_t r = 9; r >= 1; r--) {
        HBFV_shift_rows(state,1);
		HBFV_sb(state, 1);
		HBFV_ark(state, r);
		HBFV_mc(state,1);
	}
    HBFV_shift_rows(state,1);
	HBFV_sb(state, 1);
    HBFV_ark(state, 0);
	for (uint8_t i = 0; i < 4; i++) {
		for (uint8_t j = 0; j < 4; j++) {
			out[i+4*j] = state[4*i+j];
		}
	}
}

int HBFV_encrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength) {
    size_t bufferSize = HBFV_enc_buf_size(length);
    size_t padding = bufferSize - length;
    *resultLength = bufferSize;
    int blocks = (int) (length >> 4);
    uint8_t state[16];
    uint8_t out[16];
    for (int block = 0; block < blocks; block++) {
        memcpy(state, input + block * 16, 16);
        HBFV_cipher(state, out);
        memcpy(result + block * 16, out, 16);
    }
    size_t remain = length % 16;
    if (remain > 0) {
        memcpy(state, input + 16 * blocks, remain);
    }
    for (int i = 0; i < padding; i++) {
        state[remain + i] = (uint8_t) padding;
    }
    HBFV_cipher(state, out);
    memcpy(result + blocks * 16, out, 16);
    return 0;
}

int HBFV_decrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength) {
    int blocks = (int) (length >> 4);
    uint8_t state[16];
    uint8_t out[16];
    for (int block = 0; block < blocks; block++) {
        memcpy(state, input + block * 16, 16);
        HBFV_inv_cipher(state, out);
        memcpy(result + block * 16, out, 16);
        
        if(block == blocks - 1){
            *resultLength = length - out[15];
        }
    }
    return 0;
}