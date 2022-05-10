; ====================================================
; Assembly Two Way Traffic Lights With Pedestrian Crossing
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

; We must expose the timer overflow and external interrupt labels
.global INT4_vect
.global TIMER1_OVF_vect
.global TIMER3_OVF_vect

; WORKING REIGSTER USAGE
; ====================================================
; r17  ----> usart transmit value ascii
; r18  ----> temporary single use values
; r19  ----> ped interrupt triggered flag & green flash loop counter
; r20  ----> interrupt repeat counter
; r24-r27 -> custom delay


; SETUP
; ====================================================

; Assembly version of setup() function
setup:
        ; Run setup routines for pins and interrupts
        call init_pins            ; Run pin and port initialisation

        ; Setup r20 as interrupt counter so every 10 interrupts, it will run
        ldi    r20, 1             ; Store 10 in r20

        ; Initialise serial interface
        call init_usart           ; Call init_usart subroutine
        
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

        call print_status         ; Print starting status of LEDs
        
        ; Finish setup and return
        ret                       ; Return from setup routine


; INITIALISATION ROUTINES
; ====================================================

init_pins:
        ; Set data direction for PORTA (All outputs)
        ldi   r18, 0xFF           ; Store 1111 1111 into register 18
        out   DDRA,r18            ; Set data direction of PORTA to value in r18
        
        ; Start lights 1 at red
        call set1_red             ; Set lights 1 to red
        
        ; Start lights 2 at red
        call set2_green           ; Set lights 2 to green
        
        ; Start pedestrian lights at red
        call ped_red              ; Set ped lights red
        
        ret                       ; Return from subroutine

init_interrupts:
        ; Setup interrupt 4 to be rising edge triggered
        ldi   r18,0x03            ; Load 0011 into reg 18 (for rising edge)
        sts   EICRB,r18           ; Set EICRB (0x6A) to 11 from register 18
        
        ; Enable interrupt 4 by unmasking external interrupt mask register
        sbi   EIMSK,4             ; Set INT4 bit in EIMSK (0x1D) register
        
        ; Clear Timer Control Registers TCCR1A, TCCR1B, TCCR3A and TCCR3B
        ldi   r18, 0x00           ; Load 0 into reg 18
        sts   0x80,r18            ; Store 0 from reg 18 into TCCR1A (0x80)
        sts   0x81,r18            ; Store 0 from reg 18 into TCCR1B (0x81)
        sts   0x90,r18            ; Store 0 from reg 18 into TCCR3A (0x90)
        sts   0x91,r18            ; Store 0 from reg 18 into TCCR3B (0x91)

          ; Set scalar for timer (1024) in timer 1 and 3 control registers B
        ldi   r18, 5              ; Load 5 (0101) into reg 18 (scalar 1024)
        sts   0x81,r18            ; Store 5 from reg 18 into TCCR1B (0x81)
        sts   0x91,r18            ; Store 5 from reg 18 into TCCR3B (0x91)
        ret                       ; Return from subroutine


; Setup USART for sending data to serial port
init_usart:
        ; Clear usart control status register and baud rate high register
        clr   r18                   ; Clear register 24
        sts   UCSR0A, r18           ; Set UCSR0A to value in r24 (0000 0000)
        sts   UBRR0H, r18           ; Set UBRR0H to value in r24 (0000 0000)

        ; Set baud rate to 9600 calculated from clock_freq / 16 * rate + 1 = 103
        ldi   r18, 103              ; Store baud rate in r24
        sts   UBRR0L, r18           ; Write baud rate into low byte of UBRR0
        
        ; Set mask to allow tx and rx
        ldi   r18,  1 << TXEN0      ; Store transmit and receive bits into r24
        sts   UCSR0B, r18           ; Write transmit and receive bits into UCSR0B

        ; Set character frame size to 8 bits (1 byte)
        ldi   r18, 1 << UCSZ00 | 1 << UCSZ01    ; Set transmit character frame size to 8 bits
        sts   UCSR0C, r18                       ; Write character frame size

        ; Return from usart setup
        ret                         ; Return from subroutine

; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:    
        ; Idle Loop
        nop                       ; Do nothing
        jmp loop                  ; Return to beginning of loop


; INTERRUPT ROUTINES
; ====================================================

INT4_vect:
          ; Disable this interrupt once run
          cbi   EIMSK,4          ; Clear INT4 bit in EIMSK (0x1D) masking interrupt

          ; Set custom flag for pedestrian crossing
          ldi   r19, 0x01        ; Load 1 into register 19
          
          reti                   ; Return from interrupt

; Timer 1 Overflow Interrupt Routine
TIMER1_OVF_vect:

        ; Reset this timer
        call reset_timer1_clock   ; Reset timer 1 counter

        ; Check if on 10th iteration
        dec  r20                  ; Decrement value in r20 by 1
        brne end_timer_1          ; Go to end_timer_1 if zero flag not set
        ldi  r20, 10              ; If is set then reset r20 to 10

  start_1:
        ; Set light 2 combination to 010 (Amber)
        call set2_amber           ; Call set_amber function

        ; Delay between change
        call delay_1s             ; Wait for 1 second
        
        ; Set light 2 combination to 100 (Red)
        call set2_red             ; Call set_red function

        ; Delay between change
        call delay_2s             ; Wait for 2 seconds

        ; Check if interrupt set for ped lights
        ldi  r18, 0x01            ; Load 1 into register 18
        eor  r18, r19             ; XOR r18 with r19

        ; If zero set then trigger ped crossing, else jump to resume_1
        brne resume_1             ; Branch if zero flag set
        call ped_crossing         ; Run pedestrian crossing routine
        clr  r19                  ; Clear r19 to be 0 ready for next interrupt
        sbi  EIFR,4               ; Clear flag if set in between crossing
        sbi  EIMSK,4              ; Set INT4 bit in EIMSK (0x1D) unmasking interrupt
        
  resume_1:
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
        call enable_timer3        ; Enable the next timer

  end_timer_1:
        reti                      ; Return from interrupt

        
; Timer 3 Overflow Interrupt Routine
TIMER3_OVF_vect:

        ; Reset this timer
        call reset_timer3_clock   ; Reset timer 3 counter

        ; Check if on 10th iteration
        dec  r20                  ; Decrement r20
        brne end_timer_3          ; If zero flag not set, jump to end of timer
        ldi  r20, 10              ; Reset r20 to 10

  start_3:
        ; Set light 1 combination to 010 (Amber)
        call set1_amber           ; Call set_amber function

        ; Delay between change
        call delay_1s             ; Wait for 1 second
        
        ; Set light 1 combination to 100 (Red)
        call set1_red             ; Call set_red function

        ; Delay between change
        call delay_2s             ; Wait for 2 seconds

        ; Check if interrupt set for ped lights
        ldi  r18, 0x01            ; Load 1 into register 18
        eor  r18, r19             ; XOR r18 with r19

        ; If zero set then trigger ped crossing, else jump to resume_3
        brne resume_3             ; Branch if zero flag set
        call ped_crossing         ; Run pedestrian crossing routine
        clr  r19                  ; Clear r19 to be 0 ready for next interrupt
        sbi  EIFR,4               ; Clear flag if set in between crossing
        sbi  EIMSK,4              ; Set INT4 bit in EIMSK (0x1D) unmasking interrupt

  resume_3:
        ; Set light 2 combination to 110 (Red Amber)
        call set2_red_amber       ; Call set_red_amber function

        ; Delay between change
        call delay_1s             ; Wait for 1 second
        
        ; Set light 2 combination to 001 (Green)
        call set2_green           ; Call set_green function
    
        ; Disable this interrupt
        call disable_timer3       ; Disable this timer

        ; Set the timer clock for timer 1
        call reset_timer1_clock   ; Reset timer 1 counter
        
        ; Enable timer 1 interupt
        call enable_timer1        ; Enable the next timer

  end_timer_3:
        reti                  ; Return from interrupt
        


; INTERRUPT FUNCTIONS
; ====================================================

; Resets the clock value stored in TCNT1
reset_timer1_clock:
        ; Set the starting timer value (offset from 65536)
        ldi   r18, timer_delay >> 8   ; Load high byte into reg 18
        sts   0x85,r18                ; Copy reg 18 value into TCNT1H (0x85)
        ldi   r18, timer_delay & 255  ; Load low byte into reg 18
        sts   0x84,r18                ; Copy reg 18 value into TCNT1L (0x84)
        ret                           ; Return from subroutine

; Resets the clock value stored in TCNT3  
reset_timer3_clock:
        ; Set the starting timer value (offset from 65536)
        ldi   r18, timer_delay >> 8   ; Load high byte into reg 18
        sts   0x95,r18                ; Copy reg 18 value into TCNT3H (0x95)
        ldi   r18, timer_delay & 255  ; Load low byte into reg 18
        sts   0x94,r18                ; Copy reg 18 value into TCNT3L (0x94)
        ret                           ; Return from subroutine

; Unmasks timer 1 interrupt flag
enable_timer1:
        ; Unmask timer 1 enabling it
        lds   r18, 0x6f           ; Load value in TIMSK1 (0x6f) into reg 18
        ori   r18, 0x01           ; Set first bit to 1
        sts   0x6f,r18            ; Store new value in reg 18 into TIMSK1 (0x6f)
        ret                       ; Return from subroutine
     
; Masks timer 1 interrupt flag   
disable_timer1:
        ; Mask timer 1 disabling it
        lds   r18, 0x6f           ; Load value in TIMSK1 (0x6f) into reg 18
        andi  r18, 0xfe           ; Clear first bit by 'and'ing with 11111110
        sts   0x6f,r18            ; Store new value in reg 18 into TIMSK1 (0x6f)
        ret                       ; Return from subroutine

; Unmasks timer 3 interrupt flag
enable_timer3:
        ; Unmask timer 1 enabling it
        lds   r18, 0x71           ; Load value in TIMSK3 (0x71) into reg 18
        ori   r18, 0x01           ; Set first bit to 1
        sts   0x71,r18            ; Store new value in reg 18 into TIMSK3 (0x71)
        ret                       ; Return from subroutine
        
; Masks timer 3 interrupt flag
disable_timer3:
        ; Mask timer 1 disabling it
        lds   r18, 0x71           ; Load value in TIMSK3 (0x71) into reg 18
        andi  r18, 0xfe           ; Clear first bit by 'and'ing with 11111110
        sts   0x71,r18            ; Store new value in reg 18 into TIMSK3 (0x71)
        ret                       ; Return from subroutine


; USART ROUTINES
; ====================================================

; Writes the value stored at r17 to the serial port
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


; Reset traffic lights 1 to 000 while maintaining the other sets
mask_set1:
        in    r18, PORTA      ; Read in PORTA value
        andi  r18, 0b00011111 ; Mask out last 3 bits
        ret                   ; Return from subroutine

; Sets traffic lights 1 to red while maintaining the other sets
set1_red:
        call  mask_set1       ; Mask out 3 bits for lights 1
        ori   r18, 0b10000000 ; Load 1000 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine

; Sets traffic lights 1 to red/amber while maintaining the other sets
set1_red_amber:
        call  mask_set1       ; Mask out 3 bits for lights 1
        ori   r18, 0b11000000 ; Load 1000 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine

; Sets traffic lights 1 to green while maintaining the other sets
set1_green:
        call  mask_set1       ; Mask out 3 bits for lights 1
        ori   r18, 0b00100000 ; Load 1000 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine

; Sets traffic lights 1 to amber while maintaining the other sets
set1_amber:
        call  mask_set1       ; Mask out 3 bits for lights 1
        ori   r18, 0b01000000 ; Load 1000 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine

; Reset traffic lights 2 to 000 while maintaining the other sets
mask_set2:
        in    r18, PORTA      ; Read in PORTA value
        andi  r18, 0b11100011 ; Mask out middle 3 bits
        ret                   ; Return from subroutine
        
; Sets traffic lights 2 to red while maintaining the other sets
set2_red:
        call  mask_set2       ; Mask out 3 bits for lights 2
        ori   r18, 0b00010000 ; Load 0001 0000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine

; Sets traffic lights 2 to red/amber while maintaining the other sets
set2_red_amber:
        call  mask_set2       ; Mask out 3 bits for lights 2
        ori   r18, 0b00011000 ; Load 0001 1000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine

; Sets traffic lights 2 to green while maintaining the other sets
set2_green:
        call  mask_set2       ; Mask out 3 bits for lights 2
        ori   r18, 0b00000100 ; Load 0000 0100 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine

; Sets traffic lights 2 to amber while maintaining the other sets
set2_amber:
        call  mask_set2       ; Mask out 3 bits for lights 2
        ori   r18, 0b00001000 ; Load 0000 1000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine


; Runs the pedestrian crossing routine
ped_crossing:
        ; Set ped crossing to green
        call ped_green

        ; Wait 5 seconds for crossing
        call delay_5s

        ; Store number of green flashes (+1 since it skips on 0)
        ldi r19, 4

  flash_ped:
        ; Flash ped crossing on and off with a delay of 1 second
        call ped_green        ; Set ped crossing green (flash 1)
        call delay_1s         ; Wait 1 second
        call mask_ped         ; Mask ped crossing
        out PORTA, r18        ; Write mask (blanking ped)
        call print_status     ; Print status of all lights
        call delay_1s         ; Wait 1 second

        ; Repeat flash until r19 reaches 0
        dec r19               ; Decrement r19
        brne flash_ped        ; Repeat until r19 is zero

        ; Reset pedestrian lights to red before returning
        call ped_red          ; Set ped crossing red
        call delay_2s         ; Wait 2 seconds

        ; Return from ped crossing routine
        ret                   ; Return from subroutine

; Sets the pedestrian lights to 00 while mainaining the other sets
mask_ped:
        in    r18, PORTA      ; Read in PORTA value
        andi  r18, 0b11111100 ; Mask out last 2 bits
        ret                   ; Return from subroutine
        
; Sets pedestrian lights to red while maintaining the other sets
ped_red:
        call  mask_ped        ; Mask out last 2 bits for ped crossing
        ori   r18, 0b00000010 ; Load 0000 1000 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine
        
; Sets pedestrian lights to green while maintaining the other sets
ped_green:
        call  mask_ped        ; Mask out last 2 bits for ped crossing
        ori   r18, 0b00000001 ; Load 0000 0001 into register 18
        out   PORTA,r18       ; Write value in register 18 to PORTA
        call print_status     ; Print status of all lights
        ret                   ; Return from subroutine


; USART FUNCTIONS
; ====================================================

; Print all traffic light values
print_status:

        ; Print label "T1:"
        call printT           ; Send 'T' to serial port
        call print1           ; Send '1' to serial port
        call printColon       ; Send ':' to serial port

        ; Print if bit 7 is 0 or 1
        sbis PORTA,7          ; Skip next if bit 7 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,7          ; Skip next if bit 7 is clear in PORTA
        call print1           ; Print '1'

        ; Print if bit 6 is 0 or 1
        sbis PORTA,6          ; Skip next if bit 6 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,6          ; Skip next if bit 6 is clear in PORTA
        call print1           ; Print '1'

        ; Print if bit 5 is 0 or 1
        sbis PORTA,5          ; Skip next if bit 5 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,5          ; Skip next if bit 5 is clear in PORTA
        call print1           ; Print '1'
        
        ; Print gap with space " "
        call printSpace       ; Send ' ' to serial port

        ; Print label "T2:"
        call printT           ; Send 'T' to serial port
        call print2           ; Send '2' to serial port
        call printColon       ; Send ':' to serial port

        ; Print if bit 4 is 0 or 1
        sbis PORTA,4          ; Skip next if bit 4 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,4          ; Skip next if bit 4 is clear in PORTA
        call print1           ; Print '1'

        ; Print if bit 3 is 0 or 1
        sbis PORTA,3          ; Skip next if bit 3 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,3          ; Skip next if bit 3 is clear in PORTA
        call print1           ; Print '1'

        ; Print if bit 2 is 0 or 1
        sbis PORTA,2          ; Skip next if bit 2 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,2          ; Skip next if bit 2 is clear in PORTA
        call print1           ; Print '1'

        ; Print gap with space " "
        call printSpace       ; Send ' ' to serial port

        ; Print label "P:"
        call printP           ; Send 'P' to serial port
        call printColon       ; Send ':' to serial port


        ; Print if bit 1 is 0 or 1
        sbis PORTA,1          ; Skip next if bit 1 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,1          ; Skip next if bit 1 is clear in PORTA
        call print1           ; Print '1'

        ; Print if bit 0 is 0 or 1
        sbis PORTA,0          ; Skip next if bit 0 is set in PORTA
        call print0           ; Print '0'
        sbic PORTA,0          ; Skip next if bit 0 is clear in PORTA
        call print1           ; Print '1'

        ; Print line feed to successive prints to next line
        call printLF
        
        ret                   ; Return from subroutine

printT:
        ldi r17, 0x54         ; Load ASCII value 'T' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine
        
printP:
        ldi r17, 0x50         ; Load ASCII value 'P' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine
        
printColon:
        ldi r17, 0x3A         ; Load ASCII value ':' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine
        
printSpace:
        ldi r17, 0x20         ; Load ASCII value ' ' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine

print0:
        ldi r17, 0x30         ; Load ASCII value '0' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine
        
print1:
        ldi r17, 0x31         ; Load ASCII value '1' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine
        
print2:
        ldi r17, 0x32         ; Load ASCII value '2' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine
        
printLF:
        ldi r17, 0x0A         ; Load ASCII value '2' to r17
        call transmit         ; Send value from r17 to serial port
        ret                   ; Return from subroutine

; CUSTOM DELAYS
; ====================================================

; Function to delay for 5 seconds by modifying 1s delay start 
; and using a jump to 100ms delay
delay_5s:
        push r24              ; Store register 24 value on stack
        push r25              ; Store register 25 value on stack
        push r26              ; Store register 26 value on stack
        push r27              ; Store register 27 value on stack
        ldi  r24,50           ; Load 50 into register 24 (in place of 10 for 1s)
        jmp delay_100ms       ; Jump to delay_100ms
        
; Function to delay for 2 seconds by modifying 1s delay start 
; and using a jump to 100ms delay
delay_2s:
        push r24              ; Store register 24 value on stack
        push r25              ; Store register 25 value on stack
        push r26              ; Store register 26 value on stack
        push r27              ; Store register 27 value on stack
        ldi  r24,20           ; Load 20 into register 24 (in place of 10 for 1s)
        jmp delay_100ms       ; Jump to delay_100ms
        
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
