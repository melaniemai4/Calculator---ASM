# Calculator-ASM

For this project, we decided to establish some schedules to think through and write the code together. We had no issues among ourselves, and used Meet calls where one person would share their screen, while the other two helped think and structure the instructions. We switched roles, and found this to be the best way to move forward smoothly.

## Approach

Now, we’ll explain how we approached some specific subroutines.

At the beginning of the `main`, we call:
- `bienvenida`: Asks the user to input an operation where each number is no longer than 6 digits.
- `leer_input_usuario`: Uses a syscall to read the user input from the keyboard.
- `salida_usuario`: Checks if the input is “gracias,” which exits the program.

One issue we encountered was detecting and working with negative numbers. To solve this, we implemented several subroutines (`es_negativo`, `detectar_negativo`) that check if there is a `-` before a number. If there is, a flag is set in `r3` (#-1), and the position advances to the next character (which should be a number). Then, the program jumps to `es_cuenta`.

## Handling Input

We faced some challenges resolving the tasks as suggested in the prompt, so we opted to:
- Traverse the input until a space is found.
- Store the first number.

The subroutine accepts only spaces, numbers (their ASCII equivalents), and newlines (`\n`). If it detects anything else, it throws an error. As we learned in class, we subtract `30h` from the pointed number and use another subroutine to multiply by the positional weight (hundreds, tens, etc.).

Once we reach the first space, we return to the `main` with a subroutine called `volver_main`. Since we needed a condition to return to `main` (in this case, the space character), we created this routine.

If the entered number had a `-`, using the `r3` flag, we pass the number to `convertir_a_negativo`. After cleaning some registers, we repeat the same process for the second number. To advance to where the second number would be, we store the memory address of the first space in a helper register (since we will need it to know the operation) and move 3 positions forward (1st: operator, 2nd: second space, and 3rd: a `-` or the start of the number). After obtaining the second number, we use the helper register where we stored the position of the first space and move one place forward. From there, we call `leer_operacion`.

Using subroutines like `convertir_a_negativo` made our work much easier, as operations between two numbers, regardless of their sign, can be performed without any issues. However, we had to create additional functions specifically for division.

In `leer_operacion`, if it detects a division, it jumps to a subroutine called `prev_division`. This function converts numbers to positive (if they aren’t already) and increments a counter in `r8`. Later, we use this flag to determine if both numbers had the same sign (the flag will be 0 or 2) or if there was a sign difference (flag in 1). `prev_division` also checks that both numbers are not zero, as we encountered two special cases with zero:
1. If the first number is 0, the result is 0 regardless of the second number.
2. If the second number is 0, an error is thrown since division by zero is not allowed.

After passing through these “control” subroutines, it jumps to `division`.

Back in the `main`, if the result is negative, a flag is set in `r0` to be used when printing the result. To avoid complications when converting from integer to `.asciz`, we decided to convert the result to positive and work with the number only.

Finally, in the `main`, we check if the result has 1 digit (0 to 9) or 2 digits and beyond. If it has more than two digits, it jumps to `recorrer_resultado_xDigito`; otherwise, it proceeds to another subroutine called `imprimir_digito`.

In `recorrer_resultado_xDigito`, we simply take the number, divide it by 10 until we get the remainder. For each division, we increment a counter (quotient). When we find the remainder, we call `push_digito`; here, we convert the digit to hexadecimal and push it onto the stack. We use two counters: one to keep track of how many pushes we did (`r4`) and another to determine how many characters we will print (`r11`). This register is used in `mostrar_salida`, so we print exactly the number of characters needed. In `push_digito`, the `RESTO` register gets the number remaining as the quotient, and `COCIENTE` is reset to 0. When the “new” remainder is less than 10, the program will understand that it has reached the first digit and performs one last conversion to hexadecimal and push.

Finally, we compare the flags to determine if the result was negative or if a `-` should be printed in the case of division. `r0` is used generally for the negative result, and `r8` when dealing with division; `r8` will inform if both numbers had the same sign or not (we care only if it has a 1).

If so, it goes to `push_negativo`, where we only store the ASCII `2D` (the `-`) in the result register, push it onto the stack, and increment both counters. From there, it directly calls `desapilar_digitos` to pop each character in order. This is stored in an `.asciz` initialized as `""` (empty) until the push counter is 0.

For aesthetic reasons, we added a subroutine that only adds a newline (`\n`) at the end of the string to print. It then proceeds to `mostrar_salida`, where a syscall is performed to display the result on the screen, and finally advances to `limpiar_registros`. At the end of this last subroutine, it jumps back to the `main`, where everything executes correctly again. As mentioned at the beginning, the program will continue running and requesting operations until the user inputs the word “gracias.” If an invalid format like “24 +3” or “45-1” is entered, or any word other than “gracias” like “hola” or “chau,” an error will be thrown informing that the format is invalid and asking for a valid operation.

We observed one particular operation where the program fails. Due to the number of digits supported by the `mul` command, multiplying two 6-digit numbers results in an error. For example, multiplying 100000 * 100000 should give 10 billion (2540be400 in hexadecimal). However, when printing, it shows 1410065408 (540be400). We believe that due to having 9 hexadecimal digits and certain architecture limitations, it could only print 8 digits.

