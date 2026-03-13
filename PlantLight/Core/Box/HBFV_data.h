#ifndef __HBFV_H__
#define __HBFV_H__

#include <stdint.h>

static const uint8_t HBFV_rows_shift[] = {0, 1, 2, 3, 5, 6, 7, 4, 10, 11, 8, 9, 15, 12, 13, 14};
static const uint8_t HBFV_inv_rows_shift[] = {0, 1, 2, 3, 7, 4, 5, 6, 10, 11, 8, 9, 13, 14, 15, 12};

extern const uint8_t HBFV_gdata[16][16][256][4];
extern const uint8_t HBFV_sdata[2][16][256][16];
extern const uint8_t HBFV_isdata[3][16][256][16];
extern const uint32_t HBFV_ix_data[2][15][256];
extern const uint8_t HBFV_xor_data[8][12][9][256];

#endif