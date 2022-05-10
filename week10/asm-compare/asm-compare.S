; ====================================================
; Assembly Compare
; ====================================================

; == Definitions ==
#define __SFR_OFFSET 0

; Include libraries or other header files
#include "avr/io.h"

; Expose these global functions
.global setup            ; Used in place of setup() c function
.global loop             ; Used in place of loop() c function


; SETUP
; ====================================================

; Assembly version of setup() function
setup:
        ; Setup pins
        sbi DDRB, 7                   ; Store 1000 0000 in DDRB

        ; Store 2 values of different sizes
        ldi r18, 0x01                 ; Choose a value
        ldi r19, 0x02                 ; Choose a second value bigger or smaller than first

        ; Compare the values
        cp r18, r19                   ; Take r19 from r18 to set or clear overflow/zero

        ; Output if the first is bigger than the other
        breq values_equal             ; If zero flag set jump to values_equal label
        brcc first_bigger             ; If carry flag set jump to first_bigger
        jmp second_bigger             ; Else jump to second_bigger

first_bigger:
        ; First value is bigger than the second so set led on
        sbi PORTB, 7                  ; Write 1 to PB7
        jmp finish_setup              ; End setup
        
second_bigger:
        ; Second value is bigger than first so leave led off
        nop                           ; Do nothing
        jmp finish_setup              ; End setup
        
values_equal:
        ; Values are equal so do nothing (like not swapping in a sort)
        nop                           ; Do nothing
        
finish_setup:
        ; Finish setup
        ret                           ; Return from subroutine


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
        ; Idle loop
        nop                           ; Do nothing (Idle)
        jmp loop                      ; Return from subroutine
