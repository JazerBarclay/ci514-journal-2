/**
 * ASM Inline Blink
 * 
 * A simple blink sketch that uses inline
 * assembly to turn the on-board LED on and
 * off.
 * 
 * Author: Jazer Barclay
 */

// Setup Function (Runs once at the start)
void setup() {

  // First we must initialise the LED pin
  // This is the equivalent of setting the "pinMode" in C.
  // We do this by setting the data direction register for the desired
  // LED to 1. For this we set data direction register b - bit 7 to 1
  asm volatile (
    "ldi r18,0x80 ; Load immediate the value 1000 0000 into register 18 \n"
    "out 0x04,r18 ; Write contents of register 18 to IO register 4 (DDRB) \n"
    ::: "r18" // Clobber register 18
  );
  
}

// Main Loop (Repeats forever)
void loop() {

  // At the start of the loop we must turn on the light
  // We need to set the pin high by writing to the port register
  asm volatile(
    "ldi r18,0x80 ; Write 1000 0000 to register 18 \n"
    "out 0x05,r18 ; Write value in register 18 to PORTB (0x05) \n"
    :::"r18" // Clobber register 18
  );

  // Wait 1 second using the C function delay()
  delay(1000);

  // After the delay we now turn off the light
  // We can set the LED low by changing the value we write to DDRB
  asm volatile(
    "ldi r18,0x00 ; Write 0000 0000 to register 18 \n"
    "out 0x05,r18 ; Write value in register 18 to PORTB (0x05) \n"
    :::"r18" // Clobber register 18
  );

  // Wait 1 second using the C function delay()
  delay(1000);

} // END OF LOOP (Returns to start of loop)
