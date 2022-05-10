/**
 * ASM Inline Strobe
 * 
 * I wanted to learn more about bit manipulation
 * within a byte. For this I move a single bit from
 * left to right within a register, then write the value
 * of the byte to PORTA.
 * 
 * I use the previous week's inline delay function to create
 * the 1 second delays between each iteration.
 * 
 * For shifting the bit, I use LSL to left shift the value
 * in a register by 1.
 * 
 * Finally we return to the start of the loop once 7 cycles 
 * complete.
 * 
 * Author: Jazer Barclay
 */

// Setup Function (Runs once at the start)
void setup() {

  // Set all of PORTA (D22-D29) as outputs
  asm volatile (
    "ldi r18,0xFF ; Load immediate the value 1111 1111 into register 18 \n"
    "out 0x01,r18 ; Write contents of register 18 to I/O register 1 (DDRA) \n"
    ::: "r18"     // Clobber register 18
  );
  
}

// Main Loop (Repeats forever)
void loop() {

  // Sets a register with a single bit which is written to PORTB
  // and bit shifted left 7 times with a delay of 1 second.
  asm volatile (
    
    // Main loop
    "start%=:        ldi  r23,0x01         ; Load 0000 0001 into register 23 \n"
    "                ldi  r22,0x08         ; Load 8 into register 22 (used to count iterations) \n"
    "next%=:         out  0x02,r23         ; Write contents of r23 to PORTA (0x02) \n"
    "                call delay_1s%=       ; Delay for 1 second \n"
    "                lsl  r23              ; Shift value of r23 left 1 bit \n"
    "                dec  r22              ; Reduce value in register 22 by 1 \n"
    "                brne next%=           ; Go to 'next' while r22 > 0 \n"
    "                call start%=          ; Go to 'start' once 7 cycles complete \n"

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
    ::: "r22","r23","r24","r25","r26","r27"
  );

} // END OF LOOP (Returns to start of loop)
