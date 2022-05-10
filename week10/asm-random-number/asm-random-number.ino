/* 
 * Assembly Random Number
 * 
 * Generates random numbers using 
 * the floating value of the analog input
 * pin A0 as a seed value.
 * 
 * It then uses a second fixed value
 * and XORs them together. After the
 * nibbles (first and last 4 bits)
 * are swapped. This serves as the next
 * number.
 * 
 * To seed the next XOR value the two
 * numbers are added together.
 * 
 * Author: Jazer
 */
