section	.text
global _render
_render:
	push ebp
	mov ebp, esp

	push ebx
	push esi
	push edi

	mov eax, DWORD [ebp + 8]
	mov ebx, DWORD [ebp + 12]
	lea esi, [eax + 786486]
loopy:
	mov edi, [eax]
	mov [ebx], edi
	add eax, 1
	add ebx, 1
	cmp eax, esi
	jne loopy

	pop edi
	pop esi
	pop ebx

	mov esp, ebp
	pop ebp
	ret