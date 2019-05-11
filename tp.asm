;*********************************************************************
; tp.asm
; 
;
;
;*********************************************************************
segment pila	stack
      	  resb 1064

segment datos data

vectorHexa  db  "0123456789ABCDEF"
vectorOctal db  "01234567"

	fullword		resw	1
	char 			resb	1
	aux 			resb	2
	auxHexa  db		000
	msgIng  db  	"Ingrese el caracter 0 o el caracter 1: $"
	msgIng1 db 		"0 para ingresar un nro en Octal , 1 para ingrear un nro en hexa $"
	msgMues db  	10,13,"Ud ingreso: ","$"
	
			db 		3
			db		0
	cadena 	times 3 resb 	1
	msgMues1 db  	10,13,"se convirtio en: $"
	
			db 		2
			db		0
	auxOctal dw		0
	auxPrn	db		'15$'
	auxSec	db 		'000$'
	msgCmb	db		10,13,'El numero en la otra base es: $'
	msgErr	db  	10,13,"No ingreso un caracter correcto!$"
	msgHexa	db 		10,13,"Quiere ingresar una palabra hexa$"
	msgOcta db 		10,13,"Quiere ingresar una palabra octal$"
	msg1	db 		10,13,"Ingrese la palabra Octal que desea ingresar: $"
	msg2	db 		10,13,"Ingrese la palabra Hexa  que desea ingresar: $"
	msgYay	db 		10,13,"Pertenece$"

segment codigo code
..start:
	mov		ax,datos		;ds <-- dir del segmento de datos
	mov		ds,ax
	mov		ax,pila		;ss <-- dir del segmento de pila
	mov		ss,ax

	lea		dx,[msgIng]	;dx <-- offset de 'msgIng' dento del segmento de datos
	call 	printMsg
	
	lea		dx,[msgIng1]	;dx <-- offset de 'msgIng' dento del segmento de datos
	call 	printMsg

	mov		ah,1			   ;servicio 8 para int 21h -- Lee caracter de teclado, lo deja en 'al'
	int		21h
	mov		[char],al		;guardo en char el ascii

	cmp		byte[char],'0'	; char = 0 => ok
	je  	esOctal

	cmp		byte[char],'1'	; char = 1 => ok
	jbe		esHexa

	jmp		error

error:
	lea		dx,[msgErr]	; Imprimo msg de error
	call 	printMsg
	jmp		fin		; me voy al fin

esHexa:	
	lea		dx,[msgHexa]	; Imprimo msg de que el numero va a ser hexa
	call 	printMsg
	
	lea		dx,[msg2]
	call 	printMsg
	call 	pedirNum

; chequeo que sea hexa
	mov 	al,[cadena] 	;apunto al primer byte de la cadena 
	mov 	byte[aux],16	;es el largo del vector para recorrer 
							;el vector de chequeo
	call 	chequearHexa	
	mov 	al,[cadena+1]  	;apunto al segundo byte de la cadena 
	call 	chequearHexa	
	
; transformo el hexa a binario
	mov 	ax,0	
	mov 	al,[cadena]		; cargo primer caracter

	; corrección para letras
	cmp		al,'A'
	jl		noletra1
	sub		al,'A'
	add		al,'9'
	add		al,1

noletra1:
	sub 	al,0x30
	mov 	bl,16
	mul 	bl 
	add		[auxOctal],ax

	mov 	al,[cadena+1]	; cargo segundo caracter

	; corrección para letras
	cmp		al,'A'
	jl		noletra2
	sub		al,'A'
	add		al,'9'
	add		al,1

noletra2:
	sub 	al,0x30
	add 	[auxOctal],ax

	
; transformo el binario a *tres* octales y convierto a ASCII 
	mov 	ax,[auxOctal]
	mov 	dl,8
	div 	dl	;AX se usa como dividiendo, AL tiene el cociente y AH el resto
	mov		bx,0
	mov		bl,ah
	add 	bx,vectorOctal	; indexo en vectorOctal
	mov		ah,[bx]			; obtengo el caracter apuntado
	mov 	[auxSec+2],ah

	mov 	ah,0	;evito que no tenga basura porque me importa solo el cociente
	mov 	dl,8
	div 	dl
	mov		bx,0
	mov		bl,ah
	add 	bx,vectorOctal
	mov		ah,[bx]
	mov 	[auxSec+1],ah

	mov		bl,al			; el cociente es lo que me importa ahora 
	add 	bx,vectorOctal	; indexo en vectorOctal
	mov		al,[bx]			; obtengo el caracter apuntado
	mov 	[auxSec],al
	
	
; imprimo
	lea		dx,[msgMues1]
	call 	printMsg
	lea		dx,[auxSec]
	call	printMsg
	
	jmp		fin		; me voy al fin
	
esOctal:
	lea		dx,[msgOcta]	; Imprimo msg de que el numero va a ser octal
	call 	printMsg
	
	lea		dx,[msg1]
	call 	printMsg		;pido ingreso del buffer	
	call 	pedirNum
	mov 	al,[cadena]
	mov 	byte[aux],9		;es el largo del vector para recorrer
	 						;el vector de chequeo
	call 	chequearOctal	
	mov 	al,[cadena+1]  	
	call 	chequearOctal	

	mov		ax,0
;	transformo cadena a un número binario
	mov 	al,[cadena]		
	sub 	al,0x30			; convierto de ASCII a binario
	mov		bl,8
	mul 	bl				; multiplica AH por 8 lo guarda en AX	
	add 	[auxOctal],ax

	mov 	al,[cadena+1]		
	sub 	al,0x30			; convierto de ASCII a binario
	add 	[auxOctal],ax

; transformo el binario a ASCII
	mov		ax,[auxOctal]
	mov		dl,16
	div 	dl

	mov		bx,0
	mov		bl,al
	add 	bx,vectorHexa	; indexo en vectorHexa
	mov		al,[bx]			; obtengo el caracter apuntado

	mov		bx,0
	mov		bl,ah
	add 	bx,vectorHexa
	mov		ah,[bx]

	mov 	[auxPrn],al
	mov 	[auxPrn+1],ah

; imprimo el número
	lea		dx,[msgMues1]
	call 	printMsg
	lea 	dx,[auxPrn]
	call 	printMsg
			
	jmp 	fin 


pedirNum:	
	lea 	dx,[cadena-2]	;cargo desplaz del buffer
	mov 	ah,0ah
	int 	21h 			;Ingreso de cadena
	
	mov 	ax,0
	mov 	al,[cadena-1]
	mov 	si,ax
	mov 	byte[cadena+si],'$' ;piso el 0Dh con el '$' para indicar
								;fin de string para imprimir
	lea 	dx,[msgMues]
	call 	printMsg
	lea 	dx,[cadena]
	call 	printMsg
		ret

chequearHexa:	
	mov		si,0				;contador para loop
	lea		bx,[vectorHexa]		;bx <- desplaz del vector dentro del segmento de datos
	jmp 	otro
		ret 
		
		
chequearOctal:	
	mov		si,0					;contador para loop
	lea		bx,[vectorOctal]		;bx <- desplaz del vector dentro del segmento de datos
	jmp 	otro
		ret

	
otro:
	mov		dl,[bx+si]			;dl <- elemento del vector apuntado por bx+si
	cmp 	dl,al
	je 		pertenece
	add		si,1					; me posiciono en el sgte elemento del vector
	cmp		si,aux
	jl		otro
	cmp		si,aux
	je 		error 
		ret 
					
pertenece:	
	mov		dx,msgYay	; Imprimo msg de que pertenece
	call 	printMsg
		ret 
	
; printMsg sobreescribe los contenidos de ah
printMsg:
	mov 	ah,9	;servicio 9 para int 21h -- Imprimir msg en pantalla
	int 	21h
	ret
	
;Esta rutina puede borrarse, total nunca se la llama	
ok:
	mov		dx,msgMues	; Imprimo msg de ok
	call 	printMsg
	mov		dl,[char]		; dl <-- caracter ascii a imprimir
	mov		ah,2		; servicio 2 para int 21h -- Imprime un caracter, que esta en 'dl'
	int		21h
		ret 
	
fin:
;retorno al DOS
	mov	ax,4c00h
	int	21h
