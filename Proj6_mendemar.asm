TITLE "String Primitives and Macros"     (Proj6_mendemar.asm)

; Author: Mark Mendez
; Last Modified: 11/23/2020
; OSU email address: mendemar@oregonstate.edu
; Course number/section: CS271 Section 400
; Project Number: 6                Due Date: 12/6/2020
; Description: displays a list of validated user integers, with their sum and average

INCLUDE Irvine32.inc
MAXSIZE     = 30							; max chars/bytes of user string, including null terminator
TESTCOUNT   = 10                            ; length of userInts array and loop counter for testing

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
userInt 		SDWORD	?																	        ; int value after conversion from string
charsEntered    DWORD   ?                                                                           ; how many characters long a given number is
charLengths  	DWORD	TESTCOUNT DUP(?)															; how many characters long each number is. TODO: rename to digitLengths

digitsEntered   DWORD   ?                                                                           ; holds a given value of charLengths for testing
userInts        SDWORD  TESTCOUNT DUP(?)                                                            ; used for testing
separator       BYTE    ", ",0

negativeSign    BYTE    45,0
userStringOut	BYTE	MAXSIZE DUP(?)

youEntered		BYTE	"You entered the following numbers: ",0
theSumIs		BYTE	"The sum of these numbers is: ",0
theAvgIs		BYTE	"The rounded average is: ",0

thanks			BYTE	"Thanks for playing! I had so much fun",0

.code
main PROC
  ; get 10 valid inputs
  mov  ECX, TESTCOUNT
  mov  EDI, OFFSET userInts
  mov  EBX, OFFSET charLengths

  _testRead:
    ; get valid number from user
    push EBX                              ; address of first empty element in charLengths
    push OFFSET userInt
    push OFFSET charsEntered
    push OFFSET prompt
    push OFFSET invalidErrorMsg
    push userStringSize
    push OFFSET userString
    call ReadVal

    ; append userInt to array
    push EAX
    mov  EAX, userInt
    mov  [EDI], EAX
    pop  EAX

    ; maintain test loop
    add  EDI, TYPE userInts               ; move userInts pointer to next element
    add  EBX, TYPE charLengths            ; move charLengths pointer to next element
    loop _testRead

  ; print the 10 integers
  call CrLf
  mov  EDX, OFFSET youEntered
  call WriteString

  ; prepare for loop
  mov  ESI, OFFSET userInts                ; ESI = array of numbers to print
  mov  ECX, TESTCOUNT

  mov  EBX, OFFSET charLengths
  _testWrite:
    ; userInt = [ESI]. For test
    push EAX
    mov  EAX, [ESI]
    mov  userInt, EAX                      ; userInt = userInts[index]
    mov  EAX, [EBX]
    mov  digitsEntered, EAX                ; digitsEntered = charLengths[index]. For test
    pop  EAX

    ; convert userInt to ASCII string and print
    push OFFSET negativeSign
    push OFFSET userStringOut
    push digitsEntered                       ; already accounts for not including sign
    push userInt
    call WriteVal

    ; print a separator (e.g., comma and space) unless it's the last element
    cmp  ECX, 1
    je   _noSeparator
    mov  EDX, OFFSET separator
    call WriteString

    _noSeparator:
    ; maintain test loop
    add  ESI, TYPE userInts               ; move userInts pointer to next element
    add  EBX, TYPE charLengths            ; move charLengths pointer to next element
    loop _testWrite

  ; print goodbye message
  call CrLf
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
;	[ebp+12] DWORD  = digitsEntered: number of digits in integer to print
;	[ebp+16] DWORD  = OFFSET userStringOut
;   [ebp+20] DWORD  = OFFSET negativeSign: memory location of ascii code of negative sign
;
; ---------------------------------------------------------------------------------
WriteVal PROC
  local isNe:BYTE
  ; local directive executes...
  ;   push	EBP
  ;   mov	EBP, ESP

  push	EAX
  push	EBX
  push  ECX
  push	EDX
  push	EDI

  mov	ECX, [EBP+12]           ; ECX = charsEntered (including "-" if any)
  mov	EDI, [EBP+16]		    ; EDI = OFFSET userStringOut
  mov   [EDI], DWORD PTR 0      ; clear userStringOut to make sure old digits aren't written by mDisplayString
  add   EDI, digitsEntered	    ; move pointer to prepare for writing backwards
  dec   EDI				     	; EDI was already pointing at the first element before adding charsEntered

  ; check if userInt is negative
  cmp   userInt, 0
  jge   _numberIsPositive	    ; number is positive! Move on and convert to string

  ; number is negative; undo processing from earlier and assign 2's comp to EAX
  ; print a negative sign
  mov	EDX, [EBP+20]		    ; EDX = (ascii for "-")
  call	WriteString

  ; decrement loop counter and userStringOut pointer to account for not including the negative sign. TODO: remove?
;  dec   ECX
;  dec   EDI

  ; convert negative number to positive by subtracting from 0 TODO: need to use 0 - QWORD mem operand, not register. Asked about SBB
  ; if no SBB, make an absoluteValue proc to... 
  ;   1. apply two's comp (invert bits, then add 1)
  ;   2. clear the first bit and read back as a number

  mov   EAX, 0      		    ; EAX = 0
  mov   EBX, [EBP+8]            ; EBX = userInt
  sub   EAX, EBX                ; EAX = 0 - userInt

  ; skip numberIsPositive section
  jmp _convertNext

  ; else, it's already positive, so assign directly to EAX
  _numberIsPositive:
    mov   EAX, [EBP+8]		    ; EAX = the first number to divide

  ; divide the param by 10. Quotient is the next thing to be divided, and remainder is the rightmost digit  
  ; EAX is the first number to divide
  _convertNext:  
    mov   EBX, 10
    cdq
    idiv  EBX					; now EAX contains the next thing to divide, and EDX contains rightmost digit

    push  EAX					; save next number to divide
    mov   AL, DL				    ; no data is lost, because each converted result is only 1 byte
    add	  AL, '0'			    ; convert to string

    ; AL contains ASCII value to be appended to the BYTE array string
    ; store AL into EDI (from right to left using std)
    std
    stosb						; [EDI] = digitChar, then EDI--

    pop	  EAX					; restore next number to divide
    loop  _convertNext

  ; print the string
  mDisplayString [EBP+16]

  pop	EDI
  pop	EDX
  pop	ECX
  pop	EBX
  pop	EAX
  ; local directive executes: pop	EBP
  ret   16
WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; reads a given SDWORD integer from the terminal, handling + and - signs as appropriate
;
; Preconditions: 
;
; Receives:
;	[ebp+8]  = OFFSET userString
;	[ebp+12] = LENGTHOF userString
;	[ebp+16] = OFFSET invalidErrorMsg
;	[ebp+20] = OFFSET prompt
;	[ebp+24] = OFFSET charsEntered
;	[ebp+28] = OFFSET userInt: SDWORD to store integer entered by user
;   [ebp+32] = OFFSET charLengths (at index to save in): offset of first empty element in DWORD array storing the number of characters in each number
;
; Returns:
;	userInt SDWORD = integer entered by user
; ---------------------------------------------------------------------------------
ReadVal PROC
  local hasSign:BYTE, isNegative:BYTE, digitCount:DWORD
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
  mov	ESI, [EBP+24]       ; loop as many times as there are chars in what user entered
  mov	ECX, [ESI]		    ; ECX = charsEntered
  mov	EBX, 0			    ; tracks finalInteger
  mov	ESI, [EBP+8]	    ; ESI = OFFSET userString
  cld					    ; starting from the msb
  lodsb					    ; MOV AL, [ESI] then increment (due to cld) ESI

  ; got the first ascii value in AL
  ; VALIDATE: check if the first char is a +/- sign
  cmp	AL, 43		    	; is it a + sign?
  jne	_isNotPlusSign

  ; it is a plus sign. Skip to next char, since + sign is redundant
  mov   hasSign, 1          ; hasSign = 1 (true)
  cld
  lodsb
  dec	ECX		    		; start loop at next char, because first char's check is complete
  jmp	_buildInt		

  _isNotPlusSign:
  mov   isNegative, 0       ; isNegative = 0 (false)
  cmp	AL, 45  			; is it a - sign?

  ; if not negative, leave isNegative clear and _buildInt
  jne	_buildInt

  ; else, it is negative. Set isNegative and _buildInt. Final step will be to convert from positive to negative by 0 - value
  mov   hasSign, 1          ; hasSign = 1 (true)
  mov   isNegative, 1       ; isNegative = 1 (true)
  cld
  lodsb					    ; start loop at next char, beause first char's check is complete
  dec	ECX

  ; TODO: validate not out of bounds. Try using SQWORD and just jge 2^31-1
  ; else, VALDIATE: now that ESI points to first number, count the digits OR use SQWORD
  ;   ESI+charsEntered = lastDigit
  ;   lastDigit - ESI = digits
  ;   if hasSign, dec digits to account for sign, since only digits are to be counted
  ;   if digits > 10 (max digits of a SDWORD), can short circuit to _invalidInput

  ; convert the rest of the string to number form
  _buildInt:
  ; first char already loaded into AL for first iteration

  ; VALIDATE: is it a number (between 48-57 in ASCII)?
  cmp	AL, 48			    ; is it less than 48?
  jl	_invalidInput

  cmp	AL, 57			    ; is it more than 57?
  jg	_invalidInput

  jmp _validInput		    ; passed validation. Char is a number's ASCII code

  _invalidInput:
  mov	EDX, [EBP+16]	    ; print invalid error message
  call	WriteString
  jmp	_getUserString      ; go all the way back to square 1 and _getUserString afresh

  _validInput:
  ; TODO: make this loop into a helper function convertAsciiToInt

  ; ascii value is for an integer. Convert it, append it, and loop to next char  
  ; convert via: finalInteger = 10 * finalInteger + (asciiValue - 48)
    ; AL = asciiValue of next char of userString
    ; EBX = finalInteger
  ; EBX = EBX * 10 + (AL - 48)
  
  sub	AL, 48		        ; AL - 48 (aka, nextDigit to add)
;  mov	temp, AL		    ; temp = AL		TODO: make local nextDigit
  mov	DL, AL			    ;				TODO: delete after local nextDigit
  
  push	EAX				    ; save EAX
  mov	EAX, 10
  push	EDX				    ; preserve temp EDX for mul
  mul	EBX				    ; EAX = EBX * 10
  mov	EBX, EAX		    ; EBX = EAX
  pop	EDX				    ; restore EDX after mul
  pop	EAX				    ; restore EAX

;  add	EBX, DWORD PTR temp ; EBX = EBX + temp
  push	EBX
  movzx EBX, DL
  mov   EDX, EBX		    ;				TODO: maybe delete after local nextDigit
  pop	EBX
  add	EBX, EDX		    ;				TODO: delete after local nextDigit

  ; maintain loop
  cld					    ; iterate left to right
  lodsb				        ; MOV AL, [ESI] then inc ESI

  loop _buildInt

  ; if isNegative, subtract value (EBX) from 0
  cmp   isNegative, 1       ; compare isNegative to 1 (true)
  jne	_saveAsUserInt	    ; nothing to do here if not equal--it's positive!

  ; number should be negative, so negate value
  push	EAX
  mov	EAX, 0
  sub	EAX, EBX		    ; EAX = 0 - EBX
  mov	EBX, EAX		    ; EBX = EAX
  pop   EAX

  _saveAsUserInt:
  ; save finalInteger as userInt
  mov	EDI, [EBP+28]       ; EDI = OFFSET userInt
  mov	[EDI], EBX		    ; userInt = EBX

  ; save the number of digits in this number
  push  EAX
  mov   EAX, [EBP+24]       ; EAX = OFFSET charsEntered
  mov   EBX, [EAX]          ; digitCount = charsEntered
  mov   digitCount, EBX
  cmp   hasSign, 1          ; compare hasSign to 1 (true)
  pop   EAX
  jne   _saveDigitCount     ; if hasSign, decrement digit count before saving (to not include the sign)
  
  dec   digitCount

  _saveDigitCount:
  mov   EDI, [EBP+32]       ; charLengths (pointed to the right index by caller)
  mov   EBX, digitCount
  mov   [EDI], EBX          ; charLengths (at index) = digitCount

  pop   EDI
  pop   ESI
  pop	EDX
  pop	ECX
  pop	EBX
  pop	EAX
  ; local executes: pop EBP
  ret	20
ReadVal ENDP

END main
