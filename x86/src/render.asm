section	.text
global _render
_render:
	push ebp
	mov ebp, esp

	push ebx
	push esi
	push edi

	mov eax, DWORD [ebp + 8]
	mov cl, BYTE [eax]
	add ecx, 1
	mov [eax], BYTE cl

	pop edi
	pop esi
	pop ebx

	mov esp, ebp
	pop ebp
	ret