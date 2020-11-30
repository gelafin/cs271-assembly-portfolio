TITLE "String Primitives and Macros"     (Proj6_mendemar.asm)

; Author: Mark Mendez
; Last Modified: 11/29/2020
; OSU email address: mendemar@oregonstate.edu
; Course number/section: CS271 Section 400
; Project Number: 6                Due Date: 12/6/2020
; Description: displays a list of validated user integers, with their sum and average

INCLUDE Irvine32.inc
MAXSIZE     = 30							; max chars/bytes of user string, including null terminator
TESTCOUNT   = 10                            ; length of userInts array and loop counter for testing

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints a given string to the terminal
;
; Receives:
;   stringOffset = address of array
; ---------------------------------------------------------------------------------
mDisplayString MACRO stringOffset:REQ
  push  EDX

  mov	EDX, stringOffset
  call	WriteString

  pop   EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Gets a string of input from the user and saves it to memory
;
; Postconditions:
;   mGetString uses Irvine32::ReadString, so chars may be truncated
;
; Receives:
;   userStringOffset   = address of string array to store input
;   userStringSize     = DWORD length of userStringOffset
;   promptOffset       = address of string array prompt to display when asking for user's input
;   charsEnteredOffset = address of DWORD to store number of characters captured
;
; returns: 
;   [charsEnteredOffset] = number of characters captured
;   userStringOffset     = reference to string captured
; ---------------------------------------------------------------------------------
mGetString	MACRO userStringOffset:REQ, userStringSize:REQ, promptOffset:REQ, charsEnteredOffset:REQ
  push	EAX
  push	ECX
  push	EDX
  push	ESI
  push	EDI

  ; print prompt
  mov	EDX, promptOffset
  call	WriteString

  ; get user string
  mov	EDX, userStringOffset
  mov	ECX, userStringSize
  call	ReadString
  mov	EDI, charsEnteredOffset
  mov	[EDI], EAX

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

; ---------------------------------------------------------------------------------
; Name: mConvertIntToString
;
; Converts a given integer value to its ASCII code equivalent
;
; Preconditions: integer is validated
;
; Receives:
;   userInt             = DWORD integer to print
;   userStringOutOffset = address of byte array to use for return
;   digitsEntered       = DWORD number of digits in userInt
;
; returns: 
;   userStringOutOffset = reference to string of ASCII codes representing userInt's digits
; ---------------------------------------------------------------------------------
mConvertIntToString MACRO userInt:REQ, userStringOutOffset:REQ, digitsEntered:REQ
  LOCAL _convertNext

  push  EAX
  push  EBX
  push  ECX
  push  EDX
  push  EDI

  mov   EDI, userStringOutOffset  ; EDI = address of array return value
  add   EDI, digitsEntered        ; move pointer to prepare for writing backwards
  dec   EDI				     	  ; EDI was already pointing at the first element before adding digitsEntered

  mov	ECX, digitsEntered        ; excludes "-" if any
  mov   EAX, userInt		      ; EAX = the first number to divide

  ; divide the param by 10. Quotient is the next thing to be divided, and remainder is the rightmost digit
  _convertNext:  
    mov   EBX, 10
    cdq
    idiv  EBX					   ; now EAX contains the next thing to divide, and EDX contains rightmost digit

    push  EAX
    mov   AL, DL				   ; no data is lost, because each converted result is only 1 byte
    add	  AL, '0'			       ; convert to string

    ; AL contains ASCII value to be appended to the BYTE array string
    ; store AL into EDI (from right to left using std)
    std
    stosb						   ; [EDI] = digit as char, then EDI--

    pop	  EAX
    loop  _convertNext

  pop   EDI
  pop   EDX
  pop   ECX
  pop   EBX
  pop   EAX
ENDM

; ---------------------------------------------------------------------------------
; Name: mGetDigitCount
;
; Counts the number of digits in a given integer and stores the result
;
; Preconditions: integer is validated
;
; Receives:
;   integer          = DWORD integer whose digits need counting
;   digitCountOffset = address of DWORD to store number of digits in integer
;
; returns: 
;   [digitCountOffset] = number of digits in integer
; ---------------------------------------------------------------------------------
mGetDigitCount MACRO integer:REQ, digitCountOffset:REQ
    LOCAL _countDigitsOfNegative, _countDigitsOfPositive, _gotDigitCount, digits  
  .data
    digits  DWORD   0
  .code
    push EAX
    push EBX
    push ECX
    push EDI

    mov  ECX, 10                           ; maximum of 10 digits in a 32-bit mem
    mov  digits, 1                         ; sum guaranteed to have at least 1 digit
    mov  EAX, -9                           ; comparator (changed to start at 9 for positive sum)

    cmp  integer, 0
    jl   _countDigitsOfNegative            ; if sum is negative, _countDigitsOfNegative
    mov  EAX, 9                            ; else, sum is positive; start comparing from 9

    _countDigitsOfPositive:
      cmp  integer, EAX
      jle  _gotDigitCount                  ; break if number of digits is known
  
      ; maintain loop
      inc  digits
  
      mov  EBX, 10                         ; add a 9 digit to comparator (multiply by 10 and add 9)
      mul  EBX
      add  EAX, 9

      loop _countDigitsOfPositive

    _countDigitsOfNegative:
      cmp  integer, EAX
      jg   _gotDigitCount                   ; break if number of digits is known

      ; maintain loop
      inc  digits
  
      mov  EBX, 10                          ; add a 9 digit to comparator (multiply by 10 and sub 9)
      mul  EBX
      sub  EAX, 9

      loop _countDigitsOfNegative

    _gotDigitCount:
      ; return the digit count
      mov   EDI, digitCountOffset
      mov   EAX, digits
      mov   [EDI], EAX

    pop   EDI
    pop   ECX
    pop   EBX
    pop   EAX
ENDM

; ---------------------------------------------------------------------------------
; Name: mClearArray
;
; Clears all elements of a given array
;
; Preconditions: arrayLength is validated
;
; Receives:
;   arrayOffset = address of array to clear
;   arrayLength = DWORD length of array to clear
;
; returns: 
;   arrayOffset = reference to a now empty array
; ---------------------------------------------------------------------------------
mClearArray MACRO arrayOffset:REQ, arrayLength:REQ
  push EAX
  push ECX
  push EDI

  ; prepare preconditions for rep stosb
  mov  EAX, 0
  mov  ECX, arrayLength
  mov  EDI, arrayOffset

  ; clear all elements of userStringOut
  rep  stosb

  pop  EDI
  pop  ECX
  pop  EAX
ENDM

.data
; first used in Main
header			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",10,13
				BYTE	"Programmed by Mark Mendez",10,13,10,13,0									
intro			BYTE	"Please provide 10 signed decimal integers.",10,13							; instructions and explanation of program
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register. "
				BYTE	"After you have finished inputting the raw numbers I will display a "
				BYTE	"list of the integers, their sum, and their average value.",10,13,10,13,0
userInts        SDWORD  TESTCOUNT DUP(?)                                                            ; array of userInt values
charLengths  	DWORD	TESTCOUNT DUP(?)															; array of charLenth values
youEntered		BYTE	"You entered the following numbers: ",0
theSumIs		BYTE	"The sum of these numbers is: ",0
theAvgIs		BYTE	"The rounded average is: ",0
thanks			BYTE	"Thanks for playing! I had so much fun",0

; first used in ReadVal
prompt			BYTE	"Please enter a signed number: ",0
userString		BYTE	MAXSIZE DUP(?)
userStringSize	DWORD	LENGTHOF userString															
invalidErrorMsg	BYTE	"ERROR: You did not enter a signed number or your number was too big.",10,13,0
tryAgain		BYTE	"Please try again: ",0
userInt 		SDWORD	?																	        
charsEntered    DWORD   ?                                                                           ; number of characters (includes sign)

; first used in WriteVal
digitsEntered   DWORD   ?                                                                           ; number of digits (excludes sign)
separator       BYTE    ", ",0
string2EXP31    BYTE    "-2147483648",0
negativeSign    BYTE    45,0
userStringOut	BYTE	MAXSIZE DUP(?)

; first used in sumArray
sum             SDWORD  ?

; first used in averageArray
average         SDWORD  ?

.code
main PROC
; --------------------------
; Print header
;
; --------------------------
  mov  EDX, OFFSET header
  call WriteString

; --------------------------
; Print intro
;
; --------------------------
  mov  EDX, OFFSET intro
  call WriteString

; --------------------------
; Test ReadVal by interacting with user to get some (TESTCOUNT) integers.
;   Validate the integers while getting them, printing an error message if invalid.
;   Store the validated integers in an array.
;   Since WriteVal requires knowing the digit count of each number, store the digit
;   count of each number in another array
;   
; --------------------------
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

; --------------------------
; Test WriteVal by printing the integers gathered by ReadVal,
;   using the digit count gathered by ReadVal's loop in Main as
;   the corresponding argument for WriteVal
;
; --------------------------
  call CrLf
  mov  EDX, OFFSET youEntered
  call WriteString

  ; prepare for loop
  mov  ESI, OFFSET userInts
  mov  ECX, TESTCOUNT
  mov  EDI, OFFSET userStringOut
  mov  EBX, OFFSET charLengths

  _testWrite:
    push EAX
    mov  EAX, [ESI]
    mov  userInt, EAX                     ; userInt = userInts[index]
    mov  EAX, [EBX]
    mov  digitsEntered, EAX               ; digitsEntered = charLengths[index]
    pop  EAX

    ; convert userInt to ASCII string and print
    push OFFSET string2EXP31
    push OFFSET negativeSign
    push EDI                              ; EDI == OFFSET userStringOut
    push OFFSET digitsEntered             ; already accounts for not including sign
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
      mClearArray OFFSET userStringOut, LENGTHOF userStringOut
      loop _testWrite

; --------------------------
; Sum the numbers gathered by ReadVal, and print the sum
;
; --------------------------
  push OFFSET sum
  push LENGTHOF userInts
  push OFFSET userInts
  call sumArray

  ; get digit count of sum
  mGetDigitCount sum, OFFSET digitsEntered

  ; print the sum
  call CrLf
  call CrLf
  mov  EDX, OFFSET theSumIs
  call WriteString

  push OFFSET string2EXP31
  push OFFSET negativeSign
  push OFFSET userStringOut
  push OFFSET digitsEntered               ; obtained above in mGetDigitCount
  push sum
  call WriteVal

; --------------------------
; Average the numbers gathered by ReadVal, and print the average
;
; --------------------------
  mov  EAX, sum
  mov  EBX, TESTCOUNT
  cdq
  idiv  EBX
  mov  average, EAX                       ; average = sum // TESTCOUNT

  ; get digit count of average
  mGetDigitCount average, OFFSET digitsEntered

  ; clear userStringOut to prepare for another WriteVal
  mClearArray OFFSET userStringOut, LENGTHOF userStringOut

  ; print average
  call CrLf
  call CrLf
  mov  EDX, OFFSET theAvgIs
  call WriteString

  push OFFSET string2EXP31
  push OFFSET negativeSign
  push OFFSET userStringOut               
  push OFFSET digitsEntered               ; obtained above in mGetDigitCount
  push average
  call WriteVal

; --------------------------
; Print goodbye message
;
; --------------------------
  call CrLf
  call CrLf
  mDisplayString OFFSET thanks

  Invoke ExitProcess,0	; exit to operating system
main ENDP
; ---------------------------------------------------------------------------------
; Name: sumArray
;
; prints the sum of numbers in a given integer array to the terminal
;
; Preconditions: 
;   integers are validated
;   total sum of integers fits inside a 32-bit SDWORD
;
; Postconditions:
;	userStringOut = string of ascii codes representing the integer param
;
; Receives:
;   [ebp+8]  = OFFSET userInts: offset of array of integers to print
;   [ebp+12] = LENGTHOF userInts: number of elements in userInts
;   [ebp+16] = OFFSET sum: SDWORD to store sum of integers
;
; Returns:
;   [ebp+16] = sum of integers
;
; ---------------------------------------------------------------------------------
sumArray PROC
local total:SDWORD
  ; local directive executes...
  ;   push	EBP
  ;   mov	EBP, ESP
  push  EAX
  push  EBX
  push  ECX
  push  ESI

  mov   ESI, [EBP+8]        ; ESI = OFFSET userInts
  mov   ECX, [EBP+12]       ; ECX = LENGTHOF userInts
  mov   EBX, 0              ; initialize de facto accumulator
  ; loop through ESI, adding each userInt to EAX
  _next:
    cld
    lodsd                   ; EAX = userInts[index]
    add   EBX, EAX          ; total += userInts[index]

    loop _next

  ; return sum
  mov   EDI, [EBP+16]       ; EDI = OFFSET sum
  mov   [EDI], EBX          ; sum = total

  pop   ESI
  pop   EBX
  pop   ECX
  pop   EAX
  ; local directive executes: pop EBP
  ret   12

sumArray ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; prints a given integer to the terminal
;
; Preconditions: 
;   integer is validated
;   all elements of userStringOut are clear
;
; Postconditions:
;	userStringOut = string of ascii codes representing the integer param
;
; Receives:
;   [ebp+8]  SDWORD = integer to print (32 bits or fewer)
;	[ebp+12] DWORD  = OFFSET digitsEntered: number of digits in integer to print
;	[ebp+16] DWORD  = OFFSET userStringOut
;   [ebp+20] DWORD  = OFFSET negativeSign: memory location of ascii code of negative sign
;   [ebp+24] DWORD  = OFFSET string2EXP31
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
  push  ESI
  push	EDI

  ; special treatment for -2^31, which causes overflow during NEG
  mov   EAX, [EBP+8]
  cmp   EAX, -2147483648
  jne   _checkNegative                    ; if it's not that value, continue to next check
  mov   EDI, [EBP+16]                     ; EDI = OFFSET userStringOut
  mov   ESI, [EBP+24]
  mov   ECX, 10                           ; prepare rep movsb: 10 digits in -2^31
  rep   movsb                             ; userStringOut array = "-2,147,483,648",0
  jmp   _printString

  _checkNegative:
  ; check if userInt is negative
  mov   EAX, [EBP+8]
  cmp   EAX, 0
  jge   _numberIsPositive	              ; number is positive! Move on and convert to string

  ; number is negative; undo processing from earlier and assign 2's comp to EAX
  ; print a negative sign
  mov	EDX, [EBP+20]		              ; EDX = (ascii for "-")
  call	WriteString

  ; convert negative number to positive
  mov   EAX, [EBP+8]                      ; EAX = abs(userInt)
  neg   EAX                               

  ; skip numberIsPositive section
  jmp _convertToString

  ; else, it's already positive, so assign directly to EAX
  _numberIsPositive:
  mov   EAX, [EBP+8]		              ; EAX = the first number to divide

  _convertToString:
  push  ESI
  mov   ESI, [EBP+12]
  mConvertIntToString EAX, [EBP+16], [ESI]   ; convertIntToString(userInt, OFFSET userStringOut, digitsEntered)
  pop   ESI

  _printString:
  ; print the string
  mDisplayString [EBP+16]                 ; mDisplayString(OFFSET userStringOut)

  pop	EDI
  pop   ESI
  pop	EDX
  pop	ECX
  pop	EBX
  pop	EAX
  ; local directive executes: pop	EBP
  ret   20
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
  mGetString [EBP+8], [EBP+12], [EBP+20], [EBP+24]
  
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

  ; TODO:* if bounds validation in below TODO fails, use VALDIATE: now that ESI is past sign, validate the rest of the string by comparing each digit's ascii code to the boundary numbers' ascii codes
  ;   Then, pop ESI pointer

  ; convert the digits in the string to number form
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
  ; ASCII value is for an integer
  ; Convert ascii value, append it, and loop to next char  
  ; convert via: finalInteger = 10 * finalInteger + (asciiValue - 48)
    ; AL = asciiValue of next char of userString
    ; EBX = finalInteger
  ; EBX = EBX * 10 + (AL - 48)
  
  sub	AL, 48		        ; AL - 48 (aka, nextDigit to add)
  mov	DL, AL
  
  push	EAX				    ; save EAX
  mov	EAX, 10
  push	EDX				    ; preserve temp EDX for mul
  imul	EBX				    ; EAX = EBX * 10

  ; VALIDATE: IMUL increases total, so make sure result fits in 32-bit signed reg/mem
  jc    _invalidInput
  jo    _invalidInput

  mov	EBX, EAX		    ; EBX = EAX
  pop	EDX				    ; restore EDX after mul
  pop	EAX				    ; restore EAX

  push	EBX
  movzx EBX, DL
  mov   EDX, EBX		    
  pop	EBX
  add	EBX, EDX		    

  ; VALIDATE: ADD increases total at LSB, so make sure result fits in 32-bit signed reg/mem
  jc    _carryOverflow
  jo    _carryOverflow
  jmp   _maintainLoop

  _carryOverflow:
    cmp   isNegative, 1     ; compare isNegative to 1 (true)
    jne   _invalidInput     ; negative limit gets one more chance for the edge case of -2^31

    cmp   DL, 8             ; is the final digit an 8 (which is the final digit of -2^31)?
    je   _maintainLoop

    jmp _invalidInput       ; value isn't -2^31, so now it fails validation

  _maintainLoop:
    cld					    ; iterate left to right
    lodsb				    ; MOV AL, [ESI] then inc ESI

  loop _buildInt

  ; if isNegative, subtract value (EBX) from 0
  cmp   isNegative, 1       ; compare isNegative to 1 (true)
  jne	_saveAsUserInt	    ; nothing to do here if not equal--it's positive!

  ; number should be negative, so negate value
  neg   EBX

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
