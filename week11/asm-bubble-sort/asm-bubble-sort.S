; ====================================================
; Assembly Bubble Sort
; ====================================================

; == Definitions ==
#define __SFR_OFFSET 0

; == Number Array Start ==
#define SRAMSTART 0x0300

; == Number Of Random Numbers ==
#define RANDOMNUMS 50

; Include libraries or other header files
#include "avr/io.h"

; Expose these global functions
.global setup             ; Used in place of setup() c function
.global loop              ; Used in place of loop() c function
.global INT4_vect         ; Expose the external interrupt

; WORKING REIGSTER USAGE
; ====================================================
; R17 - USART transmit value
; R18 - General temporary use
; R19 & R20 - Random number generation
; R21 & 22 -> Comparison / swap registers
; R23      -> Swap flag (Bit 0)
; R24 - 27 -> Delay & Binary to Decimal ASCII
; R30 & 31 -> Z-Reg SRAM pointer

; SETUP
; ====================================================

; Assembly version of setup() function
setup:
        ; Setup I/O pins
        call init_pins                ; Call init_pins subroutine

        ; Initialise the analog to digital converter
        call init_adc                 ; Call init_adc subroutine

        ; Initialise serial interface
        call init_usart               ; Call init_usart subroutine
        
        ; Generate random numbers
        call init_rand_nums           ; Call init_rand_nums subroutine
        
        ; Print all values in array
        call print_all_numbers        ; Call print_all_numbers subroutine

        ; Setup external interrupt 4 (pin 2)
        call init_interrupts          ; Setup interrupts
        
        ; Finish setup
        ret                           ; Return from setup subroutine


; INITIALISATION ROUTINES
; ====================================================

; Setup the pin modes for leds used
init_pins:

        ; Set all of PORTA as outputs
        ldi r18, 0xff       ; Store 1111 1111 in r18
        out DDRA, r18       ; Write value in r18 to DDRA

        ; Return from pin setup
        ret                 ; Return from init_pins subroutine


; Setup the Analog to Digital Conversion for reading A0
init_adc:
        
        ; Set A0 as input (PF0 on the mega)
        cbi DDRF, 0         ; Clear bit 0 of port f for input

        ; Set which Analog input to read and how to format 10-bit value
        ldi r18, 0xC0       ; Write 11000000 to r18 (2.56v, right-adjust, adc0)
        sts ADMUX, r18      ; Store r18 direct to sram ADMUX (0x7C)

        ; Enable analog input and set prescale
        ldi r18, 0x87       ; Write 10000111 to r18 (Enable, Prescale clk/128)
        sts ADCSRA, r18     ; Store r18 direct to sram ADCSRA (0x7A)
        
        ; Return from intialising adc
        ret                 ; Return from init_adc subroutine


; Setup USART for sending numbers to serial port
init_usart:
        ; Clear usart control status register and baud rate high register
        clr   r18                   ; Clear register 24
        sts   UCSR0A, r18           ; Set UCSR0A to value in r24 (0000 0000)
        sts   UBRR0H, r18           ; Set UBRR0H to value in r24 (0000 0000)

        ; Set baud rate to 9600 (clock_freq / 16 * rate + 1) = 103
        ldi   r18, 103              ; Store baud rate in r24 (for baud [clock_freq / 16 * rate + 1] )
        sts   UBRR0L, r18           ; Write baud rate into low byte of UBRR0
        
        ; Set mask to allow tx and rx
        ldi   r18,  1 << TXEN0      ; Store transmit and receive bits into r24
        sts   UCSR0B, r18           ; Write transmit and receive bits into UCSR0B

        ; Set character frame size to 8 bits (1 byte)
        ldi   r18, 1 << UCSZ00 | 1 << UCSZ01    ; Set transmit character frame size to 8 bits
        sts   UCSR0C, r18                       ; Write character frame size

        ; Return from usart setup
        ret                         ; Return from subroutine


; Reset the z-reg pointer to the beginning of our array
reset_sram_location:

        ldi ZL, SRAMSTART & 255     ; Load ZL with lower byte of the address
        ldi ZH, SRAMSTART >> 8      ; Load ZH with higher byte of the address
        
        ret                         ; Return from reset_sram_location subroutine


; Generate random numbers to fill the array
init_rand_nums:

        ; Get random seed from A0 and store in r19
        call read_adc
        
        ; Init second (fixed) seed value
        ldi r20, 0xAF
        
        ; Set Z-reg to sram start location (start of array)
        call reset_sram_location

  generate:
        ; Get next random number
        call gen_rand_num

        ; Store random number from r19 into pointer location of z-reg
        st Z+, r19            ; Write value in r19 to sram location in z-reg then increment pointer
        
        ; Compare low byte of Z reg with random count
        cpi ZL, RANDOMNUMS    ; Compare low byte of z-reg with number count

        ; Until zero flag set (both ZL and Total are equal) jump to generate
        brne generate         ; If zero flag not set, go to generate
        
        ; Finish setup
        ret                   ; Return from init_rand_nums subroutine


; Setup interrupt 4 (pin 2) for push button interrupt 
init_interrupts:
        cli                    ; Disable global interrupts

        ; Setup external interrupt control register B
        ldi   r18,0x03         ; Load 0011 into reg 18 (for rising edge combination)
        sts   EICRB,r18        ; Set EICRB (0x6A) to 11 from register 18

        ; Enable external interrupt 4
        sbi   EIMSK,4          ; Set INT4 bit in EIMSK (0x1D) register

        sei                    ; Enable global interrupts
        ret                    ; Return from subroutine



; MAIN LOOP
; ====================================================

; Assembly version of loop() function
loop:
        ; Idle loop
        nop           ; Do nothing
        jmp loop      ; Jump to loop


; INTERRUPT ROUTINE
; ====================================================

; Interrupt 4 routine
INT4_vect:
        ; Disable this interrupt while running
        cbi   EIMSK,4           ; Clear INT4 bit in EIMSK (0x1D) masking interrupt

        call bubble_sort        ; Run bubble sort subroutine

        ; Print all (now sorted) values
        call print_all_numbers

        ; Reset z-reg pointer location
        call reset_sram_location

        ; Read first value in
        ld r21, Z+    

        ; Write smallest value to LEDs
        out PORTA, r21
        
        ; Return from button interrupt routine
        reti                   ; Return from interrupt

bubble_sort:
        ; Reset z-reg pointer location
        call reset_sram_location
        
        ; Reset swap flag
        ldi r23, 0x00         ; Set r23 to 0000 0000

        ; Read in next value
        ld r22, Z+            ; Load value from sram location at z-reg into r21

  next:
        ; Move values up to match sram registers
        mov r21, r22          ; Shift register values up
        
        ; Read in next value
        ld r22, Z+            ; Load value from sram location at z-reg into r22

  compare:
        ; Compare and swap if second is bigger than first
        cp r21,r22            ; Compare r21 with 22
        breq continue         ; If equal then next
        brcc swap             ; If carry not set (second is smaller) then swap
        
  continue:
        ; Compare low byte of Z reg with random count and finish when they match
        cpi ZL, RANDOMNUMS    ; Compare ZL with random number count
        brne next             ; If zero flag not set (not equal) then compare next 

  check_flag:
        ; If flag was set then start again, if not then finish
        sbrc r23, 0           ; Skip next if first bit in r23 is set to 1 (swap was made)
        jmp bubble_sort         ; Jump to beginning of function to call itself
        
        jmp finish            ; Flag not set so finish
        
  swap:
        ; Store r21 (first num) in second reg slot
        st -Z, r21            ; Decrement pointer z and Load value into sram from r21
        
        ; Store second num in first reg slot
        st -Z, r22            ; Decrement pointer z and Load value into sram from r22

        ; Move pointer back to last position
        adiw ZL, 2            ; Add 2 to Z-reg

        ; Swap in working registers
        push r21              ; Temprarily store r21 in stack
        mov r21, r22          ; Move r22 value into r21
        pop r22               ; Restore r21 value from stack into r22

        ; Set swap flag to 1
        ldi r23, 0x01         ; Write 1 to r23

        ; Continue by jumping to next
        jmp continue          ; Jump to continue
        
    finish:
        ; Return from subroutine
        ret

; ANALOG TO DIGITAL CONVERSION
; ====================================================

; Read the value at A0 and store in R19
read_adc:
        lds r18, ADCSRA    ; Load ADCSRA from SRAM to r18
        ori r18, 0x40      ; Enable ADSC to start conversion
        sts ADCSRA, r18    ; Write adjusted ADCSRA back to 0x7C

  wait_adc:
        lds r18, ADCSRA   ; Check interrupt flag in ADCSRA (0x7A)
        sbrs r18, 4       ; Skip next if bit 4 is set in r22
        jmp wait_adc      ; Jump back to wait_adc since not ready

  reset_adc_flag:
        lds r18, ADCSRA   ; Load ADCSRA to r18
        ori r18, 0x10     ; Re-enable interrupt flag
        sts ADCSRA, r18   ; Set value

  record_adc:
        lds r19, ADCL     ; Get low byte from ADCL
        ret               ; Returns from read_adc subroutine


; RANDOM NUMBER GENERATION FUNCTION
; ====================================================

; Generate a random number using the preset r19 and r20 values
gen_rand_num:

        ; Randomise using xor, swap and add
        eor r19, r20      ; XOR two values
        swap r19          ; Swap nibbles in result
        add r20, r19      ; Add new value to r20 for next loop
        
        ret


; USART FUNCTIONS
; ====================================================

; Print all numbers in the sram array
print_all_numbers:

      ; Reset z-reg pointer location
      call reset_sram_location
      
    read_next:
        ld r24, Z+

        ; Convert r24 from binary number to decimal across r25-r27
        call convert_bin_num_to_dec

        ; Store 0x30 into r16 (to be added to each)
        ldi r16, 0x30

    print_100s:
        mov r17, r25
        add r17, r16
        call transmit

    print_10s:
        mov r17, r26
        add r17, r16
        call transmit

    print_1s:
        mov r17, r27
        add r17, r16
        call transmit

    print_space:
        ldi r17, 0x20
        call transmit

        ; Compare low byte of Z reg with random count + 1
        cpi ZL, RANDOMNUMS      ; Compare ZL with random number count
        brne read_next          ; If zero flag not set (not equal) then compare next

    print_cr:
        ldi r17, 10
        call transmit
        
        ret                       ; Return from print all numbers routine


; Sends the ascii value at r17 to the serial port
transmit:
        ; Check if ready to transmit
        clr r18
        lds   r18, UCSR0A         ; Store value at UCSR0A into r18
        sbrs  r18, UDRE0          ; Skip if bit in register is set
        jmp  transmit            ; Return to transmit beginning
        
        ; Once ready write the value
        sts   UDR0, r17           ; Write value in r18 to serial port
        
        ret                       ; Return from subroutine


; Converts the value in r24 to decimal
; r25 = 100s  r26 = 10s  r27 = 1s
convert_bin_num_to_dec:
        clr r25                   ; Clear r25
        clr r26                   ; Clear r26
        clr r27                   ; Clear r27
  hundreds:
        cpi r24, 100              ; Compare r24 with 100
        breq done_hundred         ; If equal then add to 100s then finish
        brcs tens                 ; If smaller than 100 then move onto 10s
        subi r24, 100             ; Subtract 100 from r24
        inc r25                   ; Increment 100s counter r25
        jmp hundreds              ; Jump to hundreds to repeat
  done_hundred:                 
        inc r25                   ; Increment 100s counter r25
        ret                       ; Return from subroutine
  tens:
        cpi r24, 10               ; Compare r24 with 10
        breq done_tens            ; If equal then add to 10s then finish
        brcs units                ; If smaller than 10 then move into 1s
        subi r24, 10              ; Subtract 10 from r24
        inc r26                   ; Increment 10s counter r26
        jmp tens                  ; Jump to tens to repeat
  done_tens:      
        inc r26                   ; Increment 10s counter r26
        ret                       ; Return from subroutine
  units:
        subi r24, 1               ; Subtract 1 from r24
        breq done_units           ; If zero then add to 1s then finish
        inc r27                   ; Increment r27
        jmp tens                  ; Jump to units to repeat
  done_units:
        inc r27                   ; Increment 1s counter r27
        ret                       ; Return from subroutine

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
