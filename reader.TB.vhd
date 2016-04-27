library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity testbench is
end;

architecture arc OF testbench is
	signal clk100mhz:std_logic:='0';
	constant not_data_at_data_clk:std_logic_vector:="000000000000000000000011010111101111100110110110011011111001101111110011011110001101101100110111100011011011110101111100110101111110101010011110000000000000000000000000000000000000000011010111110111110011011011001101111100110111110011011110001101101100011011110001101101111010111110011010111110101010011110000000000000000000000000000000000000000000000000000000001101011110111110011011011001100111110011011111001101111000110110110011011110001101101111011011111001101011111010101001111000000000000000000000000000000000000000001101011110111110011011011001101111100110111110011011110000110110110011011110001101101111010111110011010111110101010001111000000000000000000000000000000000011010111101111100110110110011011111001101111100110111100001101101100110111100011011011110101111100110101111101010100011110000000000000000000000000000000000000110101111011111001101100110011011111001101111100110111100011011011001101111000110111011110101111100110101111101010100111100000000000000000000000000000110101111011111100110110110011011111001101111100110111100011011011001100111100011011011110101111100110101111101010100111100000000000000000000000000000000000000000000001101011110111110011011011001101111100111011111001101111000110110110011011110001101101111010111110001101011111010101001111000000000000000000000000000000000000000000000000000000000001101011110111110011011011001101111100110111111001101111000110110110011011110001101101111010111110011101011111010101001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110101111011111100110110110011011111001101111100110111100011011011001100111100011011011110101111100110101111101010100111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110101111011111001101101100110111110001101111100110111100011011011001101111000110110111101011111100110101111101010100111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100101111011111001101101100110111110011011111001101111000110111011001101111000110110111101011111001101011111010101001111000000000000000000000000000000000000000000011010111101111100110110110011101111100110111110011011110001101101100110111100011011011111010111110011010111110101010011110000000000000000";
	signal data_clk:std_logic:='0'; --clk2400hz
	signal pmod:std_logic_vector(1 downto 0);
	signal data:std_logic;
	signal byte:std_logic_vector(7 downto 0);
	signal reset:std_logic:='0';
	signal uart_tx:std_logic;
	component reader
		port(
			clk100mhz	:in std_logic;
			reset		:in std_logic;
			data		:in std_logic;
			byte		:out std_logic_vector(7 downto 0);
			uart_tx		:out std_logic;
			pmod		:out std_logic_vector(1 downto 0) -- debug outputs
	);
	end component;
begin
	reader_inst:reader
		port map(
			clk100mhz	=>clk100mhz,
			reset		=>reset,
			data		=>data,
			byte		=>byte,
			uart_tx		=>uart_tx,
			pmod		=>pmod
		);
	clk100mhz<=not clk100mhz after 5 ns; -- 10 ns = (1/100Mhz)/2, T(50Mhz)=20ns
	reset<='0','1' after 1 us;
	data_clk<=not data_clk after 208333 ns;
	process(data_clk,reset)
		variable counter:integer;
		begin
		if reset='0' then
			counter:=0;
			data<='0';
		elsif rising_edge(data_clk) then
			counter:=counter+1;
			if counter<not_data_at_data_clk'length then
				data<=not not_data_at_data_clk(counter);
			else
				counter:=0;
			end if;
		end if;
	end process;
end;