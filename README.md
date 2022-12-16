
# NAGSM

## WE'RE IN DEMO BABYYY LESGO

- Main Menu  

    ![menu](/assets/main_menupng.png)

- game scene ***"for now"***

    ![game](/assets/game.png)

## How to run

 1. #### You'll need some sort of virual machine to run 16 bit stuff. [DOSBOX](https://www.dosbox.com/) is intutive and easy to use
 2. #### You'll need an assembler to make an executable out of your .asm file we use **MASM** you can download the assembler from [here](https://drive.google.com/drive/folders/1akM4UNg6StiVE3ehzEstOgOhEw1JBxA0) 


paste the assembler in your project folder for simplicity.
after downloading and installing **DOSBOX**, run it and mount the project folder by typing

    mount c c:\<PATH_OF_THE_PROJECT>
then type
	

    c:
you're now in directory of the project in the virutal machine, to make sure that your are you can type 

    dir
and a list of the files and folders in the directory will be printed in the console.
if it doesn't make sure you replicated the previous steps correctly

now assemble the .asm file by typing

    masm /a <FILE_NAME>.asm

Link it by typing

    link <THE_NAME_OF_THE_OBJ_YOU_CHOSE>

and you now have an executable of your assembly
simply type its name in the console and it will start running
