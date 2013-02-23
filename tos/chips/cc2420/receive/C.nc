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

/*
    task void T1 ();
    task void T2 ();
    task void T3 ();
*/
  
    event void Boot.booted() {
        call AMControl.start();
        call Alarm1.start(50);      // ~10ms
        call Alarm2.start(100);     // ~30ms
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
            call MilliTimer.startPeriodic(100);

// ORIG: 2107 // 171.180   // 12109

// SYNC: 2096 // 3.167.0   // 11986

// CEUS: 1851 // 54.166.0  // 11852

// 1 mote
// ORIG: 774  // 197.105.1 // 12159
// SYNC: 777  // 31.65.1   // 12023
// CEUS: 761  // 203.51.1  // 11970

        }
    else {
        call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

/*
    uint32_t C = 0;
    task void T1 () {
atomic
{
        if (END) return;
        C++;
        post T1();
}
    }
    task void T2 () {
atomic
{
        if (END) return;
        C++;
        post T2();
}
    }
    task void T3 () {
atomic
{
        if (END) return;
        C++;
        post T3();
}
    }
*/

    uint16_t D = 0;
    async event void Alarm1.fired() {
atomic
{
        if (END) return;
        call BusyWait.wait(1500);
        call Alarm1.start(50);
        atomic {
            D++;
        }
}
    }
    async event void Alarm2.fired() {
atomic
{
        if (END) return;
        call BusyWait.wait(3000);
        call Alarm2.start(100);
        atomic {
            D++;
        }
}
    }

    event void MilliTimer.fired()
    {
atomic
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
atomic
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
atomic
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




