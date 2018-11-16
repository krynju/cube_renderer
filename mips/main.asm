.include "macros.asm"

.eqv	BITMAP_SIZE 				786432
.eqv	CANVAS_DISTANCE				80.0
.eqv	CUBE_ROTATION_MATRIX_SIZE		36
.eqv	CUBE_POSITION_VECTOR_SIZE		12
.eqv	VERTICES_ARRAY_SIZE			96
.eqv	PROJECTED_POINTS_SIZE			64



.data
	## cube rotation matrix 		36 bytes = 3x3 bytes
	cube_rotation:		.float		1.0, 0.0, 0.0, 
						0.0, 1.0, 0.0, 
						0.0, 0.0, 1.0
			
	## cube position vector 		12 bytes = 3x4 bytes
	cube_position:		.float		0.0, 
						100.0, 
						-200.0
	
	## array of vertex vectors 		96 bytes = 8x12 bytes 
	vertices:		.float		75.0, 	75.0, 	75.0, 		
						75.0, 	-75.0, 	75.0, 		
						-75.0, 	75.0, 	75.0,
						-75.0, 	-75.0, 	75.0,
						75.0, 	75.0, 	-75.0, 		
						75.0, 	-75.0, 	-75.0, 		
						-75.0, 	75.0, 	-75.0,
						-75.0, 	-75.0, 	-75.0
						
	## array of projected vertices onto the canvas, contains a pair of x and y cords (float) for every vertex
	##				 	bytes = 8x8 bytes
	projected_points:	.space		PROJECTED_POINTS_SIZE
	
	## canvas distance 
	canvas_distance:	.float		CANVAS_DISTANCE
	
	## output filename 
	filename:		.asciiz 	"mips_output.bmp"
	
	## 512x512 basic 24-bit bitmap header
	bitmap_header:		.half		0x4d42, 0x0036, 0x000c, 0x0000, 0x0000, 0x0036, 0x0000, 0x0028,
 						0x0000, 0x0200, 0x0000, 0x0200, 0x0000, 0x0001, 0x0018, 0x0000,
 						0x0000, 0x0000, 0x000c, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
 						0x0000, 0x0000, 0x0000
	## pixel space - 512x512x3 bytes
				.align 2
	bitmap: 		.space		BITMAP_SIZE ## 786432
	float1:			.float		1.0
	
.text

main:
#####################################################################################################################
	## CUBE_MATRIX x VERTICES_VECTORS MULTIPLY	## REGISTERS USED IN ITERATION AND OFFSET
	##	$t0 					## matrix row offset, start at sizeof(matrix)
	##	$t1 					## position vector row offset, start at sizeof(pos_vector)
	##	$t2					## currently calculated element offset	
	##	$t3					## vertices iteration, starts at sizeof(vertices)
	
	li	$t0, CUBE_ROTATION_MATRIX_SIZE #32	## matrix row offset, load with sizeof(matrix)
	li	$t1, CUBE_POSITION_VECTOR_SIZE #12	## position vector row offset, load with sizeof(pos_vector)
matrix_loop:
	sub	$t0, $t0, 12				## decrement matrix offset
	sub	$t1, $t1, 4				## decrement pos_vector offset
	
	lwc1	$f2, cube_rotation($t0)		## load matrix row 
	lwc1	$f3, cube_rotation+4($t0)
	lwc1	$f4, cube_rotation+8($t0)
	lwc1	$f5, cube_position($t1)		## load position vector element
	
	li	$t3, VERTICES_ARRAY_SIZE		## vertices iteration, load with sizeof(vertices)
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
	li	$t2, PROJECTED_POINTS_SIZE #64		## projected points iteration, load with sizeof(projected_points)
	li	$t3, VERTICES_ARRAY_SIZE   #96		## vertices iteration, load with sizeof(vertices)
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
	##li	$t0, 196608				## pixelmap iteration, load with sizeof(bitmap)
	##li	$t1, 0xFFFFFFFF				## constant to be written on all bytes
##fill_loop:
	##sub	$t0, $t0, 4				## decrement pixelmap iteration
	##sw	$t1, bitmap($t0)			## red
	##bnez	$t0, fill_loop				## loopback filling loop
	
#####################################################################################################################
	## DRAW POINTS 
	#todo add comments
	li	$t0, PROJECTED_POINTS_SIZE #64	
	li	$t4, 0xFF
point_drawing_loop:
	sub	$t0, $t0, 8
	lwc1	$f1, projected_points($t0)
	lwc1	$f2, projected_points+4($t0)
	cvt.w.s	$f1, $f1
	cvt.w.s	$f2, $f2
	mfc1	$t1, $f1
	mfc1	$t2, $f2
	add	$t1, $t1, 256
	add	$t2, $t2, 256
	mul	$t3, $t2, 512		##todo change to shift left
	add	$t3, $t3, $t1
	mul	$t3, $t3, 3		## todo maybe change to shift +add
	sb	$t4, bitmap($t3)			## red
	sb	$t4, bitmap+1($t3)			## green
	sb	$t4, bitmap+2($t3)			## blue
	bnez	$t0, point_drawing_loop
	
#####################################################################################################################
	## DRAW LINE TEST
	li	$t0, PROJECTED_POINTS_SIZE #64	
	li	$t4, 0xFF

	sub	$t0, $t0, 8
	lwc1	$f3, projected_points($t0)
	lwc1	$f4, projected_points+4($t0)
	sub	$t0, $t0, 24
	lwc1	$f5, projected_points($t0)
	lwc1	$f6, projected_points+4($t0)
	
	sub.s	$f7, $f5, $f3	#x2-x1
	sub.d	$f8, $f6, $f4  #y2-y1
	
	div.s	$f30,$f8, $f7 	#a
	mul.s  $f31, $f30, $f3
	neg.s	$f31,$f31
	add.s	$f31,$f31,$f4	#b
	#y=ax+b
	
	mov.s	$f1, $f3
	
	li $t0, 50
	lwc1 $f12, float1
	mov.s $f1, $f3
line_drawing_loop:
	#color pixel at ($f1, $f2)
	sub $t0, $t0, 1
	add.s $f1, $f1, $f12
	mul.s $f2, $f1, $f30
	add.s $f2, $f2, $f31

	
	cvt.w.s	$f21, $f1
	cvt.w.s	$f22, $f2
	mfc1	$t1, $f21
	mfc1	$t2, $f22
	add	$t1, $t1, 256
	add	$t2, $t2, 256
	mul	$t3, $t2, 512		##todo change to shift left
	add	$t3, $t3, $t1
	mul	$t3, $t3, 3		## todo maybe change to shift +add
	
	sb	$t4, bitmap($t3)			## red
	sb	$t4, bitmap+1($t3)			## green
	sb	$t4, bitmap+2($t3)			## blue
	
	bnez	$t0, line_drawing_loop
	
	
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
	li   	$a2, BITMAP_SIZE ## 786432		## hardcoded buffer length
	syscall            				## write to file
	
	li   	$v0, 16       				## system call for close file
	move 	$a0, $s6      				## file descriptor to close
	syscall            				## close file


#####################################################################################################################
	## PRINT RESULT					## PRINT PROJECTED POINTS AND VERTEX VECTORS
	li	$t0, PROJECTED_POINTS_SIZE #64		## projected
	li	$t1, VERTICES_ARRAY_SIZE   #96		## vertices
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



