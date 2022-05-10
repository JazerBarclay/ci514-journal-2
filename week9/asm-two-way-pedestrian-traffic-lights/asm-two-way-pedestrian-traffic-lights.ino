/* 
 * Assembly Two Way Traffic Lights with pedestrian crossing
 * 
 * This is a purely assembly written, interrupt driven
 * traffic light system.
 * 
 * By using two timer interrupts for each set of lights and
 * an external interrupt for pedestrain crossings, it uses
 * the interrupt driven system ideology with an idle loop
 * at its center.
 * 
 * The timers driving the default changing of which
 * lanes have priority is the default however if the button
 * on digital pin 2 goes high, it will store a flag to allow
 * pedestrains to cross when both lights next go red.
 * 
 * The status of the LEDs is written to the serial port
 * upon each change 
 * 
 * Author: Jazer Barclay
 */
