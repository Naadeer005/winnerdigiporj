library ieee;
use ieee.std_logic_1164.all;

entity vga_timing is
  port(clk, reset : in std_logic;
       x : out integer range 0 to 799; y : out integer range 0 to 524;
       pixel_en, visible, hsync, vsync, frame_tick : out std_logic);
end;
architecture rtl of vga_timing is
  signal divider : std_logic := '0';
  signal h : integer range 0 to 799 := 0;
  signal v : integer range 0 to 524 := 0;
begin
  x<=h; y<=v; pixel_en<=divider;
  visible<='1' when h<640 and v<480 else '0';
  hsync<='0' when h>=656 and h<752 else '1';
  vsync<='0' when v>=490 and v<492 else '1';
  -- Begin updates at vertical blank, allowing grid scans to finish off screen.
  frame_tick<='1' when divider='1' and h=0 and v=480 else '0';
  process(clk) begin
    if rising_edge(clk) then
      if reset='1' then divider<='0'; h<=0; v<=0;
      else
        divider<=not divider;
        if divider='1' then
          if h=799 then
            h<=0;
            if v=524 then v<=0; else v<=v+1; end if;
          else h<=h+1; end if;
        end if;
      end if;
    end if;
  end process;
end;
