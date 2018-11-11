.include "macros.asm"

.data
	## cube rotation matrix 3x3 -> 9 floats -> 36 bytes 
	cube_rotation_matrix:	.float		1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0
	## cube position vector 3x1 -> 3 floats -> 12 bytes
	cube_position_vector:	.float		0.0, 0.0, -100.0
	## cube vertices array of vectors, each vector 12 bytes -> 2x12 -> 24 bytes 
	## TEMPORARLY ONLY 2 VERTICES FOR TESTING PURPOSES	
	vertices:		.float		50.0, 50.0, 50.0, -50.0, 50.0, 50.0,
						50.0, -50.0, 50.0, -50.0, -50.0, 50.0,
						50.0, 50.0, -50.0, -50.0, 50.0, -50.0,
						50.0, -50.0, -50.0, -50.0, -50.0, -50.0
	## array of pairs (x,y), vertices vectors projected onto plane, each pair 8 bytes -> 2x8 -> 16 bytes
	projected_points:	.space		64
	## canvas distance 
	canvas_distance:	.float		10.0
	
	filename:		.asciiz 	"mips_output.bmp"
	bitmap_header:		.half		0x4d42, 0x0036, 0x0003, 0x0000, 0x0000, 0x0036, 0x0000, 0x0028,
						0x0000, 0x0100, 0x0000, 0x0100, 0x0000, 0x0001, 0x0018, 0x0000,
						0x0000, 0x0000, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
						0x0000, 0x0000, 0x0000
	## pixel space - 256*256*3byte 
	bitmap: 		.space		196608
	
.text

main:
#####################################################################################################################
	## CUBE_MATRIX x VERTICES_VECTORS MULTIPLY	## REGISTERS USED IN ITERATION AND OFFSET
	##	$t0 					## matrix row offset, start at sizeof(matrix)
	##	$t1 					## position vector row offset, start at sizeof(pos_vector)
	##	$t2					## currently calculated element offset	
	##	$t3					## vertices iteration, starts at sizeof(vertices)
	
	li	$t0, 36					## matrix row offset, load with sizeof(matrix)
	li	$t1, 12					## position vector row offset, load with sizeof(pos_vector)
matrix_loop:
	sub	$t0, $t0, 12				## decrement matrix offset
	sub	$t1, $t1, 4				## decrement pos_vector offset
	
	lwc1	$f2, cube_rotation_matrix($t0)		## load matrix row 
	lwc1	$f3, cube_rotation_matrix+4($t0)
	lwc1	$f4, cube_rotation_matrix+8($t0)
	lwc1	$f5, cube_position_vector($t1)		## load position vector element
	
	li	$t3, 96					## vertices iteration, load with sizeof(vertices)
vertices_loop:
	sub	$t3, $t3, 12				## decrement the vertices offset
	add	$t2, $t3, $t1				## calculate the current element offset
	
	lwc1	$f6, vertices($t3)			## load vertex vector
	lwc1	$f7, vertices+4($t3)
	lwc1	$f8, vertices+8($t3)
	
	mov.s	$f0, $f5				## 0 + pos_vector * 1 
	mul.s	$f1, $f2, $f6				## mxm1 * vertex_vector1
	add.s	$f0, $f0, $f1
	mul.s	$f1, $f3, $f7				## mxm2 * vertex_vector2
	add.s	$f0, $f0, $f1
	mul.s	$f1, $f4, $f8				## mxm3 * vertex_vector3
	add.s	$f0, $f0, $f1
	
	swc1	$f0, vertices($t2)			## save the result
	
	bnez	$t3, vertices_loop			## inner loopback - vertices iteration
	bnez	$t0, matrix_loop			## outer loopback - matrix row iteration
	
#####################################################################################################################
	## PROJECTING VERTICES TO PLANE		## REGISTERS USED IN ITERATION AND OFFSET
	##	$f2					## canvas distance 
	##	$t2					## projected points iteration, starts with sizeof(projected_points)
	##	$t3					## vertices iteration, starts with sizeof(vertices)
	
	lwc1	$f2, canvas_distance			## load canvas distance
	li	$t2, 64					## projected points iteration, load with sizeof(projected_points)
	li	$t3, 96					## vertices iteration, load with sizeof(vertices)
projection_loop:
	sub	$t2, $t2, 8				## decrement the projected_points offset
	sub	$t3, $t3, 12				## decrement the vertices offset
	
	lwc1	$f6, vertices($t3)			## load vertex vector
	lwc1	$f7, vertices+4($t3)
	lwc1	$f8, vertices+8($t3)
	
	neg.s	$f3, $f2				## -distance
	div.s	$f3, $f3, $f8				## -distance/z
	
	mul.s	$f0, $f6, $f3 				## x * (-distance/z)
	mul.s	$f1, $f7, $f3				## y * (-distance/z)
	
	swc1	$f0, projected_points($t2)		## store x
	swc1	$f1, projected_points+4($t2)		## store y
	
	bnez	$t3, projection_loop			## loopback projection iteration
	
	
#####################################################################################################################
	## FILL PIXELMAP				## FILL THE BITMAP WITH SOME CONSTANT
	li	$t0, 196608				## pixelmap iteration, load with sizeof(bitmap)
	la	$t1, 0xCC				## constant to be written on all bytes
fill_loop:
	sub	$t0, $t0, 3				## decrement pixelmap iteration

	sb	$t1, bitmap($t0)			## red
	sb	$t1, bitmap+1($t0)			## green
	sb	$t1, bitmap+2($t0)			## blue

	bnez	$t0, fill_loop				## loopback filling loop
	
#####################################################################################################################
	## FILE HANDLING				## write header to file, then fill the bitmap
  	li	$v0, 13					## system call for open file
	la	$a0, filename				## output file name
	li	$a1, 1					## Open for writing (flags are 0: read, 1: write)
	li	$a2, 0        				## mode is ignored
	syscall            				## open a file (file descriptor returned in $v0)
	move	$s6, $v0      				## save the file descriptor 

	li	$v0, 15       				## system call for write to file
	move 	$a0, $s6      				## file descriptor 
	la   	$a1, bitmap_header  			## address of buffer from which to write
	li   	$a2, 54     				## hardcoded buffer length
	syscall            				## write to file
	
	li	$v0, 15       				## system call for write to file
	move 	$a0, $s6   				## file descriptor 
	la   	$a1, bitmap				## address of buffer from which to write
	li   	$a2, 196608    				## hardcoded buffer length
	syscall            				## write to file
	
	li   	$v0, 16       				## system call for close file
	move 	$a0, $s6      				## file descriptor to close
	syscall            				## close file


#####################################################################################################################
	## PRINT RESULT					## PRINT PROJECTED POINTS AND VERTEX VECTORS
	li	$t0, 64					## projected
	li	$t1, 96					## vertices
print_loop:
	sub	$t0, $t0, 8
	sub	$t1, $t1, 12
	lwc1	$f12, projected_points($t0)
	li	$v0, 2
	syscall	
	print_tab
	lwc1	$f12, projected_points+4($t0)
	li	$v0, 2
	syscall
	print_tab
	print_tab
	lwc1	$f12, vertices($t0)
	li	$v0, 2
	syscall	
	print_comma
	print_tab
	lwc1	$f12, vertices+4($t0)
	li	$v0, 2
	syscall	
	print_tab
	lwc1	$f12, vertices+8($t0)
	li	$v0, 2
	syscall		
	print_newline
	bnez	$t0, print_loop
#####################################################################################################################
	## EXIT
exit:
	li	$v0, 10
	syscall



