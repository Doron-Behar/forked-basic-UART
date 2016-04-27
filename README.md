# forked-basic-UART

This is a UART controller based on one built by **Eric** **Bainville -** - Mar 2013, [The original files](http://www.bealto.com/fpga-basic-uart-src.html) can be downloaded [here](http://www.bealto.com/fpga-uart.html).

---------------------
#### The changes I made:

1. Using records instead of signals with underscores - "\_".
2. Better indentation for god sakes. - The files are meant to be viewed with ts=4 - tabsize=4 spaces
3. I merged both of the files `t_serial` and `basic_uart.vhd` to a one larger file with all the processes and signals in it together.

**The overall idea** is that it might be easier to use this repository vs **Eric**'s original if you are an 'indentation Nazi' like me and/or if you are a fan of using records in VHDL programming.

#### Notes:
 - The processes migrated from `t_serial.vhd` are under section called `reciever` and it is full with a headline-style comment.
 - The processes based on `basic_uart.vhd` or what ever are under section `UART` with comments like with `reciever`.
 - I added a testbench `reader.TB.vhd`. The testbench is sending a UART signal based on samples from my repository ["parallax-28140-RFID-reader"](https://github.com/Doron-Behar/parallax-28140-RFID-reader). Checkout branch `simulation` for more examples.
 - In the repository I mentioned above, I used eventually **Eric**'s UART controller
 - I'm sorry **Eric** but I didn't find a reason why the files should be separate. I'll be more than happy if you'll propose your ideas about what I've done here in the ["Issues"](https://github.com/Doron-Behar/forked-basic-UART/issues) section.
