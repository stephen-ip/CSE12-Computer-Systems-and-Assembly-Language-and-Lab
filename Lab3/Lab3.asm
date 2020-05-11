########################################################################################################################################################
# Created by:	Ip, Stephen
# 		scip
# 		9 May 2020
#
# Assignment:	Lab 3: ASCII-risks (Asterisks)
# 		CSE 12/12L, Computer Systems and Assembly Language Laboratory
# 		UC Santa Cruz, Spring 2020
#
# Description:	This program takes in an user integer input that is greater than 0, and prints out a number and stars in an inverted pyramid pattern. 
#
# Notes:	This program is intended to be run from the MARS IDE.
########################################################################################################################################################

.text
main:
	li $v0, 4                  # ask for height of the pattern
	la $a0, prompt
	syscall
	
	li $v0, 5                  # store and move height of pattern value to $t0
	syscall
	move $t0, $v0
	
	ble $t0, $0, Raise_Error   # if height <= 0: raise error message and input height again

	li $s0, 2               # star multiplier is constant (kept in saved register)
	subi $t0, $t0, 1        # (height - 1)
	mul $t1, $t0, $s0       # number of stars in first row stored in $t1 = [2 * (height - 1)]
	addi $t0, $t0, 1        # restore height to original value
	
	li $t2, 0       # row counter 
	li $t3, 0       # number counter (left)
	li $t4, 0       # output counter
	li $t5, 0       # number counter (right)

Rows_Loop:
	beqz $t0, exit_program  # check if height is 0 yet
	addi $t2, $t2, 1        # increment row count
	b Left_Hand_Nums_Loop   # begin the process for printing numbers on the left
	
Left_Hand_Nums_Loop:
	beq $t4, $t2, End_Left  # check if the correct amount of numbers have been outputted on the left hand side
	addi $t3, $t3, 1        # increment number by 1
	li $v0, 1               # print
	la $a0, ($t3)
	syscall
	addi $t4, $t4, 1        # increment numbers outputted by 1
	jal Insert_Tab          # print tab
	j Left_Hand_Nums_Loop   # restart loop

End_Left:
	la $t5, ($t3)   # store the last number outputted so the right side knows where to start
	li $t4, 0       # reset output counter
	
Stars_Loop:
	beq $t4, $t1 End_Stars  # check if the correct amount of stars have been outputted
	li $v0, 11              # print star character
	li $a0, '*'
	syscall
	addi $t4, $t4, 1        # increment stars outputted by 1
	jal Insert_Tab          # print tab
	j Stars_Loop            # restart loop

End_Stars:
	subi $t1, $t1, 2        # decrement number of stars to be outputted for next iteration
	li $t4, 1               # reset output counter to one instead of 0 to have a special case in printing last number to avoid extra tab

Right_Hand_Nums_Loop:
	beq $t4, $t2, End_Right # check if the correct amount of numbers have been outputted on the right hand side
	li $v0, 1               # print
	la $a0, ($t5)           # start with the number that you ended with on the left side
	syscall
	subi $t5, $t5, 1        # decrement number counter by 1
	addi $t4, $t4, 1        # increment number outputted by 1
	jal Insert_Tab          # print tab
	j Right_Hand_Nums_Loop  # restart loop

End_Right:
	li $v0, 1               # print last number without the tab at the end
	la $a0, ($t5)
	syscall
	li $v0, 4               # print new line
	la $a0, newline
	syscall
	li $t4, 0               # reset output counter
	subi $t0, $t0, 1        # decrement height by 1
	j Rows_Loop             # go back to the first loop to start printing next row
	
Raise_Error:
	li $v0, 4       # prompt error message
	la $a0, error
	syscall
	li $v0, 4       # print new line
	la $a0, newline
	syscall
	j main          # return to beginning, where new height is asked

Insert_Tab:
	li $v0, 11      # print tab
	li $a0, 9
	syscall
	jr $ra          # jump back to return address
	
exit_program:
	li $v0, 10      # syscall for exit program (called when program is finished)
	syscall

.data
	prompt: .asciiz "Enter the height of the pattern (must be greater than 0):	"
	error: .asciiz "Invalid Entry!"
	newline: .asciiz "\n"
