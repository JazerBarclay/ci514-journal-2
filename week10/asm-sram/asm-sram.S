; ====================================================
; Assembly SRAM
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
        ldi r18, 0xff                 ; Store 1111 1111 in r18
        out DDRA, r18                 ; Write value in r18 to DDRA

        ; Store value which we want to send to sram
        ldi r18, 0b10101010           ; Store 1010 1010 in r18

        ; Load sram memory location into z-reg
        ldi ZL, 0x00   ; Load ZL with lower byte of the address
        ldi ZH, 0x03   ; Load ZH with higher byte of the address

        ; Store value in z-reg location in memory
        st Z, r18     ; Store the content of R20 into location
        
        ; Finish setup
        ret                           ; Return from subroutine


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
        ; Read value in sram at z-reg location
        ld r18, Z
        out PORTA, r18
        jmp loop                     ; Return from subroutine
