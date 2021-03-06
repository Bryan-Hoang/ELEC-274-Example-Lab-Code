# LAB3PRT1.S [170114]
# 
###############################################################################
# LAB3PRT1 illustrates how to save and restore the return address - when
# one function calls another
#
# Author:
# David Athersych, P.Eng. Cynosure Computer Technologies Inc.
#
# HISTORY:
# 170114 DFA	First release
###############################################################################

# Actual assembly code starts here:
#
# Directives - configuration information to the assembler.

# Symbol definitions
	.equ	LAST_RAM_WORD,	0x007FFFFC
	.equ	JTAG_UART_BASE,	0x10001000	# base address of JTAG UART
	.equ	OFFSET_DATA,	0			# offset from base for data register
	.equ	OFFSET_STATUS,	4			# offset from base for status register
	.equ	WSPACE_MASK,	0xFFFF		# 16 bit mask used to get status bits

# Object module configuration.
	.text				# tell assembler that this is code segment
	.global	_start		# tell assembler that _start is visible to linker

	.org	0x00000000	# starting address for the following code

_start:
	# Initialize stack pointer to point to last word in memory. Stack is
	# used by hardware to store return address during function call. Stack
	# may also be used for temporary variables.
	movia	sp, LAST_RAM_WORD

	movia	r4, MSG1
	call	PrintString
	movia	r4, MSG2
	call	PrintString
    
    # add a newline character to the end
	movi	r2, '\n'		# just like C
	call	PrintChar
    
	movia	r4, MSG3
	call	PrintString
	movia	r4, MSG4
	call	PrintString
_end:
	br		_end		# nothing else to do and nowhere else to go.

#==============================================================================
# Subroutine PrintChar
# Print 1 character to output device.  Taken from Lab1part2 - unchanged.
# Note that this code does not call any other functions, so it does not save
# ra.
#
# Parameters:
#	R2	- contains character to be displayed
# Return value:
#	nothing

PrintChar:
	subi	sp, sp, 8	# subtract 8 from sp, making room for two words.
	stw		r3, 4(sp)	# save contents of r3
	stw		r4, 0(sp)	# and r4.
	movia	r3, JTAG_UART_BASE	# r3 points to base of UART device registers
loop2:
	ldwio	r4, OFFSET_STATUS(r3)	# fetch contents of status register
	andhi	r4, r4, WSPACE_MASK		# keep only high-order 16 bits
	beq		r4, r0, loop2			# all 0? Try again
	# Get here when READY bit turns on
	stwio	r2, OFFSET_DATA(r3)		# Write character to data register
	# our work accomplished; restore register values
	ldw		r3, 4(sp)
	ldw		r4, 0(sp)
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
	ret					# go back to calling site, all registers preserved

#==============================================================================
# Subroutine PrintString
# Print ASCIZ string to output device.  This code uses the PrintChar function
# so it needs to save ra.

# Parameters:
#	R4	- contains address of string to be displayed
# Return value:
#	nothing, but r4 will point to end of string

PrintString:
	# We will call another function, so we need to save contents of ra
	subi	sp, sp, 8	# subtract 8 from sp, making room for two words.
	stw		ra, 4(sp)	# save contents of ra
	stw		r2, 0(sp)	# save contents of r2
	##---<SNIP>---
loop:
	ldb		r2, 0(r4)		# fetch the byte pointed to by r3
	beq		r2, r0, done	# if byte value is 0, branch to done.
	call	PrintChar		# print character in r2
	addi	r4, r4, 1		# increment r3 pointer
	br		loop			# do next character
done:
	# add a newline character to the end
	movi	r2, '\n'		# just like C
	call	PrintChar
	##---<SNIP>---
	ldw		ra, 4(sp) 	# restore original ra
	ldw		r2, 0(sp)	# restore original r2
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
	ret							# return to address in ra

#==============================================================================

	.org	0x00001000	# where this code is to go in memory
MSG1:.asciz	"Hello TA,"	# first message
MSG2:.asciz	"This part was easy!"	# second message
MSG3:.asciz	"This code can print"
MSG4:.asciz	"many messages!"

	.end				# tells assembler this is the end

