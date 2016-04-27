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
	type state_t is record
		fsm_state:fsm_state_type; -- FSM state
		tx_data:std_logic_vector(7 downto 0);
		tx_enable:std_logic;
	end record;
	signal state,state_next:state_t;
	signal reset: std_logic;
	signal uart_rx_data: std_logic_vector(7 downto 0);
	signal uart_rx_enable: std_logic;
	signal uart_tx_data: std_logic_vector(7 downto 0);
	signal uart_tx_enable: std_logic;
	signal uart_tx_ready: std_logic;
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
			state.fsm_state<=idle;
			state.tx_data<=(others=>'0');
			state.tx_enable<='0';
		elsif rising_edge(sys_clk) then
			state<=state_next;
		end if;
	end process;
	fsm_next:process(state,uart_rx_enable,uart_rx_data,uart_tx_ready) is
	begin
		state_next<=state;
		case state.fsm_state is
			when idle=>
				if uart_rx_enable = '1' then
					state_next.tx_data<=uart_rx_data;
					state_next.tx_enable<='0';
					state_next.fsm_state<=received;
				end if;
			when received=>
				if uart_tx_ready = '1' then
					state_next.tx_enable<='1';
					state_next.fsm_state<=emitting;
				end if;
			when emitting=>
				if uart_tx_ready = '0' then
					state_next.tx_enable<='0';
					state_next.fsm_state<=idle;
				end if;
		end case;
	end process;
	fsm_output:process(state) is
	begin
		uart_tx_enable<=state.tx_enable;
		uart_tx_data<=state.tx_data;
		led<=state.tx_data;
	end process;
end arc;
