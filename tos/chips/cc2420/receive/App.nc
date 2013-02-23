#include "App.h"

configuration App {}
implementation {
  components MainC, C as App, LedsC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();
  components ActiveMessageC;

  components new Alarm32khz32C() as Alarm1;
  App.Alarm1 -> Alarm1;
  components new Alarm32khz32C() as Alarm2;
  App.Alarm2 -> Alarm2;

  components BusyWaitMicroC;
  App.BusyWait -> BusyWaitMicroC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
}
