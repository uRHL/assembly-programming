.data
	M: .word 3  
    N: .word 4
    matrixA: .float 0.0, 0.0, -0.0, -Infinity, Infinity, Infinity, NaN, NaN, NaN, NaN, 1.1, -1.2, 1.2345
    matrixB: .float 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0
    matrixC: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    vectorV: .word 0, 0, 0, 0, 0, 0
    
.text
	.globl main
    main:
    	#We load the input values for function Extract Values, no stack needed
    	la $a0 matrixA		#A[][]
		lw $a1 M			#M
        lw $a2 N			#N
        la $a3 vectorV		#V[]

        jal extractValues
        
        #We load the input values for function Extract Values, no stack needed
    	la $a0 matrixA		#A[][]
        la $a1 matrixB		#B[][]
        la $a2 matrixC		#C[][]
        la $t0 M
        lw $t0 ($t0)
        move $a3 $t0		#M
        subu $sp $sp 20
        la $t0 N
        lw $t0 ($t0)
        sw $t0 ($sp)		#N (to stack)
        jal add
        
        sucededEnd:
    		li $v0 10
            syscall

#------ADD FUNCTION---------------------------------------------------------------------
    	add:
        	move $t0 $a0	#A[][]
            move $t1 $a1	#B[][]
            move $t2 $a2	#C[][]
            move $t3 $a3	#M
            lw $t4 ($sp)	
            addu $sp $sp 20	#N (from stack)
            
            ble $t3 $zero errorAdd
            ble $t4 $zero errorAdd
            mul $t3 $t3 $t4	#M*N
            move $t4 $zero	#i=0
            
            doAdd:
            	lwc1 $f0 0($t0)	#$f0=A[i]
                lwc1 $f2 0($t1)	#$f1=B[i]
                add.s $f0 $f0 $f2
                swc1 $f0 0($t2)	#C=A[i]+B[i]
            	addu $t4 $t4 1	#i++
                addu $t0 $t0 4 	#A[][]++
                addu $t1 $t1 4	#B[][]++
                addu $t2 $t2 4 	#C[][]++
            whileAdd:
            	bge $t4 $t3 endWhileAdd
                b doAdd
            
        endWhileAdd:
        	li $v0 0
            jr $ra            
        errorAdd:
        	li $v0 -1
            jr $ra       	                   

#------EXTRACT VALUES FUNCTION---------------------------------------------------------------------
    	extractValues:
        	move $t0 $a0		#A[]
            move $t1 $a3		#V[]
            move $t2 $a1		#M
            move $t3 $a2		#N
            
            ble $t2 $zero errorExtractValues
            ble $t3 $zero errorExtractValues	#If(M||N==0)
            
            mul $t2 $t2 $t3		#M*N
            move $t3 $zero		#i=0
            
            doExtract:                
               		lwc1 $f0 0($t0)			#load word coprocessor 1
					mfc1 $t5 $f0			#move from coprocessor 1
					li $t4 0x7F800000		#infinite
					and $t6 $t5 $t4 		#logical and
					srl $t6 $t6 23			#shift right logical to get the exponent
					sub $t6 $t6 127					#exponent of the float number is in t6
                    #Now we make sort of a switch
                    li $t7 -127
                    beq $t6 $t7 case0		#Zero value (0.0 or -0.0)
                    beq $t6 $zero case3		#Non nomalized value (1,X)
                    li $t7 128
                    beq $t6 $t7 case1		#Infinity, -Infinity and NaN values
                    b case2
                    
                case0:                
                   	#The value is zero
                    lw $t4 0($t1)
                    addu $t4 $t4 1			#We stract the value from V[0] and add 1
                    sw $t4 0($t1)
                    b endCases
				case1:
                	sll $t6 $t5 9			#shift left logical to get the mantisa
                    beq $t6 $zero v12                   
                    		#The value is Not a Number NaN
                    lw $t4 12($t1)
                    addu $t4 $t4 1			#We stract the value from V[3] and add 1
                    sw $t4 12($t1)
                    b endCases
                    v12:	#The value is infinty OR -infinity
                    srl $t6 $t5 31
                    beq $t6 $zero v1
                    b v2
                    v1:		#The value is infinity
                    lw $t4 4($t1)
                    addu $t4 $t4 1			#We stract the value from V[1] and add 1
                    sw $t4 4($t1)
                    b endCases
                    v2:		#The value is minus infinite
                    lw $t4 8($t1)
                    addu $t4 $t4 1			#We stract the value from V[2] and add 1
                    sw $t4 8($t1)
                    b endCases
                case2:		#The values is normal number
                	lw $t4 20($t1)
                    addu $t4 $t4 1			#We stract the value from V[1] and add 1
                    sw $t4 20($t1)
                    b endCases
                case3:
                 		#The value is Non Normalized
                    lw $t4 16($t1)
                    addu $t4 $t4 1			#We stract the value from V[4] and add 1
                    sw $t4 16($t1)
                    b endCases
                endCases:
            	addu $t3 $t3 1	#i++
                addu $t0 $t0 4	#A[]++
            whileExtract:
            	bgt $t3 $t2 endExtractValues
            	b doExtract
            endExtractValues:
            	li $v0 0
                jr $ra
  			errorExtractValues:
            	li $v0 -1
                jr $ra