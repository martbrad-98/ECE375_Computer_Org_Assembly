;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for the ECE 375 final project
;*
;***********************************************************
;*
;*	 Author: Bradley Martin
;*	   Date: 12/6/2020
;*
;***********************************************************
.include "m128def.inc"			; Include definition file
;***********************************************************
;*	Internal Register Definitions and Constants
;*	(feel free to edit these or add others)
;***********************************************************
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable
.def	mpr = r16				; Multipurpose register 
.def	temp = r23
.def	temp2 = r24
.def	temp3 = r25

.equ	WTime = 15

.equ	temp_string = $0220
;***********************************************************
;*	Data segment variables
;*	(feel free to edit these or add others)
;***********************************************************
.dseg
.org	$0200						; data memory allocation for operands
i:		.byte 2				; allocate 2 bytes for a variable named operand1

.org	$0210
Letter:			.byte 2

; Important Reminder:
; The LCD driver expects its display data to be arranged as follows:
; - Line 1 data is in address space $0100-$010F
; - Line 2 data is in address space $0110-$010F

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp  INIT				; Reset interrupt
.org	$0046					; End of Interrupt Vectors
;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:	; The initialization routine
		clr  zero

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

		; Initialize LCD display
		rcall	LCDInit
		rcall	LCDClr

		;Configure Timer/Counter
		ldi		mpr, 0b00000000
		out		TCCR1A, mpr
		ldi		mpr, 0b00000101
		out		TCCR1B, mpr


;-----------------------------------------------------------
; Main procedure
;-----------------------------------------------------------
MAIN:
		rcall StartScreen			; Set up the Start Screen
		rcall Init_Letter			; set the letter to A
		rcall Init_index			; set index to 0
		ldi		temp, WTime			; Add debounce
		rcall	wait1
			
		sbic	PIND, 0				; Check to see if PD0 has been pressed
		jmp		main		
		jmp		char_select


Char_Select:
		ldi		temp, WTime			; Add debounce
		rcall	wait1
		rcall	Init_Select_Screen	; Set up the Text for selecting a character

poll_loop:	
		sbic	PIND, 6				; Check to see if PD6 has been pressed
		jmp Letter_dec				; If not check next button
		rcall	Inc_Letter			; if pressed increase letter

Letter_Dec:
		sbic	PIND, 7				; Check to see if PD7 has been pressed
		jmp		Transmit			; If not check next button
		rcall	Dec_Letter			; If pressed decrease letter
Transmit:
		sbic	PIND, 3				; check if PD4 has been pressed				
		jmp		Confirm_letter		; if not check next button
		rcall	Transmission		; if pressed then send message
		jmp		poll_loop			; return to top of loop
Confirm_Letter:
		sbic	PIND, 0				; check to see if PD0 has been pressed
		jmp		Nothing				; if not then jump to nothing and loop back to top
		rcall	Add_Letter			; If it has been pressed add a letter to the stored string
		ldi		ZL, low(i)			; Load our index into Z
		ldi		ZH, high(i)
		ld		mpr, Z				; load the contents of Z into mpr
		cpi		mpr, 16				; if our index is greater then 16 then transmit
		brne	nothing				; if not then loop back to top
		rcall	transmission
Nothing:
		jmp		poll_loop

;***********************************************************
;*	Procedures and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: StartScreen
; Desc: Loads Start_String1 to the top line of the LCD display and
;		loads Start_String2 to the bottom line of the LCD display.
;-----------------------------------------------------------
StartScreen:
		ldi ZL,		low(Start_string1<<1)     ; Initialize the Z pointer to the addresses of String 1
		ldi ZH,		high(Start_string1<<1)
		ldi YL,		low(LCDLn1Addr)			; Initialize the Y pointer to hold our string on line 1
		ldi YH,		high(LCDLn1Addr)
		ldi temp,	16						; Counter register that will decrement through our bytes

L1:		lpm mpr, Z+							; Load the strings from program memory
		st Y+, mpr							; store the contents of the string to the Y register shift by one
		dec	temp							; Decrease the counter for the loop to tell how many bits are left
		brne L1								; If L1 has not decremented the counter to 0 then keep looping

		ldi ZL,		low(Start_String2<<1)		; Initialize the Z pointer to the addresses of string 2
		ldi ZH,		high(Start_String2<<1) 
		ldi YL,		low(LCDLn2Addr)			; Initialize the Y pointer to hold our string on line 2
		ldi YH,		high(LCDLn2Addr);	
		ldi temp,	16						; Reset the counter back to 16 from previous loop

L2:		lpm mpr, Z+							; load contents of Z into Y
		st Y+, mpr
		dec temp
		brne L2

		rcall LCDWrite						; Update the LCD display

		ret	
;-----------------------------------------------------------
; Func: Init_Letter_list
; Desc: set letter to A
;
;-----------------------------------------------------------
Init_Letter:
		ldi ZL, low(Letter)					; Load Z with letter address
		ldi ZH, high(Letter)

		ldi mpr, 65							; set letter to A and store
		st	Z, mpr

		ret
;-----------------------------------------------------------
; Func: Select_Letter
; Desc: set index to 0
;
;-----------------------------------------------------------
Init_index:
		ldi		XL, low(i)					; Load X with index
		ldi		XH, High(i)

		ldi		mpr, $00					; set index to 0
		st		X, mpr

		ret
;-----------------------------------------------------------
; Func: Init_Select_Screen
; Desc: initilize screen for seccting a letter
;
;-----------------------------------------------------------
Init_Select_Screen:
		rcall LCDClr

		ldi ZL,		low(Input_String1<<1)   ; Initialize the Z pointer to the addresses of String 1
		ldi ZH,		high(Input_String1<<1)
		ldi YL,		low(LCDLn1Addr)			; Initialize the Y pointer to hold our string on line 1
		ldi YH,		high(LCDLn1Addr)
		ldi temp,	16						; Counter register that will decrement through our bytes

upper:	lpm mpr, Z+							; Load the strings from program memory
		st Y+, mpr							; store the contents of the string to the Y register shift by one
		dec	temp							; Decrease the counter for the loop to tell how many bits are left
		brne upper							; If L1 has not decremented the counter to 0 then keep looping

		ldi ZL,		low(letter)				; Initialize the Z pointer to the addresses of String 1
		ldi ZH,		high(letter)
		ldi YL,		low(LCDLn2Addr)			; Initialize the Y pointer to hold our string on line 2
		ldi YH,		high(LCDLn2Addr);


lower:	ld mpr, Z							; Load A into first index of LCD
		st Y, mpr

		rcall LCDWrite						; Update the LCD display
		
		ret
;-----------------------------------------------------------
; Desc: increments letter and writes to lcd
;-----------------------------------------------------------
Inc_Letter:
		ldi		temp, WTime			; Add debounce
		rcall	wait1

		ldi		ZL,	low(letter)     ; Initialize the Z pointer to the addresses of letter
		ldi		ZH,	high(letter)


		ldi		YL, low(i)			; Load Y with address of index
		ldi		YH, high(i)
		ld		temp, Y				; load temp with our index

		ld		mpr, Z				; Loads current letter into temp
		inc		mpr					; Increments to next letter
		st		Z, mpr				; stores new letter back into Z
		rcall	Check_Letter		; Checks to see if that letter is within bounds

		ldi		line, 2				; set what line we want to write to
		mov		count, temp			; set what index we are writing to
		rcall	LCDWriteByte		; write the letter to LCD
		ret


;-----------------------------------------------------------
; Desc: decrements letter and writes to lcd
;
;-----------------------------------------------------------
Dec_Letter:
		ldi		temp, WTime			; Add debounce
		rcall	wait1

		ldi		ZL,	low(letter)     ; Initialize the Z pointer to the addresses of String 1
		ldi		ZH,	high(letter)

		ldi		YL, low(i)			; Load Y with addess of index
		ldi		YH, high(i)
		ld		temp, Y				; load our index into temp

		ld		mpr, Z				; load current letter into mpr
		dec		mpr					; decrement letter
		st		Z, mpr				; store letter back into memory
		rcall	Check_letter		; check to see if that letter is within bounds

		ldi		line, 2				; set what line we want to write to
		mov		count, temp			; set what index we are writing to
		rcall	LCDWriteByte		; Write the letter to LCD

		ret
;-----------------------------------------------------------
; Desc: Checks if we are still inbetween A-Z
;
;-----------------------------------------------------------
Check_Letter:
		cpi mpr, 91			; compare our letter with upper bound
		brsh Reset_A		; if we are past then branch to reset letter to A
		cpi mpr, 65			; compare our letter with lower bound
		brlo Reset_Z		; if we are past then branch to reset letter to Z
		ret
Reset_A:
		ldi mpr, 65			; Set letter to A
		st Z, mpr			; store A
		ret
Reset_Z:
		ldi mpr, 90			; set letter to Z
		st Z, mpr			; set Z
		ret

;-----------------------------------------------------------
; Desc: Transmits message
;
;-----------------------------------------------------------
Transmission:
		ldi		YL, low(LCDLn2Addr)			; set Y to line 2 address
		ldi		YH, high(LCDLn2Addr)
		ldi		XL, low(i)					; set x to index address
		ldi		XH, high(i)
		ld		temp3, X					; load index into temp3
		cpi		temp3, 0					; compare index with 0
		brne	trans_loop					; if index is not 0 then branch
		inc		temp3						; if it is zero increment to 1
trans_loop:
		ld		mpr, Y+						; load contents of line 2 to mpr
		rcall	send_letter					; send that letter to convert to morse
		dec		temp3						; decrement how many letters are left
		brne	trans_loop					; continue until all letters have transmited
		
		rcall	Init_Index					; reset values for next message
		rcall	LCDclrLn2
		rcall	Init_Letter
		ret
;-----------------------------------------------------------
; Desc: converts letters to morse code
;-----------------------------------------------------------
Send_letter:
		subi	mpr, 65						; subtract 65 from our letter
		ldi		temp, 0						; load 0 into temp
				
		ldi		ZL, low(Morsetiming<<1)		; get first address of morse timeing array
		ldi		ZH, high(Morsetiming<<1)
		add		ZL, mpr						; add offset to address
		adc		ZH, temp

		lpm		temp, Z						; load the value at the offset

		ldi		ZL, low(Morselength<<1)		; get first address of morse length array
		ldi		ZH, high(Morselength<<1)
		add		ZL, mpr						; add offset to address
		adc		ZH, temp

		lpm		temp2, Z					; load the value at the offset

Morse_loop:
		Rol		temp						; rotate bit into carry
		brcs	Dash						; if its a 1 then send dash
		rcall	Send_Dot					; otherwise send a dot
		dec		temp2						; decrement how dots/dashes are left
		brne	Morse_loop					; continue while there is still more
		ret
Dash:	
		rcall	Send_dash					; send a dash
		dec		temp2						; decrement how many dots/daashes are left
		brne	Morse_loop

		ldi		mpr, 0b00000000				; turn off transmission led
		out		PORTB, mpr
		ret
;-----------------------------------------------------------
; Desc: Sends a dot to leds
;
;-----------------------------------------------------------
Send_Dot:
		push	temp				; save temp
		push	temp3				; save temp3

		ldi		temp3, 0b11110000	; set what leds to turn on
		out		PORTB, temp3		; turn on leds
		ldi		temp, 100			; load value for delay
		rcall	wait1				; delay 1 sec
		ldi		temp3, 0b00010000	; set only transmission led on
		out		PORTB, temp3		; turn on/off leds
		rcall	wait1				; delay 3 sec
		rcall	wait1
		rcall	wait1
		pop		temp3				; return temp3
		pop		temp				; return temp

		ret
;-----------------------------------------------------------
; Desc: sends a dash to leds
;
;-----------------------------------------------------------
Send_Dash:
		push	temp				; save temp
		push	temp3				; save temp3

		ldi		temp3, 0b11110000	; set what leds to turn on
		out		PortB, temp3		; turn on leds
		ldi		temp, 100			; load value for delay
		rcall	wait1				; delay 3 sec
		rcall	wait1	
		rcall	wait1
		ldi		temp3, 0b00010000	; set only transmission led on
		out		PORTB, temp3		; turn on/off leds
		rcall	wait1				; delay 3 sec
		rcall	wait1
		rcall	wait1

		pop		temp3				; return temp3
		pop		temp				; return temp
		ret
	
	
;-----------------------------------------------------------
; Desc: add a letter to our stored string
;
;-----------------------------------------------------------
Add_Letter:
		ldi		temp, WTime			; Add debounce
		rcall	wait1
		ldi		XL, low(i)			; set X to address of index
		ldi		XH, high(i)
		ld		temp, X				; load index into temp

		inc		temp				; increase our index
		st		X, temp				; store index back into memory

		rcall	Init_letter			; reset letter to A
		; Print A to screen
		ldi		ZL,	low(letter)     ; Initialize the Z pointer to the addresses of String 1
		ldi		ZH,	high(letter)
		ld		mpr, Z				; Loads current letter into mpr
		ldi		line, 2				; set line 2 as line we write to
		mov		count, temp			; set count to our index
		rcall	LCDWriteByte		; write A to LCD

		ret
;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait1:
		push	temp			; Save wait register
		push	temp2			; Save ilcnt register
		push	temp3			; Save olcnt register

Loop:	ldi		temp3, 224		; load olcnt register
OLoop:	ldi		temp2, 237		; load ilcnt register
ILoop:	dec		temp2			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		temp3		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		temp		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		temp3		; Restore olcnt register
		pop		temp2		; Restore ilcnt register
		pop		temp		; Restore wait register
		ret				; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************
Start_String1: 
	.DB "Welcome!        "
Start_String1_End:

Start_String2: 
	.DB "Please press PD0"
Start_String2_End:

Input_String1: 
	.DB "Enter word:     "
Input_String1_end:

Morsetiming: 
	.DB 0b01000000, 0b10000000, 0b10100000, 0b10000000, 0b00000000, 0b00100000,0b11000000, 0b00000000, 0b00000000, 0b01110000, 0b10100000, 0b01000000, 0b11000000, 0b10000000, 0b11100000, 0b01100000, 0b11010000, 0b01000000, 0b00000000, 0b10000000, 0b00100000, 0b00010000, 0b01100000, 0b10010000, 0b10110000, 0b11000000
Morsetiming_end:

MorseLength:
	.DB 2, 4, 4, 3, 1, 4, 3, 4, 2, 4, 3, 4, 2, 2, 3, 4, 4, 3, 3, 1, 3, 4, 3, 4, 4, 4
MorseLength_End:
;***end of your code***end of your code***end of your code***end of your code***end of your code***
;******************************* Do not change below this point************************************
;******************************* Do not change below this point************************************
;******************************* Do not change below this point************************************


;***********************************************************
;*	Stored Program Data
;***********************************************************

; Contents of program memory will be changed during testing
; The label names are not changed

; If UserMode is 0x01, then one unit of time is 1 second
UserMode:	.DB	0x01, 0x00
; You can ignore the second byte (it's only included so that there is an even number of bytes)

; If UserMode is 0x00, then one unit of time is 200 milliseconds
; This would look like the following:
;UserMode:	.DB	0x00, 0x00
; (again, ignore the second byte)

; UserMode will always be set to either 0x00 or 0x01


;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver from Lab 4
