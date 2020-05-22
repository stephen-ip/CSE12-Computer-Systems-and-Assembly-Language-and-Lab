########################################################################################################################################################
# Created by:	Ip, Stephen
# 		scip
# 		17 May 2020
#
# Assignment:	Lab 4: Sorting Integers
# 		CSE 12/12L, Computer Systems and Assembly Language Laboratory
# 		UC Santa Cruz, Spring 2020
#
# Description:	This program takes in hexadecimal numbers as program arguments, then print out these arguments, their integer values (unsorted), and their sorted integer values.
#
# Notes:	This program is intended to be run from the MARS IDE.
########################################################################################################################################################
# PSEUDO CODE:
#
# $a0 is number of arguments inputted: store this value in $s0
# $s0 is original adress of args, $t1 will hold the same value, but will be manipulated
# Binary slot counter: start at 0 ($t3)
# A = 10, B = 11, C = 12, D = 13, E = 14, F = 15 (Character * 16^ binary slot) Example: 0xA3 = A*16^1 + 3*16^0: Create a assignment dictionary of some sort
# 
# Argument output loop: if output counter = (number of arguments - 1) branch to argument_end function, else:
# 	loop through address $a1 to get arguments.
# 	use "lw" instruction to pull argument
#	print string
# 	print space
# 	store value in our array to make it easier to use
# 	inrcement index for address in $t1 and index for our array by 4 (word) to properly fetch and store value
# 	increment output counter by 1
# 	restart loop
#
# argument_end:
# 	print and store last argument with no space at the end
# 	reset all counters and index to 0
# 	print 2 new lines
# 	print "Integer Values" prompt
# 	print new line
#
# get_hex_arg: (outer loop of the process to convert hex args to ints)
# 	check if nums_outputted($t3) == num_arguments($s3). if so, branch to conversion_finished
# 	lw arg in array to $t4 (pull word)
# 	lw from $t4 to $t5 to make bytes accessible 
# 	addi 2 to $t5 so that index skips past the "0x" in the hex number
# 	
# finding_len_of_arg:
# 	load the byte up from $t5 for examination in reg $t6
# 	check if $t6 is a null character yet (0). if so, branch finding_len_end
# 	increment len counter by 1 ($t8)
# 	increment byte index by 1 to get next character ($t5)
# 	restart loop
#	
# finding_len_end: (once we determine the len of the hex arg, we can begin conversion process)
# 	reset $t5 to first hex char
# 	converting the register to be a counter by making $t4 = 0 (need more reg)
#	addi $t5, $t5, 2 # increment byte index by 2 to skip past "0x"
#
# hex_to_dec_conversion: (have 3 separate functions depending on len)
# 	if len == 1: branch to len1_conversion
#	if len == 2: branch to len2_conversion
# 	if len == 3: branch to len3_conversion
#
# len1_conversion:
# 	lb and put in $t6
# 	jal to a function that checks the byte and assigns a numerical value to reg $t1
# 	since only 1 hex char, the answer in $t1 is final answer
# 	load final answer in $t9
# 	jump to end_conversion
#
# len2_conversion:
# 	if 2 iterations are completed: branch to conversion_end (use $t4 to track iterations)
# 	lb and put in $t6
# 	jal to check_char function
# 	if $t4 == 0, this means it is the first char: jump to branch multiply $t1 by 16 (if $t4 != 0, that means it is second iteration and multiplication is not needed)
# return_label2: (after multiplying)
# 	add $t1 and $t9 and store in $t9 (keep track of sum in each iteration)
# 	increment $t4 and $t5 by 1 to keep track of byte and char
# 	j len2_conversion to restart loop
#
# len3_conversion:
#	if 3 iterations are completed: branch to conversion_end (use $t4 to track iterations)
#	lb and put in $t6
#	jal to check_char function
#	if $t4 == 0, this means it is the first char: jump to branch multiply $t1 by 16*16
#	if $t4 == 1, this means it is the first char: jump to branch multiply $t1 by 16
# return_lable3:
#	add $t1 and $t9 and store in $t9 (keep track of sum in each iteration)
#	increment $t4 and $t5 by 1 to keep track of byte and char
#	j len3_conversion to restart loop
#
# conversion_end:
# 	store output in a new array that will be sorted later (uses same counter as other array index)
#	increment output counter by 1 ($t3)
#	reset hex counter to 0 ($t4)
#	reset len counter to 0 (t8)
#	reset sum to 0 ($t9)
#	increment array index by 4 to get next word ($t2)
#	j get_hex_arg (outer loop)
#
# conversion_finished:
#	reset output counter to 0 ($t3)
#	reset index counter to 0 ($t2)
#
# print_unsorted_integers: (print all the numbers in the newly made array)
#	check if numbers outputted equal number of arguments - 1
#	print number using lw
#	print space character
#	increment numbers outputted by 1 ($t3)
#	increment index by 4 to get next number ($t2)
#	j print_unsorted_integers # restart loop
#	
# print_unsorted_end:
#	print last number with no space at the end
#	add 2 new lines
#	print "Sorted values:"
#	print new line
#	reset index array counter to 0. (second one in pair) $t2
#	reset output counter to 0 ($t3)
#	free up some regsiters we don't need anymore for new use (iteration counter) ($t5)
#	free up some regsiters we don't need anymore for new use (first one in pair) ($t1)
#
# bubble_sort:
#	check if number of iterations ($t5) equal number of arguments yet ($s0). if yes, bubblesort complete, print sorted values
#	check if first iteration is complete ($t3) == $t0? (arguments - 1). if yes, go to iteration_end
#	lw from array and put first number in $t1
#	increment index by 4 to get next number ($t4)
#	lw from array to get second number and put it in $t2
#	if second number is greater than first number: branch to swap
#	increment "output counter" by 1 ($t3)
#	restart loop if first number is less than second number (swap not needed)
#
# swap:
#	copy first number to save register $s1
#	copy second number to save register $s2
#	index back to the first number $t4 - 4
#	put second number in first number slot
#	index back to the second number $t4 + 4
#	put first number in second number slot
#	increment "output counter" by 1 ($t3)
#	return back to bubble sort loop
#	
# iteration_end:
#	reset output counter to 0 ($t3)
#	reset index back to 0 ($t4)
#	increment iteration counter by 1 ($t5)
#	go back to restart bubble_sort loop
#	
# print_sorted_values:
#	check if output counter equals number of (arguments - 1) yet ($t3). if yes, go to sort_print_end
#	print number from array
#	print space
#	increment index by 4 to get next number ($t4)
#	increment output counter by 1 ($t3)
#	restart print_sorted_values loop
#	
# sort_print_end:
#	print last number without space at the end
#	print new line
#	jump to exit_program
#
########################################################################################################################################################
# setting up registers
.text
.main:
	la $s0, ($a0)   # num of arguments stored in $s0
	la $s1, ($a1)   # original address
	la $t1, ($a1)   # address that will be manipulated
	
	subi $t0, $s0, 1        # number of arguments - 1
	li $t2, 0               # index_counter_array
	li $t3, 0               # output counter
	li $t4, 0               # argument holder
	li $t5, 0               # byte bridge
	li $t6, 0               # argument's byte
	li $t7, 0               # byte index counter
	li $t8, 0               # argument length (excluding 0x)
	li $t9, 0               # sum of indiv hex char
	li $s2, 16              # const 16 mutliplier for hex conversion
	li $s3, 256             # const 256 multiplier for hex conversion (16*16)

#####################################################################################################################
# printing out Program Arguments
	la $a0, program_arguments_prompt        # print "Program arguments:"
	jal print_string
	jal print_new_line                      # print new line
	
fetch_program_arguments:                                # goes through address $a1 to print each argument and store each argument in the array
	beq $t3, $t0, program_arguments_finished        # check if number of outputs equal number of arguments - 1
	lw $a0, ($t1)                                   # print argument
	jal print_string
	li $a0, 20                                      # print space
	jal print_character
	sw $t1, data_array($t2)                         # store argument in array
	addi $t1, $t1, 4                                # increment index counter by 4 for next argument
	addi $t2, $t2, 4                                # increment index counter of array by 4 to store arguments properly
	addi $t3, $t3, 1                                # increment output counter by 1
	j fetch_program_arguments

program_arguments_finished:
	lw $a0, ($t1)                   # print last argument with no space at the end
	jal print_string
	sw $t1, data_array($t2)         # store last argument in array
	li $t2, 0                       # reset index counter for array to 0
	li $t3, 0                       # reset output counter to 0
	jal print_new_line              # print 2 new lines
	jal print_new_line
	la $a0, integer_values_prompt   # print "Integer values:"
	jal print_string
	jal print_new_line              # print new line

#####################################################################################################################
# Printing out integer conversions
getting_hex_number:                             # iterate through each argument (hex number)
	beq $t3, $s0, conversion_finished       # check if number of outputs equal number of arguments
	lw $t4, data_array($t2)                 # load argument (word) into $t4
	lw $t5, ($t4)                           # make bytes accesible in $t5 *****************
	addi $t5, $t5, 2                        # increment byte index by 2 to skip past "0x"

finding_len:                            # find the len of the given argument (excluding "0x")
	lb $t6, ($t5)                   # load the byte up for examination
	beqz $t6, finding_len_end       # check if $t6 is a null character yet (0)
	addi $t8, $t8, 1                # increment len counter by 1
	addi $t5, $t5, 1                # increment byte index by 1 to get next character
	j finding_len                   # restart loop
	
finding_len_end:
	lw $t5, ($t4)           # reset $t5 to first hex char
	li $t4, 0               # converting the register to be a counter to track how many individual hex chars have been converted
	addi $t5, $t5, 2        # increment byte index by 2 to skip past "0x"

hex_to_dec_conversion:                  # separate procedure for converting hex num depending on its length
	beq $t8, 1, len1_conversion     # if len of hex num is 1 go to len1 conversion
	beq $t8, 2, len2_conversion     # if len of hex num is 2 go to len2 conversion
	beq $t8, 3, len3_conversion     # if len of hex num is 3 go to len3 conversion
	
len1_conversion:                # reuse $t1 as num holder
	lb $t6, ($t5)           # load byte up for examination
	jal check_hex_char      # jump and link to a function that will assign $t1 with the numerical value of the hex char in $t6, then return back here
	la $t9, ($t1)           # load sum with the one char value
	j conversion_end        # only one iteration is needed since it is len1, can jump to end of conversion

len2_conversion:
	beq $t4, 2, conversion_end      # check if the 2 hex chars have been converted yet. if so, go to end of conversion
	lb $t6, ($t5)                   # load byte up for examination
	jal check_hex_char              # jump and link to a function that will assign $t1 with the numerical value of the hex char in $t6, then return back here
	beqz $t4, multiply_16_2         # if it is the first iteration, multiply the recently assigned number ($t1) by 16
return_len2:                            # since jal was not used, a label was created so the previous function can return back to this area
	add $t9, $t1, $t9               # sum up hex char
	addi $t4, $t4, 1                # increment counter for hex
	addi $t5, $t5, 1                # increment byte index by 1 for next char
	j len2_conversion               # restart this len2 conversion loop
	
len3_conversion:
	beq $t4, 3, conversion_end      # check if the 3 hex chars have been converted yet. if so, go to end of conversion
	lb $t6, ($t5)                   # load byte up for examination
	jal check_hex_char              # jump and link to a function that will assign $t1 with the numerical value of the hex char in $t6, then return back here
	beqz $t4, multiply_256_3        # if it is the first iteration (first hex char), multiply the recently assigned number ($t1) by 16*16 (256)
	beq $t4, 1, multiply_16_3       # if it is the second iteration (second hex char), multiply the recently assigned number ($t1) by 16
return_len3:                            # since jal was not used, a label was created so the previous function can return back to this area
	add $t9, $t1, $t9               # sum up hex char
	addi $t4, $t4, 1                # increment counter for hex
	addi $t5, $t5, 1                # increment byte index by 1 for next char
	j len3_conversion               # restart this len3 conversion loop

conversion_end:                 # come here once an entire hex number is converted to an integer value, which is stored in $t9
	sw $t9, sort_array($t2) # store output in a new array that will be sorted later (uses same counter as other array index)
	addi $t3, $t3, 1        # increment output counter by 1
	li $t4, 0               # reset hex counter to 0
	li $t8, 0               # reset len counter to 0
	li $t9, 0               # reset sum to 0
	addi $t2, $t2, 4        # increment array index by 4 to get next word (argument)
	j getting_hex_number    # return back to the first (outer) loop to get conversions for the rest of the arguments

check_hex_char: # assignment process for converting a hex char to an integer value (checking ASCII value: 48 = 0 ... 70 = F)
	beq $t6, 48, char_0
	beq $t6, 49, char_1
	beq $t6, 50, char_2
	beq $t6, 51, char_3
	beq $t6, 52, char_4
	beq $t6, 53, char_5
	beq $t6, 54, char_6
	beq $t6, 55, char_7
	beq $t6, 56, char_8
	beq $t6, 57, char_9
	beq $t6, 65, char_A
	beq $t6, 66, char_B
	beq $t6, 67, char_C
	beq $t6, 68, char_D
	beq $t6, 69, char_E
	beq $t6, 70, char_F

char_0:
	li $t1, 0       # since hex char is 0: give $t1 a value of 0
	jr $ra          # return back to conversion main
char_1:
	li $t1, 1       # since hex char is 1: give $t1 a value of 1
	jr $ra          # return back to conversion main
char_2:
	li $t1, 2       # since hex char is 2: give $t1 a value of 2
	jr $ra          # return back to conversion main
char_3:
	li $t1, 3       # since hex char is 3: give $t1 a value of 3
	jr $ra          # return back to conversion main
char_4:
	li $t1, 4       # since hex char is 4: give $t1 a value of 4
	jr $ra          # return back to conversion main
char_5:
	li $t1, 5       # since hex char is 5: give $t1 a value of 5
	jr $ra          # return back to conversion main
char_6:
	li $t1, 6       # since hex char is 6: give $t1 a value of 6
	jr $ra          # return back to conversion main
char_7:
	li $t1, 7       # since hex char is 7: give $t1 a value of 7
	jr $ra          # return back to conversion main
char_8:
	li $t1, 8       # since hex char is 8: give $t1 a value of 8
	jr $ra          # return back to conversion main
char_9:
	li $t1, 9       # since hex char is 9: give $t1 a value of 9
	jr $ra          # return back to conversion main
char_A:
	li $t1, 10      # since hex char is A: give $t1 a value of 10
	jr $ra          # return back to conversion main
char_B:
	li $t1, 11      # since hex char is B: give $t1 a value of 11
	jr $ra          # return back to conversion main
char_C:
	li $t1, 12      # since hex char is C: give $t1 a value of 12
	jr $ra          # return back to conversion main
char_D:
	li $t1, 13      # since hex char is D: give $t1 a value of 13
	jr $ra          # return back to conversion main
char_E:
	li $t1, 14      # since hex char is E: give $t1 a value of 14
	jr $ra          # return back to conversion main
char_F:
	li $t1, 15      # since hex char is F: give $t1 a value of 15
	jr $ra          # return back to conversion main

multiply_16_2:                  # immediate of 16 is stored in $s2
	mul $t1, $t1, $s2       # multiply the recently converted hex char by 16 since it is the first char in a 2 len num
	j return_len2           # go back to conversion main
multiply_256_3:                 # immediate of 256 is stored in $s3
	mul $t1, $t1, $s3       # multiply the recently converted hex char by 256 since it is the first char in a 3 len num
	j return_len3           # go back to conversion main
multiply_16_3:
	mul $t1, $t1, $s2       # multiply the recently converted hex char by 16 since it is the second char in a 3 len num
	j return_len3           # go back to conversion main
	
conversion_finished:    # once all hex numbers have been converted to integers
	li $t3, 0       # reset output counter to 0
	li $t2, 0       # reset index counter to 0

print_unsorted_integers:                        # index through the new array to print the recently stored values
	beq $t3, $t0, print_unsorted_end        # check if numbers outputted equal number of arguments - 1
	lw $a0, sort_array($t2)                 # print number
	jal print_integer
	li $a0, 32                              # print space character
	li $v0, 11
	syscall
	addi $t3, $t3, 1                        # increment numbers outputted by 1
	addi $t2, $t2, 4                        # increment index by 4 to get next number
	j print_unsorted_integers               # restart loop
	
print_unsorted_end:
	lw $a0, sort_array($t2)         # print last number with no space at the end
	jal print_integer               # add 2 new lines
	jal print_new_line
	jal print_new_line
	la $a0, sorted_values_prompt    # print "Sorted values:"
	jal print_string
	jal print_new_line              # print new line
	li $t2, 0                       # reset index array counter to 0. (second one in pair)
	li $t3, 0                       # reset output counter to 0
	li $t4, 0                       # free up some regsiters we don't need anymore for new use (index counter)
	li $t5, 0                       # free up some regsiters we don't need anymore for new use (iteration counter)
	li $t1, 0                       # free up some regsiters we don't need anymore for new use (first one in pair)

#####################################################################################################################
# Printing out sorted integer values using bubble sort
bubble_sort:         # sort integer values in sort_array
	beq $t5, $s0, print_sorted_values       # check if number of iterations equal number of arguments yet
	beq $t3, $t0, iteration_end             # check if first iteration is complete
	lw $t1, sort_array($t4)                 # get first number
	addi $t4, $t4, 4                        # increment index by 4 to get next number
	lw $t2, sort_array($t4)                 # get second number
	bgt $t1, $t2, swap                      # if second number is greater than first number: swap
	addi $t3, $t3, 1                        # increment "output counter" by 1
	j bubble_sort                           # restart loop if first number is less than second number

swap:
	la $s1, ($t1)           # copy first number to save register
	la $s2, ($t2)           # copy second number to save register
	subi $t4, $t4, 4        # index back to the first number
	sw $s2, sort_array($t4) # put second number in first number slot
	addi $t4, $t4, 4        # index back to the second number
	sw $s1, sort_array($t4) # put first number in second number slot
	addi $t3, $t3, 1        # increment "output counter" by 1
	j bubble_sort           # return back to bubble sort loop
	
iteration_end:
	li $t3, 0               # reset output counter to 0
	li $t4, 0               # reset index back to 0
	addi $t5, $t5, 1        # increment iteration counter by 1
	j bubble_sort           # restart another bubble sort iteration
	
print_sorted_values:                    # once bubble sort has completed all of its iterations, the data set is sorted, so we can print now
	beq $t3, $t0, sort_print_end    # check if output counter equals number of (arguments - 1) yet
	lw $a0, sort_array($t4)         # print number
	jal print_integer
	li $a0, 32                      # print space character
	li $v0, 11
	syscall
	addi $t4, $t4, 4                # increment index by 4 to get next number
	addi $t3, $t3, 1                # increment output counter by 1
	j print_sorted_values           # restart loop to print next value
	
sort_print_end:
	lw $a0, sort_array($t4) # print last number without space at the end
	jal print_integer
	jal print_new_line      # print new line
	j exit_program          # program is completed: go exit
	
#####################################################################################################################
# useful functions
print_integer:
	li $v0, 1       # print integer (load $a0 manually)
	syscall
	jr $ra

print_string:
	li $v0, 4       # print string (load $a0 manually)
	syscall
	jr $ra

print_character:
	li $v0, 11      # print chracter (load $a0 manually)
	syscall
	jr $ra

print_new_line:
	li $v0, 4       # print new line
	la $a0, newline
	syscall
	jr $ra

exit_program:
	li $v0, 10      # syscall for exit program (called when program is finished)
	syscall

.data
	program_arguments_prompt: .asciiz "Program arguments:"
	integer_values_prompt: .asciiz "Integer values:"
	sorted_values_prompt: .asciiz "Sorted values:"
	newline: .asciiz "\n"
	data_array:     # used to store addresses for program arguments
		.space 32
	sort_array:     # used to store converted integer values
		.space 32
