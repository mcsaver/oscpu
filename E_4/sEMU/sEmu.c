#include<stdint.h>
#include<stdio.h>
#include<stdbool.h>
#include<stdlib.h>

// sISA architecture resources
uint8_t PC = 0;             // Program Counter (4 bits in ISA, use uint8_t in C)
uint8_t R[4] = {0, 0, 0, 0}; // General Purpose Registers (4 registers)

/*
 Program to compute sum = 1 + 2 + ... + 10 and output result via OUT instruction.

 We use registers:
    R0 : accumulator (sum)
    R1 : loop counter (i)
    R2 : temporary / constant 1
    R3 : temporary / target for branch address

 Instruction encoding (8-bit instruction):
    [ opcode:4 ][ op1:2 ][ op2:2 ]

 Opcodes used:
    0x0 : add   R[op1] = R[op1] + R[op2]
    0x1 : mov   R[op1] = R[op2]
    0x2 : load  R[op1] = M[R[op2]]   (not used here)
    0x3 : store M[R[op2]] = R[op1]   (not used here)
    0x4 : bner0 if (R[op1] != 0) PC = R[op2] else PC++
    0x5 : out   print R[op1] and exit emulator

 Program layout (addresses 0..N):
    0: mov R0, R0       ; clear R0 (redundant if already zero)
    1: mov R1, R1       ; initialize R1 = 0
    2: mov R2, R2       ; initialize R2 = 1 (we'll set M[...] to hold 1 and load it)
    3: mov R3, R3       ; placeholder

 We'll instead directly load immediate-like constants by using memory locations as "constants":
 Place constant 1 at M[12]; place constant 10 at M[13]; place the OUT instruction at the end.

 The instruction sequence below implements:
     R0 = 0
     R1 = 1
 loop:
     R0 = R0 + R1
     R1 = R1 + 1
     if (R1 <= 10) goto loop
     out R0

 Because bner0 checks for != 0, we implement the loop by decrementing a counter instead.

 We'll implement a counter C = 10 in R3, and decrement it until zero.
 R1 will hold current addend, starting from 1.

 Memory layout (constants):
    M[12] = 1
    M[13] = 10
    M[14] = 0  (unused)
    M[15] = 0  (will hold final out instruction if needed)
*/

uint8_t M[16] = {
    /* 0 */ 0x02, /* add R0 = R0 + R2  (accumulate counter) */
    /* 1 */ 0x0B, /* add R2 = R2 + R3  (decrement counter since R3 = 0xFF) */
    /* 2 */ 0x49, /* bner0: if(R2 != 0) PC = R1 (R1 holds loop addr 0) */
    /* 3 */ 0x50, /* out R0: print R0 and exit */
    /* 4 */ 0x00,
    /* 5 */ 0x00,
    /* 6 */ 0x00,
    /* 7 */ 0x00,
    /* 8 */ 0x00,
    /* 9 */ 0x00,
    /*10 */ 0x00,
    /*11 */ 0x00,
    /*12 */ 0x00,
    /*13 */ 0x00,
    /*14 */ 0x00,
    /*15 */ 0x00
};

// Execute one instruction cycle
void inst_cycle() {
    uint8_t inst = M[PC]; // Fetch instruction
    uint8_t opcode = (inst & 0xF0) >> 4; // Extract opcode (high 4 bits)
    uint8_t op1 = (inst & 0x0C) >> 2;    // Extract operand 1 (bits 3-2)
    uint8_t op2 = (inst & 0x03);         // Extract operand 2 (bits 1-0)

    switch (opcode)
    {
    case 0x0:   // add: R[op1] = R[op1] + R[op2]
        R[op1] = R[op1] + R[op2];
        PC = (PC + 1) & 0x0F; // keep PC 4-bit
        break;
    case 0x1:   // mov: R[op1] = R[op2]
        R[op1] = R[op2];
        PC = (PC + 1) & 0x0F;
        break;
    case 0x2:   // load: R[op1] = M[R[op2]]
        R[op1] = M[R[op2] & 0x0F];
        PC = (PC + 1) & 0x0F;
        break;
    case 0x3:   // store: M[R[op2]] = R[op1]
        M[R[op2] & 0x0F] = R[op1];
        PC = (PC + 1) & 0x0F;
        break;
    case 0x4:   // bner0: if(R[op1] != 0) PC = R[op2]; else PC++
        if (R[op1] != 0)
        {
            PC = R[op2] & 0x0F;
        }
        else PC = (PC + 1) & 0x0F;
        break;
    case 0x5:   // out: print R[op1] to terminal and exit emulator
        printf("%d\n", R[op1]);
        fflush(stdout);
        exit(0);
        break;
    default: // unknown instruction, halt or loop
        while (1) { /* hang */ }
        break;
    }
}

int main() {
    /* Initialize registers for the sum program:
       R0 = 0 (accumulator)
       R1 = 0 (loop address / helper)
       R2 = 10 (counter)
       R3 = 255 (0xFF) used to decrement R2 via addition
    */
    R[0] = 0;
    R[1] = 0;
    R[2] = 10;
    R[3] = 0xFF;
    PC = 0;

    while (true) {
        inst_cycle();
    }
    return 0;
}