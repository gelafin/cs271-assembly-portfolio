TITLE "String Primitives and Macros"     (Proj6_mendemar.asm)

; Author: Mark Mendez
; Last Modified: 11/23/2020
; OSU email address: mendemar@oregonstate.edu
; Course number/section: CS271 Section 400
; Project Number: 6                Due Date: 12/6/2020
; Description: displays a list of validated user integers, with their sum and average

INCLUDE Irvine32.inc
MAXSIZE = 30							; max chars/bytes of user string, including null terminator


mDisplayString MACRO stringOffset:REQ
  mov	EDX, stringOffset
  call	WriteString
ENDM

mGetString	MACRO userStringOffset:REQ, userStringSize:REQ, invalidInputMsgOffset:REQ, promptOffset, charsEnteredOffset
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
  mov	ECX, userStringSize
  call	ReadString
  mov	EDI, charsEnteredOffset
  mov	[EDI], EAX

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
userStringSize	DWORD	LENGTHOF userString															; size including null terminator
invalidErrorMsg	BYTE	"ERROR: You did not enter a signed number or your number was too big.",10,13,0
tryAgain		BYTE	"Please try again: ",0
userInt			SDWORD	?																			; int value after conversion from string
charsEntered	DWORD	?																			; how many characters the user entered

userStringOut	DWORD	?

youEntered		BYTE	"You entered the following numbers: ",10,13,0
theSumIs		BYTE	"The sum of these numbers is: ",0
theAvgIs		BYTE	"The rounded average is: ",0

thanks			BYTE	"Thanks for playing! I had so much fun",0

.code
main PROC
  ; get valid number from user
  push OFFSET userInt
  push OFFSET charsEntered
  push OFFSET prompt
  push OFFSET invalidErrorMsg
  push userStringSize
  push OFFSET userString
  call ReadVal

  ; convert DWORD integer to ASCII string and print
  call CrLf
  push OFFSET userStringOut
  push charsEntered
  push userInt
  call WriteVal

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
; Preconditions: integer is validated
;
; Postconditions:
;	userStringOut = string of ascii codes representing the integer param
;
; Receives:
;   [ebp+8]  SDWORD = integer to print (32 bits or fewer)
;	[ebp+12] DWORD  = number of digits in integer to print  TODO: subtract one if sign
;	[ebp+16] BYTE   = OFFSET userStringOut
;
; ---------------------------------------------------------------------------------
WriteVal PROC
  local userIntString
  ; local directive executes...
  ;   push	EBP
  ;   mov	EBP, ESP

  push	EAX
  push	EBX
  push  ECX
  push	EDX
  push	EDI

  mov	ECX, [EBP+12]
  ; TODO: if the first char is a sign, decrement ECX (will stop loop one early, which excludes first digit, since loop does RTL stosb )

  ; divide the param by 10. Quotient is the next thing to be divided, and remainder is the rightmost digit
  mov	EAX, [EBP+8]		; EAX = the first number to divide
  mov	EDI, [EBP+16]		; EDI = OFFSET userStringOut

  _convertToString:  
  mov	EBX, 10
  cdq
  idiv	EBX					; now EAX contains the next thing to divide, and EDX contains rightmost digit

  push	EAX					; save next number to divide
  mov	AL, DL				; no data is lost, because each converted result is only 1 byte
  add	AL, '0'			    ; convert to string

  ; AL contains ASCII value to be appended to the BYTE array string
  ; store AL into EDI (from right to left using std)
  std
  stosb						; [EDI].append(digitChar), then EDI--

  pop	EAX					; restore next number to divide
  loop	_convertToString

  ; print the string
  mDisplayString [EBP+16]	; TODO*****: see video at https://canvas.oregonstate.edu/courses/1784177/pages/exploration-1-lower-level-programming?module_item_id=20049973 
							; EBP+16's memory location is the START of the byte array, but std above wrote behind the start

  pop	EDI
  pop	EDX
  pop	ECX
  pop	EBX
  pop	EAX
  ; local directive executes: pop	EBP
  ret   8
WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; reads a given integer from the terminal, handling + and - signs as appropriate
;
; Preconditions: 
;
; Receives:
;	[ebp+8]  = OFFSET userString
;	[ebp+12] = LENGTHOF userString
;	[ebp+16] = OFFSET invalidErrorMsg
;	[ebp+20] = OFFSET prompt
;	[ebp+24] = OFFSET charsEntered
;	[ebp+28] = OFFSET userInt
;
; Returns:
;	userInt SDWORD = integer entered by user
; ---------------------------------------------------------------------------------
ReadVal PROC
  local isNegative:BYTE
  ; local executes...
  ;  push	EBP
  ;  mov	EBP, ESP

  push	EAX
  push	EBX
  push	ECX
  push	EDX
  push	ESI
  push	EDI

  ; get user string and save to userString
  _getUserString:
  mGetString [EBP+8], [EBP+12], [EBP+16], [EBP+20], [EBP+24]
  
  ; convert userString to SDWORD int
  mov	ESI, [EBP+24]   ; loop as many times as there are chars in what user entered
  mov	ECX, [ESI]		;   (cont)
  mov	EBX, 0			; tracks finalInteger
  mov	ESI, [EBP+8]	; ESI = OFFSET userString
  cld					; starting from the msb
  lodsb					; MOV AL, [ESI]

  ; got the first ascii value in AL. 
  ; VALIDATE: check if the first char is a +/- sign
  cmp	AL, 43			; is it a + sign?
  jne	_isNotPlusSign

  ; it is a plus sign. Skip to next char, since + sign is redundant
  cld
  lodsb
  dec	ECX				; start loop at next char, because first char's check is complete
  jmp	_buildInt		

  _isNotPlusSign:
  mov   isNegative, 0
  cmp	AL, 45			; is it a - sign?

  ; if not negative, leave isNegative clear and _buildInt
  jne	_buildInt

  ; else, it is negative. Set isNegative and _buildInt. Final step will be to convert from positive to negative by 0 - value
  mov	isNegative, 1
  cld
  lodsb					; start loop at next char, beause first char's check is complete
  dec	ECX

  ; convert the rest of the string to number form
  _buildInt:
  ; first char already loaded into AL for first iteration

  ; VALIDATE: is it a number (between 48-57 in ASCII)?
  cmp	AL, 48			; is it less than 48?
  jl	_invalidInput

  cmp	AL, 57			; is it more than 57?
  jg	_invalidInput

  jmp _validInput		; passed validation. Char is a number's ASCII code

  _invalidInput:
  mov	EDX, [EBP+16]	; print invalid error message
  call	WriteString
  jmp	_getUserString  ; go all the way back to square 1 and _getUserString afresh

  _validInput:
  ; TODO: make this loop into a helper function convertAsciiToInt

  ; ascii value is for an integer. Convert it, append it, and loop to next char  
  ; convert via: finalInteger = 10 * finalInteger + (asciiValue - 48)
    ; AL = asciiValue of next char of userString
    ; EBX = finalInteger
  ; EBX = EBX * 10 + (AL - 48)
  
  sub	AL, 48		    ; AL - 48 (aka, nextDigit to add)
;  mov	temp, AL		; temp = AL		TODO: make local nextDigit
  mov	DL, AL			;				TODO: delete after local nextDigit
  
  push	EAX				; save EAX
  mov	EAX, 10
  push	EDX				; preserve temp EDX for mul
  mul	EBX				; EAX = EBX * 10
  mov	EBX, EAX		; EBX = EAX
  pop	EDX				; restore EDX after mul
  pop	EAX				; restore EAX

;  add	EBX, DWORD PTR temp ; EBX = EBX + temp
  push	EBX
  movzx EBX, DL
  mov   EDX, EBX		;				TODO: maybe delete after local nextDigit
  pop	EBX
  add	EBX, EDX		;				TODO: delete after local nextDigit

  ; maintain loop
  cld					; iterate left to right
  lodsb				    ; MOV AL, [ESI] then inc ESI

  loop _buildInt

  ; if isNegative, subtract value (EBX) from 0
  cmp	isNegative, 1
  jne	_saveAsUserInt	; nothing to do--not negative!

  ; negate value
  push	EAX
  mov	EAX, 0
  sub	EAX, EBX		; EAX = 0 - EBX
  mov	EBX, EAX		; EBX = EAX
  pop   EAX

  _saveAsUserInt:
  ; save finalInteger as userInt
  mov	EDI, [EBP+28]   ; EDI = OFFSET userInt
  mov	[EDI], EBX		; userInt = EBX

  pop   EDI
  pop   ESI
  pop	EDX
  pop	ECX
  pop	EBX
  pop	EAX
  ; local executes: pop EBP
  ret	16
ReadVal ENDP

END main
