TITLE "String Primitives and Macros"     (Proj6_mendemar.asm)

; Author: Mark Mendez
; Last Modified: 11/23/2020
; OSU email address: mendemar@oregonstate.edu
; Course number/section: CS271 Section 400
; Project Number: 6                Due Date: 12/6/2020
; Description: displays a list of validated user integers, with their sum and average

INCLUDE Irvine32.inc
MAXSIZE = 3							; max chars/bytes of user string


mDisplayString MACRO stringOffset:REQ
  mov	EDX, stringOffset
  call	WriteString
ENDM

mGetString	MACRO userStringOffset:REQ, userStringLength:REQ, invalidInputMsgOffset:REQ, promptOffset
  LOCAL _getUserString, _gotValidInput

  ; preserve registers
  push	EAX
  push	ECX
  push	EDX
  push	ESI
  push	EDI

  ; print prompt
  mov	EDX, promptOffset
  call	WriteString

  ; get user string
  _getUserString:
  mov	EDX, userStringOffset
  mov	ECX, userStringLength
  call	ReadString
 ; mov	inputCharCount, EAX

  TODO1: ; call bool number validation proc inside this validation loop

  TODO: ; may not have to validate string length
  ; if user string is too big (inputCharCount > ECX), get another string
  ;  cmp	inputCharCount, ECX
  cmp	EAX, ECX
  jbe	_gotValidInput
  
  ; else, not valid input
  mov	EDX, invalidInputMsgOffset
  call	WriteString
  jmp	_getUserString

  _gotValidInput:
  ; save user string to memory
  mov	ESI, EDX
  mov	EDI, userStringOffset
  cld
  rep	movsb

  pop	EDI
  pop	ESI
  pop	EDX
  pop   ECX
  pop	EAX
ENDM

.data
header			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",10,13
				BYTE	"Programmed by Mark Mendez",10,13,10,13,0									
intro			BYTE	"Please provide 10 signed decimal integers.",10,13							; instructions and explanation of program
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register."
				BYTE	"After you have finished inputting the raw numbers I will display a "
				BYTE	"list of the integers, their sum, and their average value.",10,13,10,13,0

prompt			BYTE	"Please enter a signed number: ",0
userString		BYTE	MAXSIZE DUP(?)
userStringLen	DWORD	LENGTHOF userString															; length including null terminator
invalidErrorMsg	BYTE	"ERROR: You did not enter a signed number or your number was too big.",10,13,0
tryAgain		BYTE	"Please try again: ",0

youEntered		BYTE	"You entered the following numbers: ",10,13,0
theSumIs		BYTE	"The sum of these numbers is: ",0
theAvgIs		BYTE	"The rounded average is: ",0

thanks			BYTE	"Thanks for playing! I had so much fun",0

.code
main PROC
  ; get valid number from user
  call ReadVal

  ; convert DWORD integer to ASCII string and print
;  push 5
;  call WriteVal

  ; print goodbye message
  call CrLf
  mDisplayString OFFSET thanks

  Invoke ExitProcess,0	; exit to operating system
main ENDP
; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; prints a given integer to the terminal
;
; Preconditions: 
;
; Receives:
;   [ebp+8]  = integer to print (32 bits or fewer)
; ---------------------------------------------------------------------------------
WriteVal PROC
  push	EBP
  mov	EBP, ESP
  push	EAX
  push  ECX

  mov	EAX, [EBP+8]		; EAX now contains user number
  mov	ECX, 8				; TODO: replace with LENGTHOF userNumber (# of digits)
  
  ; check each bit until nonzero value--this is the beginning of what needs to be printed
  _advanceToNonzero:
  

  ; if no nonzero value, print 0 and jump to _print
  ; else, continue to _convert

  _convert:
  ; for each digit, add 48 to convert from integer to the ASCII code for that integer
  

  ; after conversion, AL contains ASCII value to be appended to the BYTE array string
  ;stosb

  loop	_convert

  _print:
  ; print the string
  ;mDisplayString OFFSET EDX

  pop	ECX
  pop	EAX
  pop	EBP
  ret   4
WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; reads a given integer from the terminal
;
; Preconditions: 
;
; Receives:
;   [ebp+8]  = integer to print (32 bits or fewer)
;	[ebp+12] = OFFSET userString
;	[ebp+16] = LENGTHOF userString
; ---------------------------------------------------------------------------------
ReadVal PROC
  push	EBP
  mov	EBP, ESP
  push	ESI

  ; get user string and save to userString
  mGetString OFFSET userString, userStringLen, OFFSET invalidErrorMsg, OFFSET prompt
  
  ; TODO: how to access userString to assign to ESI?

  ; convert userString to SDWORD int
  mov	ECX, [EBP+16]

  _printInt:
  ; get next digit of the string into AL
  mov	ESI, [EBP+12]  ; ESI now contains OFFSET userString
  cld
  lodsb				   ; MOV AL, [ESI] then inc ESI

  loop _printInt


  pop   ESI
  pop	EBP
  ret 4
ReadVal ENDP
END main
