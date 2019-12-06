TITLE Macros In/Out Program    (inout_MASM.asm)

; Author: Jamie Mott
; Last Modified: December 6, 2019
; Description: This program demonstrates using macros and low level input/output procedures.
;				The user is asked to enter 10 unsigned integers. They are read as a string and  
;				have to be converted to numbers using the readVal procedure. Numbers are converted 
;				back to strings for printing using the writeVal procedure. The total and average  
;				of the numbers entered by the user are calculated and then the program displays 
;				the numbers entered, their sum and average.


INCLUDE Irvine32.inc


;Macro definitions

;-------------------------------------------------------------------------------- 
; displayString
; Description: This macro prints a string to the screen.
; Receives: address of string to be printed
; Returns: none
; Preconditions: none
; Registers changed:  none
;--------------------------------------------------------------------------------
displayString	MACRO	string
	push	edx

	mov		edx, string
	call	WriteString

	pop		edx
ENDM


;-------------------------------------------------------------------------------- 
; getString
; Description: This macro shows a prompt and collects user input
; Receives: address of prompt to be printed, address of variable to store input
; Returns: user input is saved in memory
; Preconditions: none
; Registers changed:  none
;--------------------------------------------------------------------------------
getString	MACRO	prompt, userInputNum
	push	edx
	push	ecx

	displayString prompt
	mov		edx, userInputNum
	mov		ecx, 19
	call	ReadString

	pop		ecx
	pop		edx
ENDM


;Constants
MININT = 0															;bottom of unsigned 32-bit int
MAXINT = 4294967294													;top of unsigned 32-bit int - 1 (leave room for adding)


.data
intro1		BYTE	"Author: Jamie Mott            Program Title: Macros In/Out Program ", 0
intro2		BYTE	"**EC: 1 Numbers input lines and displays a running total.", 0
instruct1	BYTE	"This program has you enter 10 decimal unsigned integers and will then", 0
instruct2	BYTE	"display a list of the numbers entered, their sum and average.", 0
instruct3	BYTE	"Each number must be small enough to fit in inside a 32 bit register.", 0
parens		BYTE	"(", 0
prompt1		BYTE	") Current subtotal: ", 0
prompt2		BYTE	"    Please enter an integer:  ", 0
errorMsg	BYTE	"Error: that was too big or not an integer. Please try again.", 0
arrayMsg	BYTE	"The numbers you entered were:", 0
commas		BYTE	", ", 0
sumMsg		BYTE	"The sum of these numbers is: ", 0
averageMsg	BYTE	"The average (rounded) is: ", 0
goodbye1	BYTE	"Thanks for running my program! ", 0
userNum		BYTE	20 DUP(?)										;empty string to hold user input
tempString	BYTE	11	DUP(?)										;used when converting numbers to strings
numArray	DWORD	10 DUP(-1)										;array initialization, use -1 for singal value
sum			DWORD	0
numAvg		DWORD	?


.code
;-------------------------------------------------------------------------------- 
; main
; Description: This is the main driver procedure for the program.
; Receives: none
; Returns: none
; Preconditions: none
; Registers changed:  none
;--------------------------------------------------------------------------------
main PROC
	push	OFFSET instruct3
	push	OFFSET instruct2
	push	OFFSET instruct1
	push	OFFSET intro2
	push	OFFSET intro1
	call	introduction				;display intro and instructions

	push	OFFSET parens
	push	OFFSET tempString
	push	OFFSET errorMsg
	push	OFFSET prompt2
	push	OFFSET prompt1
	push	OFFSET sum
	push	OFFSET userNum
	push	OFFSET numArray
	call	getNumbers					;collect and verify 10 user input numbers, uses readVal and writeVal

	push	sum
	push	OFFSET numAvg
	call	calcAverage					;calculate the average number entered

	push	numAvg
	push	sum
	push	OFFSET tempString
	push	OFFSET numArray
	push	OFFSET commas
	push	OFFSET arrayMsg
	push	OFFSET sumMsg
	push	OFFSET averageMsg
	call	displayResults				;display numbers entered, sum and average, uses writeVal

	push	OFFSET goodbye1
	call	goodbye						;display parting message

	exit

main ENDP


;-------------------------------------------------------------------------------- 
; introduction
; Description: Procedure to introduce the program and show instructions.
; Receives: addresses for intro and instruction statements
; Returns: none
; Preconditions: program starts
; Registers changed: none
;--------------------------------------------------------------------------------
introduction PROC
	push	ebp							;set up stack frame
	mov		ebp, esp			
	
	displayString [ebp + 8]				;intro1
	call	CrLf
	displayString [ebp + 12]			;intro2
	call	CrLf
	call	CrLf

	displayString [ebp + 16]			;instruct1
	call	CrLf
	displayString [ebp + 20]			;instruct2
	call	CrLf
	displayString [ebp + 24]			;instruct3
	call	CrLf
	call	CrLf

	pop		ebp
	ret		20							;clean up stack from messages

introduction ENDP


;-------------------------------------------------------------------------------- 
; getNumbers
; Description: Procedure to get 10 unsigned integers from the user. Calls readVal
;				to get and validate entry. Calls writeVal for printing line # and subtotal
; Receives: addresses of numArray, userNum, sum, prompt1, prompt2, errorMsg, tempString and parens
; Returns: 10 user inputs are validated, converted and stored in numArray
; Preconditions: none
; Registers changed: none
;--------------------------------------------------------------------------------
getNumbers PROC
	push	ebp							;set up stack frame and save registers
	mov		ebp, esp
	push	edi
	push	eax
	push	ebx
	push	ecx
	push	edx

	mov		ebx, 1						;counter for EC line numbering
	mov		ecx, 10
	mov		edi, [ebp + 8]				;grab numArray
inputLoop:
	displayString [ebp + 36]			;print "(" for EC
	push	ebx							;send line number to writeVal
	push	[ebp + 32]					;send tempString to writeVal
	call	writeVal
	displayString [ebp + 20]			;display subtotal message for EC
	mov		edx, [ebp + 16]				;grab subtotal
	mov		eax, [edx]					
	push	eax							;push subtotal for writeVal printing
	push	[ebp + 32]					;push tempString
	call	writeVal
	
	push	[ebp + 28]					;push error message
	push	edi							;push current numArray index address
	push	[ebp + 24]					;push prompt2
	push	[ebp + 12]					;push userNum string
	call	readVal						;request and validate input
	
	mov		eax, [edi]					;get the value at the current numArray index
	cmp		eax, -1						;compare to the signal value: if -1, entry was not valid, repeat
	je		inputLoop
	add		[edx], eax					;eax holds current subtotal, add new number
	add		edi, 4						;increment index
	inc		ebx							;increment line number
	loop	inputLoop

	call	CrLf

	pop		edx							;restore registers
	pop		ecx
	pop		ebx
	pop		eax
	pop		edi
	pop		ebp
	ret		32							;clean up stack from variables

getNumbers ENDP


;-------------------------------------------------------------------------------- 
; readVal
; Description: Procedure to get input from user, validate and convert to number
; Receives: address of userNum, prompt2, address of current numArray index, errorMsg
; Returns: if user input is valid, it is converted and stored in given numArray index
; Preconditions: numArray index is valid
; Registers changed: none
;--------------------------------------------------------------------------------
readVal PROC
	push	ebp							;set up stack frame and save registers
	mov		ebp, esp
	push	edi
	push	esi
	push	eax
	push	ebx
	push	edx

	getString [ebp + 12], [ebp + 8]		;get number from user, pass prompt2 and userNum strings
	mov		esi, [ebp + 8]				;put user entry in esi to use LODSB
	mov		edi, [ebp + 16]				;address of current numArray index
	mov		edx, 0						;clear values for validation
	mov		eax, 0
	mov		ebx, 0
		
validate:
	cld									;clear direction flag so that we move left to right
	LODSB
	cmp		al, 00h						;finished when we hit null terminator
	je		doneChecking
	sub		al, 48						;subtract 48 to get integer ASCII code, if not 0-9, not valid
	cmp		al, 0
	jb		errorMessage
	cmp		al, 9
	ja		errorMessage				;not in the range 0-9, not valid
	push	eax							;using method of taking individual digits, multiplying by 10 and adding from lecture 23
	mov		eax, ebx					;ebx starts at 0 outside loop, next iteration will hold current value from last iteration
	mov		ebx, 10
	mul		ebx
	jo		overflowError				;if we hit overflow, num is too big
	mov		ebx, eax					;move the result to ebx to make room in eax
	pop		eax							;pop original number and add
	add		ebx, eax
	jc		errorMessage				;if we hit carry, num is too big
	mov		eax, 0						;reset eax for next round
	inc		edx							;count values
	jmp		validate

doneChecking:
	cmp		edx, 0						;no values, empty string, not valid
	je		errorMessage
	cmp		ebx, MININT					;should not hit this with current set up, but just for redundancy
	jb		errorMessage
	cmp		ebx, MAXINT					;should catch with overflow jump, but just in case
	ja		errorMessage
	mov		eax, ebx
	mov		[edi], eax					;put validated number in array
	jmp		exitLoop					;skip error message
	
overflowError:
	pop		eax							;pop eax to restore stack balance

errorMessage:
	call	CrLf
	displayString	[ebp + 20]			;display error message
	call	CrLf

exitLoop:
	pop		edx							;restore registers
	pop		ebx
	pop		eax
	pop		esi
	pop		edi
	pop		ebp
	ret		16							;clean up stack from variables

readVal ENDP


;-------------------------------------------------------------------------------- 
; writeVal
; Description: Procedure to convert numbers to strings and display them. Divides
;				repeatly by 10 and pushes remainder on stack to get the number
; Receives: value to be converted, tempString
; Returns: tempString holds string just printed, but will be overwritten each use
; Preconditions: value is a number
; Registers changed: none
;--------------------------------------------------------------------------------
writeVal PROC
	push	ebp							;set up stack frame and save registers
	mov		ebp, esp
	push	edi
	push	eax
	push	ebx
	push	edx

	mov		edi, [ebp + 8]				;pull tempString into edi
	mov		eax, [ebp + 12]				;put value to be converted into eax
	mov		ebx, 10						;use 10 for division for converting, using reverse of readVal method above
	push	00h							;signal value to stop, also null terminator for string

pushLoop:								;use stack to push remainder of division by 10, then pop back to convert
	mov		edx, 0						;clear edx
	div		ebx
	add		edx, 48						;add 48 to division remainder to get ASCII value for string
	push	edx							;push value onto stack. Top will be leftmost digit
	cmp		eax, 0						;division resulting in 0 means we hit the last digit
	ja		pushLoop

popLoop:								;top of stack is leftmost digit, bottom of string is 00h
	pop		eax
	cld
	STOSB								;pop and place into tempString to form string version of number
	cmp		eax, 00h					;once eax holds 00h, string is done
	je		endPop
	jmp		popLoop

endPop:
	displayString [ebp + 8]				;call macro to display the value as a string

	pop		edx							;restore registers
	pop		ebx
	pop		eax
	pop		edi	
	pop		ebp
	ret		8							;clean up stack from value and temp string

writeVal ENDP


;-------------------------------------------------------------------------------- 
; calcAverage
; Description: Procedure to calculate the average value of numbers entered
; Receives: sum, address of numAvg
; Returns: average is placed into numAvg
; Preconditions: sum must be calculated
; Registers changed: none
;--------------------------------------------------------------------------------
calcAverage PROC
	push	ebp							;set up stack frame and save registers
	mov		ebp, esp
	push	edi
	push	eax
	push	ebx
	push	edx

	mov		edi, [ebp + 8]				;put address of numAvg in edi
	mov		eax, [ebp + 12]				;put value of sum in eax
	mov		ebx, 10						;we know we have 10 numbers
	mov		edx, 0						;clear edx for division
	div		ebx
	mov		[edi], eax					;ignore edx for rounding, place value in numAvg

	pop		edx							;restore registers
	pop		ebx
	pop		eax
	pop		edi
	pop		ebp
	ret		8							;clean up stack from messages

calcAverage ENDP


;-------------------------------------------------------------------------------- 
; displayResults
; Description: Procdure to print the numbers entered, the sum and the average
; Receives: sum, numAvg, addresses of: numArray, tempString, commas, arrayMsg, sumMsg, averageMsg
; Returns: none
; Preconditions: sum and numAvg are calculated, numArray is full
; Registers changed: none
;--------------------------------------------------------------------------------
displayResults PROC								
	push	ebp							;save registers
	mov		ebp, esp
	push	edi
	push	eax
	push	ecx

	displayString [ebp + 16]			;display array message
	call	CrLf
	mov		edi, [ebp + 24]				;grab numArray
	mov		ecx, 10

arrayPrint:								;loop to print each number in array
	mov		eax, [edi]
	push	eax							;push value for writeVal
	push	[ebp + 28]					;push tempString
	call	WriteVal
	add		edi, 4						;increment to move to next
	cmp		ecx, 1						;compare so comma is not placed after last number
	je		arrayDone
	displayString [ebp + 20]			;print ", " after each number except last
	loop	arrayPrint

arrayDone:
	call	CrLf

	displayString [ebp + 12]			;display sum message
	push	[ebp + 32]					;push sum for writeVal
	push	[ebp + 28]					;push tempString
	call	writeVal
	call	CrLf

	displayString [ebp + 8]				;display average message
	push	[ebp + 36]					;push numAvg for writeVal
	push	[ebp + 28]					;push tempString
	call	writeVal
	call	CrLf

	pop		edi							;restore registers
	pop		eax
	pop		ecx
	pop		ebp
	ret		32							;clean up stack from variables

displayResults	ENDP


;-------------------------------------------------------------------------------- 
; goodbye
; Description: Procedure to print the program ending message and exits the program.
; Receives: address of goodbyeMsg
; Returns: none
; Preconditions: program completes
; Registers changed: none 
;--------------------------------------------------------------------------------
goodbye PROC
	push	ebp								;set up stack frame
	mov		ebp, esp

	call	CrLf
	displayString [ebp + 8]					;pull address of goodbye message
	call	CrLf

	pop		ebp
	ret		4								;clean up stack from message

goodbye ENDP


END main