#ifndef APP_H
#define APP_H

typedef nx_struct radio_count_msg {
  nx_uint8_t counter[20];
} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
