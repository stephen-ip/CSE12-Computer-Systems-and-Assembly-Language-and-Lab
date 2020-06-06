########################################################################################################################################################################
# Created by:	Ip, Stephen
# 		scip
# 		6 June 2020
#
# Assignment:	Lab 5: Functions and Graphics
# 		CSE 12/12L, Computer Systems and Assembly Language Laboratory
# 		UC Santa Cruz, Spring 2020
#
# Description:	This program contains macros and procedures that allows you to draw different types of circles on the MARS bitmap.
#
# Notes:	This program is intended to be run from the MARS IDE. The bitmap specifications are 128 x 128, and base address for display is 0xffff0000 (memory map).
########################################################################################################################################################################

# Macro that stores the value in %reg on the stack 
#  and moves the stack pointer.
.macro push(%reg)
subi $sp, $sp, 4        # stack grows down so decrement by 4 to make room
sw %reg, 0($sp)         # store register at decremented location
.end_macro 

# Macro takes the value on the top of the stack and 
#  loads it into %reg then moves the stack pointer.
.macro pop(%reg) 
lw %reg, 0($sp)         # load the register at current $sp location
addi $sp, $sp, 4        # now that the register is loaded, increment back up to update pointer
.end_macro

# Macro that takes as input coordinates in the format
# (0x00XX00YY) and returns 0x000000XX in %x and 
# returns 0x000000YY in %y
.macro getCoordinates(%input %x %y)
srl %x, %input, 16      # shift right 4 bits (4*4 since its hex) to move XX to the right location (end)
sll %y, %input, 24      # shift left 6 bits (6*4 since its hex) to get replace XX with 0's
srl %y, %y, 24          # shift right 6 bits (6*4 since its hex) to put YY back in original position
.end_macro

# Macro that takes Coordinates in (%x,%y) where
# %x = 0x000000XX and %y= 0x000000YY and
# returns %output = (0x00XX00YY)
.macro formatCoordinates(%output %x %y)
sll %x, %x, 16          # shift left 4 bits (4*4 since its hex) to move XX in right place
or %output, %x, %y      # merge XX and YY by using or
.end_macro 


.data
originAddress: .word 0xFFFF0000

.text
# the goal is to try and use these regs but they will be overwritten eventually
# $t0 bit map origin (start)
# $t1 bit map size (end)
# $t2 row length (* variable)
# $t3 x coord
# $t4 y coord
# $t5 random var **
# $t6 x min
# $t7 x max
# $t8 y min
# $t9 y max

j done

    done: nop
    li $v0 10 
    syscall

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Subroutines defined below
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#*****************************************************
#Clear_bitmap: Given a color, will fill the bitmap display with that color.
#   Inputs:
#    $a0 = Color in format (0x00RRGGBB) 
#   Outputs:
#    No register outputs
#    Side-Effects: 
#    Colors the Bitmap display all the same color
#*****************************************************
clear_bitmap: nop
	lw $t0, originAddress           # bit map origin (start)
	li $t1, 0xFFFFFFFC              # bit map size (end)
place_pixel:	
	sw $a0, ($t0)                   # store color in pixel at address
	addi $t0, $t0, 4                # increment address by 4 to get next bit
	ble $t0, $t1, place_pixel       # if output is not yet at last pixel, restart loop
	lw $t0, originAddress           # reset original address
	jr $ra                          # return
	
#*****************************************************
# draw_pixel:
#  Given a coordinate in $a0, sets corresponding value
#  in memory to the color given by $a1	
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of pixel in format (0x00XX00YY)
#    $a1 = color of pixel in format (0x00RRGGBB)
#   Outputs:
#    No register outputs
#*****************************************************
draw_pixel: nop
	lw $t0, originAddress           # bit map origin (start)
	li $t1, 0xFFFFFFFC              # bit map size (end)
	li $t2, 128                     # row length (* variable)
	getCoordinates ($a0, $t3, $t4)  # get x and y from coordinate $a0, and put x in $t3 and y in $t4
	mul $t4, $t4, $t2               # row * row length
	add $t4, $t4, $t3               # (row * row length) + column | this is the number of pixels needed to cross
	li $t2, 4                       # temporarily hold bit multiplier in $t2
	mul $t4, $t4, $t2               # multiply distance by 4 since each pixel is 4 bits | this is the distance address needs to be offset by
	add $t0, $t0, $t4               # add this value to $t0 to get location of pixel
	bgt $t0, $t1, draw_end          # if pixel out of range, end
	sw $a1, ($t0)                   # store color ($a1) to pixel's location
	jr $ra                          # return
draw_end:                               # if pixel out of range, end
	jr $ra                          # return
	
#*****************************************************
# get_pixel:
#  Given a coordinate, returns the color of that pixel	
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of pixel in format (0x00XX00YY)
#   Outputs:
#    Returns pixel color in $v0 in format (0x00RRGGBB)
#*****************************************************
get_pixel: nop
	lw $t0, originAddress           # bit map origin (start)
	li $t1, 0xFFFFFFFC              # bit map size (end)
	li $t2, 128                     # row length (* variable)
	getCoordinates ($a0, $t3, $t4)  # get x and y from coordinate $a0, and put x in $t3 and y in $t4
	mul $t4, $t4, $t2               # row * row length
	add $t4, $t4, $t3               # (row * row length) + column | this is the number of pixels needed to cross
	li $t2, 4                       # temporarily hold bit multiplier in $t2
	mul $t4, $t4, $t2               # multiply distance by 4 since each pixel is 4 bits | this is the distance address needs to be offset by
	add $t0, $t0, $t4               # add this value to $t0 to get location of pixel
	bgt $t0, $t1, get_end           # if pixel out of range, end
	lw $v0, ($t0)                   # store color in pixel at this location to $v0
	jr $ra                          # return
get_end:                                # if pixel out of range, end
	jr $ra                          # return

#***********************************************
# draw_solid_circle:
#  Considering a square arround the circle to be drawn  
#  iterate through the square points and if the point 
#  lies inside the circle (x - xc)^2 + (y - yc)^2 = r^2
#  then plot it.
#-----------------------------------------------------
# draw_solid_circle(int xc, int yc, int r) 
#    xmin = xc-r
#    xmax = xc+r
#    ymin = yc-r
#    ymax = yc+r
#    for (i = xmin; i <= xmax; i++) 
#        for (j = ymin; j <= ymax; j++) 
#            a = (i - xc)*(i - xc) + (j - yc)*(j - yc)	 
#            if (a < r*r ) 
#                draw_pixel(x,y) 	
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of circle center in format (0x00XX00YY)
#    $a1 = radius of the circle
#    $a2 = color in format (0x00RRGGBB)
#   Outputs:
#    No register outputs
#***************************************************
draw_solid_circle: nop
	push ($ra)                              # push original $ra since we will need it last when we are finished
	getCoordinates ($a0, $t3, $t4)          # get x and y from coordinate $a0 and store xc in $t3 and yc in $t4
	sub $t6, $t3, $a1                       # xmin = xc-r (i)
	add $t7, $t3, $a1                       # xmax = xc+r
	sub $t8, $t4, $a1                       # ymin = yc-r (j)
	add $t9, $t4, $a1                       # ymax = yc+r
	
outer_loop:
	push ($t8)                              # store original value of j in stack to restore later on new iteration of outer loop
	bgt $t6, $t7, draw_solid_circle_end     # if xmin is greater than xmax, iterations are done. Else: continue to inner loop
	
inner_loop:
	# calculating a (use $t2 and $t5 as var storage)
	bgt $t8, $t9, inner_loop_end            # if ymin > ymax, go to inner_loop_end
	sub $t2, $t6, $t3                       # (i-xc) stored in $t2
	mul $t2, $t2, $t2                       # (i-xc)*(i-xc) stored in $t2
	sub $t5, $t8, $t4                       # (j-yc) stored in $t5
	mul $t5, $t5, $t5                       # (j-yc)*(j-yc) stored in $t5
	add $t5, $t2, $t5                       # (i – xc)*(i – xc) + (j – yc)*(j – yc) store a in $t5
	mul $t2, $a1, $a1                       # store r^2 in $t2
	blt $t5, $t2, draw_pix                  # if a < r^2: go to procedure for drawing pix
	addi $t8, $t8, 1                        # increment $t8 (j) by 1
	j inner_loop                            # return to start new iteration of innner_loop

draw_pix:
	push ($a0)                              # push all the variables that will be altered by draw_pixel
	push ($a1)
	push ($a2)
	push ($t0)
	push ($t1)
	push ($t2)
	push ($t3)
	push ($t4)
	push ($t5)
	push ($t6)
	push ($t8)
	move $a1, $a2                           # move the value of $a2 (color given) to $a1 (color reader)
	formatCoordinates ($a0, $t6, $t8)       # format coordinates for the draw_pix function
	jal draw_pixel                          # call the draw_pixel function now that preparations are made
	pop ($t8)                               # restore all values to original
	pop ($t6)
	pop ($t5)
	pop ($t4)
	pop ($t3)
	pop ($t2)
	pop ($t1)
	pop ($t0)
	pop ($a2)
	pop ($a1)
	pop ($a0)
	addi $t8, $t8, 1                        # increment $t8 (j) by 1
	j inner_loop                            # return to start new iteration of innner_loop
	
inner_loop_end:                                 # when all iterations of the inner loop are done given a single iteration in the outer loop
	addi $t6, $t6, 1                        # increment $t6 (i) by 1
	pop ($t8)                               # restore $t8 (j) to original value
	j outer_loop                            # return to outer_loop

draw_solid_circle_end:
	pop ($t8)                               # pop $t8 to get rid of it from the stack, so $ra can be popped
	pop ($ra)                               # restore original $ra of the function
	jr $ra                                  # return

		
#***********************************************
# draw_circle:
#  Given the coordinates of the center of the circle
#  plot the circle using the Bresenham's circle 
#  drawing algorithm 	
#-----------------------------------------------------
# draw_circle(xc, yc, r) 
#    x = 0 
#    y = r 
#    d = 3 - 2 * r 
#    draw_circle_pixels(xc, yc, x, y) 
#    while (y >= x) 
#        x=x+1 
#        if (d > 0) 
#            y=y-1  
#            d = d + 4 * (x - y) + 10 
#        else
#            d = d + 4 * x + 6 
#        draw_circle_pixels(xc, yc, x, y) 	
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of the circle center in format (0x00XX00YY)
#    $a1 = radius of the circle
#    $a2 = color of line in format (0x00RRGGBB)
#   Outputs:
#    No register outputs
#***************************************************
draw_circle: nop
	push ($ra)              # store initial return address to return to when function is done
	li $t5, 0               # x = 0
	la $t6, ($a1)           # y = r
	li $t7, 2               # load immediate 2 into temp register
	mul $t7, $t7, $t6       # (2 * r)
	li $t8, 3               # load immediate 3 into temp register
	sub $t7, $t8, $t7       # d = 3 - (2 * r)
	la $a1, ($a2)           # move color of line to color of pixel
	
	# $t5 = x
	# $t6 = y
	# $t7 = d	
	
	push ($t5)              # save original variables
	push ($t6)
	push ($t7)
	                        # coordinates of the circle center is already formatted in $a0
	la $a2, ($t5)           # current x value from the Bresenham's circle algorithm
	la $a3, ($t6)           # current y value from the Bresenham's circle algorithm
	jal draw_circle_pixels  # go to draw pixel procedure now that preparations are made
	pop ($t7)               # restore original variables
	pop ($t6)
	pop ($t5)

while_loop:
	blt $t6, $t5, draw_circle_end   # while (y >= x) 
	addi $t5, $t5, 1                # x = x + 1
	
	blez $t7, else                  # if (d > 0):
	subi $t6, $t6, 1                # y = y - 1
	li $t8, 4                       # load immediate 4 in temp register
	sub $t9, $t5, $t6               # (x - y)
	mul $t0, $t8, $t9               # 4 * (x - y)
	add $t7, $t7, $t0               # d + 4 * (x - y)
	addi $t7, $t7, 10               # d = d + 4 * (x - y) + 10 
	push ($t5)                      # save original variables
	push ($t6)
	push ($t7)
	la $a2, ($t5)                   # current x value from the Bresenham's circle algorithm
	la $a3, ($t6)                   # current y value from the Bresenham's circle algorithm
	jal draw_circle_pixels          # go to draw pixel procedure now that preparations are made
	pop ($t7)                       # restore original variables
	pop ($t6)
	pop ($t5)
	j while_loop                    # restart while loop since iteration is done
	
else:
	li $t8, 4                       # load immediate 4 in temp register
	mul $t9, $t8, $t5               # (4 * x) stored in $t9
	add $t7, $t7, $t9               # d = d + (4 * x)
	addi $t7, $t7, 6                # + 6
	push ($t5)                      # save original variables
	push ($t6)
	push ($t7)
	la $a2, ($t5)                   # current x value from the Bresenham's circle algorithm
	la $a3, ($t6)                   # current y value from the Bresenham's circle algorithm
	jal draw_circle_pixels          # go to draw pixel procedure now that preparations are made
	pop ($t7)                       # restore original variables
	pop ($t6)
	pop ($t5)
	j while_loop                    # restart while loop since iteration is done

draw_circle_end:
	pop ($ra)                       # restore original $ra of the function
	jr $ra                          # return
	
#*****************************************************
# draw_circle_pixels:
#  Function to draw the circle pixels 
#  using the octans' symmetry
#-----------------------------------------------------
# draw_circle_pixels(xc, yc, x, y)  
#    draw_pixel(xc+x, yc+y) 
#    draw_pixel(xc-x, yc+y)
#    draw_pixel(xc+x, yc-y)
#    draw_pixel(xc-x, yc-y)
#    draw_pixel(xc+y, yc+x)
#    draw_pixel(xc-y, yc+x)
#    draw_pixel(xc+y, yc-x)
#    draw_pixel(xc-y, yc-x)
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of circle center in format (0x00XX00YY)
#    $a1 = color of pixel in format (0x00RRGGBB)
#    $a2 = current x value from the Bresenham's circle algorithm
#    $a3 = current y value from the Bresenham's circle algorithm
#   Outputs:
#    No register outputs	
#*****************************************************
draw_circle_pixels: nop
	push ($ra)                      # store initial return address to return to when function is done
	push ($a0)                      # store center circle coordinates
	getCoordinates ($a0, $t3, $t4)  # get coordinates of center: x in $t3, y in $t4
	la $t5, ($a2)                   # current x value from the Bresenham's circle algorithm
	la $t6, ($a3)                   # current y value from the Bresenham's circle algorithm
	
	# $t3 = xc
	# $t4 = yc
	# $t5 = x
	# $t6 = y
	# $t7 = var x
	# $t8 var y
	
	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)
	add $t7, $t3, $t5                       # xc+x
	add $t8, $t4, $t6                       # yc+y
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)
	
	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)
	sub $t7, $t3, $t5                       # xc-x
	add $t8, $t4, $t6                       # yc+y
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)

	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)	
	add $t7, $t3, $t5                       # xc+x
	sub $t8, $t4, $t6                       # yc-y
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)

	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)	
	sub $t7, $t3, $t5                       # xc-x
	sub $t8, $t4, $t6                       # yc-y
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)
	
	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)
	add $t7, $t3, $t6                       # xc+y
	add $t8, $t4, $t5                       # yc+x
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)

	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)
	sub $t7, $t3, $t6                       # xc-y
	add $t8, $t4, $t5                       # yc+x
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)	
	
	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)
	add $t7, $t3, $t6                       # xc+y
	sub $t8, $t4, $t5                       # yc-x
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)	

	push ($t3)                              # store original variables
	push ($t4)
	push ($t5)
	push ($t6)
	sub $t7, $t3, $t6                       # xc-y
	sub $t8, $t4, $t5                       # yc-x
	formatCoordinates ($a0, $t7, $t8)       # send coordinates to $a0
	jal draw_pixel                          # draw pixel at coordinate
	pop ($t6)                               # restore original variables
	pop ($t5)
	pop ($t4)
	pop ($t3)	
	
	pop ($a0)                               # restore original circle center
	pop ($ra)                               # restore original return address
	jr $ra                                  # return
