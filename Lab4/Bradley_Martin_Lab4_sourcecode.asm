
;***********************************************************
;*
;*	Enter name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver
.def	input = r23
.def	temp = r25

.equ	B1 = 0
.equ	B2 = 1
.equ	B3 = 7

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr
		
		; Initialize LCD Display
		rcall LCDInit

		;Initialize Port D for input
		ldi		mpr, $00
		out		DDRD, mpr
		ldi		mpr, $FF
		out		PORTD, mpr

		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		in		input, PIND			; Get input from the buttons
		mov		mpr, input			; Send the input to mpr	
		cpi		mpr, 0b11111110		; Check to see if button 1 has been pressed
		brne	NEXT				; Branch to NEXT if button 1 is not pressed
		rcall	Button1				; Run the Button1 function if it has been pressed
		rjmp	MAIN				; Loop back to MAIN after Button1 has run

NEXT:	cpi		mpr, 0b11111101		; Check to see if button 2 has been pressed
		brne	NEXT2				; Branch to NEXT2 if button 2 is not pressed
		rcall	Button2				; Run Button2 function if it has been pressed
		rjmp	MAIN				; Loop back to MAIN after Button2 has run
		
NEXT2:	cpi		mpr, 0b01111111		; Check to see if button 7 has been pressed
		brne	MAIN				; Branch to Main if button 3 is not pressed
		rcall	Button3				; Run Button3 if it has been pressed
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Button1
; Desc: Loads string 1 to the top line of the LCD display and
;		loads string 2 to the bottom line of the LCD display.
;-----------------------------------------------------------
Button1:							

		ldi ZL,		low(STRING1_BEG<<1)     ; Initialize the Z pointer to the addresses of String 1
		ldi ZH,		high(STRING1_BEG<<1)
		ldi YL,		low(LCDLn1Addr)			; Initialize the Y pointer to hold our string on line 1
		ldi YH,		high(LCDLn1Addr)
		ldi temp,	16						; Counter register that will decrement through our bytes

L1:		lpm mpr, Z+							; Load the strings from program memory
		st Y+, mpr							; store the contents of the string to the Y register shift by one
		dec	temp							; Decrease the counter for the loop to tell how many bits are left
		brne L1								; If L1 has not decremented the counter to 0 then keep looping

		ldi ZL,		low(STRING2_BEG<<1)		; Initialize the Z pointer to the addresses of string 2
		ldi ZH,		high(STRING2_BEG<<1) 
		ldi YL,		low(LCDLn2Addr)			; Initialize the Y pointer to hold our string on line 2
		ldi YH,		high(LCDLn2Addr);	
		ldi temp,	16						; Reset the counter back to 16 from previous loop

L2:		lpm mpr, Z+
		st Y+, mpr
		dec temp
		brne L2

		rcall LCDWrite						; Update the LCD display

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
Button2:							

		ldi ZL,		low(STRING2_BEG<<1)		; Initialize the Z pointer to the addresses of string 2
		ldi ZH,		high(STRING2_BEG<<1) 
		ldi YL,		low(LCDLn1Addr)			; Initialize the Y pointer to hold our string on line 1
		ldi YH,		high(LCDLn1Addr)
		ldi temp,	16						; Counter register that will decrement through our bytes

upper:	lpm mpr, Z+							; Load the String from program memory
		st Y+, mpr							; Store the contents of the String into the Y register shift by one
		dec temp							; Decrease the counter 
		brne L2								; If upper is not finished not continue to loop through

 		ldi ZL,		low(STRING1_BEG<<1)		; Initialize the Z pointer to the addresses of string 1
		ldi ZH,		high(STRING1_BEG<<1) 
		ldi YL,		low(LCDLn2Addr)			; Initialize the Y pointer to hold our string on line 2
		ldi YH,		high(LCDLn2Addr)	
		ldi temp,	16						; Reset the counter back to 16 from the previous loop

lower:	lpm mpr, Z+
		st Y+, mpr
		dec temp
		brne L2

		rcall LCDWrite						; Update the LCD Dispaly

		ret						; End a function with RET
;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
Button3:							

		rcall LCDClr			; Clear LCD display

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING1_BEG:
.DB		"Bradley Martin  "		; Declaring data in ProgMem
STRING1_END:

STRING2_BEG:
.DB		"Hello, World    "
STRING2_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
