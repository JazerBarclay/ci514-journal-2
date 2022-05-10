; ====================================================
; Assembly Interrupt Driven Single Traffic Lights
; ====================================================

; Definitions
#define __SFR_OFFSET 0

; Starting counter value for timer interrupt
; Calculated from (2^regSize - 1) - (Crystal / Scalar / Frequency )
; 2^16 - 1 = 65535
; 16*10^6 / 1024 / 1 = 15625
; 65535-15625 = 49910
#define timer_delay 49910

; Include input output library for I/O access
#include "avr/io.h"

; Expose these global functions for setup and loop
.global setup ; Used in place of setup() c function
.global loop  ; Used in place of loop() c function

; We must expose the interrupt vector label too
.global TIMER1_OVF_vect


; SETUP
; ====================================================

; Assembly version of setup() function
setup:
        ; Set data direction for PORTA
        ldi   r18, 0b11100000     ; Store 1110 0000 into register 18
        out   DDRA,r18            ; Set data direction of PORTA to value in r18

        ; Start traffic lights at green
        call set_green            ; Call set green subroutine
        
        ; Disable all interrupts to prevent action during setup
        cli                       ; Disable global interrupts
        
        ; Setup registers for taking interrupt on pin 2 (pedestrian button)
        call init_interrupts      ; Call init_interrupts

        ; Enable global interrupts now setup complete
        sei                       ; Enable global interrupts
        
        ; Finish setup and return
        ret                       ; Return from setup routine


; INITIALISATION ROUTINES
; ====================================================

; Initialise timer interrupt
init_interrupts:
          ; Clear timer control registers TCCR1A, TCCR1B
          ldi   r18, 0x00           ; Load 0 into reg 18
          sts   0x80,r18            ; Store 0 from reg 18 into TCCR1A (0x80)
          sts   0x81,r18            ; Store 0 from reg 18 into TCCR1B (0x81)
          
          ; Set scalar for timer (1024) in timer 1 control register B
          ldi   r18, 5              ; Load 5 (0101) into reg 18 (scalar 1024)
          sts   0x81,r18            ; Store 5 from reg 18 into TCCR1B (0x81)
          ret                       ; Return from subroutine


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
      ; Idle loop
      nop                         ; Do nothing
      jmp loop                    ; Return to start of loop


; INTERRUPT ROUTINE
; ====================================================

; External Interrupt 4 (pin 2) Overflow Interrupt Routine
TIMER1_OVF_vect:

        ; Disable interrupts while interrupt is running
        cli                       ; Disable global interrupts
        
        ; Allow delay for remaining traffic
        call delay_5s             ; Wait for 5 seconds
        
        ; Set light combination to 010 (Amber)
        call set_amber            ; Call set_amber function

        ; Delay between change
        call delay_1s             ; Wait for 1 second
        
        ; Set light combination to 100 (Red)
        call set_red              ; Call set_red function
        
        ; Long delay for letting pedestrians cross
        call delay_10s             ; Wait for 10 seconds
        
        ; Set light combination to 110 (Red Amber)
        call set_red_amber        ; Call set_red_amber function

        ; Delay between change
        call delay_1s             ; Wait for 1 second
        
        ; Set light combination to 001 (Green)
        call set_green            ; Call set_green function

        ; Set the starting timer value (offset from 65536)
        ldi   r18, timer_delay >> 8   ; Load high byte into reg 18
        sts   0x85,r18                ; Copy reg 18 value into TCNT1H (0x85)
        ldi   r18, timer_delay & 255  ; Load low byte into reg 18
        sts   0x84,r18                ; Copy reg 18 value into TCNT1L (0x84)

        ; Enable interrupts now interrupt routine complete
        sei                       ; Enable global interrupts

        ; End of interrupt
        reti                      ; Return from interrupt routine


; LED CONTROL
; ====================================================

; Set Lights to red combination (100)
set_red:
        ldi   r18,0x80        ; Load 1000 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        ret                   ; Return from subroutine

; Set Lights to red and amber combination (110)
set_red_amber:
        ldi   r18,0xC0        ; Load 1100 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        ret                   ; Return from subroutine

; Set Lights to green combination (001)
set_green:
        ldi   r18,0x20        ; Load 0010 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        ret                   ; Return from subroutine

; Set Lights to amber combination (010)
set_amber:
        ldi   r18,0x40        ; Load 0100 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        ret                   ; Return from subroutine


; CUSTOM DELAYS
; ====================================================

; Function to delay for 5 seconds by altering the 10 second delay to loop 5 times instead of 10
delay_5s:
        push r18              ; Store r18 on the stack as we will use it for this routine
        ldi r18,5             ; Store 10 into register 18
        jmp wait_10           ; Jump to wait_10 where we decrement and repeat

; Function to delay for 10 seconds using 10 1 second delays
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
