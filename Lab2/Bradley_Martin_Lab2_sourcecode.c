/*
Lab2.c

Created: 10/13/2020 8:44:54 PM
Author : Bradley M. Martin
 

This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
Port D, Pin 1 -> Input -> Left Whisker
Port D, Pin 0 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	DDRB = 0b11111111; //configure Port B pins for input
	DDRD = 0b00000000; //configure Port D for output
	PORTB = 0b01100000; //set initially forward
	while (1) // loop forever
	{
		if(PIND == 0b11111110){	//if the Right whisker is hit
			//turn left
			PORTB = 0b00000000; //move backwards
			_delay_ms(1000);	//wait for 1 sec
			PORTB = 0b00100000;	//turn to the left
			_delay_ms(1000);	//wait for 1 sec
			PORTB = 0b01100000;	//continue to move forward
		}
		else if(PIND == 0b11111101){//if the Left whisker is hit
			//turn Right
			PORTB = 0b00000000; //move backwards
			_delay_ms(1000);	//wait for 1 sec
			PORTB = 0b01000000;	//turn to the right
			_delay_ms(1000);	//wait for 1 sec
			PORTB = 0b01100000;	//continue forward
		}
		
		else if((PIND == 0b11111110) && (PIND == 0b11111101)){//if both whiskers are hit are pushed
			//turn left
			PORTB = 0b00000000; //move backwards
			_delay_ms(1000);	//wait for 1 sec
			PORTB = 0b00100000;	//turn left
			_delay_ms(1000);	//wait for 1 sec
			PORTB = 0b01100000;	//continue forward
		}
	}
}
