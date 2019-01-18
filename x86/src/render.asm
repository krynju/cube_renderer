section .data
matrix: dd  1.0, 0, 0, 0,       \
            0, 1.0, 0, 0,       \
            0, 0, 1.0, -200.0,  \
            0, 0, 0, 1.0

distance: dd -100.0
half_size: dd 256.0

section .bss
points: resd 32
projected_points: resd 16
sine: resd 3
cosine: resd 3

section .text
global _render
_render:
	push ebp
	mov ebp, esp

	push ebx
	push esi
	push edi


calc_trigs:
    mov eax, [ebp+8]

    fld DWORD [eax+140]         ;push x rot to fpu stack
    fsin
    fstp DWORD [sine]            ;save sin(x)
    fld DWORD [eax+140]         ;push x rot to fpu stack
    fcos
    fstp DWORD [cosine]          ;save cos(x)

    fld DWORD [eax+144]         ;push y rot to fpu stack
    fsin
    fstp DWORD [sine+4]          ;save sin(y)
    fld DWORD [eax+144]         ;push z rot to fpu stack
    fcos
    fstp DWORD [cosine+4]        ;save cos(y)

    fld DWORD [eax+148]         ;push z rot to fpu stack
    fsin
    fstp DWORD [sine+8]          ;save sin(z)
    fld DWORD [eax+148]         ;push z rot to fpu stack
    fcos
    fstp DWORD [cosine+8]        ;save cos(z)

fill_position_vector:
    mov eax, [ebp+8]

    mov ebx, DWORD [eax+128]
    mov [matrix + 12], DWORD ebx
    mov ebx, [eax+132]
    mov [matrix + 28], DWORD ebx
    mov ebx, [eax+136]
    mov [matrix + 44], DWORD ebx

fill_rotation_matrix:
    movss xmm2, [sine]                      ;sin(x)
    movss xmm3, [cosine]                    ;cos(x)
    movss xmm4, [sine+4]                    ;sin(y)
    movss xmm5, [cosine+4]                  ;cos(y)
    movss xmm6, [sine+8]                    ;sin(z)
    movss xmm7, [cosine+8]                  ;cos(z)

    movss xmm0, xmm5                        
    mulss xmm0, xmm7                        ; a11 = cos(y)*cos(z)
    movss [matrix], xmm0                    ; a11 store

    movss xmm0, xmm5
    mulss xmm0, xmm6				        ; a12 = cos(y)*sin(z)
    movss [matrix+4], xmm0 			        ; a12 store

    xorps xmm0, xmm0
    subss xmm0, xmm4				        ; a13 = -sin(y)
    movss [matrix+8] ,xmm0 			        ; a13 store

    movss xmm0, xmm7
    mulss xmm0, xmm2				        ; cos(z)*sin(x)
    mulss xmm0, xmm4				        ; cos(z)*sin(x)*sin(y)
    movss xmm1, xmm3
    mulss xmm1, xmm6				        ; cos(x)*sin(z)
    subss xmm0, xmm1				        ; a21 = cos(z)*sin(x)*sin(y) - cos(x)*sin(z)
    movss [matrix+16], xmm0 			    ; a21 store

    movss xmm0, xmm3
    mulss xmm0, xmm7				        ; cos(x)*cos(z)
    movss xmm1, xmm2
    mulss xmm1, xmm4				        ; sin(x)*sin(y)
    mulss xmm1, xmm6				        ; sin(x)*sin(y)*sin(z)
    addss xmm0, xmm1				        ; a22 = cos(x)*cos(z) + sin(x)*sin(y)*sin(z)
    movss [matrix+20], xmm0 			    ; a22 store

    movss xmm0, xmm5
    mulss xmm0, xmm2				        ; a23 = cos(y)*sin(y)
    movss [matrix+24], xmm0 			    ; a23 store

    movss xmm0, xmm2
    mulss xmm0, xmm6				        ; sin(x)*sin(z)
    movss xmm1, xmm3
    mulss xmm1, xmm7				        ; cos(x)*cos(z)
    mulss xmm1, xmm4				        ; cos(x)*cos(z)*sin(y)
    addss xmm0, xmm1				        ; a31 = sin(x)*sin(z) + cos(x)*cos(z)*sin(y)
    movss [matrix+32], xmm0 			    ; a31 store

    movss xmm0, xmm3
    mulss xmm0, xmm4				        ; cos(x)*sin(y)
    mulss xmm0, xmm6				        ; cos(x)*sin(y)*sin(z)
    movss xmm1, xmm2
    mulss xmm1, xmm7				        ; cos(z)*sin(x)
    subss xmm0, xmm1				        ; a32 = cos(x)*sin(y)*sin(z) - cos(z)*sin(x)
    movss [matrix+36], xmm0 			    ; a32 store

    movss xmm0, xmm3
    mulss xmm0, xmm5				        ; a33 = cos(x)*cos(y)
    movss [matrix+40], xmm0 			    ; a33 store





matrix_times_vertices:
	mov eax, [ebp + 8]
	mov ebx, 128
    .outer_loop:

;todo implement this matrix x vector multiplication
; xmm0 - wektor do pomnożenia
; xmm4..7 - macierz 4x4
;movps xmm3, xmm0
;mulps xmm3, xmm7 ; 4 składniki 4. elementu
;movps xmm2, xmm0
;mulps xmm2, xmm6 ; 4 składniki 3. elementu
;movps xmm1, xmm0
;mulps xmm1, xmm5 ; 4 składniki 2. elementu
;mulps xmm0, xmm4 ; 4 składniki 1. elementu
;haddps xmm2, xmm3 ; po 2 składniki 4. i 3. elementu
;haddps xmm0, xmm1 ; po 2 składniki 2. i 1. elementu
;haddps xmm0, xmm2
; xmm0 - wynik

        sub ebx, 16
        movaps xmm1, [eax + ebx]        ;load vertex vector

        movaps xmm0, [matrix]           ;load transformation matrix row
        mulps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0
        movd [points + ebx], xmm0

        movaps xmm0, [matrix+16]
        mulps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0
        movd [points+4+ebx], xmm0

        movaps xmm0, [matrix+32]
        mulps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0
        movd [points+8+ebx], xmm0

        movaps xmm0, [matrix+48]
        mulps xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0
        movd [points+12+ebx], xmm0

        cmp ebx, 0
        jnz .outer_loop

projecting:
    mov eax, 128
    mov ebx, 64

    movd xmm4, [half_size]
    outer_loop_2:
        sub eax, 16
        sub ebx, 8

        movd xmm0, [points+eax]
        movd xmm1, [points+eax+4]
        movd xmm2, [points+eax+8]

        movd xmm3, [distance]
        divss xmm3, xmm2

        mulss xmm0, xmm3
        mulss xmm1, xmm3

        addss xmm0, xmm4
        addss xmm1, xmm4

        movd [projected_points+ebx], xmm0
        movd [projected_points+4+ebx], xmm1

        cmp eax, 0
        jnz outer_loop_2

;draw:
;    mov eax, [ebp + 12]
;    add eax, 54
;    mov ebx, 64
;
;    outer_loop_3:
;        sub ebx, 8
;
;        fld DWORD [projected_points+ebx]
;        fisttp DWORD [projected_points+ebx]
;
;        fld DWORD [projected_points+ebx+4]
;        fisttp DWORD [projected_points+ebx+4]
;
;        mov edi, [projected_points+ebx]
;        mov esi, [projected_points+ebx+4]
;
;        shl esi, 9
;
;        add esi, edi
;
;        mov edi, esi    ;mul 3
;        shl esi, 1
;        add esi, edi
;;todo add bounds check on the calculated address to prevent segfaults
;        mov [eax+esi], BYTE 0xff
;        mov [eax+esi+1], BYTE 0xff
;        mov [eax+esi+2], BYTE 0xff
;
;        cmp ebx, 0
;        jnz outer_loop_3

draw_lines:
    mov eax, [ebp+8]
    add eax, 152
    mov ebx, 96
    .outer_loop:
    sub ebx, 8

    mov edi, [eax+ebx]      ; from
    mov esi, [eax+ebx+4]    ; to

    movss xmm0, [projected_points+4*edi]		; from x
	movss xmm1, [projected_points+4+4*edi]		; from y
	movss xmm2, [projected_points+4*esi]		; to x
	movss xmm3, [projected_points+4+4*esi]		; to y

    movss xmm4, xmm2    ;dx = x2
    movss xmm5, xmm3    ;dy = y2

    subss xmm4, xmm0    ;dx = x2-x1
    subss xmm5, xmm1    ;dy = y2-y1

    movss xmm6, xmm4
    movss xmm7, xmm5

    pslld  xmm6, 1  ;abs
    psrld  xmm6, 1

    pslld  xmm7, 1
    psrld  xmm7, 1

    comiss xmm7, xmm6
    jle .skip           ; step = dx
    movss xmm6, xmm7    ; step = dy
    .skip:

    divss xmm4, xmm6
    divss xmm5, xmm6

    ;load some with float 0 to iterate
    .inner_loop:
        addss xmm0, xmm4
        addss xmm1, xmm5

        cvtss2si edi, xmm0
        cvtss2si esi, xmm1

        .hey:
        shl esi, 9

        add esi, edi

        mov edi, esi    ;mul 3
        shl esi, 1
        add esi, edi
    ;    ;todo add bounds check on the calculated address to prevent segfaults


        push eax
        mov eax, [ebp+12]
        add eax, 54
        mov [eax+esi], BYTE 0xff
        mov [eax+esi+1], BYTE 0xff
        mov [eax+esi+2], BYTE 0xff

        pop eax

    cmp ebx, 8
    jne .outer_loop




	pop edi
	pop esi
	pop ebx

	mov esp, ebp
	pop ebp
	ret