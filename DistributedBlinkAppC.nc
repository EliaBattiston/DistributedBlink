#include "DistributedBlink.h"

configuration DistributedBlinkAppC {}
implementation {
    components MainC, DistributedBlinkC as App, LedsC;
    components new AMSenderC(AM_RADIO_COUNTER_MSG);
    components new AMReceiverC(AM_RADIO_COUNTER_MSG);
    components new TimerMilliC();
    components ActiveMessageC;

    App.Boot -> MainC.Boot;

    App.Receive -> AMReceiverC;
    App.AMSend -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.Leds -> LedsC;
    App.MilliTimer -> TimerMilliC;
    App.Packet -> AMSenderC;
}