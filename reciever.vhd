library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity reciever is
	port(
		sys_clk		:in std_logic;
		led			:out std_logic_vector(7 downto 0);
		uart_rx		:in std_logic;
		uart_tx		:out std_logic;
		pmod_1		:out std_logic; -- debug outputs
		pmod_2		:out std_logic;
		reset_btn	:in std_logic
	);
end reciever;

architecture arc of reciever is
	component basic_uart is
		generic (
			DIVISOR:natural  -- DIVISOR = 100,000,000 / (16 x BAUD_RATE)
				-- for a frequency of 2400hz you need to put 2604 as a divisor
				-- for a frequency of 9600hz you need to put 651 as a divisor
				-- for a frequency of 115200hz you need to put 54 as a divisor
				-- for a frequency of 1562500hz you need to put 4 as a divisor
				-- for a frequency of 2083333hz you need to put 3 as a divisor
		);
		port (
			clk			:in std_logic;
			reset		:in std_logic;
			-- Client interface
			rx_data		:out std_logic_vector(7 downto 0);	-- received byte
			rx_enable	:out std_logic;						-- validates received byte (1 system clock spike)
			tx_data		:in std_logic_vector(7 downto 0);	-- byte to send
			tx_enable	:in std_logic;						-- validates byte to send if tx_ready is '1'
			tx_ready	:out std_logic;						-- if '1', we can send a new byte, otherwise we won't take it
			-- Physical interface
			rx			:in std_logic;
			tx			:out std_logic
		);
	end component;
	type fsm_state_type is (idle,received,emitting);
	type reciever_state_type is record
		state:fsm_state_type; -- FSM state
		tx_data:std_logic_vector(7 downto 0);
		tx_enable:std_logic;
	end record;
	type reciever_type is record
		current:reciever_state_type;
		last:reciever_state_type;
	end record;
	signal reciever:reciever_type;
	signal reset:std_logic;
	signal uart_rx_data:std_logic_vector(7 downto 0);
	signal uart_rx_enable:std_logic;
	signal uart_tx_data:std_logic_vector(7 downto 0);
	signal uart_tx_enable:std_logic;
	signal uart_tx_ready:std_logic;
begin
	basic_uart_inst:basic_uart
		generic map(
			DIVISOR => 2604 -- for 2400hz
		)
		port map(
			clk			=>sys_clk,
			reset		=>reset,
			rx_data		=>uart_rx_data,
			rx_enable	=>uart_rx_enable,
			tx_data		=>uart_tx_data,
			tx_enable	=>uart_tx_enable,
			tx_ready	=>uart_tx_ready,
			rx			=>uart_rx,
			tx			=>uart_tx
		);
	reset_control:process(reset_btn) is
	begin
		if reset_btn = '1' then
			reset<='0';
		else
			reset<='1';
		end if;
	end process;
	pmod_1 <= uart_tx_enable;
	pmod_2 <= uart_tx_ready;
	fsm_clk:process(sys_clk,reset) is
	begin
		if reset='1' then
			reciever.last.state<=idle;
			reciever.last.tx_data<=(others=>'0');
			reciever.last.tx_enable<='0';
		elsif rising_edge(sys_clk) then
			reciever.last<=reciever.current;
		end if;
	end process;
	fsm_next:process(reciever.last,uart_rx_enable,uart_rx_data,uart_tx_ready) is
	begin
		reciever.current<=reciever.last;
		case reciever.last.state is
			when idle=>
				if uart_rx_enable = '1' then
					reciever.current.tx_data<=uart_rx_data;
					reciever.current.tx_enable<='0';
					reciever.current.state<=received;
				end if;
			when received=>
				if uart_tx_ready = '1' then
					reciever.current.tx_enable<='1';
					reciever.current.state<=emitting;
				end if;
			when emitting=>
				if uart_tx_ready = '0' then
					reciever.current.tx_enable<='0';
					reciever.current.state<=idle;
				end if;
		end case;
	end process;
	fsm_output:process(reciever.last) is
	begin
		uart_tx_enable<=reciever.last.tx_enable;
		uart_tx_data<=reciever.last.tx_data;
		led<=reciever.last.tx_data;
	end process;
end arc;
