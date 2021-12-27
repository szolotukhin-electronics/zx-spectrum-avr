;
; attimiy-zx-sync.asm
;
; Created: 26.12.2021 18:22:35
; Author : szolotukhin
; The Cycle Counter and Stopwatch is only available with the simulator. To use these, first, click Start Debugging and Break  to start a debug session and then open the Processor Status window by typing 'Processor' into the quick-launch bar and hitting enter (or this can be found under Debug > Windows > Processor Status). Similarly, the Disassembly window can also be opened.
; Assembler documentation
; https://onlinedocs.microchip.com/pr/GUID-E06F3258-483F-4A7B-B1F8-69933E029363-en-US-2/index.html?GUID-33B053ED-725C-46CD-AD2C-A7300E2343F4

; #define us_to_ns(t_us) ( ( ( t_us * 1000 / T_CYCLE_NS - 3 ) / 3 + 1 ) )

.equ F_CPU = 7000000
.equ ns = 1000000000
.equ T_CYCLE_NS = 1.0 / F_CPU * ns

.def A = r16

.macro wait_us
	ldi A, ( ( ( @0 * 1000 / T_CYCLE_NS - 3 ) / 3 + 1 ) ) ; 1 cycle
loop: 
	dec A ; 1 cycle
	brne loop ; Cycles 1 if condition is false,  2 if condition is true	
.endmacro
	
.macro us
	
.endmacro

; entry point
start:
	// wait_us 4.7

	; config PINB1 of PORTB as ouput
	in A, DDRB
	sbr A, (1<<PINB1)
    out DDRB, A

	; set sync default high level
	in A, PORTB
	sbr A, (1<<PINB1)
    out PORTB, A

	; config PINB0 of PORTB as input
	in A, DDRB
	cbr A, (1<<PINB0)
    out DDRB, A

	; pull-up resistor on PINB0 of PORTB
	in A, DDRB
	sbr A, (1<<PINB0)
    out PORTB, A

wait_external_sync:
	; wait external sync
	in A, PINB
	sbrs A, PINB0 ; Skip next instruction if bit in register is set
	rjmp wait_external_sync 

	; start sync pulse
	in A, PORTB
	cbr A, (1<<PINB1)
    out PORTB, A

	; preload timer counter with 
	ldi   A, 223        
	out   TCNT0, A

	; timer source is controller clock / start timer 
	ldi A, 1 
	out TCCR0B, A

wait_timer_end:
	in A, TIFR0
	sbrs A, TOV0 ; Skip next instruction if bit in register is set
	rjmp wait_timer_end 

	; end sync pulse
	in A, PORTB
	sbr A, (1<<PINB1)
    out PORTB, A

	; stop timer counting
	ldi A, 0 
	out TCCR0B, A

	; clear timer overflow flag
	ldi  A, (1<<TOV0)  
	out  TIFR0, A
    
    rjmp start
