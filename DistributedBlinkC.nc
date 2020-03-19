//Specification of the DistributedBlink component

#include "Timer.h"
#include "DistributedBlink.h"

module DistributedBlinkC @safe() {
	uses {
		interface Leds;
		interface Boot;
		interface Receive;
		interface AMSend;
		interface Timer<TMilli> as MilliTimer;
		interface SplitControl as AMControl;
		interface Packet;
	}
}
implementation {

	message_t packet;
	
	bool transmitting = FALSE; 	//To avoid sending new packets while already sending
	uint16_t counter = 0;

	event void Boot.booted()
	{
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t err)
	{
		if(err == SUCCESS)
		{
			//Start the mote's timer
			uint16_t period;
			switch(TOS_NODE_ID)
			{
				case 1:
				{
					period = 1000;
					break;
				}
				case 2:
				{
					period = 333;
					break;
				}
				case 3:
				{
					period = 200;
					break;
				}
				default:
				{
					//Avoid turning on the radio
					dbg("DistributedBlinkC", "Node ID not among the specified ones\n");
					return; 				
				}
			}
			
			call MilliTimer.startPeriodic(period);
		}
		else
		{
			//Try again
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err)
	{
		//Nothing to do here, we never stop the radio
	}
	
	event void MilliTimer.fired()
	{
		if(transmitting)
		{
			return;
		}
		else
		{
			//Create packet
			counter_msg_t* message = (counter_msg_t*)call Packet.getPayload(&packet, sizeof(counter_msg_t));
			if(message == NULL)
			{
				dbg("DistributedBlinkC", "Error in packet creation\n");
				return;
			}

			message->counter = counter;
			message->id = TOS_NODE_ID;
			
			//Send the message
			if( call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(counter_msg_t)) == SUCCESS )
			{
				//Lock transmission until it ends
				transmitting = TRUE;
			}
		}
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error)
	{
		if(&packet == bufPtr)
		{
			//Remove transmission lock when our packet finished being sent
			transmitting = FALSE;
		}
	}
	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		if(len != sizeof(counter_msg_t))
		{
			dbg("DistributedBlinkC", "Received a packet of wrong size\n");
		}
		else
		{
			counter_msg_t* message = (counter_msg_t*)payload;

			//Increment counter at package reception
			counter++;

			if(message->counter % 10 == 0)
			{
				//If the received counter is a multiple of 10, then turn all the leds off
				call Leds.led0Off();
				call Leds.led1Off();
				call Leds.led2Off();
			}
			else
			{
				switch(message->id)
				{
					case 1:
						call Leds.led0Toggle();
						break;
					case 2:
						call Leds.led1Toggle();
						break;
					case 3:
						call Leds.led2Toggle();
						break;
				}
			}
		}

		return bufPtr;
	}
	
}
