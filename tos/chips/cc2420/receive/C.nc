#include "Timer.h"
#include "App.h"
 
module C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;

    interface Alarm<T32khz,uint32_t> as Alarm1;
    interface Alarm<T32khz,uint32_t> as Alarm2;

    interface BusyWait<TMicro, uint16_t>;

  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t c_send = 0;
  uint16_t c_recv = 0;

    bool END = FALSE;
 
    #define DT_SEND  100    // 100ms
    #define DT_A1    150    //  45ms
    #define DT_A2    300    //  90ms
    #define DT_W1   1000    //   1ms
    #define DT_W2   3000    //   3ms
    #undef SYNC

/*
    #define DT_SEND  100    // 100ms
    #define DT_A1    250    //  75ms
    #define DT_A2    600    // 180ms
    #define DT_W1   1000    //   1ms
    #define DT_W2   3000    //   3ms
    ORIG: 798 // 1140
    CEUS: 798 // 1140

    #define DT_SEND  100    // 100ms
    #define DT_A1    150    //  45ms
    #define DT_A2    300    //  90ms
    #define DT_W1   1000    //   1ms
    #define DT_W2   3000    //   3ms
    ORIG: 798 // 1297
    CEUS: 798 // 1294

    #define DT_SEND   50    //  50ms
    #define DT_A1    150    //  45ms
    #define DT_A2    300    //  90ms
    #define DT_W1   1000    //   1ms
    #define DT_W2   3000    //   3ms
    ORIG: 766 // 2244
    ORIG: 751 // 2239
*/
    event void Boot.booted() {
        call AMControl.start();
        call Alarm1.start(DT_A1);
        call Alarm2.start(DT_A2);
        call Leds.set(0);
/*
        post T1();
        post T2();
        post T3();
*/
    }

    int v = 0;

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            call MilliTimer.startPeriodic(DT_SEND);
        }
    else {
        call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

    uint16_t D = 0;
    async event void Alarm1.fired() {
#ifdef SYNC
atomic
#endif
{
        if (END) return;
        call BusyWait.wait(DT_W1);
        call Alarm1.start(DT_A1);
        atomic {
            D++; D%=3200;
        }
}
    }
    async event void Alarm2.fired() {
#ifdef SYNC
atomic
#endif
{
        if (END) return;
        call BusyWait.wait(DT_W2);
        call Alarm2.start(DT_A2);
        atomic {
            D++; D%=3200;
        }
}
    }

    event void MilliTimer.fired()
    {
#ifdef SYNC
atomic
#endif
{
        c_send++;
        if (c_send > 799) {
            call Leds.set(c_recv/100);
            atomic {
                END = TRUE;
            }
            return;
        }
        //if (TOS_NODE_ID == 0)
            //return;

        if (locked) {
            return;
        } else {
            radio_count_msg_t* rcm = (radio_count_msg_t*)
                call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
            if (rcm == NULL) {
                return;
            }

            {
                int i;
                for (i=0; i<20; i++) {
                    rcm->counter[i] = (i == c_send%20);
                }
            }

            if (call AMSend.send(AM_BROADCAST_ADDR, &packet,
                                sizeof(radio_count_msg_t)) == SUCCESS) {
                locked = TRUE;
            }
        }
}
    }

    int R = 0;
    event message_t* Receive.receive(message_t* bufPtr, void* payload,
                                     uint8_t len) {
#ifdef SYNC
atomic
#endif
{
        radio_count_msg_t* rcm = (radio_count_msg_t*) payload;

//call Leds.led0Toggle();
        R++;
        {
            int i;
            for (i=0; i<20; i++) {
                c_recv += rcm->counter[i];
            }
        }

        //call Leds.set(c_recv);
        return bufPtr;
}
    }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
#ifdef SYNC
atomic
#endif
{
    if (&packet == bufPtr) {
      locked = FALSE;
    }
    else {
       call Leds.set(7);
    }
}
  }

}




