#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

// Base Addresses (Match your Verilog parameters)
#define UART_BASE   0x10000000
#define TIMER_BASE  0x10001000

// UART Registers
#define UART_DATA   (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_STATUS (*(volatile uint32_t*)(UART_BASE + 0x04)) // bit 0 = tx_ready

// Timer Registers
#define TIMER_VALUE   (*(volatile uint32_t*)(TIMER_BASE + 0x00))
#define TIMER_COMPARE (*(volatile uint32_t*)(TIMER_BASE + 0x04))

#endif