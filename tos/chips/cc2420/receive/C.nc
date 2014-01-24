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

  //bool locked;
  uint16_t c_send = 0;
  uint16_t c_recv = 0;

    bool END = FALSE;

    //#define ATOMIC_ON
    #define MSGS    100

    // ALARM
    // 32000x  per 1000ms
    //   320x  per   10ms

    // BATTERY
/*
    #define CRYPT
    #define DT_SEND     2000    // 2000ms -> 100000 ms (all 100 msgs)
    #define DT_BUSY     2000    //    2ms
*/

    // BATTERY
    #define DT_SEND    2000    // 2000ms -> 200000 ms (all 100 msgs)
    #define DT_PERIOD  1500    //   50ms ->    XX times
    #define DT_BUSY       1    //    1ms
/*
*/

/*
    #define CRYPT
    #define DT_SEND      600    // 600ms -> 60000 ms (all 100 msgs)
    #define DT_BUSY     8000    //   8ms
    // ORIG: 1000
    // CEUS: 1000
*/

/*
    #define CRYPT
    #define DT_SEND      500
    #define DT_BUSY     8000    //   8ms
    // ORIG:  991
    // CEUS:  994
*/

/*
    #define CRYPT
    #define DT_SEND      400
    #define DT_BUSY     8000    //   8ms
    // ORIG: 1000
    // CEUS: 1000
*/

/*
    #define CRYPT
    #define DT_SEND      300
    #define DT_BUSY     8000    //   8ms
    // ORIG:  999
    // CEUS:  999
*/

/*
    #define CRYPT
    #define DT_SEND      200
    #define DT_BUSY     8000    //   8ms
    // ORIG:  991
    // CEUS:  991
*/

/*
    #define CRYPT
    #define DT_SEND      100
    #define DT_BUSY     8000    //   8ms
    // ORIG:  955
    // CEUS:  850
*/

/*
    #define CRYPT
    #define DT_SEND       80
    #define DT_BUSY     8000    //   8ms
    // ORIG:  785
    // CEUS:  637
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY       0    //   0ms
    // ORIG: 979 // 115
    // CEUS: 953 // 115
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY    1000    //   1ms
    // ORIG: 979 // 114
    // CEUS: 953 // 115
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY    2000    //   2ms
    // ORIG: 979 // 114
    // CEUS: 953 // 114
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY    4000    //   4ms
    // ORIG: 979 // 114
    // CEUS: 949 // 114
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY    8000    //   8ms
    // ORIG: 979 // 113
    // CEUS: 950 // 113
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY   16000    //  16ms
    // ORIG: 976 // 112
    // CEUS: 928 // 112
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY   32000    //  32ms
    // ORIG: 976 // 108
    // CEUS: 922 // 108
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY       2    //  64ms
    // ORIG: 956 // 103
    // CEUS: 867 // 103
*/

/*
    #define DT_SEND     150    // 150ms -> 15000 ms (all 100 msgs)
    #define DT_PERIOD  4160    // 140ms ->    XX times
    #define DT_BUSY       4    // 128ms
    // ORIG: 898 // 93
    // CEUS: 683 // 93
*/


    event void Boot.booted() {
        call AMControl.start();
#ifndef CRYPT
        if (TOS_NODE_ID == 1)
            call Alarm1.start(DT_PERIOD);
#endif
        //call Alarm2.start(DT_A2);
        call Leds.set(0);
    }

    int v = 0;

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            if (TOS_NODE_ID == 1) {
                c_send = MSGS;
                call MilliTimer.startOneShot((uint32_t)DT_SEND*MSGS);
            } else {
                call MilliTimer.startPeriodic(DT_SEND);
            }
        }
    else {
        call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

    uint16_t D = 0;
    //uint32_t d = 0;
    async event void Alarm1.fired() {
#ifdef ATOMIC_ON
atomic
#endif
{
        if (END) return;
        if (DT_BUSY == 0) {
        } else if (DT_BUSY < 10) {
            int i;
            for (i=1; i<=DT_BUSY; i++)
                call BusyWait.wait(32000);  // 32ms
        } else {
            call BusyWait.wait(DT_BUSY);
        }
#ifndef CRYPT
        call Alarm1.start(DT_PERIOD);
#endif
        atomic {
            D++; //D%=3200;
        }
}
    }
    async event void Alarm2.fired() {
/*
#ifdef ATOMIC_ON
atomic
#endif
{
        if (END) return;
        call BusyWait.wait(DT_W2);
        call Alarm2.start(DT_A2);
        atomic {
            D++; //D%=3200;
        }
}
*/
    }

    event void MilliTimer.fired()
    {
#ifdef ATOMIC_ON
atomic
#endif
{
/*
        if (locked) {
            call Leds.led0Toggle();
            return;
        }
*/

        //c_send++;
        if (c_send >= MSGS) {
            call Leds.set(7);
            atomic {
                END = TRUE;
                //D = d / 10;
            }
            return;
        }
        //if (TOS_NODE_ID == 0)
            //return;

        {
            error_t err;
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

            err = call AMSend.send(AM_BROADCAST_ADDR, &packet,
                                sizeof(radio_count_msg_t));
                call Leds.set(err == EBUSY);
            if (err == SUCCESS) {
                //locked = TRUE;
            }
        }
}
    }

    int R = 0;
    event message_t* Receive.receive(message_t* bufPtr, void* payload,
                                     uint8_t len) {
#ifdef ATOMIC_ON
atomic
#endif
{
        radio_count_msg_t* rcm = (radio_count_msg_t*) payload;

        if (TOS_NODE_ID != 1)
            return bufPtr;

//call Leds.led0Toggle();
        R++;
        {
            int i;
            for (i=0; i<20; i++) {
                c_recv += rcm->counter[i];
            }
        }

#ifdef CRYPT
        call BusyWait.wait(DT_BUSY);
#endif

        //call Leds.set(c_recv);
        return bufPtr;
}
    }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
#ifdef ATOMIC_ON
atomic
#endif
{
                c_send++;
/*
    if (&packet == bufPtr) {
      locked = FALSE;
    }
    else {
       call Leds.set(7);
    }
*/
}
  }

}




