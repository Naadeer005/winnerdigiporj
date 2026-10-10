library ieee;
use ieee.std_logic_1164.all;

entity controls is
  generic(DEBOUNCE_CYCLES : positive := 500000; REPEAT_CYCLES : positive := 7500000);
  port(clk : in std_logic; key_n : in std_logic_vector(1 downto 0);
       sw : in std_logic_vector(9 downto 0);
       reset, start_pulse, fire_pulse, left_pulse, right_pulse : out std_logic);
end;
architecture rtl of controls is
  signal raw, sync_meta, sync_clean, stable, previous : std_logic_vector(4 downto 0) := (others=>'0');
  type debounce_array is array(0 to 4) of integer range 0 to DEBOUNCE_CYCLES-1;
  type repeat_array is array(0 to 1) of integer range 0 to REPEAT_CYCLES-1;
  signal counts : debounce_array := (others=>0);
  signal repeats : repeat_array := (others=>0);
  signal power_on : integer range 0 to DEBOUNCE_CYCLES+4 := 0;
  attribute altera_attribute : string;
  attribute altera_attribute of sync_meta, sync_clean : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  raw <= sw(9) & sw(1) & sw(0) & not key_n;
  reset <= '1' when stable(4)='1' or power_on<DEBOUNCE_CYCLES+4 else '0';
  process(clk) begin
    if rising_edge(clk) then
      sync_meta<=raw; sync_clean<=sync_meta; previous<=stable;
      if power_on<DEBOUNCE_CYCLES+4 then power_on<=power_on+1; end if;
      for i in 0 to 4 loop
        if sync_clean(i)=stable(i) then counts(i)<=0;
        elsif counts(i)=DEBOUNCE_CYCLES-1 then stable(i)<=sync_clean(i); counts(i)<=0;
        else counts(i)<=counts(i)+1; end if;
      end loop;
      fire_pulse<=stable(2) and not previous(2);
      start_pulse<=stable(3) and not previous(3);
      left_pulse<='0'; right_pulse<='0';
      for i in 0 to 1 loop
        if stable(i)='0' or stable(4)='1' then repeats(i)<=0;
        elsif previous(i)='0' or repeats(i)=REPEAT_CYCLES-1 then
          repeats(i)<=0;
          if i=0 then left_pulse<='1'; else right_pulse<='1'; end if;
        else repeats(i)<=repeats(i)+1; end if;
      end loop;
    end if;
  end process;
end;
