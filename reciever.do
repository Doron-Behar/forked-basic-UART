vcom -2008 basic-UART.vhd reciever.vhd reciever.TB.vhd
vsim -voptargs=+acc testbench
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /testbench/reset
add wave -noupdate -format Logic /testbench/data_clk
add wave -noupdate -format Logic /testbench/uart_rx
add wave -noupdate -format Literal -radix hexadecimal /testbench/led
add wave -noupdate -format Logic /testbench/uart_tx
add wave -noupdate -format Logic /testbench/pmod_1
add wave -noupdate -format Logic /testbench/pmod_2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16241234 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
run 300 ms 
