library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
entity tb_controls is end;
architecture test of tb_controls is
  signal clk : std_logic := '0';
  signal keys : std_logic_vector(1 downto 0) := "11";
  signal sw : std_logic_vector(9 downto 0) := (others=>'0');
  signal reset,start,fire,left,right : std_logic;
  signal fire_count,left_count,right_count,start_count : natural := 0;
begin
  clk<=not clk after 10 ns;
  dut: entity work.controls generic map(4,10) port map(clk,keys,sw,reset,start,fire,left,right);
  process(clk) begin
    if rising_edge(clk) then
      if fire='1' then fire_count<=fire_count+1; end if;
      if start='1' then start_count<=start_count+1; end if;
      if left='1' then left_count<=left_count+1; end if;
      if right='1' then right_count<=right_count+1; end if;
    end if;
  end process;
  process
    variable count_before : natural;
    procedure cycles(n : positive) is
    begin for i in 1 to n loop wait until rising_edge(clk); wait for 1 ns; end loop; end;
  begin
    cycles(1); assert reset='1' report "Power-on reset" severity failure;
    cycles(12); assert reset='0' severity failure;
    sw(0)<='1'; cycles(2); sw(0)<='0'; cycles(12);
    assert fire_count=0 report "Bounce accepted" severity failure;
    sw(0)<='1'; cycles(40); assert fire_count=1 report "Held fire repeats" severity failure;
    sw(0)<='0'; cycles(12); sw(0)<='1'; cycles(12); assert fire_count=2 severity failure;
    sw(1)<='1'; cycles(40); assert start_count=1 severity failure;
    keys(0)<='0'; cycles(40); assert left_count>=3 and right_count=0 report "Aim repeat" severity failure;
    keys(0)<='1'; cycles(12); count_before:=left_count; cycles(20); assert left_count=count_before severity failure;
    keys(1)<='0'; cycles(20); assert right_count>=1 severity failure;
    sw(9)<='1'; cycles(12); assert reset='1' severity failure;
    sw(9)<='0'; cycles(12); assert reset='0' severity failure;
    report "tb_controls PASS: debounce, edge pulses, repeat, reset"; stop; wait;
  end process;
end;
