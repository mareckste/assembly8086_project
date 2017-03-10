;==================================================================================================================================
;==================================================================================================================================
;Marek Števuliak, pondelok 16:00, cv. Ing. Ján Hudec, PhD., zhodnotenie na KONCI TOHTO SUBORU
;MAIN
;Napíšte program (v JSI) ktorý umožní používateľovi pomocou jednoduchého menu opakovane vykonať nasledujúce akcie: zadať meno súboru,
;vypísať obsah súboru, výpísať dĺžku súboru, vykonať pridelenú úlohu, ukončiť program. Program načíta voľbu používateľa z klávesnice. 
;V programe vhodne použite makro s parametrom, ako aj vhodné volania OS (resp. BIOS) pre načítanie znaku, nastavenie kurzora, výpis 
;reťazca, zmazanie obrazovky a pod. Definície makier musia byť v samostatnom súbore. Pridelená úloha musí byť realizovaná ako externá 
;procedúra (kompilovaná samostatne a prilinkovaná k výslednému programu). Program musí korektne spracovať súbory s dĺžkou aspoň do 128kB. 
;Pri čítaní využite pole vhodnej veľkosti (buffer), pričom zo súboru do pamäte sa bude presúvať vždy (až na posledné čítanie) celá veľkosť
;poľa.Ošetrite chybové stavy. Program, respektíve každý súbor, musí obsahovať primeranú technickú dokumentáciu.
;==================================================================================================================================
;==================================================================================================================================

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
  
  ;;;;;;;;;;;;;; RETRIEVES THE FILE LENGTH
  proc orm
    call open_file
    call get_file_length
    call close_file
    ret
  endp
  ;;;;;;;;;;;;;; PRINTS THE FILE CONTENT ON THE SCREEN
  write_file_cont proc
    call clear_screen
    xor cx, cx
    xor si, si
    mov cx, file_length       ; init counter for loop -> file size
    mov si, 0                 ; current position index to si
    read:
      mov dl, file_cont[ si ] ; store character to be outputed on the screen into the dl
      mov ah, 02h             ; output character on the screen
      int 21h

      inc si                  ; move to another unit in file_cont array
      loop read
    xor si, si                ; si -> 0
    ret
  endp
  ;;;;;;;;;;;;;; CLEARS THE SCREEN
  clear_screen proc
    mov ax, 03h
    int 10h
    ret 
  endp
  ;;;;;;;;;;;;;; READS THE NAME OF THE FILE
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
  ;;;;;;;;;;;;;; CONVERTS THE ASCII VALUE OF NUMBER TO DECIMAL and PRINTS IT
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
  ;;;;;;;;;;;;;; STORES THE FILE SIZE INTO file_length VARIABLE
  proc get_file_length
    mov ah, 42H             ; move file ptr 
    mov bx, handle          ; file handle
    xor cx, cx              ; clear CX
    xor dx, dx              ; 0 bytes to move
    mov al, 2               ; relative to end
    int 21H                 ; move pointer to end. DX:AX = file size
    jc opening_error        ; error if CF = 1
   
    mov file_length, 0      ; store file size into file file_length
    add file_length, ax
    add file_length, dx
    ret
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
  ;;;;;;;;;;;;;; READS THE FILE 
  read_file proc
    xor ax, ax
    mov ah, 3fh
    mov bx, handle
    mov cx, 60000           ; size of buffer
    lea dx, file_cont       ; where to store file content
    int 21h
    jc  opening_error
    ret
  endp
  ;;;;;;;;;;;;;; WAITS FOR ENTER TO BE PRESSED
  check_enter proc
    write2 enter_alert, 0   ; macro, shows alert message
    mov ah, 01h
    int 21h
    cmp al, 13
    je show_menu
    ret
  endp
; ================== HELPER PROGRAM PROCEDURES END ==============================
  opening_error:    ; privides error info while opening file without success
    write opening_error_text, 0
    call check_enter
    jmp terminate
    
  closing_error:  ; privides error info while closing file without success
    write closing_error_text, 0
    call check_enter
    jmp terminate
; ================== MAIN PROGRAM ===============================================
start:
   mov ax, SEG DATA        ; init the data segment
   mov ds, ax
    
  show_menu:
    write menu_text, 0     ; pop up the menu screen
    
  get_choice:              ; test for chosen option
    mov ah, 01h
    int 21h
    
    cmp al, 53
    jg  show_error
    
    cmp al, 49             ; test on 1 
    jl show_error
    je option_1  
    
    cmp al, 50             ; test on 2
    je option_2
    
    cmp al, 51             ; test on 3
    je option_3

    cmp al, 52             ; test on 3
    je option_4
    
  terminate:               ; terminates the program execution
    mov ah, 4ch
    int 21h
  
;==== NAVESTIA PRE JEDNOTLIVE VOLBY ====
  option_1:
    call provide_file_name ; process the provided filename
    jmp show_menu          ; return back to menu

  option_2:
    call orm               ; get file length by lseek instruction call
    call open_file         ; open the file
    call read_file         ; read and store the file
    call close_file        ; close the file
    call write_file_cont   ; output the file content
    call check_enter       ; wait for enter to be returned to the menu screen
    jmp terminate
  
  option_3:
    call orm
    mov ax, file_length
    lea si, bf            ; helper buffer to store numbers backwards
    call convert          ; convert file length from ascii to decimal 
    call check_enter      ; wait for enter to be returned to the menu screen
    jmp terminate
  
  option_4:
    call orm              ; get file length by lseek instruction call
    call line_end         ; print lines the contains end of the sentence mark (called as an external procedure)
    call check_enter      ; wait for enter to be returned to the menu screen
    jmp terminate
  
  option_5:
    jmp terminate         ; program finishes
  
  show_error:             ; handle illegal input scenarios
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

end start

;==================================================================================================================================
;====================================================CONCLUSION====================================================================
; Our task was to get fammiliar with language of symbolic instructions. Specifically, the most of the task underlied work and 
; manipulation with an array. Personally, I leaned towards using general registers including source and destinantion indices. 
; My approach was pretty straightforward so I was solving the given task utilizing loops and 2 additional registers. The main idea 
; was to track the current position in the file along with current possition on the investigated line making it possible easily 
; return to the beginning of the line when required. Additionally, I used lseek function to obtain file size without reading its
; content. 

; Whereas the code was expanding on its size, I focused on grouping the most used instructions into several procedures to avoid the 
; code dupplication. Some subtasks were specific and required special approach, though. Therefore some parts of the code may look 
; a bit simmilar.
; Apparentely, LSI is hard in particular cases to debug which implicates significant time consumption to trace inconsistences 
; within program. As I was using TASM, I consider turbo debuger rather helpful while testing the correctness of my approach.

; At the end, I managed to succesfully fulfill the task and additional subtask studying provided information and sources on the 
; course's website. 
;==================================================================================================================================
;==================================================================================================================================