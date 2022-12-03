## what each line in the template means
```c++
.386
.model flat,stdcall
.stack 4096
ExitProcess proto,dwExitCode:dword
.data
	; your variables here
.code

main PROC
	; your code here

	invoke ExitProcess, 0
main ENDP
END main
```
```
Line 1 contains the .386 directive, which identifies this as a 32-bit program that can access
 32-bit registers and addresses.

Line 2 selects the program’s memory model (flat), and identifies
 the calling convention (named stdcall) for procedures. We use this because 32-bit
Windows services require the stdcall convention to be used

Line 3 sets aside 4096 bytes of storage for the runtime stack, which every program
 must have.

Line 4 declares a prototype for the ExitProcess function, which is a standard Windows service

A prototype consists of the function name, the PROTO keyword, a comma, and a list of
 input parameters. The input parameter for ExitProcess is named dwExitCode.

Line 17 uses the end directive to mark the last
 line to be assembled, and it identifies the program entry point (main). The label main was
declared on Line 10, and it marks the address at which the program will begin to execute.
```
