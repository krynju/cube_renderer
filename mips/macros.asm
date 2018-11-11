.macro print_newline
	li	$a0, '\n'
	li	$v0, 11
	syscall	
.end_macro

.macro print_comma
	li	$a0, ','
	li	$v0, 11
	syscall	
.end_macro

.macro print_space
	li	$a0, ' '
	li	$v0, 11
	syscall	
.end_macro

.macro print_tab
	li	$a0, '	'
	li	$v0, 11
	syscall	
.end_macro
