#ifndef DISTRIBUTED_BLINK
#define DISTRIBUTED_BLINK

//Message structure containing the counter value
//and the sender mote's id
typedef nx_struct counter_msg {
  nx_uint16_t counter;
  nx_uint8_t id;
} counter_msg_t;

//Arbitrary value associated with the message type
enum {
  AM_RADIO_COUNTER_MSG = 6,
};

#endif
