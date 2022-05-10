/**
 * ASM Inline Delay
 * 
 * To make the full blink sketch in asm,
 * I created a delay subroutine within assembly.
 * 
 * This uses bytes and words with their respective
 * decrement opcodes DEC and SBIW.
 * 
 * I also make use of the branch opcode BRNE which
 * checks the zero flag and jumps to the label until
 * the zero flag is set.
 * 
 * Finally, I use CALL to invoke subroutines and JMP
 * to return to the beginning of the start loop.
 * 
 * Author: Jazer Barclay
 */

// Setup Function (Runs once at the start)
void setup() {

  // Set the pin mode of digital pin 13 (PB7) to output
  asm volatile (
    "sbi 0x04,7 ; Set bit 7 in I/O register 4 (DDRB) \n"
  );
  
}

// Main Loop (Repeats forever)
void loop() {
  
  // Blinks the on-board LED on and off using an assembly implementation
  // of the delay function using registers 24-27
  asm volatile (
    
    // Assembly main loop
    "start%=:        sbi  0x05,7           ; Set bit 7 in I/O register 5 (DDRB) \n"
    "                call delay_1s%=       ; Delay for 1 second \n"
    "                cbi  0x05,7           ; Clear bit 7 in I/O register 5 (DDRB) \n"
    "                call delay_1s%=       ; Delay for 1 second \n"
    "                jmp start%=           ; Jump to start to loop \n "

    // 1 second delay method
    "delay_1s%=:     ldi  r24,10           ; Load 10 into register 24 \n"
    "delay_100ms%=:  ldi  r25,100          ; Load 100 into register 25 \n"
    "delay_1ms%=:    ldi  r27,4000 >> 8    ; Load high byte of value 4000 into reg 27 \n"
    "                ldi  r26,4000 & 255   ; Load low byte of value 4000 into reg 26 \n"
    "delay_ms%=:     sbiw r26,1            ; Decrement ms count (X-register r27:r26) \n"
    "                brne delay_ms%=       ; Loop to delay_ms while r26 > 0 \n"
    "                dec  r25              ; Decrement register 25 by 1 \n"
    "                brne delay_1ms%=      ; Loop to delay_1ms while r25 > 0 \n"
    "                dec  r24              ; Decrement register 24 by 1\n"
    "                brne delay_100ms%=    ; Loop to delay_100ms while r24 > 0 \n"
    "                ret                   ; Return from subroutine \n"
    
    // Clobber registers 22-27
    ::: "r24","r25","r26","r27"
    
  );

} // END OF LOOP (Returns to start of loop)
