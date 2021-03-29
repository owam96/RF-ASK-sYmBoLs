;--------------------------------------------------------
;
;  Introduction:
;
;  RF ASK Moudle Transmitter Program (with sYmBoLs)
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
;  In this program, the data to be sent is the analog value read on ADC Channels 0 & 1, after being encoded to sYmBoLs
;  I use a joystick module connectd to pin A0 and pin A1
;
;  Hardware connection of transmitter:
;  TX pin connects to DATA pin of transmitter module
;  GND of ATmega16A connects to GND of transmitter module
;  Provide VCC to transmitter module (5V)
;
;  Hardware connection of joystick module:
;  VRX connects to pin A0
;  VRY connects to pin A1
;  GND of ATmega16A connects to GND of joystick module
;  Provide VCC to joystick module (5V)
;
;--------------------------------------------------------

; Definitions:

.DEF GREG1 = R16 ; General Register 1
.DEF GREG2 = R17 ; General Register 2
.DEF ADC_VALX_L = R18 ; Analog X value LOW
.DEF ADC_VALX_H = R19 ; Analog X value HIGH
.DEF ADC_VALY_L = R20 ; Analog Y value LOW
.DEF ADC_VALY_H = R21 ; Analog Y value HIGH
.DEF ADC_X0_Y1 = R22 ; Flag
.DEF DREG = R23 ; DATA REGISTER
.DEF SYM_L = R24
.DEF SYM_H = R25

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

; Initialize ADC

LDI GREG1, 0B01000000 ; Reference = AVCC, Result right-adjusted, ADC channel = 0
OUT ADMUX, GREG1
LDI GREG1, 0B10000111 ; Enable ADC, /128 prescaler
OUT ADCSRA, GREG1

; Initialize USART

LDI GREG1, (1<<TXEN) ; Enable Transmitter
OUT UCSRB, GREG1
LDI GREG1, 0B10000010 ; Writing to UCSRC, Asynchronus Mode, No parity, 1 stop bit, 6-bit data size
OUT UCSRC, GREG1
LDI GREG1, 249 ; UBRRL = (8,000,000/(16*2000))-1 = 249 ---> 2000BPS baud rate
OUT UBRRL, GREG1

START_PREAMBLE:
LDI ZH, HIGH(PREAMBLE<<1)
LDI ZL, LOW(PREAMBLE<<1)

TRNSMT_PREAMBLE:
LPM GREG1, Z+
CPI GREG1, 0
BREQ END_OF_PREAMBLE
CHECK0: IN GREG2, UCSRA ; Always check for busy *****
SBRS GREG2, UDRE        ;
RJMP CHECK0             ;
OUT UDR, GREG1
CHECK1: IN GREG1, UCSRA
SBRS GREG1, TXC
RJMP CHECK1
OUT UCSRA, GREG1
RJMP TRNSMT_PREAMBLE

END_OF_PREAMBLE:

; After sending the preamble we get the X value and the Y value using ADC

LDI GREG1, 0B01000000 ; Reference = AVCC, Result right-adjusted, ADC channel = 0
OUT ADMUX, GREG1
SBI ADCSRA, ADSC ; Start conversion
CONV_X:
SBIC ADCSRA, ADSC ; ADSC Flag is cleared automatically when conversion is complete, no need to manually clear it *****
RJMP CONV_X
IN ADC_VALX_L, ADCL
IN ADC_VALX_H, ADCH

LDI GREG1, 0B01000001 ; Reference = AVCC, Result right-adjusted, ADC channel = 1
OUT ADMUX, GREG1
SBI ADCSRA, ADSC ; Start conversion
CONV_Y:
SBIC ADCSRA, ADSC ; ADSC Flag is cleared automatically when conversion is complete, no need to manually clear it *****
RJMP CONV_Y
IN ADC_VALY_L, ADCL
IN ADC_VALY_H, ADCH

; We then convert the X and Y values to sYmBoLs and send them

MOV DREG, ADC_VALX_L
RCALL CNVRT_TO_SYM
RCALL SEND_SYM
MOV DREG, ADC_VALX_H
RCALL CNVRT_TO_SYM
RCALL SEND_SYM
MOV DREG, ADC_VALY_L
RCALL CNVRT_TO_SYM
RCALL SEND_SYM
MOV DREG, ADC_VALY_H
RCALL CNVRT_TO_SYM
RCALL SEND_SYM
RJMP START_PREAMBLE

;--------------------------------------------------------

; Functions:

CNVRT_TO_SYM:
LDI ZH, HIGH(sYmBoLs<<1)
LDI ZL, LOW(sYmBoLs<<1)
MOV GREG1, DREG
ANDI GREG1, 0X0F
ADD ZL, GREG1
BRCC NO_CARRY1
INC ZH
NO_CARRY1:
LPM SYM_L, Z
LDI ZH, HIGH(sYmBoLs<<1)
LDI ZL, LOW(sYmBoLs<<1)
MOV GREG1, DREG
SWAP GREG1
ANDI GREG1, 0X0F
ADD ZL, GREG1
BRCC NO_CARRY2
INC ZH
NO_CARRY2:
LPM SYM_H, Z
RET

SEND_SYM:
OUT UDR, SYM_L
CHECK2: IN GREG1, UCSRA
SBRS GREG1, TXC
RJMP CHECK2
OUT UCSRA, GREG1
OUT UDR, SYM_H
CHECK3: IN GREG1, UCSRA
SBRS GREG1, TXC
RJMP CHECK3
OUT UCSRA, GREG1
RET

;--------------------------------------------------------

; ISRs:

;--------------------------------------------------------

; DELAYS:

;--------------------------------------------------------

; Stored data:

; The preamble is a stream of 0s and 1s in the form: 10101010..., encoded as 6-bit chuncks.
; It is sent before every 16-bit message to "train" the receiver and help it recognize the ones and zeros in the message.
; The preamble's length is 36 bits, followed by a start symbol that is 12-bits long and which also maintains
; the receiver's slicing symmetry.

PREAMBLE: .DB 0x2A, 0X2A, 0X2A, 0X2A, 0X2A, 0X2A, 0X0D, 0X26, 0X00, 0X00 ; Start symbol = 0B110100100110 = 0XD26

sYmBoLs:  .DB 0x0D,  0x0E,  0x13,  0x15,  0x16,  0x19,  0x1A,  0x1C,  0x23,  0x25,  0x26,  0x29,  0x2A,  0x2C,  0x32,  0x34
;            001101 001110 010011 010101 010110 011001 011010 011100 100011 100101 100110 101001 101010 101100 110010 110100

;--------------------------------------------------------