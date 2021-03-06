section .data
matrix: 	dd  1.0, 0, 0, 0,       \
            	0, 1.0, 0, 0,       \
            	0, 0, 1.0, -200.0,  \
            	0, 0, 0, 1.0
distance: 	dd 	-100.0
half_size: 	dd 	256.0
float1: 	dd 	1.0

section .bss
points: 			resd 	32
        			align 	16
projected_points: 	resd 	16
sine: 				resd 3
cosine: 			resd 3

section .text
global _render

_render:
	push ebp
	mov ebp, esp

	push ebx
	push esi
	push edi

calculate_trigs:
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
    mov ebx, [eax+128]
    mov [matrix + 12], ebx
    mov ebx, [eax+132]
    mov [matrix + 28], ebx
    mov ebx, [eax+136]
    mov [matrix + 44], ebx

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

vertices_transformation:
	mov eax, [ebp + 8]
	mov ebx, 128
.outer_loop:
	sub ebx, 16
	movaps xmm0, [eax + ebx]        ; load vertex vector

	movaps xmm4, [matrix]           ; load transformation matrix rows
	movaps xmm5, [matrix+16]
	movaps xmm6, [matrix+32]
	movaps xmm7, [matrix+48]

	movaps xmm3, xmm0   ; copy vector
	mulps xmm3, xmm7    ; row4*vector
	movaps xmm2, xmm0   ; copy vector
	mulps xmm2, xmm6    ; row3*vector
	haddps xmm2, xmm3   ; xmm2 =
	; | xmm2[127:96]+xmm2[95:64] | xmm2[63:31]+xmm2[31:0] | xmm3[127:96]+xmm3[95:64] | xmm3[63:31] + xmm3[31:0] |

	movaps xmm1, xmm0   ; copy vector
	mulps xmm1, xmm5    ; row2*vector
	mulps xmm0, xmm4    ; row1*vector
	haddps xmm0, xmm1   ; xmm0 =
	; | xmm0[127:96]+xmm0[95:64] | xmm0[63:31]+xmm0[31:0] | xmm1[127:96]+xmm1[95:64] | xmm1[63:31] + xmm1[31:0] |

	haddps xmm0, xmm2
	; | xmm0[127:64]+xmm0[63:0] | xmm1[127:64]+xmm1[63:0] | xmm2[127:64]+xmm2[63:0] | xmm3[127:64]+xmm3[63:0] |
	; xmm0 = | xmm0[127:0] | xmm1[127:0] | xmm2[127:0] | xmm3[127:0] |

	movaps [points + ebx], xmm0 ; load the transformed vector to memory

	cmp ebx, 0
	jnz .outer_loop

projecting_vertices:
    mov eax, 128
    mov ebx, 64
    movss xmm5, [distance]
    shufps xmm5, xmm5, 0x00   ; fill xmm5 with distance
    movss xmm4, [half_size]
    shufps xmm4, xmm4, 0x00   ; fill xmm4 with 256.0's
.loop:
	sub eax, 16
	sub ebx, 8

	movaps xmm0, [points+eax]   ; load xmm0 with x y z 1
	shufps xmm1, xmm0, 0xAA     ; load xmm1 with 0 0 z z
	shufps xmm1, xmm1, 0xAA     ; load xmm1 with z z z z

	movaps xmm3, xmm5           ; copy distance register to xmm3
	divps xmm3, xmm1            ; distance / z

	mulps xmm0, xmm3            ; xmm0 vector times distance/z

	addps xmm0, xmm4            ; add 256.0 filled vector

	movss [projected_points+ebx], xmm0      ; save projected x
	shufps xmm0, xmm0, 0xE5                 ; shuffle projected y onto [31:0]
	movss [projected_points+4+ebx], xmm0    ; save projected y

	cmp eax, 0
	jnz .loop



draw_lines:
    mov eax, [ebp+8]                    ; load cube struct address
    add eax, 152                        ; add offset for
    mov edx, [ebp+12]                   ; load bitmap address
    add edx, 54                         ; add header offset
    movss xmm6, [float1]                ; load float 1.0 into a register for fast incrementing

    mov ebx, 96                         ; load connections size for offsetting
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