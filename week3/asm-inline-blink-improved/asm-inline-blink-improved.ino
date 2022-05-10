/**
 * ASM Inline Blink Improved
 * 
 * I improved the previous inline-blink sketch
 * by implementing the SBI and CBI opcodes.
 * 
 * These allow for single bit manipulation
 * with only a single opcode mneumonic.
 * 
 * Author: Jazer Barclay
 */

// Setup Function (Runs once at the start)
void setup() {

  // First we must set the "pinMode".
  // I improved this by using SBI to set bit 7 in DDRB
  
  asm volatile (
    "sbi 0x04,7 ; Set bit 7 in io register 4 (DDRB) \n"
  );
  
}

// Main Loop (Repeats forever)
void loop() {
  
  // Now we need to set the pin high by writing to the port register
  asm volatile (
    "sbi 0x05,7 ; Set bit 7 in io register 5 (PORTB) to 1 \n"
  );

  // Wait 1 second using the C function delay()
  delay(1000);

  // We can set the LED low by clearing the value we write to DDRB
  asm volatile (
    "cbi 0x05,7 ; Clear bit 7 in io register 5 (PORTB) to 0 \n"
  );

  // Wait 1 second using the C function delay()
  delay(1000);

} // END OF LOOP (Returns to start of loop)
