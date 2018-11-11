.eqv	cube_rotation_matrix_r0c0 cube_rotation_matrix
.eqv	cube_rotation_matrix_r0c1 cube_rotation_matrix + 4
.eqv	cube_rotation_matrix_r0c2 cube_rotation_matrix + 8
.eqv	cube_rotation_matrix_r1c0 cube_rotation_matrix + 12
.eqv	cube_rotation_matrix_r1c1 cube_rotation_matrix + 16
.eqv	cube_rotation_matrix_r1c2 cube_rotation_matrix + 20
.eqv	cube_rotation_matrix_r2c0 cube_rotation_matrix + 24
.eqv	cube_rotation_matrix_r2c1 cube_rotation_matrix + 28
.eqv	cube_rotation_matrix_r2c2 cube_rotation_matrix + 32

.eqv	CUBE_ROT_MATRIX_SIZE	36
.eqv	VERTICES_SIZE		24
.eqv	VECTOR_SIZE		12

.data
	## cube rotation matrix 3x3 -> 9 floats -> 36 bytes 
	cube_rotation_matrix:	.float	1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0
	## cube position vector 3x1 -> 3 floats -> 12 bytes
	cube_position_vector:	.float	1.0, 2.0, 3.0
	
	vertices:		.float	1.0, 1.0, 1.0, -1.0, -1.0, -1.0
	
.text
	li	$t0, 36					## iterate over matrix rows
	li	$t1, 12					## iterate over vector rows
	
	li	$t3, 0					## current element calculated in the vertex vector
	matrix_loop:
	sub	$t0, $t0, 12
	sub	$t1, $t1, 4
	
	lwc1	$f2, cube_rotation_matrix($t0)
	lwc1	$f3, cube_rotation_matrix+4($t0)
	lwc1	$f4, cube_rotation_matrix+8($t0)
	lwc1	$f5, cube_position_vector($t1)
	
	li	$t2, 24					## iterate over vertices (vertices size)
	vertices_loop:
	sub	$t2, $t2, 12				## decrement the vertices offset
	add	$t3, $t2, $t1				## calculate the current element offset
	
	lwc1	$f6, vertices($t2)
	lwc1	$f7, vertices+4($t2)
	lwc1	$f8, vertices+8($t2)
	
	mov.s	$f0, $f5
	mul.s	$f1, $f2, $f6
	add.s	$f0, $f0, $f1
	mul.s	$f1, $f3, $f7
	add.s	$f0, $f0, $f1
	mul.s	$f1, $f4, $f8
	add.s	$f0, $f0, $f1
	
	swc1	$f0, vertices($t3)			## save the result
	
	bnez	$t2, vertices_loop
	bnez	$t0, matrix_loop
	

	li	$t0, 24
	li	$v0, 2
	
	print_loop:
	sub	$t0, $t0, 4
	lwc1	$f12, vertices($t0)
	li	$v0, 2
	syscall
	li	$a0, '\n'
	li	$v0, 11
	syscall
	bnez	$t0, print_loop
	
	li	$v0, 10
	syscall