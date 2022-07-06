;***********************************************************
;*
;*	 Author: Bradley Martin
;*	   Date: 11/10/2020
;*
;***********************************************************

.include "m128def.inc"				; Include definition file

;************************************************************
;* Variable and Constant Declarations
;************************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	waitcnt = r23			; Wait Loop Counter
.def	ilcnt = r24				; Inner Loop Counter
.def	olcnt = r25				; Outer Loop Counter
.def	RightCount = r3			; Right whisker counter
.def	LeftCount = r4			; Left whisker counter
.def	temp = r2			; Holds the number of characters for Bin2ASCII

.equ	WTime = 100				; Time to wait in wait loop

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	Con1 = $0120			; Beginning address of counter string
.equ	Con2 = $0130			; Beginning address of counter string

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;**************************************************************
;* Beginning of code segment
;**************************************************************
.cseg

;--------------------------------------------------------------
; Interrupt Vectors
;--------------------------------------------------------------
.org	$0000				; Reset and Power On Interrupt
		rjmp	INIT		; Jump to program initialization

.org	$0002
		rcall HitRight		; Run HitRight function
		reti

.org	$0004
		rcall HitLeft		; Run HitLeft Function
		reti

.org	$0006
		rcall ClrRight		; Run ClrRight Function
		reti

.org	$0008
		rcall ClrLeft		; Run ClrLeft Function
		reti

.org	$0046				; End of Interrupt Vectors
;--------------------------------------------------------------
; Program Initialization
;--------------------------------------------------------------
INIT:
    ; Initialize the Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

	; Initialize counters for right and left whisker
		clr		LeftCount
		clr		RightCount	
	
	; Initialize LCD Display
		rcall LCDInit
		rcall UpdateLCD

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

	; Initialize external interrupts:

	; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01) | (0<<ISC00) | (1<<ISC11)| (0<<ISC10)
		sts		EICRA, mpr
	; Set the External Interrupt Mask
		ldi		mpr, (1<<INT0) | (1<<INT1) | (1<<INT2) | (1<<INT3)
		out		EIMSK, mpr
	; Turn on interrupts

	sei
;---------------------------------------------------------------
; Main Program
;---------------------------------------------------------------
MAIN:
		; Move Robot Forward
		ldi		mpr, MovFwd			; Load FWD command
		out		PORTB, mpr			; Send to motors

		rjmp	MAIN				; Infinite loop. End of the program

;****************************************************************
;* Subroutines and Functions
;****************************************************************

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:

		inc		RightCount			; Increment by 1
		rcall	UpdateLCD			; Update display

		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts

		; Move Backwards for a second
		ldi		mpr, MovBck			; Load Move Backward command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 1 second
		rcall	Wait1				; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL			; Load Turn Left Command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 1 second
		rcall	Wait1				; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd			; Load Move Forward command
		out		PORTB, mpr			; Send command to port

		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts

		sei
		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:

		inc		LeftCount			; Increment by 1
		rcall	UpdateLCD			; Update display
		
		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts
		
		; Move Backwards for a second
		ldi		mpr, MovBck			; Load Move Backward command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 1 second
		rcall	Wait1				; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR			; Load Turn Left Command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 1 second
		rcall	Wait1				; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd			; Load Move Forward command
		out		PORTB, mpr			; Send command to port

		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts

		sei
		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait1:
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
		ret				; Return from subrou

;-----------------------------------------------------------
; Func: Clrright
; Desc: Clears the right counter and reprints the LCD
;-----------------------------------------------------------
ClrRight:
		clr		RightCount			; Set RightCount to 0
			
		rcall	UpdateLCD			; Update the LCD

		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts

		sei
		ret

;-----------------------------------------------------------
; Func: Clrleft
; Desc: Clears the left counter and reprints the LCD
;-----------------------------------------------------------
ClrLeft:
		clr		LeftCount			; Set LeftCount to 0
			
		rcall	UpdateLCD			; Update the LCD

		ldi		mpr, 0b11111111		; Set mpr to all high
		out		EIFR, mpr			; Reset EIFR with all high to clear interrupts

		sei
		ret
;-----------------------------------------------------------
; Func: UpdateLCD
; Desc: Loads string 1 to the top line of the LCD display and
;		loads string 2 to the bottom line of the LCD display.
;-----------------------------------------------------------

UpdateLCD:							
		
		rcall LCDClr						; Clear LCD

		ldi XL,		low(Con1)				; Initialize the X pointer to hold the address of the converted left counter
		ldi XH,		high(Con1)

		mov mpr,	RightCount				; Move the value of the Right Counter to mpr
		rcall Bin2ASCII						; Convert the count to a string

		mov mpr, r18						; Get how many characters long the string is
		mov temp, mpr						; Move that number to temp

		ldi YL,		low(LCDLn1Addr)			; Initialize the Y pointer to hold our string on line 1
		ldi YH,		high(LCDLn1Addr)

L1:		ld mpr, X+							; Load the strings from X registers
		st Y+, mpr							; store the contents of the string to the Y register shift by one
		dec	temp							; Decrease the counter for the loop to tell how many bits are left
		brne L1								; If L1 has not decremented the counter to 0 then keep looping

		ldi XL,		low(Con2)				; Initialize the X pointer to hold the address of the converted right counter
		ldi XH,		high(con2)

		mov mpr,	LeftCount				; Move the value of LeftCount to mpr
		rcall Bin2ASCII						; Convert the count to a string

		mov mpr, r18						; Get how many characters long the string is
		mov temp, mpr						; Move that number to temp


		ldi YL,		low(LCDLn2Addr)			; Initialize the Y pointer to hold our string on line 2
		ldi YH,		high(LCDLn2Addr);	

L2:		ld mpr, X+							; Load the strings from X registers
		st Y+, mpr							; store the contents of the string to the Y register shift by one
		dec temp							; Decrease the counter for the loop to tell how many bits are left
		brne L2								; If L1 has not decremented the counter to 0 then keep looping

		rcall LCDWrite						; Update the LCD display

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------


;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
