library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

entity basic_uart is
	generic (
		DIVISOR:natural -- DIVISOR=100,000,000 / (16 x BAUD_RATE)
			-- 2400 -> 2604
			-- 9600 -> 651
			-- 115200 -> 54
			-- 1562500 -> 4
			-- 2083333 -> 3
	);
	port (
		clk			:in std_logic;							-- clock
		reset		:in std_logic;							-- reset
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
end entity;

architecture arc of basic_uart is
	--====================================================================
	--------------------------------UART----------------------------------
	--====================================================================
	type UART_rx_type is record
		-- received byte:
		data	:std_logic_vector(7 downto 0);
		-- validates received byte (1 system clock spike):
		enable	:std_logic;
		--physical
		buff	:std_logic;
	end record;
	type UART_tx_type is record
		-- byte to send:
		data	:std_logic_vector(7 downto 0);
		-- validates byte to send if tx_ready is '1':
		enable	:std_logic;
		-- if '1', we can send a new byte, otherwise we won't take it:
		ready	:std_logic;
		--physical
		buff	:std_logic;
	end record;
	type UART_fsm_state_type is (idle,active); -- common to both RX and TX FSM
	type UART_rxs_state_type is record
		state:UART_fsm_state_type;					-- FSM state
		counter:std_logic_vector(3 downto 0);	-- tick count
		bits:std_logic_vector(7 downto 0);		-- received bits
		nbits:std_logic_vector(3 downto 0);		-- number of received bits (includes start bit)
		enable:std_logic;						-- signal we received a new byte
	end record;
	type UART_txs_state_type is record
		state:UART_fsm_state_type; -- FSM state
		counter:std_logic_vector(3 downto 0); -- tick count
		bits:std_logic_vector(8 downto 0); -- bits to emit, includes start bit
		nbits:std_logic_vector(3 downto 0); -- number of bits left to send
		ready:std_logic; -- signal we are accepting a new byte
	end record;
	type UART_rxs_type is record
		current:UART_rxs_state_type;
		last:UART_rxs_state_type;
	end record;
	type UART_txs_type is record
		current:UART_txs_state_type;
		last:UART_txs_state_type;
	end record;
	type UART_sample_type is record
		clk:std_logic;
		counter:std_logic_vector(integer(ceil(log2(real(DIVISOR))))-1 downto 0); -- should fit values in 0..DIVISOR-1
	end record;
	type UART_type is record
		rx:UART_rx_type;
		tx:UART_tx_type;
		rxs:UART_rxs_type;
		txs:UART_txs_type;
		sample:UART_sample_type;
	end record;
	signal UART:UART_type;
begin
	--output-test
	rx_data<=UART.rx.data;
	rx_enable<=UART.rx.enable;
	UART.rx.buff<=rx;
	UART.tx.data<=tx_data;
	UART.tx.enable<=tx_enable;
	tx_ready<=UART.tx.ready;
	tx<=UART.tx.buff;
	-- sample signal at 16x baud rate, 1 clk spikes:
	sample_process:process(clk,reset) is
	begin
		if reset='1' then
			UART.sample.counter<=(others=>'0');
			UART.sample.clk<='0';
		elsif rising_edge(clk) then
			if UART.sample.counter=DIVISOR-1 then
				UART.sample.clk<='1';
				UART.sample.counter<=(others=>'0');
			else
				UART.sample.clk<='0';
				UART.sample.counter<=UART.sample.counter + 1;
			end if;
		end if;
	end process;
	-- RX, TX state registers update at each clk, and reset
	reg_process:process(clk,reset) is
	begin
		if reset='1' then
			UART.rxs.last.state<=idle;
			UART.rxs.last.bits<=(others=>'0');
			UART.rxs.last.nbits<=(others=>'0');
			UART.rxs.last.enable<='0';
			UART.txs.last.state<=idle;
			UART.txs.last.bits<=(others=>'1');
			UART.txs.last.nbits<=(others=>'0');
			UART.txs.last.ready<='1';
		elsif rising_edge(clk) then
			UART.rxs.last<=UART.rxs.current;
			UART.txs.last<=UART.txs.current;
		end if;
	end process;
	-- RX FSM
	rx_process:process (UART.rxs,UART.sample.clk,UART.rx.buff) is
	begin
		case UART.rxs.last.state is
			when idle=>
				UART.rxs.current.counter<=(others=>'0');
				UART.rxs.current.bits<=(others=>'0');
				UART.rxs.current.nbits<=(others=>'0');
				UART.rxs.current.enable<='0';
				if UART.rx.buff='0' then
					-- start a new byte
					UART.rxs.current.state<=active;
				else
					-- keep idle
					UART.rxs.current.state<=idle;
				end if;
			when active=>
				UART.rxs.current<=UART.rxs.last;
				if UART.sample.clk='1' then
					if UART.rxs.last.counter=8 then
						-- sample next RX bit (at the middle of the counter cycle):
						if UART.rxs.last.nbits=9 then
							-- back to idle state to wait for next start bit
							UART.rxs.current.state<=idle;
							-- OK if stop bit is '1':
							UART.rxs.current.enable<=UART.rx.buff;
						else
							UART.rxs.current.bits<=UART.rx.buff & UART.rxs.last.bits(7 downto 1);
							UART.rxs.current.nbits<=UART.rxs.last.nbits + 1;
						end if;
					end if;
					UART.rxs.current.counter<=UART.rxs.last.counter + 1;
				end if;
		end case;
	end process;
	-- RX output
	rx_output:process(UART.rxs) is
	begin
		UART.rx.enable<=UART.rxs.last.enable;
		UART.rx.data<=UART.rxs.last.bits;
	end process;
	-- TX FSM
	tx_process:process(UART.txs,UART.sample.clk,UART.tx.enable,UART.tx.data) is
	begin
		case UART.txs.last.state is
			when idle=>
				if UART.tx.enable='1' then
					-- start a new bit
					-- data & start
					UART.txs.current.bits<=UART.tx.data & '0';
					-- send 10 bits (includes '1' stop bit)
					UART.txs.current.nbits<="0000" + 10;
					UART.txs.current.counter<=(others=>'0');
					UART.txs.current.state<=active;
					UART.txs.current.ready<='0';
				else
					-- keep idle
					UART.txs.current.bits<=(others=>'1');
					UART.txs.current.nbits<=(others=>'0');
					UART.txs.current.counter<=(others=>'0');
					UART.txs.current.state<=idle;
					UART.txs.current.ready<='1';
				end if;
			when active=>
				UART.txs.current<=UART.txs.last;
				if UART.sample.clk='1' then
					if UART.txs.last.counter=15 then
						-- send next bit
						if UART.txs.last.nbits=0 then
							-- turn idle
							UART.txs.current.bits<=(others=>'1');
							UART.txs.current.nbits<=(others=>'0');
							UART.txs.current.counter<=(others=>'0');
							UART.txs.current.state<=idle;
							UART.txs.current.ready<='1';
						else
							UART.txs.current.bits<='1' & UART.txs.last.bits(8 downto 1);
							UART.txs.current.nbits<=UART.txs.last.nbits - 1;
						end if;
					end if;
					UART.txs.current.counter<=UART.txs.last.counter + 1;
				end if;
		end case;
	end process;
	-- TX output
	tx_output:process(UART.txs) is
	begin
		UART.tx.ready<=UART.txs.last.ready;
		UART.tx.buff<=UART.txs.last.bits(0);
	end process;
end arc;
