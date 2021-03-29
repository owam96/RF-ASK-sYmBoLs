;--------------------------------------------------------
;
;  Introduction:
;
;  RF ASK Module Receiver Program (with sYmBoLs)
;
;  Copyright (C) 2020 Omar Walid Mostafa
;  This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License 
;  as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
;  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
;  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
;  See the GNU General Public License for more details.
;  You should have received a copy of the GNU General Public License along with this program; 
;  if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
;
;  DEVICE: ATMega16A
;  CLOCK FREQUENCY: 8MHz
;
;  This program uses ASK (Amplitude Shift Keying) to send data
;  It is typically written for FS1000A Module (433MHz rf module)
;  It is based on RadioHead library which is a Copyright of Mike McCauley and is distributed under the GPL V2 Open Source License
;  The code is also based on information presented in ASH Transceiver Software Designer's Guide of 2002.08.07
;
;  In this program, the data is received in sYmBoLs through UART
;  The data represents the position of a joy stick, based on which an LED will be lit
;  We decode the symbols to the original data and then decide which LED should be ON
;
;  Hardware connection of receiver:
;  RX pin connects to DATA pin of receiver module
;  GND of ATmega16A connects to GND of receiver module
;  Provide VCC to receiver module (5V)
;
;  Hardware connection to LEDs:
;  Center LED <------------> PORTA2
;  Left1 LED <-------------> PORTA1
;  Left2 LED <-------------> PORTA0
;  Right1 LED <------------> PORTA5
;  Right2 LED <------------> PORTA6
;  Down1 LED <-------------> PORTA3
;  Down2 LED <-------------> PORTA4
;  Up1 LED <---------------> PORTC7
;  Up2 LED <---------------> PORTC6
;
;--------------------------------------------------------

; Definitions:

; LEDs connected on PORT A

.EQU LEFT2_LED = 0
.EQU LEFT1_LED = 1
.EQU CENTER_LED = 2
.EQU DOWN1_LED = 3
.EQU DOWN2_LED = 4
.EQU RIGHT1_LED = 5
.EQU RIGHT2_LED = 6

; LEDs connected on PORT C

.EQU UP2_LED = 6
.EQU UP1_LED = 7

.DEF GREG1 = R16 ; General Register 1
.DEF GREG2 = R17 ; General Register 2
.DEF GREG3 = R18
.DEF ADC_VALX_L = R19 ; Analog X value LOW
.DEF ADC_VALX_H = R20 ; Analog X value HIGH
.DEF ADC_VALY_L = R21 ; Analog Y value LOW
.DEF ADC_VALY_H = R22 ; Analog Y value HIGH
.DEF DREG = R23 ; DATA REGISTER
.DEF SYM_POINTER = R24

;--------------------------------------------------------

; Main Program:

.ORG 0X00

RJMP PROGRAM

.ORG 0X30

PROGRAM:

LDI GREG1, HIGH(RAMEND)
OUT SPH, GREG1
LDI GREG1, LOW(RAMEND)
OUT SPL, GREG1

; Set data direction

LDI GREG1, 0XFF
OUT DDRA, GREG1
SBI DDRC, 6
SBI DDRC, 7

; Initialize UART

LDI GREG1, 0B10000010 ; Writing to UCSRC, Asynchronus Mode, No parity, 1 stop bit, 6-bit data size
OUT UCSRC, GREG1
LDI GREG1, 249 ; UBRRL = (8,000,000/(16*2000))-1 = 249 ---> 2000BPS baud rate
OUT UBRRL, GREG1
LDI GREG1, (1<<RXEN) ; Enable Receiver and Transmitter
OUT UCSRB, GREG1

WAIT_FOR_DATA:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP WAIT_FOR_DATA
OUT UCSRA, GREG1
IN GREG1, UDR
CPI GREG1, 0X0D ; First 6 bits of the start symbol
BREQ SCND_PRT
RJMP WAIT_FOR_DATA

SCND_PRT:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP SCND_PRT
OUT UCSRA, GREG1
IN GREG1, UDR
CPI GREG1, 0X26 ; Second 6 bits of the start symbol
BREQ RCV_L_NIB_ADCX_L
RJMP WAIT_FOR_DATA

RCV_L_NIB_ADCX_L:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_L_NIB_ADCX_L
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_L

RCV_H_NIB_ADCX_L:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_H_NIB_ADCX_L
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_H

MOV ADC_VALX_L, SYM_POINTER

RCV_L_NIB_ADCX_H:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_L_NIB_ADCX_H
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_L

RCV_H_NIB_ADCX_H:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_H_NIB_ADCX_H
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_H

MOV ADC_VALX_H, SYM_POINTER

RCV_L_NIB_ADCY_L:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_L_NIB_ADCY_L
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_L

RCV_H_NIB_ADCY_L:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_H_NIB_ADCY_L
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_H

MOV ADC_VALY_L, SYM_POINTER

RCV_L_NIB_ADCY_H:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_L_NIB_ADCY_H
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_L

RCV_H_NIB_ADCY_H:
IN GREG1, UCSRA
SBRS GREG1, RXC
RJMP RCV_H_NIB_ADCY_H
OUT UCSRA, GREG1
IN DREG, UDR
RCALL SYM_TO_ORG_H

MOV ADC_VALY_H, SYM_POINTER

; Now we have a value ranging from 0~1023 in registers ADC_VALX_H:ADC_VALX_L & ADC_VALY_H:ADC_VALY_L
; We now take the decision to turn on an LED based on the range of that value:
; If X > 816 --> Up 2 LED ON
; Else if X > 612 --> Up 1 LED ON
; Else if X > 408 --> Center LED ON
; Else if X > 204 --> Down 1 LED ON
; Else --> Down 2 LED ON

CHECK_IF_Y:
LDI GREG1, LOW(612)
LDI GREG2, HIGH(612)
CP ADC_VALY_L, GREG1
CPC ADC_VALY_H, GREG2
BRSH GO_TO_Y
LDI GREG1, LOW(408)
LDI GREG2, HIGH(408)
CP ADC_VALY_L, GREG1
CPC ADC_VALY_H, GREG2
BRLO GO_TO_Y

CHECK_UP2:
LDI GREG1, LOW(816)
LDI GREG2, HIGH(816)
CP ADC_VALX_L, GREG1
CPC ADC_VALX_H, GREG2
BRLO CHECK_UP1
LDI GREG1, 0X00
OUT PORTA, GREG1
LDI GREG1, (1<<UP2_LED)
OUT PORTC, GREG1
RJMP WAIT_FOR_DATA

CHECK_UP1:
LDI GREG1, LOW(612)
LDI GREG2, HIGH(612)
CP ADC_VALX_L, GREG1
CPC ADC_VALX_H, GREG2
BRLO CHECK_CENTER
LDI GREG1, 0X00
OUT PORTA, GREG1
LDI GREG1, (1<<UP1_LED)
OUT PORTC, GREG1
RJMP WAIT_FOR_DATA

CHECK_CENTER:
LDI GREG1, LOW(408)
LDI GREG2, HIGH(408)
CP ADC_VALX_L, GREG1
CPC ADC_VALX_H, GREG2
BRLO CHECK_DOWN1
LDI GREG1, 0X00
OUT PORTC, GREG1
LDI GREG1, (1<<CENTER_LED)
OUT PORTA, GREG1
RJMP WAIT_FOR_DATA

CHECK_DOWN1:
LDI GREG1, LOW(204)
LDI GREG2, HIGH(204)
CP ADC_VALX_L, GREG1
CPC ADC_VALX_H, GREG2
BRLO CHECK_DOWN2
LDI GREG1, 0X00
OUT PORTC, GREG1
LDI GREG1, (1<<DOWN1_LED)
OUT PORTA, GREG1
RJMP WAIT_FOR_DATA

CHECK_DOWN2:
LDI GREG1, 0X00
OUT PORTC, GREG1
LDI GREG1, (1<<DOWN2_LED)
OUT PORTA, GREG1
RJMP WAIT_FOR_DATA

GO_TO_Y:

CHECK_RIGHT2:
LDI GREG1, LOW(816)
LDI GREG2, HIGH(816)
CP ADC_VALY_L, GREG1
CPC ADC_VALY_H, GREG2
BRLO CHECK_RIGHT1
LDI GREG1, 0X00
OUT PORTC, GREG1
LDI GREG1, (1<<RIGHT2_LED)
OUT PORTA, GREG1
RJMP WAIT_FOR_DATA

CHECK_RIGHT1:
LDI GREG1, LOW(612)
LDI GREG2, HIGH(612)
CP ADC_VALY_L, GREG1
CPC ADC_VALY_H, GREG2
BRLO CHECK_LEFT1
LDI GREG1, 0X00
OUT PORTC, GREG1
LDI GREG1, (1<<RIGHT1_LED)
OUT PORTA, GREG1
RJMP WAIT_FOR_DATA

CHECK_LEFT1:
LDI GREG1, LOW(204)
LDI GREG2, HIGH(204)
CP ADC_VALY_L, GREG1
CPC ADC_VALY_H, GREG2
BRLO CHECK_LEFT2
LDI GREG1, 0X00
OUT PORTC, GREG1
LDI GREG1, (1<<LEFT1_LED)
OUT PORTA, GREG1
RJMP WAIT_FOR_DATA

CHECK_LEFT2:
LDI GREG1, 0X00
OUT PORTC, GREG1
LDI GREG1, (1<<LEFT2_LED)
OUT PORTA, GREG1
RJMP WAIT_FOR_DATA

;--------------------------------------------------------

; Functions:

SYM_TO_ORG_L:
CLR SYM_POINTER
LDI ZH, HIGH(sYmBoLs<<1)
LDI ZL, LOW(sYmBoLs<<1)
SCAN1:
LPM GREG1, Z+
TST GREG1
BREQ WAIT_FOR_DATA_JMP
INC SYM_POINTER
CP DREG, GREG1
BREQ DONE1
RJMP SCAN1
DONE1:
DEC SYM_POINTER
RET

SYM_TO_ORG_H:
SWAP SYM_POINTER
LDI ZH, HIGH(sYmBoLs<<1)
LDI ZL, LOW(sYmBoLs<<1)
SCAN2:
LPM GREG1, Z+
TST GREG1
BREQ WAIT_FOR_DATA_JMP
INC SYM_POINTER
CP DREG, GREG1
BREQ DONE2
RJMP SCAN2
DONE2:
DEC SYM_POINTER
SWAP SYM_POINTER ; Return the lower and higher nibbles to their right places
RET

WAIT_FOR_DATA_JMP: 
POP GREG1
POP GREG1
RJMP WAIT_FOR_DATA

;--------------------------------------------------------

; ISRs:

;--------------------------------------------------------

; DELAYS:

;--------------------------------------------------------

; Stored data:

sYmBoLs:  .DB 0x0D,  0x0E,  0x13,  0x15,  0x16,  0x19,  0x1A,  0x1C,  0x23,  0x25,  0x26,  0x29,  0x2A,  0x2C,  0x32,  0x34, 0x00, 0x00
;            001101 001110 010011 010101 010110 011001 011010 011100 100011 100101 100110 101001 101010 101100 110010 110100

;--------------------------------------------------------