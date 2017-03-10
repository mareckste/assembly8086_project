;=================================================================
;=================================================================
;Marek Števuliak, pondelok 16:00, cv. Ing. Ján Hudec, PhD.
;ULOHA 19
;Vypísať riadky zo súboru ktoré obsahujú koniec vety a ich počet.
;=================================================================
;=================================================================


include macro.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STCK SEGMENT STACK
  dw 100h dup (?)
STCK ENDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ================== DATA SECTION ===========================================
DATA SEGMENT PUBLIC

    T 		   dw 0
    bf 		   db 10 dup('$')
    count_text db 10, 13, "Pocet riadkov obsahujucich koniec vety: $"
   
DATA ENDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extrn file_cont:byte
extrn file_length:word
extrn handle:word

extrn clear_screen: proc
extrn open_file: proc
extrn read_file: proc
extrn close_file: proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ================== CODE SECTION ===========================================
CODE SEGMENT PUBLIC 

ASSUME CS:CODE,DS:DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ext_proc:
;;;;;;;;;;;;;; PRINTS ON THE SCREEN LINES CONTANING END OF THE SENTENCE SIGN 
line_end proc
	call clear_screen
	call open_file
    call read_file
    call close_file

	mov T, 0
    xor cx, cx
    mov cx, [ file_length ]             ; init counter to [ file_length ]
    mov si, 0                           ; progress in file processing
    mov di, 0                           ; progress in line processing
    mov bx, 0
    
    find_chars:
    	  cmp cx, 0						; avoid underflow of cx, in case the file ends 
    	  JE termin		   				; with a newline
    	
          mov dl, file_cont[ si ]       ; move file content on the si index into dl
        
          cmp dl, 46                    ; compare on .
          JE set_line_start

          cmp dl, 63                    ; compare on ?
          JE set_line_start

          cmp dl, 33                    ; compare on !
          JE set_line_start

          cmp dl, 10                    ; if nothing found, continue to the next line
          JE newline

          inc si                        ; inc current position in file
          inc di                        ; inc current line position
        loop find_chars
        jmp termin                      ; if entire file scanned, terminate

    newline:
        inc si                          ; increment to another character
        mov di, 0                       ; make di to track another line
        dec cx                          ; decrement general counter of loop -> we have moved one char further
        jmp find_chars                  ; investigate next line

    set_line_start:
        sub si, di                      ; substract number of chars we have already gone over per 
                                        ; current line from entire progres -> gets us at the beginning index of current line
        add cx, di                      ; add how many steps we have proceeded backwards to counter
        mov di, 0                       ; make di 0 to iterate over following line
        inc T                           ; we have found -nth line that contains end of the sentence
        jmp print_until_enter           ; print current line

    
    print_until_enter:
        mov dl, file_cont[ si ]         ; character we want to print
        mov ah, 02h                     ; print char
        int 21h
        
        cmp al, 10                      ; if enter then investigate following line 
        JE  newline        
        inc si                          ; move to the next character of sequence
        loop print_until_enter
        jmp termin                      ; if eof then terminate
        
    termin:
        mov ax, T  						; process the number of lines meeting the scriteria
        lea si, bf						; stored in T for output
        call convert								
    ret
endp
;;;;;;;;;;;;;; CONVERTS THE ASCII VALUE OF NUMBER TO DECIMAL and PRINTS IT
proc convert
    ascii:
        mov bx, 10
        mov dx, 0            			; clear dx prior to dividing dx:ax by bx
        div bx              			; divide ax by 10
        add dx, 48          			; add 48 to remainder -> get ascii char of num 
        dec si              			; store characters in reverse order
        mov [ si ], dl
        cmp ax, 0            
        jz  extt            			; if no remainder, we are done
        jmp ascii           			; otherwise repeat        
     extt:
        write2 count_text, 0
        mov ah, 9            			; print number
        mov dx, si
        int 21h
        ret
endp

PUBLIC line_end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE ENDS
END