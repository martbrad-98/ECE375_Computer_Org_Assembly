;***********************************************************
;*
;*	Bradley_Martin_sourcecode
;*
;*	Program to take button input to change the speed of the tekbot.
;*
;***********************************************************
;*
;*	 Author: Bradley Martin
;*	   Date: 11/16/2020
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	waitcnt = r17			; wait loop counter
.def	ilcnt = r18				; inner loop counter
.def	olcnt = r19				; outer loop counter
.def	Speed = r20				; holds the value for what step we are on for lower bits
.def	SpeedStep = r21			; holds the value of what speed percent we are on for the higher bits
.def	temp = r22

.equ	WTime = 10				; time to wait in loop

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

.equ	MovFwd = (1<<EngDirR | 1<<EngDirL)	; enable tekbot to move forward

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

.org	$0002
		rcall Speed_Up			; button for speeding up the tekbot
		reti

.org	$0004
		rcall Speed_Down		; button for slowing down the tekbot
		reti

.org	$0006
		rcall Speed_Max			; button for max speed
		reti

.org	$0008
		rcall Speed_Min			; button for min speed
		reti

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer

		ldi		mpr, low(RAMEND)	
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Configure I/O ports

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low	

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Configure External Interrupts, if needed

		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01) | (0<<ISC00) | (1<<ISC11)| (0<<ISC10)
		sts		EICRA, mpr

		; Set the External Interrupt Mask
		ldi		mpr, (1<<INT0) | (1<<INT1) | (1<<INT2) | (1<<INT3)
		out		EIMSK, mpr

		; Configure 8-bit Timer/Counters

		ldi		mpr, 0b01101001		; initial settings
		out		TCCR0, mpr			; set timer0 to settings
		out		TCCR2, mpr			; set timer2 to settings

		ldi		mpr, $00			; load 0 into mpr for compare value
		sts		OCR0, mpr			; set compare to 0
		sts		OCR2, mpr			; set compare to 0

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)

		ldi		mpr, MovFwd		; set mpr to movefwd command
		out		PORTB, mpr		; update the leds

		; Set initial speed, display on Port B pins 3:0
		clr		Speed				; Starting at speed 0
		clr		SpeedStep
		
		out		OCR0, Speed			; update compare values
		out		OCR2, Speed
		
		in		mpr, PORTB			; store the current state of the leds

		cbr		mpr, 0b00001111		; clear the lower half leds
		or		mpr, SpeedStep		; perform or on upper half so only leds 5/8 change

		out		PORTB, mpr			; update leds

		; Enable global interrupts (if any are used)
		sei
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	Speed_up
; Desc:	Increses the speed by 17 and increments the speed step.
;-----------------------------------------------------------
Speed_Up:	; Begin a function with a label
		mov		mpr, Speed	; get the current speed
		cpi		mpr, $FF	; check to see if we are at max speed
		breq	MaxSpeed	; If we are then skip
	
		ldi		temp, $11	; if we are not then load 17 into mpr
		add		Speed, temp	; add a step to speed
		inc		r21			; increade what step we are on

		out		OCR0, Speed	; update compare values
		out		OCR2, Speed
		
		in		mpr, PORTB	; store the current state of the leds

		cbr		mpr, 0b00001111		; clear the lower half leds
		or		mpr, SpeedStep		; perform or on upper half so only leds 5/8 change

		out		PORTB, mpr			; update leds		

MaxSpeed:
		rcall	Wait				; wait for debounce
		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts

		sei
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Speed_Down
; Desc:	Decreses the speed by 17 and decrements the speed step.
;-----------------------------------------------------------
Speed_Down:	; Begin a function with a label

		mov		mpr, Speed	; get the current speed
		cpi		mpr, $00	; check to see if we are at min speed
		breq	MinSpeed	; If we are then skip

		subi	Speed, $11	; Subtract 17 from speed
		dec		SpeedStep	; decrement what step we are on

		out		OCR0, Speed	; update compare values
		out		OCR2, Speed
		
		in		mpr, PORTB	; store the current state of the leds

		cbr		mpr, 0b00001111	; clear the lower half leds
		or		mpr, SpeedStep	; perform or on upper half so only leds 5/8 change

		out		PORTB, mpr		; update leds

MinSpeed:
		rcall	Wait				; wait for debounce

		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts

		sei
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Speed_Max
; Desc:	Sets speed and speed step to max.
;-----------------------------------------------------------
Speed_Max:	; Begin a function with a label

		ldi		mpr, $FF				; load max speed into mpr
		mov		Speed, mpr				; move that value into speed
		ldi		SpeedStep, 0b00001111	; set the speed step to max
		
		out		OCR0, Speed				; upadate compare values
		out		OCR2, Speed
		
		in		mpr, PORTB				; store the current state of the leds

		cbr		mpr, 0b00001111			; clear the lower half leds
		or		mpr, SpeedStep			; perform or on upper half so only leds 5/8 change

		out		PORTB, mpr				; update leds

		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts


		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Speed_Min
; Desc:	Sets speed and speed step to 0.
;-----------------------------------------------------------
Speed_Min:	; Begin a function with a label

		ldi		mpr, $00				; load min speed into mpr
		mov		Speed, mpr				; move that value into speed
		ldi		SpeedStep, 0b00000000	; set the speed step to min

		out		OCR0, Speed				;update compare values
		out		OCR2, Speed
		
		in		mpr, PORTB				; store the current state of the leds

		cbr		mpr, 0b00001111			; clear the lower half leds
		or		mpr, SpeedStep			; perform or on upper half so only leds 5/8 change

		out		PORTB, mpr				; update leds

		ldi		mpr, 0b11111111			; Set mpr to all high
		out		EIFR, mpr				; Reset EIFR with all high to clear interrupts

		ret						; End a function with RET

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program