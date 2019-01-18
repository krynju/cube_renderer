section .data
matrix: dd  1.0, 0, 0, 0,       \
            0, 1.0, 0, 0,       \
            0, 0, 1.0, -200.0,  \
            0, 0, 0, 1.0

distance: dd -100.0
half_size: dd 256.0
float1: dd 1.0

section .bss
points: resd 32
projected_points: resd 16
sine: resd 3
cosine: resd 3

temp:resd 1
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

    movss xmm4, [half_size]
    outer_loop_2:
        sub eax, 16
        sub ebx, 8

        movss xmm0, [points+eax]
        movss xmm1, [points+eax+4]
        movss xmm2, [points+eax+8]

        movss xmm3, [distance]
        divss xmm3, xmm2

        mulss xmm0, xmm3
        mulss xmm1, xmm3

        addss xmm0, xmm4
        addss xmm1, xmm4

        movss [projected_points+ebx], xmm0
        movss [projected_points+4+ebx], xmm1

        cmp eax, 0
        jnz outer_loop_2



draw_lines:
    mov eax, [ebp+8]                ; load cube struct address
    add eax, 152                    ; add offset for
    mov edx, [ebp+12]               ; load bitmap address
    add edx, 54                     ; add header offset
    movss xmm6, [float1]            ; load float 1.0 into a register for fast incrementing

    mov ebx, 96                     ; load connections size for offsetting
    .outer_loop:
    sub ebx, 8                      ; decrement the connections offset

    mov edi, [eax+ebx]              ; load index of source vertex
    mov esi, [eax+ebx+4]            ; load index of destination vertex

    movss xmm0, [projected_points+8*edi]        ; load source vertex projected x cord
    movss xmm1, [projected_points+8*edi+4]      ; load source vertex projected y cord
    movss xmm2, [projected_points+8*esi]        ; load destination vertex projected x cord
    movss xmm3, [projected_points+8*esi+4]      ; load destination vertex projected y cord

    subss xmm2, xmm0                ; dx = x_d - x_s
    subss xmm3, xmm1                ; dy = y_d - y_1

    movss xmm4, xmm2                ; move dx to new register
    movss xmm5, xmm3                ; move dy to new register

    pslld  xmm4, 1                  ; abs(dx)
    psrld  xmm4, 1

    pslld  xmm5, 1                  ; abs(dy)
    psrld  xmm5, 1

    comiss xmm4, xmm5               ; pick the larger absolute value delta, step = max(abs(dx),abs(dy))
    ja .skip                        ; step = abs(dx)
    movss xmm4, xmm5                ; step = abs(dy)
    .skip:

    divss xmm2, xmm4                ; x_inc = dx/step
    divss xmm3, xmm4                ; y_inc = dy/step

    xorps xmm5, xmm5                ; zero       xmm5
    .inner_loop:
        cvtss2si edi, xmm0          ; convert x float to int32
        cvtss2si esi, xmm1          ; convert y float to int32

        shl esi, 9                  ; y*=512
        add esi, edi                ; y+=x
        lea esi, [esi*3]            ; y*=3

        cmp esi, 786486-54          ; check boundaries to prevent segfaults
        jge .skip_pixel_draw        ; todo add bitmap size as define here instead of size hardcode
        cmp esi, 0
        jl  .skip_pixel_draw

        mov [edx+esi], BYTE 0xff    ; fill red channel
        mov [edx+esi+1], BYTE 0xff  ; fill green channel
        mov [edx+esi+2], BYTE 0xff  ; fill blue channel

        .skip_pixel_draw:

        addss xmm0, xmm2            ; x += x_inc
        addss xmm1, xmm3            ; y += y_inc


        addss xmm5, xmm6            ; x += 1.0
        comiss xmm5, xmm4           ; check if less than step
        jb .inner_loop

    cmp ebx,0                       ; check if all connections were drawn
    jne .outer_loop

epilogue:
	pop edi
	pop esi
	pop ebx

	mov esp, ebp
	pop ebp
	ret