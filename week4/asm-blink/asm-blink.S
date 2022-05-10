; ====================================================
; ASM-Blink
; ====================================================

; Definitions
#define __SFR_OFFSET 0

; Include libraries or other header files
#include "avr/io.h"

; Expose these global functions
.global setup ; Used in place of setup() c function
.global loop  ; Used in place of loop() c function

; SETUP
; ====================================================

; Assembly version of setup() function
setup:
          ; The next line is like "pinMode(13, OUTPUT);" in C
          sbi   DDRB,7          ; Set bit 7 in data direction port b to 1
          ret                   ; Return


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
          ; This is the same as "digitalWrite(13,HIGH)" in C
          sbi   PORTB,7         ; Set bit 7 in PORTB to 1
          
          ; This is the same as "delay(1000)" in C
          rcall delay_1s        ; Call 1 second delay
          
          ; This is the same as "digitalWrite(13,LOW)" in C
          cbi   PORTB,7         ; Clear bit 7 in PORTB to 0
          
          ; This is the same as "delay(1000)" in C
          rcall delay_1s        ; Call 1 second delay

          ; This ends the loop routine
          ret                   ; Return (to beginning of loop)


; CUSTOM DELAY
; ====================================================

; Function to delay for 1 second
delay_1s:
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
          ret                   ; Return from subroutine
