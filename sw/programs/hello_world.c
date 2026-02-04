#include "soc_regs.h"

void uart_putc(char c) {
    // If your UART hardware isn't setting bit 0 to 1, this loop hangs.
    // FOR VERIFICATION: We will force it to proceed after a short timeout
    // or just comment it out to see if the write works.
    int timeout = 1000;
    while (!(UART_STATUS & 0x1) && timeout > 0) {
        timeout--;
    }
    UART_DATA = c;
}

void print(const char *p) {
    while (*p) uart_putc(*(p++));
}

int main() {
    // TEST 1: Timer Read
    volatile uint32_t start_time = TIMER_VALUE;
    
    // TEST 2: UART Write
    print("Verifying SoC...\n");

    // TEST 3: Data RAM Macro (Read/Write)
    // We create a variable in RAM and check if it holds its value
    volatile uint32_t *ram_ptr = (uint32_t *) 0x00010100;
    *ram_ptr = 0xDEADBEEF;
    
    if (*ram_ptr == 0xDEADBEEF) {
        print("RAM Macro: PASS\n");
    } else {
        print("RAM Macro: FAIL\n");
    }

    // TEST 4: Timer Progress
    if (TIMER_VALUE > start_time) {
        print("Timer: PASS\n");
    }

    while(1);
    return 0;
}


//int main() {
    // Skip print for a moment to verify the hardware path
//    volatile uint32_t *ram_ptr = (uint32_t *) 0x00010100;
    
    // Perform Write
//    *ram_ptr = 0xDEADBEEF;
    
    // Perform Read
//    volatile uint32_t val = *ram_ptr;

//    if (val == 0xDEADBEEF) {
//        UART_DATA = 'P'; // Manual UART write for PASS
//    } else {
//        UART_DATA = 'F'; // Manual UART write for FAIL
//    }

//    while(1);
//}

//void uart_putc(char c) {
    // Wait until bit 0 of UART_STATUS is 1 (Ready/Not Busy)
//    while (!(UART_STATUS & 0x1));
    // For now, we just write it
//    UART_DATA = c;
//}
//void print(const char *p) {
//    while (*p) uart_putc(*(p++));
//}

//int main() {
//    volatile uint32_t start = TIMER_VALUE;
//    print("Hello RISC-V World!\n");
    
//    while(1) {
        // Blink a bit in memory or toggle a pin if you had one
//    }
//    return 0;
//}