; ====================================================
; Assembly Random Number Generator
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
      call init_pins      ; Setup usart

      ; Initialise the analog to digital converter
      call init_adc       ; Call init_adc subroutine

      ; Seed numbers in random function
      call setup_rand
      
      ; Finish setup
      ret                 ; Return from subroutine

; INITIALISATION ROUTINES
; ====================================================

init_pins:
      ; Set all pins on port a to output
      ldi r18, 0xff       ; Store 1111 1111 in r18
      out DDRA, r18       ; Write value in r18 to DDRA

      ; Return
      ret                 ; Return from subroutine


init_adc:
      ; Set A0 as input (PF0)
      cbi DDRF, 0         ; Clear bit 0 of port f for input

      ; Set which Analog input to read and how to format 10-bit value
      ldi r18, 0xC0       ; Write 11000000 to r18 (2.56v, right-adjust, adc0)
      sts ADMUX, r18      ; Store r18 direct to sram ADMUX (0x7C)

      ; Enable analog input and set prescale
      ldi r18, 0x87       ; Write 10000111 to r18 (Enable, Prescale clk/128)
      sts ADCSRA, r18     ; Store r18 direct to sram ADCSRA (0x7A)

      ; Finish intialising adc
      ret                 ; Return from init adc subroutine


setup_rand:
      ; Get random seed from A0 and store in r19
      call read_adc
      
      ; Init second (fixed) seed value
      ldi r20, 0xde
      
      ret

; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:

        call gen_rand_num   ; Generate a random number

        out PORTA, r19      ; Write returned value from randomiser to PORTA

        call delay_1s       ; Wait 1 second
        
        jmp loop            ; Return from subroutine


; Analog to Digital Converter FUNCTIONS
; ====================================================

read_adc:
        lds r18, ADCSRA    ; Load ADCSRA from SRAM to r18
        ori r18, 0x40      ; Enable ADSC to start conversion
        sts ADCSRA, r18    ; Write adjusted ADCSRA back to 0x7C

wait_adc:
        lds r22, ADCSRA   ; Check interrupt flag in ADCSRA (0x7A)
        sbrs r22, 4       ; Skip next if bit 4 is set in r22
        jmp wait_adc      ; Jump back to wait_adc since not ready

reset_adc_flag:
        lds r18, ADCSRA   ; Load ADCSRA to r18
        ori r18, 0x10     ; Re-enable interrupt flag
        sts ADCSRA, r18   ; Set value

write_adc:
        lds r19, ADCL     ; Get low byte from ADCL
        lds r20, ADCH     ; Get high byte from ADCH

        ret               ; Returns from read_adc subroutine


; RANDOM NUMBER GENERATION FUNCTION
; ====================================================

gen_rand_num:
        ; Randomise using xor, swap and add
        eor r19, r20      ; XOR two values
        swap r19          ; Swap nibbles in result
        add r20, r19      ; Add new value to r20 for next loop

        ret


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
          ldi  r27,4000 >> 8    ; Load high byte of value 4010 into reg 27
          ldi  r26,4000 & 255   ; Load low byte of value 4010 into reg 26
    delay_ms:
          sbiw r26,1            ; Decrement ms count (r27:r26)
          brne delay_ms         ; loop to delay_ms while > 0
          dec  r25              ; Decrement register 25 by 1
          brne delay_1ms        ; loop for 100 us
          dec  r24              ; decrement register 24 by one
          brne delay_100ms      ; loop for 100 us
          pop  r27              ; Restore value r27 from stack
          pop  r26              ; Restore value r26 from stack
          pop  r25              ; Restore value r25 from stack
          pop  r24              ; Restore value r24 from stack
          ret                   ; return from subroutine
