include macro.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STAK SEGMENT STACK 
    DW 100H DUP(?)
STAK ENDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA SEGMENT PUBLIC
; ================== DATA SECTION ===========================================

  menu_text   db 10, "============MENU============"
              db 10,     "1. Zvol meno suboru"
              db 10,     "2. Zobraz obsah suboru"
              db 10,     "3. Zobraz dlzku suboru"
              db 10,     "4. Uloha 19"
              db 10,     "5. Koniec"
              db 10, 10, "Zadajte cislo volby: "
              db "$" 
              
  testtxt     db          "Testovaci$"
  enter_alert db 10,13,   "Stlacte [ENTER] ak chcete pokracovat: $"
  error_text  db          "CHYBA: Musite zadat cislo od 1-5 !$"
  opening_error_text  db  "CHYBA: Subor sa nepodarilo otvorit$"
  closing_error_text  db  "CHYBA: Subor sa nepodarilo zatvorit$"
  file_text   db 10,      "Zadajte meno suboru, kt. chcete otvorit: $"
  file_sz_t   db 10, 13,  "Velkost suboru je: $"
  buff        db 26         ; MAX NUMBER OF CHARACTERS ALLOWED (25).
              db ?          ; NUMBER OF CHARACTERS ENTERED BY USER.
              db 26 dup(0)  ; CHARACTERS ENTERED BY USER.
  handle      dw ?
  file_cont   db 60000 dup(?)
  file_length dw 0
  buffer      db 10 dup(?)
  bf db 10 dup('$')
DATA ENDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extrn line_end: proc

public handle
public file_cont
public file_length

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE SEGMENT PUBLIC
ASSUME CS:CODE,DS:DATA,SS:STAK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ================== HELPER PROGRAM PROCEDURES ==============================
  
  ;;;;;;;;;;;;;; PRINTS THE FILE CONTENT ON THE SCREEN
  read_file_cont proc
    mov cx, file_length
    mov si, 0
    read:
      mov dl, file_cont[ si ]
      mov ah, 02h
      int 21h

      inc si
      loop read
    ret
  endp

  ;;;;;;;;;;;;;; CLEARS THE SCREEN
  clear_screen proc
    mov ax, 03h
    int 10h
    ret 
  endp
  
  ;;;;;;;;;;;;;; READS THE NAME OF a FILE
  provide_file_name proc
    write file_text, 0      ; write introducing text
    
    mov ah, 0Ah             ; function to read string from input
    lea dx, buff            ; make dx to point on buff
    int 21h
    
    lea si, buff + 1        ;  ammount of inserted chars
    mov cl, [ si ]          ;  store the ammount into cl
    mov ch, 0               ;  clear cx   
    inc cx                  ;  incr cx to allow us get one unit beyond
    add si, cx              ;  make si to point on enter char
    mov al, '$'             ;  store the dollar sign in the al
    mov [ si ], al          ;  replace enter by end of string
    call clear_screen
    ret
  endp
  ;;;;;;;;;;;;;; CONVERTS THE ASCII VALUE 
  ;;;;;;;;;;;;;; OF NUMBER TO DECIMAL and PRINTS IT
  convert proc
    ascii:
        mov bx, 10
        mov dx,0            ; clear dx prior to dividing dx:ax by bx
        div bx              ; divide ax by 10
        add dx,48           ; add 48 to remainder -> get ascii char of num 
        dec si              ; store characters in reverse order
        mov [si],dl
        cmp ax,0            
        jz  extt            ; if no remainder, we are done
        jmp ascii           ; otherwise repeat        
     extt:
        call clear_screen
        mov ah,9            ; print number
        mov dx,si
        int 21h
        RET
  endp
  ;;;;;;;;;;;;;; OPENS THE FILE WHICH NAME IS STORED IN BUFF
  open_file proc
    xor dx, dx
    mov ah, 3dh             ; file open
    lea dx, buff + 2        ; copy the adress of filename to datasegment
    mov al, 0               ; read-only
    int 21h    
    mov handle, ax          ; store file handler
    jc  opening_error       ; jump if error
    ret
  endp
  ;;;;;;;;;;;;;; CLOSES THE FILE
  close_file proc
    mov ah, 3eh
    mov bx, handle
    jc  closing_error
    ret
  endp
  ;;;;;;;;;;;;;; READS FILE 
  read_file proc
    mov ah, 3fh
    mov bx, handle
    mov cx, 60000
    lea dx, file_cont
    int 21h
    jc  opening_error

    mov file_length, ax
    ret
  endp
  ;;;;;;;;;;;;;; STORES THE FILE CONTENT 
  store_file proc
    xor cx, cx
    xor dx, dx
    mov cx, ax ; poc precitanych do si
    lea si, file_cont
    mov ah, 0
    add si, cx
    mov al, '$'
    mov [si], al
    ret
  endp
  ;;;;;;;;;;;;;; WAITS FOR ENTER TO BE PRESSED
  check_enter proc
    write2 enter_alert, 0
    mov ah, 01h
    int 21h
    cmp al, 13
    je show_menu
    ret
  endp
; ================== HELPER PROGRAM PROCEDURES END ==============================
  opening_error:
    write opening_error_text, 0
    call check_enter
    jmp terminate
    
  closing_error:
    write closing_error_text, 0
    call check_enter
    jmp terminate
; ================== MAIN PROGRAM ===============================================
start:
   mov ax, SEG DATA        ;do AX vloz adresu segmentu DATA
   mov ds, ax
    
  show_menu:
    write menu_text, 0
    
  get_choice:
    mov ah, 01h
    int 21h
    
    cmp al, 53
    jg  show_error
    
    cmp al, 49      ;test na 1
    jl show_error
    je option_1  
    
    cmp al, 50      ;test na 2
    je option_2
    
    cmp al, 51      ;test na 3
    je option_3

    cmp al, 52      ;test na 3
    je option_4
    
  terminate:
    mov ah, 4ch
    int 21h
  
  testik: 
     call convert
     jmp terminate
 
;==== NAVESTIA PRE JEDNOTLIVE VOLBY ====
  option_1:
    call provide_file_name
    jmp show_menu
  
  option_2:
    call open_file
    call read_file
    call store_file
    call close_file
    ;write file_cont, 0
    call read_file_cont
    call check_enter
    jmp terminate
  
  option_3:
    call open_file
    call read_file
    mov ax, file_length
    lea si, bf
    call convert
    call close_file
    call check_enter
    jmp terminate
  
  option_4:
    call line_end
    call check_enter
    jmp terminate
  
  option_5:
    jmp terminate
  
  show_error:
    write error_text, 0
    call check_enter
    jmp terminate

CODE ENDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

public clear_screen
public open_file
public check_enter
public read_file
public close_file
public store_file

end start