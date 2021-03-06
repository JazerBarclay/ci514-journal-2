; ====================================================
; Assembly Strobe
; ====================================================

; Definitions
#define __SFR_OFFSET 0

; Include input output library for I/O access
#include "avr/io.h"

; Expose these global functions for setup and loop
.global setup ; Used in place of setup() c function
.global loop  ; Used in place of loop() c function


; SETUP
; ====================================================

; Assembly version of setup() function
setup:
          ldi   r18, 0xFF       ; Store 1111 1111 into register 18
          out   DDRA,r18        ; Set data direction of PORTA to all output
          ret                   ; Return from setup routine


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
          ldi   r23,0x01         ; Load 0000 0001 into register 23
          ldi   r22,0x08         ; Load 8 into register 22
  next:     
          out   0x02,r23         ; Write contents of r23 to PORTA
          call  delay_1s         ; Delay for 1 second
          lsl   r23              ; Shift value of r23 left 1 bit
          dec   r22              ; Reduce value in register 22 by 1
          brne  next             ; Go to 'next' while zero flag not set
          ret                    ; Return (to beginning of loop)


; CUSTOM DELAY
; ====================================================

; Function to delay for 1 second
delay_1s:
          push r24              ; Store register 24 value on stack
          push r25              ; Store register 25 value on stack
          push r26              ; Store register 26 value on stack
          push r27              ; Store register 27 value on stack
          ldi  r24,10           ; Load 10 into register 24
  delay_100ms:
          ldi  r25,100          ; Load 100 into register 25
  delay_1ms:
          ldi  r27,4000 >> 8    ; Load high byte of value 4000 into reg 27
          ldi  r26,4000 & 255   ; Load low byte of value 4000 into reg 26
  delay_ms:
          sbiw r26,1            ; Decrement ms count (X-register r27:r26)
          brne delay_ms         ; Loop to delay_ms while r26 > 0
          dec  r25              ; Decrement register 25 by 1
          brne delay_1ms        ; Loop to delay_1ms while r25 > 0
          dec  r24              ; Decrement register 24 by one
          brne delay_100ms      ; Loop to delay_100ms while r24 > 0
          pop  r27              ; Restore value r27 from stack
          pop  r26              ; Restore value r26 from stack
          pop  r25              ; Restore value r25 from stack
          pop  r24              ; Restore value r24 from stack
          ret                   ; Return from subroutine
