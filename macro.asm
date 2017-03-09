write MACRO t, c
  call clear_screen
  lea dx, t + c
  mov ah, 09h
  int 21h
endm

write2 MACRO t, c
  lea dx, t + c
  mov ah, 09h
  int 21h
endm