# Calculator-ASM

Para el desarrollo de este trabajo, decidimos establecer algunos horarios para poder pensar y 
escribir el código en conjunto. No tuvimos ningún problema entre nosotros, hacíamos llamada por 
meet y mientras uno compartía, los otros dos ayudaban a pensar a estructurar las instrucciones. 
Fuimos cambiando de rol y encontramos ésta la mejor forma y herramienta para poder avanzar sin 
problemas.

Dicho eso, pasaremos a explicar la manera en la que abarcamos algunas subrutinas en específico. 
Al comienzo del main, llamamos a bienvenida (que pide al usuario que ingrese una operación de no 
más de 6 dígitos cada número), a leer_input_usuario (donde se realiza una syscall para leer lo 
ingresado por teclado) y luego a salida_usuario (que chequea que lo ingresado sea distinto a 
“gracias”, el mensaje con el que se sale del programa).

Uno de los inconvenientes que encontramos fue cómo detectar y trabajar con números negativos. 
Para ello, lo que implementamos fue una serie de subrutinas (es_negativo, detectar_negativo) que 
básicamente chequean si antes de cada número hay un ‘—‘. Si lo hay, se guarda un flag en r3 (#-1) 
y se avanza a la siguiente posición (donde ya debería haber un número). Luego se hace un salto a 
es_cuenta. Con esta función también encontramos algunos problemas para resolver todo tal y 
como se sugería en el enunciado, entonces lo que decidimos hacer fue: recorrer el input hasta 
encontrar un espacio e ir guardando el primer número. La subrutina solo acepta espacios, números 
(sus equivalentes en ASCII) y saltos de línea (\n). Cualquier otra cosa que detecte, va a tirar error.
Como vimos en clase, le restamos 30 en hexa al número apuntado y con otra subrutina vamos 
multiplicando por peso (centenas, decenas, etc.).

Una vez que está posicionado sobre el primer espacio, vuelve al main con una subrutina llamada 
volver_main. Al tener que utilizar un condicional para volver al main (en este caso, que el caracter 
sea un espacio) vimos necesario crear esa rutina. Si el número ingresado tenía un ‘—‘ adelante, 
utilizando el flag de r3, pasamos el número a convertir_a_negativo. Después de limpiar algunos 
registros, hacemos lo mismo con el segundo número. Para avanzar hasta donde estaría ese número, 
guardamos la dirección de memoria del primer espacio en un registro auxiliar (ya que luego lo vamos 
a necesitar para saber cuál es la operación) y avanzamos 3 posiciones (1era: operador, 2da: segundo 
espacio y 3era: un ‘—‘ o el comienzo del número). Luego de obtener el segundo número, utilizamos 
aquél registro auxiliar donde guardamos la posición del primer espacio y avanzamos un lugar. De 
ahí se llama a leer_operación.

Utilizar subrutinas como convertir_a_negativo nos facilitó mucho el trabajo ya que tanto con la 
suma, como con la resta y la multiplicación, las operaciones entre dos números, sin importar su 
signo, se pueden realizar sin ningún problema. Sin embargo, tuvimos que hacer un par de funciones 
aparte solo para las divisiones. 
En leer_operacion, si detecta que debe realizar una división, salta a una subrutina llamada 
prev_division. Esta función se encarga de pasar los números a positivo (en caso de que no lo fueran) 
y aumenta un contador en r8. Más adelante, utilizaremos ese flag para saber si ambos tenían el 
mismo signo (el flag estará en 0 o 2) o si había uno con signo diferente (flag en 1).
También, prev_division chequea que ambos números sean distintos de cero ya que detectamos dos 
casos particulares con este número. A) si el primer número es 0, no importa cuál sea el segundo, el 
resultado será 0. B) si el segundo número es 0, salta un error ya que no se puede dividir por 0. Luego 
de pasar por esas subrutinas “de control”, salta a división.
2
Devuelta al main, si el resultado es negativo se guarda un flag en r0 para luego utilizarlo al imprimir 
dicho resultado. Para evitar complicaciones al momento de pasar de entero a .asciz, decidimos pasar 
el resultado a positivo y trabajar solamente con el número.
Lo último que hacemos en el main es chequear si el resultado tiene 1 digito (0 al 9) o 2 dígitos en 
adelante. Si tiene más de dos dígitos, saltará a recorrer_resultado_xDigito y sino, sigue de largo y 
salta a otra subrutina llamada imprimir_digito.
En recorrer_resultado_xDigito simplemente tomamos el número, lo vamos dividiendo por 10 hasta 
obtener el resto. Por cada vez que lo dividimos, sumamos 1 al contador (cociente). Cuando 
encontramos el resto, se llama a push_digito; acá se pasa a hexa aquél digito e inmediatamente lo 
pusheamos en la pila. Utilizamos dos contadores; uno que es 
particularmente para saber cuántos push hicimos (r4) y hacer la 
misma cantidad de pop; el otro es para saber cuántos son los 
caracteres finales que vamos a imprimir (r11) y ese registro es 
utilizado en mostrar_salida (entonces así se imprimen 
exactamente la cantidad de caracteres que necesitamos). En 
push_digito, al registro RESTO le pasamos el número que quedó 
como cociente, y a COCIENTE lo reiniciamos en 0. Cuando el 
“nuevo” resto sea menor a 10, el programa entenderá que se llegó 
al primer dígito y hará una última vez un pasaje a hexa y un push.
Por último, se comparan los flags para saber si el resultado era negativo o si debe imprimirse un 
‘—‘ en el caso de las divisiones. R0 se utilizará en general para el resultado negativo y r8 cuando se 
trate de una división; como mencionamos anteriormente, r8 informará si ambos números tenían el 
mismo signo o no (nos importa si tiene un 1 nada más).
De ser así, se pasa a push_negativo, donde lo único que hacemos es guardar el ASCII 2D (el ‘—‘) en 
el registro del resultado, lo pushea en el tope de la pila y aumenta los dos contadores. Directamente 
de ahí, se llama a desapilar_digitos y se van haciendo pop (en orden) de cada carácter a imprimir. 
Esto se va guardando en un .asciz iniciado como “” (vacío) y lo hace hasta que el contador de push 
es 0.
Solo por una cuestión estética, añadimos una subrutina que lo único que hace es agregar, al final de 
la cadena a imprimir, un salto de línea (\n). Inmediatamente, avanza a la etiqueta mostrar_salida
donde se realiza una syscall para mostrar en pantalla el resultado, y finalmente avanza a
limpiar_registros. Al final de esta última etiqueta se salta al main, donde todo se vuelve a ejecutar 
correctamente. Y como dijimos al principio, hasta que el usuario no ingrese la palabra “gracias” el 
programa se seguirá ejecutando y pidiendo que se ingresen operaciones. Si se ingresa un formato 
inválido como “24 +3” o “45-1”, poniendo espacios demás o ingresando cualquier palabra distinta a 
“gracias” como “hola” o “chau”, saltará un error informando que el formato no es válido y que debes 
ingresar una operación. 
Observamos que hay una operación en particular donde falla el programa. Por una cuestión de 
cuántos dígitos soporta el comando mul, la multiplicación entre 2 números de 6 dígitos tira error. 
Por ejemplo, al querer multiplicar 100000 * 100000, nos debería dar como resultado 10 mil millones 
(2540be400 en hexa). Sin embargo, al imprimir, sucede que imprime 1410065408 (540be400). 
Nosotros creemos que al tener 9 dígitos en hexadecimal y por ciertas limitaciones de la arquitectura, 
solo pudo imprimir 8 dígitos
