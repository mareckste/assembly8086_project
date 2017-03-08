include macro.asm

DATA SEGMENT PUBLIC

    T DW 0

    testtxt db "Testovaci$"

DATA ENDS

CODE SEGMENT PUBLIC 

ASSUME CS:CODE,DS:DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
line_end proc
  write testtxt, 0
  ret
endp

start:


PUBLIC line_end
CODE ENDS
end start