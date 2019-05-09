section .data
matrix:             dd  1.0, 0, 0, 0,       \
                        0, 1.0, 0, 0,       \
                        0, 0, 1.0, -200.0,  \
                        0, 0, 0, 1.0

distance:           dd  -100.0
half_size:          dd  256.0
float1:             dd 	1.0
bitmap_size:		dq	1048576

section .bss
points:             resd 	32
                    align 	16
projected_points:   resd 	16
					align 	16
sine:               resd 	3
cosine:             resd 	3

section .text
global render

render:
    mov [rsp + 8], rcx
    push r15
    push r14
    push r13
	push r12
	push rbx

    ;rdi 1 arg ; rcx on windows
    ;r13 2 arg ; rdx on windows
calculate_trigs:
    mov rax, rcx

    fld DWORD [rax+140]         ;push x rot to fpu stack
    fsin
    fstp DWORD [sine]           ;save sin(x)
    fld DWORD [rax+140]         ;push x rot to fpu stack
    fcos
    fstp DWORD [cosine]         ;save cos(x)

    fld DWORD [rax+144]         ;push y rot to fpu stack
    fsin
    fstp DWORD [sine+4]         ;save sin(y)
    fld DWORD [rax+144]         ;push z rot to fpu stack
    fcos
    fstp DWORD [cosine+4]       ;save cos(y)

    fld DWORD [rax+148]         ;push z rot to fpu stack
    fsin
    fstp DWORD [sine+8]         ;save sin(z)
    fld DWORD [rax+148]         ;push z rot to fpu stack
    fcos
    fstp DWORD [cosine+8]       ;save cos(z)

fill_position_vector:
    mov rax, rcx
    mov rbx, [rax+128]
    mov [matrix + 12], rbx
    mov rbx, [rax+132]
	mov [matrix + 28], rbx
    mov rbx, [rax+136]
    mov [matrix + 44], rbx

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
    mulss xmm1, xmm7						; cos(z)*sin(x)
    subss xmm0, xmm1				        ; a32 = cos(x)*sin(y)*sin(z) - cos(z)*sin(x)
    movss [matrix+36], xmm0 			    ; a32 store

    movss xmm0, xmm3
    mulss xmm0, xmm5				        ; a33 = cos(x)*cos(y)
    movss [matrix+40], xmm0 			    ; a33 store

vertices_transformation:
	mov rax, rcx
	mov rbx, 128
    .outer_loop:
    sub rbx, 16
    movaps xmm0, [rax + rbx]        ; load vertex vector

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

    movaps [points + rbx], xmm0 ; load the transformed vector to memory

    cmp rbx, 0
    jnz .outer_loop

projecting_vertices:
    mov rax, 128
    mov rbx, 64
    movss xmm5, [distance]
    shufps xmm5, xmm5, 0x00   ; fill xmm5 with distance
    movss xmm4, [half_size]
    shufps xmm4, xmm4, 0x00   ; fill xmm4 with 256.0's
    .loop:
    sub rax, 16
    sub rbx, 8

    movaps xmm0, [points+rax]   ; load xmm0 with x y z 1
    shufps xmm1, xmm0, 0xAA     ; load xmm1 with 0 0 z z
    shufps xmm1, xmm1, 0xAA     ; load xmm1 with z z z z

    movaps xmm3, xmm5           ; copy distance register to xmm3
    divps xmm3, xmm1            ; distance / z

    mulps xmm0, xmm3            ; xmm0 vector times distance/z

    addps xmm0, xmm4            ; add 256.0 filled vector

    movss [projected_points+rbx], xmm0      ; save projected x
    shufps xmm0, xmm0, 0xE5                 ; shuffle projected y onto [31:0]
    movss [projected_points+4+rbx], xmm0    ; save projected y

    cmp rax, 0
    jnz .loop



draw_lines:
    mov r8, rcx		; load cube struct address
    add r8, 152		; add offset for
    mov r9, rdx		; load bitmap address
    movss xmm6, [float1]	; load float 1.0 into a register for fast incrementing

    mov r14, 96             ; load connections size for offsetting
    .outer_loop:
    sub r14, 8              ; decrement the connections offset

    xor rax, rax
    xor rbx, rbx

    mov eax, DWORD[r8+r14]              ; load index of source vertex
    mov ebx, DWORD[r8+r14+4]            ; load index of destination vertex

	.outer_loop20:
    movss xmm0, [projected_points+8*rax]        ; load source vertex projected x cord
    movss xmm1, [projected_points+8*rax+4]      ; load source vertex projected y cord
    movss xmm2, [projected_points+8*rbx]        ; load destination vertex projected x cord
    movss xmm3, [projected_points+8*rbx+4]      ; load destination vertex projected y cord

	.outer_loop3:
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
    cvtss2si eax, xmm0          ; convert x float to int32
    cvtss2si ebx, xmm1          ; convert y float to int32

    shl rbx, 9                  ; y*=512
    add rbx, rax                ; y+=x
    lea rbx, [rbx*4]            ; y*=3

    cmp rbx, bitmap_size          ; check boundaries to prevent segfaults
    jge .skip_pixel_draw        ; todo add bitmap size as define here instead of size hardcode
    cmp rbx, 0
    jl  .skip_pixel_draw

	mov [r9+rbx], DWORD 0xffffffff

    .skip_pixel_draw:

    addss xmm0, xmm2            ; x += x_inc
    addss xmm1, xmm3            ; y += y_inc

    addss xmm5, xmm6            ; x += 1.0
    comiss xmm5, xmm4           ; check if less than step
    jb .inner_loop


    cmp r14,0                   ; check if all connections were drawn
    jne .outer_loop

epilogue:
	pop	rbx
	pop	R12
    pop R13
    pop R14
    pop R15
    ret
