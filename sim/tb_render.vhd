library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;
use work.game_pkg.all;

entity tb_render is end;
architecture test of tb_render is
  signal x : integer range 0 to 799 := 0;
  signal y : integer range 0 to 524 := 0;
  signal g : grid_t := EMPTY_GRID;
  signal s : state_t := TITLE;
  signal ceiling : integer range 0 to 360 := 0;
  signal rgb : rgb_t;
begin
  dut: entity work.renderer port map(x,y,'1',g,EMPTY_GRID,s,6,320,438,1,2,1250,ceiling,2,0,rgb);
  process
    file output : text;
    variable line_out : line;
    procedure capture(name : string; stage : state_t) is
    begin
      s<=stage; g<=initial_grid; ceiling<=0;
      if stage=WIN then g<=EMPTY_GRID; end if;
      if stage=LOSE then ceiling<=264; end if;
      file_open(output,"build/" & name & ".ppm",write_mode);
      write(line_out,string'("P3")); writeline(output,line_out);
      write(line_out,string'("640 480")); writeline(output,line_out);
      write(line_out,string'("255")); writeline(output,line_out);
      for py in 0 to 479 loop
        for px in 0 to 639 loop
          x<=px; y<=py; wait for 1 ns;
          write(line_out,to_integer(unsigned(rgb(11 downto 8)))*17); write(line_out,string'(" "));
          write(line_out,to_integer(unsigned(rgb(7 downto 4)))*17); write(line_out,string'(" "));
          write(line_out,to_integer(unsigned(rgb(3 downto 0)))*17); write(line_out,string'(" "));
        end loop;
        writeline(output,line_out);
      end loop;
      file_close(output);
    end;
  begin
    capture("title",TITLE); capture("gameplay",AIM);
    capture("win",WIN); capture("lose",LOSE);
    report "tb_render PASS: four frames captured from VHDL renderer";
    stop; wait;
  end process;
end;
