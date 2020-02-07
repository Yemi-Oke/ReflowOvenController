; This program shows how to read many push buttons using just one analog input.
; The idea is to make a voltage divider with many resistors and the push buttons
; connect the diferent voltages to an analog input.  In this example we have seven push
; buttons.  The diagram is in this image: push_button_adc.jpg.  The common pin of all
; the push buttons is connected to pin P0.4.
;

$MOD9351

XTAL EQU 7373000
BAUD EQU 115200
BRVAL EQU ((XTAL/BAUD)-16)

; OUR PINS ;

SSRpin EQU P2.7

; OUR PINS ;

	CSEG at 0x0000
	ljmp	MainProgram

bseg
PB0: dbit 1 ; Variable to store the state of pushbutton 0 after calling ADC_to_PB below
PB1: dbit 1 ; Variable to store the state of pushbutton 1 after calling ADC_to_PB below
PB2: dbit 1 ; Variable to store the state of pushbutton 2 after calling ADC_to_PB below
PB3: dbit 1 ; Variable to store the state of pushbutton 3 after calling ADC_to_PB below
PB4: dbit 1 ; Variable to store the state of pushbutton 4 after calling ADC_to_PB below
PB5: dbit 1 ; Variable to store the state of pushbutton 5 after calling ADC_to_PB below
PB6: dbit 1 ; Variable to store the state of pushbutton 6 after calling ADC_to_PB below

dseg at 0x30

; Variable meanings:

; PB0: hundreds
; PB1: tens
; PB2: units
; PB3: forward
; PB4: back
; PB5: clear
; PB6: enter

; Variables:

timesoak: ds 2
tempsoak: ds 2
timereflow: ds 2
tempreflow: ds 2
Result: ds 2
soaktimer: ds 2
reflowtimer: ds 2
		
cseg
; These 'equ' must match the wiring between the microcontroller and the LCD!
LCD_RS equ P0.7
LCD_RW equ P3.0
LCD_E  equ P3.1
LCD_D4 equ P2.0
LCD_D5 equ P2.1
LCD_D6 equ P2.2
LCD_D7 equ P2.3

$NOLIST
$include(LCD_4bit_LPC9351.inc) ; A library of LCD related functions and utility macros
$LIST

Wait1S:
	mov R2, #40
M3:	mov R1, #250
M2:	mov R0, #184
M1:	djnz R0, M1 ; 2 machine cycles-> 2*0.27126us*184=100us
	djnz R1, M2 ; 100us*250=0.025s
	djnz R2, M3 ; 0.025s*40=1s
	ret

InitADC1:
    ; Configure pins P0.4, P0.3, P0.2, and P0.1 as inputs
	orl	P0M1,#0x1E
	anl	P0M2,#0xE1
	setb BURST1 ; Autoscan continuos conversion mode
	mov	ADMODB,#0x20 ;ADC1 clock is 7.3728MHz/2
	mov	ADINS,#0xF0 ; Select the four channels for conversion
	mov	ADCON1,#0x05 ; Enable the converter and start immediately
	; Wait for first conversion to complete
InitADC1_L1:
	mov	a,ADCON1
	jnb	acc.3,InitADC1_L1
	ret
	
ADC_to_PB:
	setb PB6
	setb PB5
	setb PB4
	setb PB3
	setb PB2
	setb PB1
	setb PB0
	; Check PB6
	clr c
	mov a, AD1DAT3
	subb a, #(206-10) ; 2.8V=216*(3.3/255); the -10 is to prevent false readings
	jc ADC_to_PB_L6
	clr PB6
	ret
ADC_to_PB_L6:
	; Check PB5
	clr c
	mov a, AD1DAT3
	subb a, #(185-10) ; 2.4V=185*(3.3/255); the -10 is to prevent false readings
	jc ADC_to_PB_L5
	clr PB5
	ret
ADC_to_PB_L5:
	; Check PB4
	clr c
	mov a, AD1DAT3
	subb a, #(154-10) ; 2.0V=154*(3.3/255); the -10 is to prevent false readings
	jc ADC_to_PB_L4
	clr PB4
	ret
ADC_to_PB_L4:
	; Check PB3
	clr c
	mov a, AD1DAT3
	subb a, #(123-10) ; 1.6V=123*(3.3/255); the -10 is to prevent false readings
	jc ADC_to_PB_L3
	clr PB3
	ret
ADC_to_PB_L3:
	; Check PB2
	clr c
	mov a, AD1DAT3
	subb a, #(92-10) ; 1.2V=92*(3.3/255); the -10 is to prevent false readings
	jc ADC_to_PB_L2
	clr PB2
	ret
ADC_to_PB_L2:
	; Check PB1
	clr c
	mov a, AD1DAT3
	subb a, #(61-10) ; 0.8V=61*(3.3/255); the -10 is to prevent false readings
	jc ADC_to_PB_L1
	clr PB1
	ret
ADC_to_PB_L1:
	; Check PB1
	clr c
	mov a, AD1DAT3
	subb a, #(30-10) ; 0.4V=30*(3.3/255); the -10 is to prevent false readings
	jc ADC_to_PB_L0
	clr PB0
	ret
ADC_to_PB_L0:
	; No pusbutton pressed	
	ret

;-----------;
; OURMACROS ;
;-----------;

Set_Value MAC
	mov b, %0
	mov r0, %0
	mov r1, %0
	
	lcall _Set_Value	
endma: endmac

_Set_Value:
	
	Set_Cursor(2,1)
	mov a, r1
	Display_BCD(a) ; displays two most significant digits
	
	Set_Cursor(2,3)
	mov a, r0
	Display_BCD(a) ; displays two least significant digits
	
	lcall ADC_to_PB
	
	jb PB0, tens_check; hundreds check

	mov a, r1
	add a, #0x01
	da a
	mov r1, a
	
	mov a, b
	add a, #0x64
	da a
	mov b, a
		
hundredsloop: 
lcall ADC_to_PB
jnb PB0, hundredsloop
	
	tens_check:
	
		lcall ADC_to_PB
	
		jb PB1, units_check
		
		mov a, b
		add a, #0xA
		da a 
		mov b, a
		
		mov a, r0
		add a, #0xA
		da a
		mov r0, a
		
tensloop: 
lcall ADC_to_PB
jnb PB1, tensloop
	
	units_check:
	
		lcall ADC_to_PB
		jb PB2, buttoncheck
		
		mov a, b
		add a, #0x1
		da a
		mov b, a
		
		mov a, r0
		add a, #0x1
		da a
		mov r0, a
		
unitsloop: 
lcall ADC_to_PB
jnb PB2, unitsloop

buttoncheck:
	lcall ADC_to_PB
	;jnb PB3, GOHOME
	jnb PB4, GOHOME
	jnb PB5, GOHOME
	jnb PB6, GOHOME
	
retval:	ljmp _Set_Value

GOHOME: ret

Title: db 'Oven Controller!', 0
TimeSoakMessage: db 'Enter soak time: \r\n', 0
TempSoakMessage: db 'Enter soak temp: \r\n', 0
TimeReflowMessage: db 'Enter reflow time: \r\n', 0
TempReflowMessage: db 'Enter reflow temp: \r\n', 0
Blank: db '      ',0
Weback: db 'We are back               ', 0
forwardsuccess: db 'Onward!              ', 0
backwardsuccess: db 'Backward!           ', 0
Success: db 'We made it                  ', 0
	
MainProgram:
    mov SP, #0x7F

    ; Configure all the ports in bidirectional mode:
    mov P0M1, #00H
    mov P0M2, #00H
    mov P1M1, #00H
    mov P1M2, #00H ; WARNING: P1.2 and P1.3 need 1kohm pull-up resistors!
    mov P2M1, #00H
    mov P2M2, #00H
    mov P3M1, #00H
    mov P3M2, #00H
    
    lcall InitADC1
    lcall LCD_4BIT
	
;--------------------------------------------;
;					SSR						 ;
;--------------------------------------------;

; Program:

;  1. Soak loop time mode - enter time, hit enter
;  2. Soak loop temperature mode - enter temp, hit enter
;  3. Reflow loop time mode - enter time, hit enter
;  4. Reflow loop temperature mode - enter temp, hit enter 
;  5. Wait for user to hit start 

start:

; clears all other variables 

	mov timesoak, #0
	mov tempsoak, #0
	mov timereflow, #0
	mov tempreflow, #0
	
	sjmp mainmenu
	
SoaktimeB:
lcall ADC_to_PB
jnb PB4, SoaktimeB 

mainmenu:

	Set_Cursor(1,1)
	Send_Constant_String(#Title)
	Set_Cursor(2,1) ; (1,2)
	Send_Constant_String(#Blank)

	lcall ADC_to_PB
	jnb PB6, mainmenuwaitloop ; jumps to soak time input if forward is pressed 

sjmp mainmenu

mainmenuwaitloop:
lcall ADC_to_PB
jnb PB6, mainmenuwaitloop

; SOAKTIME ;

SoakTempB:
lcall ADC_to_PB
jnb PB4, SoakTempB

soaktime:

	Set_Cursor(1,1)
	Send_Constant_String(#TimeSoakMessage)

	Set_Value(timesoak)

soaktimeforward: jnb PB6, SoakTimeA ; next routine
	
back1:
	jnb PB4, SoakTimeBinter ; goes back to main menu
	SoakTimeBinter:  ljmp SoakTimeB
	
soaktimeclear:
	jb PB5, soaktimereturn
	mov timesoak, #0	
	soaktimereturn: ljmp soaktime	
	
;------------------------;	
;------ SOAKTEMP --------;
;------------------------;

SoakTimeA:
lcall ADC_to_PB
jnb PB6, SoakTimeA

ReflowTimeB:
lcall ADC_to_PB
jnb PB4, ReflowTimeB
	
soaktemp:

	Set_Cursor(1,1)
	Send_Constant_String(#TempSoakMessage)

	Set_Value(tempsoak)
	
soaktempforward: jnb PB6, SoakTempA ; next routine
	
back2: jnb PB4, SoakTempB ; goes back to soak time

soaktempclear: 
	jb PB5, soaktempreturn
	mov tempsoak, #0
	soaktempreturn: ljmp soaktemp
	
	soaktimeinter: ljmp soaktime
	
;----------------------------;
;--------REFLOWTIME----------;
;----------------------------;

SoakTempA:
lcall ADC_to_PB
jnb PB6, SoakTempA

ReflowTempB:
lcall ADC_to_PB
jnb PB4, ReflowTempB

reflowtime:

	Set_Cursor(1,1)
	Send_Constant_String(#TimeReflowMessage)

	Set_Value(timereflow)
	
reflowtimeforward: jnb PB6, ReflowTimeA ; next routine
	
back3: jnb PB4, ReflowTimeB ; goes back to soak time

reflowtimeclear: 
	jb PB5, reflowtimereturn
	mov timereflow, #0
	reflowtimereturn: ljmp reflowtime
	
;-----------------------------;
;-------- REFLOWTEMP ---------;
;-----------------------------;

ReflowTimeA:
lcall ADC_to_PB
jnb PB6, ReflowTimeA

Waitreturn:
lcall ADC_to_PB
jnb PB4, Waitreturn

reflowtemp:

	Set_Cursor(1,1)
	Send_Constant_String(#TempReflowMessage)

	Set_Value(tempreflow)
	
reflowtempforward: jnb PB6, ReflowTempA ; next routine
	
back4: jnb PB4, ReflowTempB ; goes back to soak time

reflowtempclear: 
	jb PB5, reflowtempreturn
	mov tempreflow, #0
	reflowtempreturn: ljmp reflowtemp
	
	
;----------------------;
;---------WAIT---------;
;----------------------;

ReflowTempA:
lcall ADC_to_PB
jnb PB6, ReflowTempA
 
Set_Cursor(1,1)
Send_Constant_String(#Success)

Set_Cursor(2,1)
Send_Constant_String(#Blank)

wait: 
lcall ADC_to_PB
jnb PB4, Waitreturn
jnb PB6, startoven 
sjmp wait	
	
					;------------;
					; START OVEN ;
					;------------;

; At this point, input values have been set, available in variables:
; timesoak, tempsoak, timereflow, tempreflow
; Step 1: Switch on SSR, switching on oven
; Step 2: Check 1 - if tempsoak achieved:
	; a: Switch off SSR
	; b: Switch on soaktimer
; Step 3: 
	; Check 2.1 - if soaktimer = timesoak, switch on oven and don't switch off
	; Check 2.2 - if oven temp < tempsoak - 3 degrees, switch on oven / else if oven temp > tempsoak + 3 degrees, switch off oven / else, chill
; Step 4: Check 3 - if tempreflow achieved:
	; a. Switch off SSR
	; b. switch on reflowtimer
; Step 5: 
	; Check 4.1  - if reflowtimer = timereflow, switch on oven and don't switch off
	; Check 4.2 - if oven temp < reflowtemp - 3 degrees, switch on oven / else if oven temp > reflowtemp + 3 degrees, switch off oven/ else, chill
	
	
; TEMPERATURE INPUT FROM OVEN: Result;

startoven:
	
; Step 1: Switch on SSR, switching on oven

	clr  a
	cpl SSRpin 
	
; Step 2: Check 1 - if Result == tempsoak:
	; a: Switch off SSR
	; b: Switch on soaktimer
	
;- SOAK RAMP -;

soakramploop: 
	
	mov a, Result
	cjne a, tempsoak, soakramploop
	
	cpl SSRpin ; Step 2a: switch off SSR
	clr a
	
;-SOAK MESA -;

soakmesaloop: ; 
	lcall Wait1s
	mov a, soaktimer
	add a, #0x01
	mov soaktimer, a; increments timer by one
	cjne a, timesoak, soakmesaloop1 ;  Check 2.1 - soak time
	
	ljmp theoatmeal
	
	; Check 2.2 - soak temperature +-3 (Result +-3)
	
soakmesaloop1:
	; Result > tempsoak + 3
	clr c 
	mov a, tempsoak
	add a, #0x03 ; 3 degree tolerance
	subb a, Result
	jc soakmesaloop2
	
	cpl SSRpin
	lcall soakcontrolroutine1
	
soakmesaloop2:	
	; Result < tempsoak - 3
	clr c
	mov a, Result
	add a, #0x03 ; 3 degree tolerance
	subb a, tempsoak
	jc soakmesaloop
	
	cpl SSRpin
	ljmp soakcontrolroutine2
			
sjmp soakmesaloop
	
; SOAKCONTROLROUTINE1 ;

soakcontrolroutine1: 

	lcall Wait1s
	mov a, soaktimer
	add a, #0x01
	mov soaktimer, a; increments timer by one
	cjne a, timesoak, soakcontrolroutinecheck1 ;  Check 2.1 - soak time
	
	ljmp theoatmeal

; Result > tempsoak + 2 control loop
; oven starts in off state in this loop
; while Result > tempsoak + 2: stay here
	; return 
	
soakcontrolroutinecheck1:

	clr c 
	mov a, tempsoak
	add a, #0x02 ; 2 degree tolerance
	subb a, Result
	jc soakcontrolroutine1
	
	ret ; if Result drops below tempsoak - 2, return to original loop
	
;---------------------

; SOAKCONTROLROUTINE2 ;

soakcontrolroutine2: 

	lcall Wait1s
	mov a, soaktimer
	add a, #0x01
	mov soaktimer, a; increments timer by one
	cjne a, timesoak, soakcontrolroutinecheck2 ;  Check 2.1 - soak time
	
	ljmp reflowramplooplessthan

; Result < tempsoak + 2 control loop
; oven starts in off state in this loop
; while Result > tempsoak + 2: stay here
	; return 

soakcontrolroutinecheck2:

	clr c
	mov a, Result
	add a, #0x02 ; 2 degree tolerance
	subb a, tempsoak
	jc soakcontrolroutine2
	
	ret
	
;--------;
; REFLOW ;
;--------;

;- REFLOWRAMP -;
			
reflowramplooplessthan: 
	
	mov a, Result
	cjne a, tempreflow, reflowramplooplessthan
	
	cpl SSRpin ; Step 2a: switch off SSR
	clr a
	sjmp reflowmesaloop
	
;- THEOATMEAL -;

theoatmeal:

	cpl SSRpin
	
reflowramploop: 
	
	mov a, Result
	cjne a, tempreflow, reflowramploop
	
	cpl SSRpin ; Step 2a: switch off SSR
	clr a
	
;-reflow MESA -;

reflowmesaloop: ; 
	lcall Wait1s
	mov a, reflowtimer
	add a, #0x01
	mov reflowtimer, a; increments timer by one
	cjne a, timereflow, reflowmesaloop1 ;  Check 2.1 - reflow time
	
	ljmp cool
	
	; Check 2.2 - reflow temperature +-3 (Result +-3)
	
reflowmesaloop1:
	; Result > tempreflow + 3
	clr c 
	mov a, tempreflow
	add a, #0x03 ; 3 degree tolerance
	subb a, Result
	jc reflowmesaloop2
	
	cpl SSRpin
	lcall reflowcontrolroutine1
	
reflowmesaloop2:	
	; Result < tempreflow - 3
	clr c
	mov a, Result
	add a, #0x03 ; 3 degree tolerance
	subb a, tempreflow
	jc reflowmesaloop
	
	cpl SSRpin
	ljmp reflowcontrolroutine2
			
sjmp reflowmesaloop
	
; reflowCONTROLROUTINE1 ;

reflowcontrolroutine1: 

	lcall Wait1s
	mov a, reflowtimer
	add a, #0x01
	mov reflowtimer, a; increments timer by one
	cjne a, timereflow, reflowcontrolroutinecheck1 ;  Check 2.1 - reflow time
	
	ljmp cool

; Result > tempreflow + 2 control loop
; oven starts in off state in this loop
; while Result > tempreflow + 2: stay here
	; return 
	
reflowcontrolroutinecheck1:

	clr c 
	mov a, tempreflow
	add a, #0x02 ; 2 degree tolerance
	subb a, Result
	jc reflowcontrolroutine1
	
	ret ; if Result drops below tempreflow - 2, return to original loop
	
;---------------------

; reflowCONTROLROUTINE2 ;

reflowcontrolroutine2: 

	lcall Wait1s
	mov a, reflowtimer
	add a, #0x01
	mov reflowtimer, a; increments timer by one
	cjne a, timereflow, reflowcontrolroutinecheck2 ;  Check 2.1 - reflow time
	
	cpl SSRpin ; in low case, SSRpin on, so we need to switch it off to cool down
	ljmp cool

; Result < tempreflow + 2 control loop
; oven starts in off state in this loop
; while Result > tempreflow + 2: stay here
	; return 

reflowcontrolroutinecheck2:

	clr c
	mov a, Result
	add a, #0x02 ; 2 degree tolerance
	subb a, tempreflow
	jc reflowcontrolroutine2
	
	ret

cool: sjmp cool
	
end

; if temp > 270 ;  input from the oven
;	then off ; pin that SSR is connected to 
	
