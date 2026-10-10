library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;

entity dino_pop is
  port(MAX10_CLK1_50 : in std_logic; KEY : in std_logic_vector(1 downto 0);
       SW : in std_logic_vector(9 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
       VGA_HS, VGA_VS : out std_logic);
end;
architecture rtl of dino_pop is
  signal reset, start_pulse, fire_pulse, left_pulse, right_pulse : std_logic;
  signal x : integer range 0 to 799; signal y : integer range 0 to 524;
  signal pixel_en, visible, hs, vs, frame_tick : std_logic;
  signal board, falling : grid_t;
  signal state : state_t;
  signal angle : integer range 0 to 16;
  signal px : integer range 0 to 639; signal py : integer range 0 to 511;
  signal current_colour, next_colour : colour_t;
  signal score : integer range 0 to 99999; signal ceiling : integer range 0 to 360;
  signal shots : integer range 0 to 4; signal fall_offset : integer range 0 to 512;
  signal rgb : rgb_t;
begin
  inputs: entity work.controls port map(MAX10_CLK1_50,KEY,SW,reset,start_pulse,fire_pulse,left_pulse,right_pulse);
  timing: entity work.vga_timing port map(MAX10_CLK1_50,reset,x,y,pixel_en,visible,hs,vs,frame_tick);
  engine: entity work.game_engine port map(
    clk=>MAX10_CLK1_50,reset=>reset,frame_tick=>frame_tick,start_pulse=>start_pulse,
    fire_pulse=>fire_pulse,left_pulse=>left_pulse,right_pulse=>right_pulse,
    board=>board,falling=>falling,state=>state,angle=>angle,projectile_x=>px,projectile_y=>py,
    current_colour=>current_colour,next_colour=>next_colour,score=>score,ceiling=>ceiling,shots=>shots,fall_offset=>fall_offset);
  pixels: entity work.renderer port map(x,y,visible,board,falling,state,angle,px,py,current_colour,next_colour,score,ceiling,shots,fall_offset,rgb);
  process(MAX10_CLK1_50) begin
    if rising_edge(MAX10_CLK1_50) then
      if reset='1' then VGA_R<=(others=>'0'); VGA_G<=(others=>'0'); VGA_B<=(others=>'0'); VGA_HS<='1'; VGA_VS<='1';
      elsif pixel_en='1' then
        VGA_R<=rgb(11 downto 8); VGA_G<=rgb(7 downto 4); VGA_B<=rgb(3 downto 0);
        VGA_HS<=hs; VGA_VS<=vs;
      end if;
    end if;
  end process;
end;
