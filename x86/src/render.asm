matrix: dd  1.0, 0, 0, 0,       \
            0, 1.0, 0, 0,       \
            0, 0, 1.0, -200.0,  \
            0, 0, 0, 1.0

distance: dd -80.0
half_size: dd 256.0

section .bss
points: resd 32
projected_points: resd 16


section .text
global _render
_render:
	push ebp
	mov ebp, esp

	push ebx
	push esi
	push edi

	mov eax, [ebp + 8]
	mov ebx, 128
outer_loop:
    sub ebx, 16
    movaps xmm1, [eax + ebx]

    movaps xmm0, [matrix]
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
    jnz outer_loop

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
    divss xmm2, xmm3

    mulss xmm0, xmm2
    mulss xmm1, xmm2

    addss xmm0, xmm4
    addss xmm1, xmm4

    movd [projected_points+ebx], xmm0
    movd [projected_points+4+ebx], xmm1

    cmp eax, 0
    jnz outer_loop_2

draw:
    mov eax, [ebp + 12]
    mov ebx, 64
    mov ecx, [ebp + 8]
outer_loop_3:
    sub ebx, 8

    mov edi, [projected_points+ebx]
    fld DWORD [projected_points+ebx]
    fisttp DWORD [projected_points+ebx]

    mov esi, [projected_points+ebx+4]
    fld DWORD [projected_points+ebx+4]
    fisttp DWORD [projected_points+ebx+4]

    mov edi, [projected_points+ebx]
    mov esi, [projected_points+ebx+4]

    shl esi, 9

    add esi, edi

    mov edi, esi    ;mul 3
    shl esi, 1
    add esi, edi

    mov [eax+esi], BYTE 0xff
    mov [eax+esi+1], BYTE 0xff
    mov [eax+esi+2], BYTE 0xff

    cmp ebx, 0
    jnz outer_loop_3





	pop edi
	pop esi
	pop ebx

	mov esp, ebp
	pop ebp
	ret