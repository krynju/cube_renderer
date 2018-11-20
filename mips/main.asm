.include "macros.asm"

.eqv	BITMAP_SIZE 				786432
.eqv	CANVAS_DISTANCE				75.0
.eqv	CUBE_ROTATION_MATRIX_SIZE		36
.eqv	CUBE_POSITION_VECTOR_SIZE		12
.eqv	VERTICES_ARRAY_SIZE			96
.eqv	PROJECTED_POINTS_SIZE			64
.eqv	BITMAP_SIDE				256.0


.data
	## cube rotation matrix 		36 bytes = 3x3x4 bytes
	cube_rotation:		.float		1.0, 0.0, 0.0, 
						0.0, 1.0, 0.0, 
						0.0, 0.0, 1.0
			
	## cube position vector 		12 bytes = 3x4 bytes
	cube_position:		.float		150.0, 
						50.0, 
						-150.0
	
	## array of vertex vectors 		96 bytes = 8x12 bytes 	## LINE CONNECTIONS
	vertices:		.float		-75.0, 	75.0, 	75.0,	## v1 -> v6,v7
						-75.0, 	-75.0, 	-75.0,	## v2 -> v5,v7
						75.0, 	-75.0, 	75.0,	## v3 -> v5,v6
						-75.0, -75.0, 	75.0,	## v4 -> v1,v2,v3
						75.0, 	-75.0, 	-75.0, 	## v5
						75.0, 	75.0, 	75.0, 	## v6
						-75.0, 	75.0, 	-75.0,	## v7
						75.0, 	75.0, 	-75.0,	## v8 -> v5,v6,v7
						
	transformed_vertices:	.space 		96	##TODO DO SOMETHING WITH THIS
							
							
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
	float0:			.float		0.0
	float2:			.float		2.0
	bitmap_side:		.float		BITMAP_SIDE
	
	lines:			.space		192
	
	s_roll:			.float		0.0
	c_roll:			.float		1.0
	s_pitch:		.float		0.0
	c_pitch:		.float		1.0
	s_yaw:			.float		0.707
	c_yaw:			.float		0.707
	
.text

main:
	lwc1	$f2, s_roll				## sin(x)
	lwc1	$f3, c_roll				## cos(x)
	lwc1	$f4, s_pitch				## sin(y)
	lwc1	$f5, c_pitch				## cos(y)
	lwc1	$f6, s_yaw				## sin(z)
	lwc1	$f7, c_yaw				## cos(z)
	
	mul.s	$f0, $f5, $f7				## a11 = cos(y)*cos(z)
	swc1	$f0, cube_rotation
	mul.s	$f0, $f5, $f6				## a12 = cos(y)*sin(z)
	swc1	$f0, cube_rotation+4
	neg.s	$f0, $f4				## a13 = -sin(y)
	swc1	$f0, cube_rotation+8
	mul.s	$f0, $f7, $f2				## cos(z)*sin(x)
	mul.s	$f0, $f0, $f4				## cos(z)*sin(x)*sin(y)
	mul.s	$f1, $f3, $f6				## cos(x)*sin(z)
	sub.s	$f0, $f0, $f1				## a21 = cos(z)*sin(x)*sin(y) - cos(x)*sin(z)
	swc1	$f0, cube_rotation+12

	mul.s	$f0, $f3, $f7
	mul.s	$f1, $f2, $f4
	mul.s	$f1, $f1, $f6
	add.s 	$f0, $f0, $f1
	swc1	$f0, cube_rotation+16
	mul.s	$f0, $f5, $f2
	swc1	$f0, cube_rotation+20
	
	mul.s	$f0, $f2, $f6
	mul.s	$f1, $f3, $f7
	mul.s	$f1, $f1, $f4
	add.s 	$f0, $f0, $f1
	swc1	$f0, cube_rotation+24
	
	mul.s	$f0, $f3, $f4			
	mul.s	$f0, $f0, $f6				
	mul.s	$f1, $f2, $f7			
	sub.s	$f0, $f0, $f1	
	swc1	$f0, cube_rotation+28
	
	mul.s	$f0, $f3, $f5
	swc1	$f0, cube_rotation+32
	
		


#####################################################################################################################
	## CUBE_MATRIX x VERTICES_VECTORS MULTIPLY	## REGISTERS USED IN ITERATION AND OFFSET
	##	$t0 					## matrix row offset, start at sizeof(matrix)
	##	$t1 					## position vector row offset, start at sizeof(pos_vector)
	##	$t2					## currently calculated element offset	
	##	$t3					## vertices iteration, starts at sizeof(vertices)
	##	$f0					## accumulator used in calcs
	##	$f1					## accumulator used in calcs
	##	$f2					## mx1	rot matrix
	##	$f3					## mx2	rot matrix
	##	$f4					## mx3	rot matrix
	##	$f5					## px 	position vector
	
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
	
	swc1	$f0, transformed_vertices($t2)		## save the result
	
	bnez	$t3, vertices_loop			## inner loopback - vertices iteration
	bnez	$t0, matrix_loop			## outer loopback - matrix row iteration
	
#####################################################################################################################
	## PROJECTING VERTICES TO PLANE		## REGISTERS USED IN ITERATION AND OFFSET
	##	$t0					## projected points iteration, starts with sizeof(projected_points)
	##	$t1					## vertices iteration, starts with sizeof(vertices)
	##	$f0					## x vertex vector
	##	$f1					## y vertex vector
	##	$f2					## z vertex vector
	##	$f3					## -distance/z
	##	$f4					## canvas distance 
	##	$f5					## load half of bitmap side size
	
	
	lwc1	$f4, canvas_distance			## load canvas distance
	lwc1	$f5, bitmap_side			## load half of bitmap side size
	li	$t0, PROJECTED_POINTS_SIZE #64		## projected points iteration, load with sizeof(projected_points)
	li	$t1, VERTICES_ARRAY_SIZE   #96		## vertices iteration, load with sizeof(vertices)
	
projection_loop:
	sub	$t0, $t0, 8				## decrement the projected_points offset
	sub	$t1, $t1, 12				## decrement the vertices offset
	
	lwc1	$f0, transformed_vertices($t1)		## x vertex vector
	lwc1	$f1, transformed_vertices+4($t1)	## y vertex vector
	lwc1	$f2, transformed_vertices+8($t1)	## z vertex vector	
	
	neg.s	$f3, $f4				## -distance
	div.s	$f3, $f3, $f2				## -distance/z
	
	mul.s	$f0, $f0, $f3 				## x * (-distance/z)
	mul.s	$f1, $f1, $f3				## y * (-distance/z)
	
	add.s	$f0, $f0, $f5				## change 0,0 cords to bottom left
	add.s	$f1, $f1, $f5
		
	swc1	$f0, projected_points($t0)		## store x
	swc1	$f1, projected_points+4($t0)		## store y
	
	bnez	$t0, projection_loop			## loopback projection iteration
	
#####################################################################################################################
	## GENERATING LINE PAIRS FOR FURTHER DRAW	## REGISTERS USED
	##	$t0					## marker where to put a new line
	##	$t1					## outer loop iterator
	##	$t2					## inner loop iterator
	##	$f0					## source	x
	##	$f1					## source	y
	##	$f2					## dest	 	x
	##	$f3					## dest   	y
	
	li	$t0, 0					## load lines iterator with 0
	
	## 1ST PART
	li	$t1, PROJECTED_POINTS_SIZE ##64	## iterator through projected points
generate_lines_part1_outer:				## what happens in 1st iter || what happens in 2nd iter
	sub	$t1, $t1, 32				## analyze the space by half (v8 -> v5,v6,v7 || v4 -> v1,v2,v3)
	add	$t2, $t1, 24				## add apropriate offset to grab v5,v6,v7 || v1,v2,v3
	lwc1	$f0, projected_points+24($t1)		## load v8's x and y || v4's x and y
	lwc1	$f1, projected_points+28($t1)
generate_lines_part1_inner:
	sub	$t2, $t2, 8				## offset to grab rightmost v
	lwc1	$f2, projected_points($t2)		## load its x and y
	lwc1	$f3, projected_points+4($t2)
							## create a line info structure
	swc1	$f0, lines($t0)				## source	x
	swc1	$f1, lines+4($t0)			## source	y
	swc1	$f2, lines+8($t0)			## dest	 	x
	swc1	$f3, lines+12($t0)			## dest   	y
	add	$t0, $t0, 16				## increment
	
	bne	$t2, $t1, generate_lines_part1_inner	## inner loop ends after iterating 3 times through v's
	bnez	$t1, generate_lines_part1_outer	## outer loop ends after iterating 2 times through two halves
	
	## 2ND PART					## outer iteration -> first half, inner iteration -> second half
	li	$t1, 24 				## load the outer iterator with the right offset
generate_lines_part2_outer:	
	sub	$t1, $t1, 8				## decrement the outer iterator
	lwc1	$f0, projected_points($t1)		## loading sources x and y
	lwc1	$f1, projected_points+4($t1)
	li	$t2, 56					## load the inner iterator with the right offset
generate_lines_part2_inner:
	sub	$t2, $t2, 8				## decrement the inner iterator
	
	sub	$t3, $t2, 32				## $t3 just for checking the expression
	beq	$t3, $t1, skip_same_index_in_2nd_half	## checking if the indexes match in both halves
							## according to the algorithm and vertex placement
	
	lwc1	$f2, projected_points($t2)		## loading destinations x and y
	lwc1	$f3, projected_points+4($t2)
	
							## create a line info structure
	swc1	$f0, lines($t0)				## source	x
	swc1	$f1, lines+4($t0)			## source	y
	swc1	$f2, lines+8($t0)			## dest	 	x
	swc1	$f3, lines+12($t0)			## dest   	y
	add	$t0, $t0, 16				## increment
	
	skip_same_index_in_2nd_half:
	bne	$t2, 32 , generate_lines_part2_inner
	bnez	$t1, generate_lines_part2_outer

#####################################################################################################################
	## DRAW GENERATED LINES			## USED REGISTERS
	##	$t0					## lines iteration, load with sizeof(lines)
	##	$f0					## iterator over vector length
	##	$f1					## source x
	##	$f2					## source y
	##	$f3					## dest   x	
	##	$f4					## dest   y
	##	$f5					## dx = x2-x1
	##	$f6 	 				## dy = y2-y1
	##	$f7					## abs(dx)
	##	$f8					## abs(dy)
	##	$f9					## step
	##	$f10					## 1.0 float for incrementing
	
	li	$t4, 0xFF				## register holding white color - temporary
	
	li	$t0, 192 				## lines iteration, load with sizeof(lines)
	
draw_line_outer_loop: ## write explaination
	sub	$t0, $t0, 16				## decrement lines iterator
							## load line structure
	lwc1	$f1, lines($t0)				## source x
	lwc1	$f2, lines+4($t0)			## source y
	lwc1	$f3, lines+8($t0)			## dest   x	
	lwc1	$f4, lines+12($t0)			## dest   y
	
	sub.s	$f5, $f3, $f1				## dx = x2-x1
	sub.s	$f6, $f4, $f2  				## dy = y2-y1
	abs.s	$f7, $f5				## abs(dx)
	abs.s	$f8, $f6				## abs(dy)
	
	mov.s	$f9, $f7				## (abs(dx) >= abs(dy)) -> step = abs(dx);
	c.lt.s 	$f8, $f7				## if(abs(dy) < abs(dx) -> 
	bc1t 	if_step_set				## \/
	mov.s	$f9, $f8				## -> step = abs(dy)
	if_step_set:
	
	div.s	$f5, $f5, $f9				## dx = dx/step
	div.s	$f6, $f6, $f9				## dy = dy/step
	

	lwc1	$f0, float0				## iterator over vector length
	lwc1	$f10, float1

line_drawing_loop:
	add.s 	$f1, $f1, $f5				## x = x + dx
	add.s 	$f2, $f2, $f6				## y = y + dy
	
	cvt.w.s	$f3, $f1				## convert x float to integer	(reuse unused $f3)
	cvt.w.s	$f4, $f2				## convert y float to integer	(reuse unused $f4)
	mfc1	$t1, $f3				## move converted x to general register
	mfc1	$t2, $f4				## move converted y to general register

	sll	$t3, $t2, 9				## y = y * 512
	add	$t3, $t3, $t1				## bitmap pixel offset = x + y
	mul	$t3, $t3, 3				## bitmap byte offset = bitmap pixel offset * 3
	
	
	sb	$t4, bitmap($t3)			## fill red 
	sb	$t4, bitmap+1($t3)			## fill green
	sb	$t4, bitmap+2($t3)			## fill blue
	
	add.s	$f0, $f0, $f10				## increment i
	c.lt.s 	$f0, $f9			
	bc1t 	line_drawing_loop			## while i < step
	
	bnez	$t0, draw_line_outer_loop
	
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
	print_newline
	lwc1	$f12, projected_points+4($t0)
	li	$v0, 2
	syscall
	print_newline
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



