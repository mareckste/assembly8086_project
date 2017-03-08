write MACRO t, c
  mov ax, 03h
    int 10h
  lea dx, t + c
  mov ah, 09h
  int 21h
endm