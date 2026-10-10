library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;
use std.env.all;
entity tb_vga is end;
architecture test of tb_vga is
  signal clk : std_logic := '0';
  signal reset : std_logic := '1';
  signal x : integer range 0 to 799;
  signal y : integer range 0 to 524;
  signal pe,visible,hs,vs,tick : std_logic;
  signal rgb : rgb_t;
begin
  clk<=not clk after 10 ns;
  dut: entity work.vga_timing port map(clk,reset,x,y,pe,visible,hs,vs,tick);
  render: entity work.renderer port map(x,y,visible,EMPTY_GRID,EMPTY_GRID,TITLE,8,320,438,1,2,0,0,0,0,rgb);
  process
    variable hcount,vcount,visible_count,ticks : natural := 0;
  begin
    wait until falling_edge(clk); reset<='0';
    for pixel in 0 to 800*525-1 loop
      wait until rising_edge(clk) and pe='1';
      assert x=pixel mod 800 and y=pixel/800 report "VGA counter sequence" severity failure;
      if hs='0' then hcount:=hcount+1; end if;
      if vs='0' then vcount:=vcount+1; end if;
      if visible='1' then visible_count:=visible_count+1;
      else assert rgb=x"000" report "RGB not blanked" severity failure; end if;
      if tick='1' then ticks:=ticks+1; assert x=0 and y=480 severity failure; end if;
      if x>=656 and x<752 then assert hs='0' severity failure; else assert hs='1' severity failure; end if;
      if y>=490 and y<492 then assert vs='0' severity failure; else assert vs='1' severity failure; end if;
    end loop;
    assert hcount=96*525 and vcount=2*800 and visible_count=640*480 and ticks=1 severity failure;
    wait until rising_edge(clk) and pe='1'; assert x=0 and y=0 severity failure;
    report "tb_vga PASS: full frame, 25 MHz enable, sync widths, blanking, frame tick"; stop; wait;
  end process;
end;
