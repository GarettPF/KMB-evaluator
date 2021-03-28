; Author: Garett Pascual-Folster
; Section: CS 218 - 1002
; Date Last Modified: March 12
; Program Description: Repeatedly prompt user for KMB format numbers until "Quit"

section .data
;   System service call values
    SYSTEM_EXIT equ 60
    SYSTEM_WRITE equ 1
    SYSTEM_READ equ 0

    EXIT_SUCCESS equ 0
    STANDARD_OUT equ 1
    STANDARD_IN equ 0
    LINEFEED equ 10
    BUFFER_SIZE equ 100
    NULL_CHAR equ 0
    MAX_INTEGER_SIZE equ 999999999999

;   Variables
    prompt db "Enter a KMB value ('Quit' to exit program): ", NULL_CHAR
    errorMessage db "KMB value enter was invalid", LINEFEED, NULL_CHAR
    successMessage db "KMB value entered was valid", LINEFEED, NULL_CHAR
    quit db "Quit", NULL_CHAR
    KMBvalue dq 0

section .bss
    response resb BUFFER_SIZE

section .text
global main
main:

    mainLoop:
    ;   prompt user
        mov rdi, prompt
        mov rsi, response
        mov rdx, BUFFER_SIZE
        call promptUser

    ;   check if "Quit" was entered
        mov rdi, rsi
        mov rsi, quit
        call compareStrings
        cmp rax, 0
        je endProgram

    ;   Convert Number
        mov rsi, KMBvalue
        call convertKMB

    ;   Output if valid
        cmp rax, -1
        mov rdi, successMessage
        jne noError
            mov rdi, errorMessage
        noError:
        call printString
    jmp mainLoop

    endProgram:
    ; 	Ends program with success return value
        mov rax, SYSTEM_EXIT
        mov rdi, EXIT_SUCCESS
        syscall



; StringLength - get length of a string
; rdi - address to a string
; rax - return value = length
global stringLength
stringLength:
    mov rax, 0 ; counter = 0
    stringLengthLoop:
        mov cl, byte[rdi + rax]
        cmp cl, NULL_CHAR
        je stringLengthLoopEnd

        inc rax
    loop stringLengthLoop
    stringLengthLoopEnd:
    inc rax ; including the null
ret


; printString - prints the string...
; rdi - address to a string
global printString
printString:
    mov r8, rdi     ; save string
    call stringLength
    mov rcx, rax    ; save length

;   print the string
    mov rax, SYSTEM_WRITE
    mov rdi, STANDARD_OUT
    mov rsi, r8
    mov rdx, rcx
    syscall

ret


; promptUser - asks user for a response
; rdi - address to string to output
; rsi - address to string buffer to store response
; rdx - maximum accepted input size
; rax - return value = size of input / -1 error
global promptUser
promptUser:
;   store rsi & rdx
    push rsi
    push rdx

;   prompt user
    call printString

;   read input
    mov rax, SYSTEM_READ
    mov rdi, STANDARD_IN
    pop rdx
    pop rsi
    syscall

;   replace linefeed with null character
    mov byte[rsi + rax - 1], NULL_CHAR


;   check if input fits in buffer
    cmp rax, BUFFER_SIZE
    jne fitsInBuffer
    ;   data doesn't fit
        mov rax, -1
    fitsInBuffer:

ret


; compareStrings - compares two strings
; rdi - address to null terminated string
; rsi - address to null terminated string
; rax - return value = 
;      1, if first string is greater
;      0, if they are equal
;      -1, if second string is greater
global compareStrings
compareStrings:    
;   get lengths of strings
    call stringLength
    mov r8, rax ; string 1 len
    push rdi
    mov rdi, rsi
    call stringLength
    mov r9, rax ; string 2 len
    pop rdi

;   compare char by char
    mov rdx, 0 ; index = 0
    compareLoop:
        mov al, byte[rdi + rdx]
        mov cl, byte[rsi + rdx]

        cmp al, cl
        jg firstString
        jl secondString
        inc rdx

    ;   strings are equal so far
    ;   if the lengths are the same
        cmp r8, r9
        jne lengthNotEqual
        ;   check if at the end of the strings
            cmp r8, rdx
            je stringsEqual
        lengthNotEqual:
        
    loop compareLoop
    firstString:
        mov rax, 1
        ret
    secondString:
        mov rax, -1
        ret
    stringsEqual:
        mov rax, 0
        ret


; convertKMB - converts a KMB string to a KMB number
; rdi - address to null terminated string
; rsi - address to 64 bit location to store the KMB number
; rax - return value = 1 (successful) / -1 (otherwise)
global convertKMB
convertKMB:
;   store rbx, r12
    push rbx
    push r12

    mov r8, 0 ; index = 0

;   check for leading white spaces
    checkLeadingSpaces:
        mov r9b, byte[rdi + r8]
        cmp r9b, 32 ; 32 = ' '
        jne checkLeadingSpacesNone

        inc r8
    loop checkLeadingSpaces
    checkLeadingSpacesNone:

;   check for sign
    cmp r9b, 45 ; 45 = '-'
    mov r10, 1 ; store sign
    jne numberIsPositive
        mov r10, -1
        inc r8
    numberIsPositive:

;   check if first char is a number
    mov r9b, byte[rdi + r8]
    cmp r9b, 48 ; 48 = '0'
    jl invalidNumber
    cmp r9b, 57 ; 57 = '9'
    jg invalidNumber
    

;   calculate the number
    mov bl, 0   ; 0 not decimal ; 1 decimal
    mov bh, 0   ; counts after decimal
    mov rcx, 0   ; store KMB multiple
    mov r12, 10; 10 to move the decimal
    mov rax, 0
    mov rdx, 0
    calculateNumber:
    ;   get next character
        mov r9b, byte[rdi + r8]

    ;   check if at the null character
        cmp r9b, NULL_CHAR
        je calculateNumberDone

    ;   skip if decimal found already
        cmp bl, 1
        je decimalFoundAlready
        ;   check if decimal
            cmp r9b, 46 ; 46 = '.'
            jne notDecimal
                mov bl, 1   ; decimal found
                inc r8
                inc bh
                mov r9b, byte[rdi + r8]
            ;   check if the char after the decimal is a number
                cmp r9b, 48 ; 48 = '0'
                jl invalidNumber
                cmp r9b, 57 ; 57 = '9'
                jg invalidNumber
            notDecimal:
        decimalFoundAlready:
        
    ;   inc bh if decimal is found
        cmp bl, 1
        jne noDecimalFound
            inc bh
        noDecimalFound:

    ;   check if r9b is a number
        cmp r9b, 48 ; 48 = '0'
        jge moreThen0
            mov cl, 1   ; 1 = is not a number
        moreThen0:

        cmp r9b, 57 ; 57 = '9'
        jle lessThen9
            mov cl, 1
        lessThen9:

    ;   check if r9b is K, M, or B
        cmp r9b, 75     ; 75 = 'K'
		je multiplyK
		cmp r9b, 107    ; 107 = 'k'
		je multiplyK
		cmp r9b, 77     ; 77 = 'M'
		je multiplyM
		cmp r9b, 109    ; 109 = 'm'
		je multiplyM
		cmp r9b, 66     ; 66 = 'B'
		je multiplyB
		cmp r9b, 98     ; 98 = 'b'
		je multiplyB

        jmp passKMBcheck
        multiplyK:
            mov cl, 3
            jmp passKMBcheck
        multiplyM:
            mov cl, 6
            jmp passKMBcheck
        multiplyB:
            mov cl, 9
            jmp passKMBcheck
        passKMBcheck:
    
    ;   if char is not a number or K,M, or B
        cmp cl, 1
        je invalidNumber
        

    ;   store number
        cmp cl, 0
        jne isKMB
            sub r9b, 48 ; 48 = '0'
            mul r12    ; mov rax one decimal right
            add al, r9b
        isKMB:

        inc r8
    jmp calculateNumber
    calculateNumberDone:

;   calculate the KMB number
    push rax ; store current number
    sub cl, bh
    mov rax, 1
    getFactorLoop:
        mul r12b
    loop getFactorLoop
    mov rcx, rax
    pop rax
    mul rcx

;   check if number is within limits
    mov rcx, MAX_INTEGER_SIZE
    cmp rax, rcx
    jg invalidNumber

;   make negative if neg
    imul r10

;   store results
    mov qword[rsi], rax
    mov rax, 1

    jmp KMBcalculated

    invalidNumber:
    ;   error has occured
        mov rax, -1
    KMBcalculated:

;   pop back r12, rbx
    pop r12
    pop rbx
ret
