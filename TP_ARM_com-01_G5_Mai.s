.data
input_usuario: .asciz "                    "
mensaje_error: .asciz "El formato es invalido\n"
error_div: .asciz "No se puede dividir por 0\n"
mensaje_bienvenida: .asciz "Ingrese la operacion\n"
num1: .int 0
num2: .int 0
resultado: .int 0
text_resultado: .asciz "  "
resto: .int 0
@prueba: .asciz "10 * 10"
mensaje_despedida: .asciz "De nada! Hasta luego :)\n"

.text

.global main

main:
	bl bienvenida
	bl leer_input_usuario   @ en r1 esta guardada la direc. de memoria del input
	bl salida_usuario

	mov r0, #1 		@ inicia el contador
	mov r2, #0	@ en r2 se van a cargar los numeros
	mov r10, #10	@ va a servir para pasar de ascii a entero

@1er_numero:
	bl es_negativo  @ se fija si hay un - adelante del primer nro, si es asi guarda -1 en r3
	bl es_cuenta    @ encuentra el primer numero y la posicion del primer espacio
	cmp r3, #-1     @ r3 se modifica en es_negativo, lo usamos de flag
	beq convertir_negativo @ el nro en decimal ahora es negativo
	ldr r9, =num1
	str r2, [r9]

	mov r8, r1	@ guardo la direccion de memoria del primer espacio
	add r1, #2	@ si lo siguiente al operador no es un espacio, error
	ldrb r5, [r1]
	cmp r5, #0x20
	bne error
	add r1, #1      @ avanza el puntero hasta el segundo numero "1_+_2" <-- ahora apunta al 2
	mov r0, #1	@ reinicio contador y donde guardo el nro 2
	mov r2, #0	@ r2 es donde voy a tener al segundo numero
	mov r3, #0	@ reiniciar si es negativo o no

@2do_numero:		@ Primero me fijo si el primer carac. es un menos, me guarda un flag
	bl es_negativo  @ para acordarse que es negativo. Encuentra el numero y lo convierte a
	bl es_cuenta    @ positivo para poder trabajar normal.
	cmp r3, #-1
        beq convertir_negativo
	ldr r11, =num2
	str r2, [r11]

@operacion:
	add r8, #1	@ En r8 estaba sobre el 1er espacio y avanzo una posicion, me posiciono en la operacion
	ldrb r5, [r8]	@ cargo en r5 lo apuntado por r8 (+,-,/,*)
	ldr r4, [r9]	@ cargo ambas variables
	ldr r2, [r11]
	mov r10, #0	@ r10 es donde voy a guardar el rdo de la operacion
	mov r3, #-1     @ lo usamos de flag para ver si el resultado es negativo
	mov r8, #0	@ si el flag es 0 o 2, los signos son iguales. si es 1, un nro es negativo
	bl leer_operacion

@vuelvo con resultado en r10
	ldr r10, [r7]	
	mov r4, #0      @ inicio el contador del push para cuando pase el rdo a asciz
	mov r5, #0	@ inicio el cociente
	ldr r6, =text_resultado
	mov r3, #-1
	mov r0, #0      @ si r0 tiene un 1, el resultado es negativo. si tiene 0, es positivo.
	bl imprimir_negativo       @ indica si tengo que imprimir un - (es un flag de si el rdo es negativo)
	cmp r10, #0
	blt convertir_rdo_positivo @ si el nro es negativo lo paso a positivo
@imprimir
	mov r11, #0
	cmp r10, #10
	bge recorrerResultadoxDigito    @ al ser 10 o mas grande, tiene que recorrer varios digitos
	bl imprimir_digito		@ sino, que imprima el unico digito
	bl end

bienvenida:
	mov r0, #1
	ldr r1,=mensaje_bienvenida
	mov r2, #21
	mov r7, #4
	swi 0
	bx lr

leer_input_usuario:
	mov r7, #3
	mov r0, #0 @lee lo que ingresa desde el puerto del teclado
	mov r2, #20
	ldr r1, =input_usuario @ingreso string
	swi 0
	bx lr

es_negativo: @verifica si hay un menos antes de un numero, si lo hay, guarda un flag y avanza una posicion
	ldrb r5, [r1]
	cmp r5, #0x2D 
	beq detectar_negativo
	bal volver_main

detectar_negativo:
	mov r3, #-1
	add r1, #1
	bx lr

convertir_negativo:
	mul r2, r3
	mov r3, #0
	bal volver_main

convertir_rdo_positivo:
	mul r10, r3   @ r3 tiene un -1, al multiplicar con un nro negativo, queda positivo
	mov r3, #0    @ reinicio el flag ya que dejo de ser nro negativo
        bal volver_main

es_cuenta:	@lo usamos para encontrar num1 y num2
	ldrb r5, [r1]
	cmp r0, #7	@ si van mas de 6 digitos se rompe (6 digitos + espacio)
	bgt error
	cmp r5, #0x20     @ compara con espacio
	beq volver_main  @ r4 apunta a la posicion del primer espacio
	cmp r5, #0xa	@ se fija si es el final --> /n (para cuando busque 2do nro)
	beq volver_main  @ vuelve si termino
	cmp r5, #00
	beq volver_main
	cmp r5, #0x30	@ chequea que en r5 solo haya numeros
	blt error	@ si no es un numero ni espacio o final de cadena, error
	cmp r5, #0x39
	bgt error
	add r1, #1
	add r0, #1
	sub r5, #0x30	@ transforma de hexa a decimal
	cmp r0, #1      @ pregunta si es el primer elemento
	bne siguiente
	mov r2, r5
	bal es_cuenta

siguiente:
	mul r2, r10     @ multiplica digitos x10
	add r2, r5	@ acumula el numero
	bal es_cuenta

volver_main:
	bx lr

error:
	mov r0, #1
	ldr r1, =mensaje_error
	mov r2, #24
	mov r7, #4
	swi 0
	bal limpiar_registros

error_division:
        mov r0, #1
        ldr r1, =error_div
        mov r2, #27
        mov r7, #4
        swi 0
        bal limpiar_registros

leer_operacion:
	cmp r5, #0x2B @suma
	beq suma
	cmp r5, #0x2D @resta
	beq resta
	cmp r5, #0x2A @multiplicacion
	beq multiplicacion
	cmp r5, #0x2F @division
	beq prev_division

suma:
	add r10, r4, r2
	ldr r7,=resultado
	str r10, [r7]
	bal volver_main

resta:
	sub r10,r4,r2
	ldr r7,=resultado
	str r10,[r7]
	bal volver_main

multiplicacion:
	mul r10,r4,r2
	ldr r7,=resultado
	str r10, [r7]
	bal volver_main

prev_division:		 @verificamos que los numeros que entran a dividir sean positivos y sino los transforma.
	cmp r4, #0
	blt pasar_r4_positivo
	cmp r2, #0
	blt pasar_r2_positivo
	cmp r4, #0
	beq primer_nro_cero
	cmp r2, #0
	beq segundo_nro_cero
	bal division

primer_nro_cero: @hay dos casos particulares en los cuales hay que tener cuidado, si el primer numero es cero o si el segundo lo es.
	mov r10, #0
	ldr r7, =resultado
	str r10, [r7]
	bal volver_main		@ si el primer numero es 0, el rdo tiene que ser 0

segundo_nro_cero:
	bal error_division	@ si el segundo numero es 0, error. no se puede dividir x 0

pasar_r4_positivo:  @ el primer numero va a ser positivo siempre
        mul r4, r3
        add r8, #1
        bal prev_division


pasar_r2_positivo: @ el segundo numero va a ser positivo siempre
	mul r2, r3
	add r8, #1
	bal prev_division

division:
	sub r4, r2 @ va restandole al dividendo el divisor
	add r10,#1 @ cada vez que resta, se suma 1 al contador. r10 tiene el resultado(cociente) y r4 el resto
	ldr r7, =resto
	str r4, [r7]
	ldr r7,=resultado
	str r10,[r7]
	cmp r4, r2
	blt volver_main
	bal division

recorrerResultadoxDigito: @lo que hace es dividir por 10 hasta encontrar el resto (1 digito) cuando lo encuentra llama a push_digito
			  @tenemos un contador que va a funcionar cociente
	cmp r10, #0
	beq rdo_cero
	sub r10, #10
	add r5, #1
	cmp r10, #10
	blt push_digito
	bal recorrerResultadoxDigito

rdo_cero: @para los casos donde rdo es 0 --> nro * 0, nro - nro, etc
	add r11, #1
	add r10, #0x30
	strb r10, [r6]
	bal salto_de_linea

imprimir_negativo: @se fija si el resultado es negativo y si lo es llama al flag_negativo
	cmp r10, #0
	blt flag_negativo
	bal volver_main

flag_negativo: @si r0 tiene un 1, el flag indica que el resultado es negativo
	mov r0, #1
	bx lr

push_negativo:  @si el flag de negativo esta activado pushea un "-" a la cima de la pila
	mov r10, #0x2D
	push {r10}
	add r4, #1
	add r11, #1
	mov r0, #0
 	mov r8, #0
	bal desapilar_digitos

push_digito: @recibe numero de un digito, lo pasa a hexa, lo pushea, aumenta contadores,
	     @el nuevo numero a dividir es el cociente, el "resto" queda en cero.
	add r10,#0x30
	push {r10}
	add r4,#1
	add r11, #1
	mov r10, r5
	mov r5, #0
	cmp r10, #10  @si no es el primer digito sigo dividiendo
	bge recorrerResultadoxDigito
	add r10, #0x30  @transforma el primer digito a hexa
	push {r10}      @pushea el primer digito
	add r4, #1      @suma uno al contador de push
	add r11, #1
	cmp r0, #1      @se fija el flag de resultado negativo
	beq push_negativo
	cmp r8, #1	@se fija si los numeros de la divison tienen o no el mismo signo
	beq push_negativo

desapilar_digitos: @en r6 estoy apuntando a la direccion del asciz de salida
		   @popeo hasta que el contador de push sea 0 y los voy guardando
		   @en un .asciz para mostar luego
	cmp r4, #0
	beq salto_de_linea
	pop {r10}
	sub r4,#1
	strb r10, [r6]
	add r6, #1
	bal desapilar_digitos

imprimir_digito: @cuando el resultado sea un solo digito se utiliza esta funcion
	add r10, #0x30
	push {r10}
	add r4, #1
	add r11, #1
	cmp r0, #1
        beq push_negativo
	cmp r8, #1
	beq push_negativo
	bal desapilar_digitos

salto_de_linea: @agrega un salto de linea al final de la cadena
	add r11, #1
	mov r0, #10
	strb r0, [r6]

mostrar_salida:		@imprimo el resultado
	mov r0, #1
	ldr r1, =text_resultado
	mov r2, r11
	mov r7, #4
	swi 0

limpiar_registros:
	mov r0, #0
	mov r1, #0
	ldr r0, =num1
	str r1, [r0]
	ldr r0, =num2
        str r1, [r0]
	ldr r0, =resultado
        str r1, [r0]
	mov r2, #0
        mov r3, #0
	mov r4, #0
        mov r5, #0
        mov r6, #0
        mov r7, #0
        mov r8, #0
        mov r9, #0
        mov r10, #0
	mov r11, #0
	bl main

salida_usuario:
	mov r0, #0
	ldrb r5, [r1, r0]
	cmp r5, #0x67  @g en asci
	bne volver_main
	add r0, #1
	ldrb r5, [r1,r0]
	cmp r5, #0x72  @r en asci
        bne volver_main
	add r0, #1
	ldrb r5, [r1,r0]
	cmp r5, #0x61  @a en asci
       	bne volver_main
	add r0, #1
	ldrb r5, [r1,r0]
        cmp r5, #0x63  @c en asci
        bne volver_main
	add r0, #1
        ldrb r5, [r1,r0]
        cmp r5, #0x69  @i en asci
        bne volver_main
        add r0, #1
        ldrb r5, [r1,r0]
	cmp r5, #0x61  @a en asci
        bne volver_main
        add r0, #1
        ldrb r5, [r1,r0]
        cmp r5, #0x73  @s en asci
        bne volver_main


mensaje_salida:
        mov r0, #1
        ldr r1, =mensaje_despedida
        mov r2, #24
        mov r7, #4
        swi 0


end:
	mov r7, #1
	swi 0
