; ====================================================
; Assembly Single Traffic Lights
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
        ; Set data direction for PORTA
        ldi   r18, 0b11100000 ; Store 1110 0000 into register 18
        out   DDRA,r18        ; Set data direction of PORTA to value in r18

        ; Finish setup and return
        ret                   ; Return from setup routine


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
        ; Set starting light combination to 100 (Red)
        ldi   r18,0x80        ; Load 1000 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA

        ; Delay between change
        call delay_5s         ; Wait for 5 seconds
        
        ; Set light combination to 110 (Red Amber)
        ldi   r18,0xC0        ; Load 1100 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA

        ; Delay between change
        call delay_1s         ; Wait for 1 second
        
        ; Set light combination to 001 (Green)
        ldi   r18,0x20        ; Load 0010 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA

        ; Delay between change
        call delay_10s         ; Wait for 10 second
        
        ; Set light combination to 010 (Amber)
        ldi   r18,0x40        ; Load 0100 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA

        ; Delay between change
        call delay_1s         ; Wait for 1 second

        ; End of main loop
        jmp loop              ; Return to start of loop



; CUSTOM DELAYS
; ====================================================

; Function to delay for 5 seconds by altering the 10 second delay to loop 5 times instead of 10
delay_5s:
        push r18              ; Store r18 on the stack as we will use it for this routine
        ldi r18,5             ; Store 10 into register 18
        jmp wait_10           ; Jump to wait_10 where we decrement and repeat


; Function to delay for 5 seconds using 10 1 second delays
delay_10s:
        push r18              ; Store r18 on the stack as we will use it for this routine
        ldi r18,10            ; Store 10 into register 18
  wait_10: 
        call delay_1s         ; Delay 1 second
        dec r18               ; Reduce r18 value by 1
        brne wait_10          ; Return to 10s_wait label if r18 > 0
        pop r18               ; Restore r18 value from stack now we are finished
        ret                   ; Return from subroutine


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
