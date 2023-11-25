.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern puts: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "CHESS",0
area_width EQU 400
area_height EQU 400
area DD 0
msgdebug db "Aici"
format db "%d", 10, 0
culoare dd 0
counter DD 0 ; numara evenimentele de tip timer

muta_alb dd 1

;0-5: piese negre: 0-rege, 1-regina, 2-turn, 3-cal, 4-nebun, 5-pion
;10-15: piese albe: 10-rege, 11-regina, 12-turn, 13-cal, 14-nebun, 15-pion

tabla DD  2, 3, 4, 1, 0, 4, 3, 2
	  DD  5, 5, 5, 5, 5, 5, 5, 5
	  DD  6, 6, 6, 6, 6, 6, 6, 6
	  DD  6, 6, 6, 6, 6, 6, 6, 6
	  DD  6, 6, 6, 6, 6, 6, 6, 6
	  DD  6, 6, 6, 6, 6, 6, 6, 6
	  DD 15,15,15,15,15,15,15,15
	  DD 12,13,14,11,10,14,13,12
	  
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
arg5 EQU 24

piesa_aleasa dd -1
piesa_aleasa_x dd -1
piesa_aleasa_y dd -1
pozitie_finala_x dd -1
pozitie_finala_y dd -1

symbol_width EQU 10
symbol_height EQU 20
piesa_width EQU 70
piesa_height EQU 70
click DB 0

include digits.inc
include letters.inc
include piese.inc

.code

position_macro macro linie, coloana, piesa, areaMat
	push areaMat
	push piesa
	push coloana
	push linie
	call position
	add esp, 16
endm

afisare_piese proc
	push ebp
	mov ebp, esp
	
	lea ebx, tabla
	
	mov ecx, 8 ;for pt linii
for_afis:
	push ebx
	mov eax, 8
	sub eax, ecx
	mov ebx, 50
	mul ebx ;eax = eax * ebx
	inc eax ;afisez la un pixel distanta
	mov esi, eax ;coordonata liniei
	pop ebx ;ce piesa e
	push ecx
	mov ecx, 8
for1_afis: ;for pt coloane
	push ebx
	mov eax, 8
	sub eax, ecx
	mov ebx, 50
	mul ebx
	inc eax
	mov edi, eax ;coordonata coloanei
	pop ebx
	position_macro esi, edi, dword ptr [ebx], area

	add ebx, 4
loop for1_afis
	pop ecx
loop for_afis
	mov esp, ebp
	pop ebp
	ret
afisare_piese endp


; arg1 y
; arg2 x
patrat proc ;fct care imi det in ce patrat de pe tabla am dat click
	push ebp
	mov ebp, esp
	
	mov eax, [ebp+arg1]
	mov ebx, 50
	mov edx, 0
	div ebx
	
	push eax
	mov eax, [ebp + arg2]
	mov edx, 0
	div ebx
	mov ecx, eax
	pop edx
	

	mov esp, ebp
	pop ebp
	ret 8
patrat endp
;ecx - linia
;edx - coloana

; arg1 coloana
; arg2 linie
click_piesa proc ;pe ce piesa am dat click
	push ebp
	mov ebp, esp
	
	mov ecx, [ebp + arg2]
	mov edx, [ebp + arg1]
	
	push edx

	mov eax, 8
	mul ecx
	pop edx
	add eax, edx
	mov eax, tabla[eax*4]
	
	mov esp, ebp
	pop ebp
	ret 8
click_piesa endp

;arg1 - piesa
;arg2 - coloana 
;arg3 - linia
mutare_piesa proc ;aici se muta piesa
	push ebp
	mov ebp, esp

	mov ecx, [ebp + arg3]
	mov edx, [ebp + arg2]
	
	push edx

	mov eax, 8
	mul ecx
	pop edx
	add eax, edx	

	mov edx, dword ptr [ebp + arg1]
	mov tabla[eax*4], edx 
	
	mov esp, ebp
	pop ebp
	ret 12
mutare_piesa endp

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat 
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

position proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg3] ;piesa
	cmp eax, 6 ;nu e piesa (gol)
	je sfarsit 
	jg piesa_alba ;piesele albe sunt de la 10 la 15

piesa_neagra: ;de la 0 la 5
	mov culoare, 0h
	lea esi, piese
	jmp continuare
piesa_alba:	
	sub eax, 10 ;imaginea corespunzatoare pentru fiecare piesa
	lea esi, piese
	mov culoare, 0FFFFFFFFh
	
continuare:
	mov ebx, 48 
	mul ebx ;ebx*eax(piesa)
	mov ebx, 48
	mul ebx
	shl eax, 2 
	add esi, eax 
	mov ecx, 48
	
for1:
	mov edi, [ebp+arg4]
	mov eax, [ebp+arg1]
	add eax, 48
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg2]
	shl eax, 2
	add edi, eax
	push ecx
	mov ecx, 48
for2:
	mov ebx, 0
	cmp dword ptr [esi], ebx
	jne dupa
	mov ebx, culoare
	mov dword ptr [edi], ebx
dupa:
	add esi, 4
	add edi, 4
	loop for2
	pop ecx
	loop for1
	
sfarsit:
	popa
	mov esp, ebp
	pop ebp
	ret
position endp 


; debug macro
	; pusha
	; push offset msgdebug
	; call puts
	; add esp, 4
	; popa
; endm

; un macro ca sa apelez mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y

line_horizontal macro x, y, len, color
local bucla_line
	push ecx
	
	mov eax, y 			;eax = y
	mov ebx, area_width
	mul ebx 			;eax=y*area_width
	add eax, x 			;eax = y*area_width + x
	shl eax, 2 			;eax = 4*(y*area_width + x)
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line
endm

b_square macro x, y, len, color
local bucla_square
	push ecx
	mov ecx, len
bucla_square:
	line_horizontal [ebp+arg2], [ebp+arg3], 50, 05b5b5bh
	pop ecx
	add dword ptr[y], 1
loop bucla_square
pop ecx
endm

w_square macro x, y, len, color
local bucla_square
	push ecx
	mov ecx, len
bucla_square:
	line_horizontal [ebp+arg2], [ebp+arg3], 50, 0bcbcbch
	pop ecx
	add dword ptr[y], 1
loop bucla_square
pop ecx
endm

lines2 macro x, y, len
local bucla_b, bucla_w
mov ecx, 4
bucla_b:
	b_square [ebp+arg2], [ebp+arg3], 50, 05b5b5bh
	w_square [ebp+arg2], [ebp+arg3], 50, 0bcbcbch 
loop bucla_b
sub dword ptr[ebp+arg2], 50
sub dword ptr[ebp+arg3], 400
mov ecx, 4
bucla_w:
	w_square [ebp+arg2], [ebp+arg3], 50, 0bcbcbch
	b_square [ebp+arg2], [ebp+arg3], 50, 05b5b5bh
loop bucla_w
endm

board macro x, y, len
	lines2 [ebp+arg2], [ebp+arg3], 50
	sub dword ptr[ebp+arg2], 50
	sub dword ptr[ebp+arg3], 400
	lines2 [ebp+arg2], [ebp+arg3], 50
	sub dword ptr[ebp+arg2], 50
	sub dword ptr[ebp+arg3], 400
	lines2 [ebp+arg2], [ebp+arg3], 50
	sub dword ptr[ebp+arg2], 50
	sub dword ptr[ebp+arg3], 400
	lines2 [ebp+arg2], [ebp+arg3], 50
endm


; arg1 piesa
; arg2 coloana veche
; arg3 linie veche
; arg4 coloana noua
; arg5 linie noua
poate_muta proc ;daca nu se afla piesa pe traseu
	push ebp
	mov ebp, esp
	
	mov edx, [ebp + arg5]
	sub edx, [ebp + arg3] ;dif linii
	
	mov ebx, [ebp + arg4]
	sub ebx, [ebp + arg2] ;dif coloane
	
	mov eax, 1
	cmp dword ptr [ebp + arg1], 3 ;pe cal nu il influenteaza
	je poate_muta_final
	cmp dword ptr [ebp + arg2], 13
	je poate_muta_final
	
	cmp edx, 0 ;pe ac linie
	je dupa_linii
	jg linii_pozitive
	mov edx, -1
	jmp dupa_linii
linii_pozitive:
	mov edx, 1
	jmp dupa_linii
	
dupa_linii:
	cmp ebx, 0
	je dupa_coloane
	jg coloane_pozitive
	mov ebx, -1
	jmp dupa_coloane
coloane_pozitive:
	mov ebx, 1
	jmp dupa_coloane
	
	
dupa_coloane:
	mov esi, [ebp + arg3]
	mov edi, [ebp + arg2]
	
	add esi, edx ;scadem cu 1 linia veche sa verif de la ea +1
	add edi, ebx ;scadem cu 1 coloana veche sa verif de la ea +1

	cmp esi, [ebp + arg5]
	jne dupa1
	cmp edi, [ebp + arg4]
	jne dupa1
	jmp poate_muta_final ;daca nu e dif => vecine
	
dupa1:
	pusha
	push esi
	push edi
	call click_piesa 
	cmp eax, 6 ;daca e spatiu gol
	popa
	je continuare1 ;mai verific
	mov eax, 0 ;daca nu, nu se poate muta
	jmp poate_muta_final
	
continuare1:

	add esi, edx ;se mai scade
	add edi, ebx
	
	cmp esi, [ebp + arg5] ;daca a ajuns la linia dorita
	jne dupa2
	cmp edi, [ebp + arg4]
	jne dupa2
	jmp poate_muta_final
	
dupa2:
	pusha
	push esi
	push edi
	call click_piesa
	cmp eax, 6
	popa
	je continuare2
	mov eax, 0
	jmp poate_muta_final
	
	
continuare2:
	add esi, edx
	add edi, ebx
	
	cmp esi, [ebp + arg5]
	jne dupa3
	cmp edi, [ebp + arg4]
	jne dupa3
	jmp poate_muta_final
	
dupa3:
	pusha
	push esi
	push edi
	call click_piesa
	cmp eax, 6
	popa
	je continuare3
	mov eax, 0
	jmp poate_muta_final
	
	
continuare3:
	add esi, edx
	add edi, ebx
	
	cmp esi, [ebp + arg5]
	jne dupa4
	cmp edi, [ebp + arg4]
	jne dupa4
	jmp poate_muta_final
	
dupa4:
	pusha
	push esi
	push edi
	call click_piesa
	cmp eax, 6
	popa
	je continuare4
	mov eax, 0
	jmp poate_muta_final
	
	
continuare4:
	add esi, edx
	add edi, ebx
	
	cmp esi, [ebp + arg5]
	jne dupa5
	cmp edi, [ebp + arg4]
	jne dupa5
	jmp poate_muta_final
	
dupa5:
	pusha
	push esi
	push edi
	call click_piesa
	cmp eax, 6
	popa
	je continuare5
	mov eax, 0
	jmp poate_muta_final

	
	
continuare5:
	add esi, edx
	add edi, ebx
	
	cmp esi, [ebp + arg5]
	jne dupa6
	cmp edi, [ebp + arg4]
	jne dupa6
	jmp poate_muta_final
	
dupa6:
	pusha
	push esi
	push edi
	call click_piesa
	cmp eax, 6
	popa
	je continuare6
	mov eax, 0
	jmp poate_muta_final
	
	
continuare6:
	add esi, edx
	add edi, ebx
	
	cmp esi, [ebp + arg5]
	jne dupa7
	cmp edi, [ebp + arg4]
	jne dupa7
	jmp poate_muta_final
	
dupa7:
	pusha
	push esi
	push edi
	call click_piesa
	cmp eax, 6
	popa
	je continuare7
	mov eax, 0
	jmp poate_muta_final
	
	
continuare7:
	add esi, edx
	add edi, ebx
	
	cmp esi, [ebp + arg5]
	jne dupa8
	cmp edi, [ebp + arg4]
	jne dupa8
	jmp poate_muta_final
	
dupa8:
	pusha
	push esi
	push edi
	call click_piesa
	cmp eax, 6
	popa
	je poate_muta_final
	mov eax, 0
	jmp poate_muta_final
	
poate_muta_final:
	mov esp, ebp
	pop ebp
	ret 20
poate_muta endp


; arg1 piesa
; arg2 coloana veche
; arg3 linie veche
; arg4 coloana noua
; arg5 linie noua
cal proc
	push ebp
	mov ebp, esp
	mov edx, [ebp + arg5]
	sub edx, [ebp + arg3]
	mov ebx, [ebp + arg4]
	sub ebx, [ebp + arg2]
	mov eax, 0
cal1:
	cmp edx, 2
	jne cal2
	cmp ebx, 1
	jne cal2
	mov eax, 1
	jmp final_cal

cal2:
	cmp edx, 2
	jne cal3
	cmp ebx, -1
	jne cal3
	mov eax, 1
	jmp final_cal

cal3:
	cmp edx, -2
	jne cal4
	cmp ebx, 1
	jne cal4
	mov eax, 1
	jmp final_cal
	
cal4:
	cmp edx, -2
	jne cal5
	cmp ebx, -1
	jne cal5
	mov eax, 1
	jmp final_cal
	
cal5:
	cmp edx, 1
	jne cal6
	cmp ebx, 2
	jne cal6
	mov eax, 1
	jmp final_cal
	
cal6:
	cmp edx, 1
	jne cal7
	cmp ebx, -2
	jne cal7
	mov eax, 1
	jmp final_cal
	
cal7:
	cmp edx, -1
	jne cal8
	cmp ebx, 2
	jne cal8
	mov eax, 1
	jmp final_cal
	
cal8:
	cmp edx, -1
	jne final_cal
	cmp ebx, -2
	jne final_cal
	mov eax, 1
	jmp final_cal
	
	
final_cal:

	mov esp, ebp
	pop ebp
	ret 20
cal endp

; arg1 piesa
; arg2 coloana veche
; arg3 linie veche
; arg4 coloana noua
; arg5 linie noua
rege proc
	push ebp
	mov ebp, esp

	mov edx, [ebp + arg5]
	sub edx, [ebp + arg3]
	mov ebx, [ebp + arg4]
	sub ebx, [ebp + arg2]
	mov eax, 0
rege1:
	cmp edx, 1
	jne rege2
	cmp ebx, 0
	jne rege2
	mov eax, 1
	jmp final_rege

rege2:
	cmp edx, 1
	jne rege3
	cmp ebx, 1
	jne rege3
	mov eax, 1
	jmp final_rege

rege3:
	cmp edx, 0
	jne rege4
	cmp ebx, 1
	jne rege4
	mov eax, 1
	jmp final_rege
	
rege4:
	cmp edx, -1
	jne rege5
	cmp ebx, 1
	jne rege5
	mov eax, 1
	jmp final_rege
	
rege5:
	cmp edx, -1
	jne rege6
	cmp ebx, 0
	jne rege6
	mov eax, 1
	jmp final_rege
	
rege6:
	cmp edx, -1
	jne rege7
	cmp ebx, -1
	jne rege7
	mov eax, 1
	jmp final_rege
	
rege7:
	cmp edx, -1
	jne rege8
	cmp ebx, 0
	jne rege8
	mov eax, 1
	jmp final_rege
	
rege8:
	cmp edx, -1
	jne final_rege
	cmp ebx, 1
	jne final_rege
	mov eax, 1
	jmp final_rege
	
	
final_rege:
	mov esp, ebp
	pop ebp
	ret 20
rege endp

; arg1 piesa
; arg2 coloana veche
; arg3 linie veche
; arg4 coloana noua
; arg5 linie noua
nebun proc
	push ebp
	mov ebp, esp
	
	mov edx, [ebp + arg5]
	sub edx, [ebp + arg3]
	
	mov ebx, [ebp + arg4]
	sub ebx, [ebp + arg2]
	
	mov eax, 0
	
	; pusha 
	; push edx
	; push offset format
	; call printf
	; add esp, 8
	; popa
	
nebun1:
	cmp edx, ebx
	jne nebun2
	mov eax, 1
	jmp nebun_final
	
nebun2:
	not edx ;nebunul poate muta si daca dif liniilor / coloanelor e egala in modul
	inc edx
	cmp edx, ebx
	jne nebun_final
	mov eax, 1
	jmp nebun_final
nebun_final:
	mov esp, ebp
	pop ebp
	ret 20
nebun endp



; arg1 piesa
; arg2 coloana veche
; arg3 linie veche
; arg4 coloana noua
; arg5 linie noua
turn proc
	push ebp
	mov ebp, esp
	
	mov edx, [ebp + arg5]
	sub edx, [ebp + arg3]
	mov ebx, [ebp + arg4]
	sub ebx, [ebp + arg2]
	mov eax, 0
	
turn1:
	cmp edx, 0
	jne turn2
	mov eax, 1
	jmp final_turn

turn2:
	cmp ebx, 0
	jne final_turn
	mov eax, 1
	jmp final_turn

	
final_turn:
	mov esp, ebp
	pop ebp
	ret 20
turn endp
	

; arg1 piesa
; arg2 coloana veche
; arg3 linie veche
; arg4 coloana noua
; arg5 linie noua
pion proc
	push ebp
	mov ebp, esp
	
	mov edx, [ebp + arg5]
	sub edx, [ebp + arg3]
	mov ebx, [ebp + arg4]
	sub ebx, [ebp + arg2]
	mov ecx, [ebp + arg1]
	mov eax, 0
	
	cmp ecx, 15
	je pion_alb
	
	cmp ecx, 5
	je pion_negru
	jmp final_pion
	
pion_alb:
	cmp ebx, 0
	jne pion_alb1
	cmp edx, -1
	jne pion_alb1
	mov eax, 1
	jmp final_pion

pion_alb1: ;captureaza pe diag
	pusha
	push [ebp + arg5]
	push [ebp + arg4]
	call click_piesa
	cmp eax, 6
	popa
	jl pion_alb_capt
	je pion_alb2
	jmp final_pion
	
pion_alb_capt:
	cmp edx, -1
	je pion_alb_capt1
	jne final_pion
	
pion_alb_capt1:
	cmp ebx, 1
	jne pion_alb_capt2
	mov eax, 1
	jmp final_pion

pion_alb_capt2:
	cmp ebx, -1
	jne pion_alb2
	mov eax, 1
	jmp final_pion
	
pion_alb2:
	cmp dword ptr [ebp + arg3], 6 ;poz initiala
	je pion_alb3
	jmp final_pion
pion_alb3:
	cmp ebx, 0
	jne final_pion
	cmp edx, -2
	jne final_pion
	mov eax, 1
	jmp final_pion

pion_negru:
	cmp ebx, 0
	jne pion_negru1
	cmp edx, 1
	jne pion_negru1
	mov eax, 1
	jmp final_pion

pion_negru1: ;captureaza pe diag
	pusha
	push [ebp + arg5]
	push [ebp + arg4]
	call click_piesa
	cmp eax, 6
	popa
	jg pion_negru_capt
	je pion_negru2
	jmp final_pion
	
pion_negru_capt:
	cmp ebx, -1
	je pion_negru_capt1
	jne final_pion
	
pion_negru_capt1:
	cmp ebx, 1
	jne pion_negru_capt2
	mov eax, 1
	jmp final_pion

pion_negru_capt2:
	cmp edx, 1
	jne pion_negru2
	mov eax, 1
	jmp final_pion
	
pion_negru2:
	cmp dword ptr [ebp + arg3], 1 ;poz initiala
	je pion_negru3
	
pion_negru3:
	cmp ebx, 0
	jne final_pion
	cmp edx, 2
	jne final_pion
	mov eax, 1
	jmp final_pion


	
final_pion:
	mov esp, ebp
	pop ebp
	ret 20
pion endp


; arg1 piesa
; arg2 coloana noua
; arg3 linie noua
capturare proc
	push ebp
	mov ebp, esp
	
	mov eax, 0
	mov ebx, [ebp + arg2]
	mov edx, [ebp + arg3]
	mov ecx, [ebp + arg1]
	cmp ecx, 6
	jg capt_alb
	jl capt_negru
	
capt_alb:
	push eax
	push [ebp + arg3]
	push [ebp + arg2]
	call click_piesa
	cmp eax, 6
	pop eax
	jg final_capt
	mov eax, 1
	jmp final_capt

capt_negru:
	push eax
	push [ebp + arg3]
	push [ebp + arg2]
	call click_piesa
	cmp eax, 6
	pop eax
	jl final_capt
	mov eax, 1
	jmp final_capt
	
final_capt:
	mov esp, ebp
	pop ebp
	ret 12
capturare endp

;arg1 - piesa
alternativ proc
	push ebp
	mov ebp, esp
	
	mov ebx, [ebp + arg1]
	mov eax, muta_alb ;albul poate muta prima data
	
	cmp eax, 1
	je alba
	jmp neagra
	
alba:
	cmp ebx, 10
	jge alba_adev
alba_fals:
	mov eax, 0
	jmp final_alternativ
alba_adev:
	mov eax, 1
	jmp final_alternativ
	
neagra:
	cmp ebx, 5
	jle neagra_adev
neagra_fals:
	mov eax, 0
	jmp final_alternativ
neagra_adev:
	mov eax, 1
	jmp final_alternativ

final_alternativ:	
	mov esp, ebp
	pop ebp
	ret 4
alternativ endp

draw proc

	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp + arg1]

	
	cmp eax, 0
	je tabla_desen
	cmp eax, 2
	je tabla_desen
	cmp eax, 1
	je click_
	jmp final_draw
	
click_:

	push [ebp + arg3]
	push [ebp + arg2]
	call patrat
	mov pozitie_finala_x, ecx
	mov pozitie_finala_y, edx
	
	

	push pozitie_finala_x
	push pozitie_finala_y
	call click_piesa
	cmp eax, 6
	je verificare_corectitudine
	
selectare_piesa:

	cmp piesa_aleasa, -1
	jne verificare_corectitudine
	mov piesa_aleasa, eax
	mov ebx, pozitie_finala_x
	mov piesa_aleasa_x, ebx
	mov ebx, pozitie_finala_y
	mov piesa_aleasa_y, ebx
	jmp tabla_desen
	
verificare_corectitudine:

	push piesa_aleasa
	call alternativ
	cmp eax, 1
	je muta
piesa_gresita:
	mov piesa_aleasa, -1
	jmp tabla_desen
	
muta:
	
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa
	call capturare
	cmp eax, 0
	je tabla_desen
	
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call poate_muta
	cmp eax, 0
	je tabla_desen
		
	
	;cal
	cmp piesa_aleasa, 3
	je verificare_cal
	cmp piesa_aleasa, 13
	je verificare_cal
	
	;rege
	cmp piesa_aleasa, 0
	je verificare_rege
	cmp piesa_aleasa, 10
	je verificare_rege
	
	;pion
	cmp piesa_aleasa, 5
	je verificare_pion
	cmp piesa_aleasa, 15
	je verificare_pion
	
	; turn
	cmp piesa_aleasa, 2
	je verificare_turn
	cmp piesa_aleasa, 12
	je verificare_turn
	
	; nebun
	cmp piesa_aleasa, 4
	je verificare_nebun
	cmp piesa_aleasa, 14
	je verificare_nebun
	
	; regina
	cmp piesa_aleasa, 1
	je verificare_reginan
	cmp piesa_aleasa, 11
	je verificare_reginan
	
	; jmp muta1

	
verificare_cal:

	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call cal
	cmp eax, 0
	je tabla_desen
	jmp muta1
	
verificare_rege:
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call rege
	cmp eax, 0
	je tabla_desen
	jmp muta1
	
verificare_pion:
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call pion
	cmp eax, 0
	je tabla_desen
	jmp muta1
	
verificare_turn:
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call turn
	cmp eax, 0
	je tabla_desen
	
verificare_nebun:
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call nebun
	cmp eax, 0
	je tabla_desen
	
verificare_reginan:
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call nebun
	cmp eax, 0
	jne muta1
	je verificare_reginat

verificare_reginat:
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa_x
	push piesa_aleasa_y
	push piesa_aleasa
	call turn
	cmp eax, 0
	je tabla_desen

muta1:
	push piesa_aleasa_x
	push piesa_aleasa_y
	push 6
	call mutare_piesa

	; pusha
	; push eax
	; push offset format
	; call printf
	; add esp, 8
	; popa
	
	push pozitie_finala_x
	push pozitie_finala_y
	push piesa_aleasa
	call mutare_piesa

	mov piesa_aleasa, -1
	mov eax, 1
	sub eax, muta_alb
	mov muta_alb, eax

tabla_desen:
	mov ecx,[area_height]
	mov dword ptr[arg3+ebp],0
	mov dword ptr[arg2+ebp],350
	
	board [ebp+arg2], [ebp+arg3], 50

	call afisare_piese
		
final_draw:

	popa
	mov esp, ebp
	pop ebp
	ret 
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
