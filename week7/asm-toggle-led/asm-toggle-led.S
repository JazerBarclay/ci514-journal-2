; ====================================================
; Assembly Toggle LED
; ====================================================

; == Definitions ==
#define __SFR_OFFSET 0

; Include libraries or other header files
#include "avr/io.h"

; Expose these global functions
.global setup ; Used in place of setup() c function
.global loop  ; Used in place of loop() c function

; We must expose the interrupt vector label too
.global INT4_vect


; SETUP
; ====================================================

; Assembly version of setup() function
setup:
        ; The next line is like "pinMode(13, OUTPUT);" in C
        sbi   DDRB,7          ; Set bit 7 in data direction port b to 1
        
        ; Disable all interrupts to prevent action during setup
        cli                   ; Disable global interrupts
        
        ; Setup registers for taking interrupt on pin 2
        call init_interrupts  ; Call init_interrupts

        ; Enable global interrupts now setup complete
        sei                   ; Enable global interrupts

        ; Finish setup and return
        ret                   ; Return



; INITIALISATION ROUTINES
; ====================================================

; Initialise timer interrupt
init_interrupts:

          ; Setup external interrupt control register for rising edge trigger
          ldi   r18,0x03         ; Load 0011 into reg 18
          sts   EICRB,r18        ; Set EICRB (0x6A) to 11 from register 18

          ; Unmask bit 4 to enable interrupt in external interrupt mask register
          sbi   EIMSK,4          ; Set INT4 bit in EIMSK (0x1D) register

          ; Finish and return
          ret                    ; Return from subroutine


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
        ; Idle loop
        nop                   ; Do nothing
        jmp loop              ; Jump to beginning of loop


; INTERRUPT ROUTINE
; ====================================================

INT4_vect:

        ; Disable interrupt by clearing bit in external interrupt mask register
        cbi   EIMSK,4         ; Clear INT4 bit in EIMSK (0x1D) masking interrupt
        
        ; Toggle led on or off
        call toggle_led       ; Call toggle led subroutine

        ; Re-enable interrupt by setting bit in external interrupt mask register
        sbi   EIMSK,4         ; Set INT4 bit in EIMSK (0x1D) unmasking interrupt
        
        ; Finish and return
        reti                  ; Return from interrupt routine


; LED CONTROL
; ====================================================

; Toggle led on or off
toggle_led:
        sbis PORTB,7          ; Skips the next instruction if PB7 is 1
        jmp toggle_on         ; Toggle on (this is skipped if set to 1 already)
        jmp toggle_off        ; Toggle off
  toggle_on:                       
        sbi PORTB,7           ; Turn on on-board LED
        ret                   ; Return from subroutine
  toggle_off:                       
        cbi PORTB,7           ; Turn off on-board LED
        ret                   ; Return from subroutine
