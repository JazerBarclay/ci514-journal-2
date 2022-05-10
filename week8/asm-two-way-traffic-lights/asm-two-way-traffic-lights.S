; ====================================================
; Assembly Two Way Traffic Lights
; ====================================================

; Definitions
#define __SFR_OFFSET 0

; Starting counter value for timer interrupt
; Calculated from (2^regSize - 1) - (Crystal / (Scalar * Frequency) )
; 2^16 - 1 = 65535
; (16*10^6 / 1024) * 1 = 15625
; 65535-15625 = 49910
#define timer_delay 49910

; Include input output library for I/O access
#include "avr/io.h"

; Expose these global functions for setup and loop
.global setup ; Used in place of setup() c function
.global loop  ; Used in place of loop() c function

; We must expose the timer overflow labels too
.global TIMER1_OVF_vect
.global TIMER3_OVF_vect

; WORKING REIGSTER USAGE
; ====================================================
; r17  ----> character to transmit via usart
; r18  ----> temporary single use values
; r20  ----> interrupt repeat counter
; r24-r27 -> custom delay


; SETUP
; ====================================================

; Assembly version of setup() function
setup:
          ; Run setup routines for pins and interrupts
          call init_pins            ; Run pin and port initialisation
          
          ; Run setup for USART communication
          call init_usart           ; Run USART initialisation

          ; Setup r20 as interrupt counter so every 10 interrupts, it will run
          ldi  r20, 10              ; Store 10 in r20
          
          ; Disable all interrupts to prevent action during setup
          cli                       ; Disable global interrupts

          ; Intialise the two timer interrupts
          call init_interrupts      ; Run interrupt initialisation

          ; Set the first timer value to start
          call reset_timer1_clock   ; Call reset_timer1_clock routine

          ; Enable mask of timer 1
          call enable_timer1        ; Call enable_timer1 routine

          ; Disable mask of timer 3
          call disable_timer3       ; Call disable_timer3 routine
          
          ; Re-enable interrupts and return from subroutine
          sei                       ; Enable global interrupts
          
          ; Finish setup and return
          ret                       ; Return from setup routine


; INITIALISATION ROUTINES
; ====================================================

init_pins:
          ; Set data direction for PORTA (All outputs)
          ldi   r18, 0xff           ; Store 1110 0000 into register 18
          out   DDRA,r18            ; Set data direction of PORTA to value in r18
          
          ; Start at red
          call set1_red             ; Set traffic lights 1 to red
          call set2_green           ; Set traffic lights 2 to green
          
          ret                       ; Return from subroutine

init_interrupts:
          ; Clear timer control registers TCCR1A, TCCR1B, TCCR3A and TCCR3B
          ldi   r18, 0x00           ; Load 0 into reg 18
          sts   0x80,r18            ; Store 0 from reg 18 into TCCR1A (0x80)
          sts   0x81,r18            ; Store 0 from reg 18 into TCCR1B (0x81)
          sts   0x90,r18            ; Store 0 from reg 18 into TCCR3A (0x90)
          sts   0x91,r18            ; Store 0 from reg 18 into TCCR3B (0x91)

          ; Set scalar for both timer control registers to 1024
          ldi   r18, 5              ; Load 5 (0101) into reg 18 (scalar 1024)
          sts   0x81,r18            ; Store 5 from reg 18 into TCCR1B (0x81)
          sts   0x91,r18            ; Store 5 from reg 18 into TCCR3B (0x91)
          ret                       ; Return from subroutine

init_usart:
          ; Clear usart control status register and baud rate high register
          clr   r18                 ; Clear register 18
          sts   UCSR0A, r18         ; Set UCSR0A to value in r18 (0000 0000)
          sts   UBRR0H, r18         ; Set UBRR0H to value in r18 (0000 0000)

          ; Set baud rate to 9600 calculated from clock_freq / 16 * rate + 1 = 103
          ldi   r18, 103            ; Store baud rate value in r18
          sts   UBRR0L, r18         ; Write baud rate into low byte of UBRR0
          
          ; Set mask to allow tx and rx
          ldi   r18, 1 << RXEN0 | 1 << TXEN0    ; Store transmit and receive bits into r18
          sts   UCSR0B, r18                     ; Write transmit and receive bits into UCSR0B

          ; Set character frame size to 8 bits (1 byte)
          ldi   r18, 1 << UCSZ00 | 1 << UCSZ01    ; Set transmit character frame size to 8 bits
          sts   UCSR0C, r18                       ; Write character 

          ret                       ; Return from subroutine


; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:    
          ; Idle Loop
          nop                       ; Do nothing
          jmp loop                  ; Return to beginning of loop


; INTERRUPT ROUTINES
; ====================================================

; Timer 1 Overflow Interrupt Routine (from t1 red and t2 green to t1 green and t2 red)
TIMER1_OVF_vect:

          ; Reset this timer
          call reset_timer1_clock   ; Reset timer 1 counter

          ; Check if on 10th iteration and skip if not
          dec  r20                  ; Decrement value in r20 by 1
          brne end_timer_1          ; Go to end_timer_1 if zero flag not set
          ldi  r20, 10              ; If is set then reset r20 to 10
          
          ; Set light 2 combination to 010 (Amber)
          call set2_amber           ; Call set_amber function

          ; Delay between change
          call delay_1s             ; Wait for 1 second
          
          ; Set light 2 combination to 100 (Red)
          call set2_red             ; Call set_red function

          ; Delay between change
          call delay_1s             ; Wait for 1 second
          
          ; Set light 1 combination to 110 (Red Amber)
          call set1_red_amber       ; Call set_red_amber function

          ; Delay between change
          call delay_1s             ; Wait for 1 second
          
          ; Set light 1 combination to 001 (Green)
          call set1_green           ; Call set_green function

          ; Disable timer 1 interrupt
          call disable_timer1       ; Disable this timer

          ; Set the timer clock for timer 3
          call reset_timer3_clock   ; Reset timer 3 counter
          
          ; Enable timer 3 interupt
          call enable_timer3        ; Enable the next timer (timer 3)

  end_timer_1:
          reti                      ; Return from interrupt

          
; Timer 3 Overflow Interrupt Routine (from t1 green and t2 red to t1 red and t2 green)
TIMER3_OVF_vect:

          ; Reset this timer
          call reset_timer3_clock   ; Reset timer 3 counter

          ; Check if on 10th iteration and skip if not
          dec  r20                  ; Decrement r20
          brne end_timer_3          ; If zero flag not set, jump to end of timer
          ldi  r20, 10              ; Reset r20 to 10

          ; Set light 1 combination to 010 (Amber)
          call set1_amber           ; Call set_amber function

          ; Delay between change
          call delay_1s             ; Wait for 1 second
          
          ; Set light 1 combination to 100 (Red)
          call set1_red             ; Call set_red function

          ; Delay between change
          call delay_1s             ; Wait for 1 second
          
          ; Set light 2 combination to 110 (Red Amber)
          call set2_red_amber       ; Call set_red_amber function

          ; Delay between change
          call delay_1s             ; Wait for 1 second
          
          ; Set light 2 combination to 001 (Green)
          call set2_green           ; Call set_green function
      
          ; Disable timer 3 interrupt
          call disable_timer3       ; Disable this timer

          ; Set the timer clock for timer 1
          call reset_timer1_clock   ; Reset timer 1 counter
          
          ; Enable timer 1 to run
          call enable_timer1        ; Enable the next timer (timer 1)

  end_timer_3:
          reti                  ; Return from interrupt


; INTERRUPT FUNCTIONS
; ====================================================

; Reset timer 1 clock to offset from 65536
reset_timer1_clock:
          ; Set the starting timer value (offset from 65536)
          ldi   r18, timer_delay >> 8   ; Load high byte into reg 18
          sts   0x85,r18                ; Copy reg 18 value into TCNT1H (0x85)
          ldi   r18, timer_delay & 255  ; Load low byte into reg 18
          sts   0x84,r18                ; Copy reg 18 value into TCNT1L (0x84)
          ret                           ; Return from subroutine
          
; Reset timer 3 clock to offset from 65536
reset_timer3_clock:
          ; Set the starting timer value (offset from 65536)
          ldi   r18, timer_delay >> 8   ; Load high byte into reg 18
          sts   0x95,r18                ; Copy reg 18 value into TCNT3H (0x95)
          ldi   r18, timer_delay & 255  ; Load low byte into reg 18
          sts   0x94,r18                ; Copy reg 18 value into TCNT3L (0x94)
          ret                           ; Return from subroutine

; Enable timer 1 interrupt
enable_timer1:
          ; Unmask timer 1 enabling it
          lds   r18, 0x6f           ; Load value in TIMSK1 (0x6f) into reg 18
          ori   r18, 0x01           ; Set first bit to 1
          sts   0x6f,r18            ; Store new value in reg 18 into TIMSK1 (0x6f)
          ret                       ; Return from subroutine
          
; Disable timer 1 interrupt
disable_timer1:
          ; Mask timer 1 disabling it
          lds   r18, 0x6f           ; Load value in TIMSK1 (0x6f) into reg 18
          andi  r18, 0xfe           ; Clear first bit by 'and'ing with 11111110
          sts   0x6f,r18            ; Store new value in reg 18 into TIMSK1 (0x6f)
          ret                       ; Return from subroutine

; Enable timer 3 interrupt
enable_timer3:
          ; Unmask timer 1 enabling it
          lds   r18, 0x71           ; Load value in TIMSK3 (0x71) into reg 18
          ori   r18, 0x01           ; Set first bit to 1
          sts   0x71,r18            ; Store new value in reg 18 into TIMSK3 (0x71)
          ret                       ; Return from subroutine
       
; Disable timer 3 interrupt   
disable_timer3:
          ; Mask timer 1 disabling it
          lds   r18, 0x71           ; Load value in TIMSK3 (0x71) into reg 18
          andi  r18, 0xfe           ; Clear first bit by 'and'ing with 11111110
          sts   0x71,r18            ; Store new value in reg 18 into TIMSK3 (0x71)
          ret                       ; Return from subroutine


; USART ROUTINES
; ====================================================

; Transmits the value stored at register 17 to the serial port
transmit:
          ; Check if ready to transmit
          lds   r18, UCSR0A         ; Store value at UCSR0A into r18
          sbrs  r18, UDRE0          ; Skip if bit in register is set
          rjmp  transmit            ; Return to transmit beginning
          
          ; write the value stored in r17
          sts   UDR0, r17           ; Write value in r18 to serial port

          ret                       ; Return from subroutine


; LED CONTROL
; ====================================================

; Reset traffic lights 1 to 000 while maintaining the other set
mask_set1:
          in    r18, PORTA      ; Read in PORTA value
          andi  r18, 0b00011111 ; Mask out last 3 bits
          ret                   ; Return from subroutine

; Sets traffic lights 1 to red while maintaining the other set
set1_red:
          call  mask_set1       ; Mask out 3 bits for lights 1
          ori   r18, 0b10000000 ; Load 1000 0000 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;

; Sets traffic lights 1 to red/amber while maintaining the other set
set1_red_amber:
          call  mask_set1       ; Mask out 3 bits for lights 1
          ori   r18, 0b11000000 ; Load 1000 0000 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;

; Sets traffic lights 1 to green while maintaining the other set
set1_green:
          call  mask_set1       ; Mask out 3 bits for lights 1
          ori   r18, 0b00100000 ; Load 1000 0000 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;

; Sets traffic lights 1 to amber while maintaining the other set
set1_amber:
          call  mask_set1       ; Mask out 3 bits for lights 1
          ori   r18, 0b01000000 ; Load 1000 0000 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;

; Reset traffic lights 2 to 000 while maintaining the other set
mask_set2:
          in    r18, PORTA      ; Read in PORTA value
          andi  r18, 0b11100011 ; Mask out middle 3 bits
          ret                   ; Return from subroutine
          
; Sets traffic lights 2 to red while maintaining the other set
set2_red:
          call  mask_set2       ; Mask out 3 bits for lights 2
          ori   r18, 0b00010000 ; Load 0001 0000 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;

; Sets traffic lights 2 to red/amber while maintaining the other set
set2_red_amber:
          call  mask_set2       ; Mask out 3 bits for lights 2
          ori   r18, 0b00011000 ; Load 0001 1000 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;

; Sets traffic lights 2 to green while maintaining the other set
set2_green:
          call  mask_set2       ; Mask out 3 bits for lights 2
          ori   r18, 0b00000100 ; Load 0000 0100 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;

; Sets traffic lights 2 to amber while maintaining the other set
set2_amber:
          call  mask_set2       ; Mask out 3 bits for lights 2
          ori   r18, 0b00001000 ; Load 0000 1000 into register 18
          out   PORTA,r18       ; Write value in register 18 to PORTA
          ret                   ;


; CUSTOM DELAYS
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
