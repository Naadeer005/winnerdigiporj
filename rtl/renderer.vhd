library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;
use work.graphics_pkg.all;

entity renderer is
  port(x : in integer range 0 to 799; y : in integer range 0 to 524;
       visible : in std_logic; board, falling : in grid_t; state : in state_t;
       angle : in integer range 0 to 16;
       projectile_x : in integer range 0 to 639; projectile_y : in integer range 0 to 511;
       current_colour, next_colour : in colour_t;
       score : in integer range 0 to 99999; ceiling : in integer range 0 to 360;
       shots : in integer range 0 to 4; fall_offset : in integer range 0 to 512;
       rgb : out rgb_t);
end;
architecture rtl of renderer is
begin
  process(all)
    variable p, sprite : rgb_t;
    variable row,col,index,cx,cy,gx,gy,relative_y : integer;
    variable colour : colour_t;
  begin
    p:=x"112";
    if y<48 then p:=x"123"; end if;
    if y>=456 then p:=x"123"; end if;
    -- Restrained background texture and a framed central arena.
    if x>=168 and x<=472 and y>=48 and y<452 then
      p:=x"123";
      if (x mod 28=16) and (y mod 24=14) then p:=x"234"; end if;
      if x<172 or x>468 then p:=x"486"; end if;
      if y<TOP_Y+ceiling-12 then p:=x"486"; end if;
      if y=DANGER_Y and (x/6) mod 2=0 then p:=x"F68"; end if;
    end if;
    if text_pixel(x,y,24,16,2,"DINO POP") then p:=x"CF9"; end if;
    if text_pixel(x,y,452,20,1,"FPGA ARCADE  01") then p:=x"8BA"; end if;
    if text_pixel(x,y,24,78,1,"SCORE") then p:=x"8BA"; end if;
    if digit_pixel(x,y,24,96,2,score,5) then p:=x"FFE"; end if;
    if text_pixel(x,y,24,150,1,"CEILING IN") then p:=x"8BA"; end if;
    if digit_pixel(x,y,24,170,3,5-shots,1) then p:=x"FD5"; end if;
    if text_pixel(x,y,52,180,1,"SHOTS") then p:=x"FFE"; end if;
    if text_pixel(x,y,496,78,1,"NEXT EGG") then p:=x"8BA"; end if;
    if egg_pixel(x,y,524,112) then p:=egg_rgb(next_colour); end if;
    if text_pixel(x,y,496,156,1,"MATCH 3+") or text_pixel(x,y,496,174,1,"TO CLEAR") then p:=x"FFE"; end if;
    if text_pixel(x,y,496,212,1,"DROP EGGS") or text_pixel(x,y,496,230,1,"FOR BONUS") then p:=x"CF9"; end if;
    if text_pixel(x,y,24,464,1,"KEY0 KEY1 AIM   SW0 FIRE   SW1 RESTART   SW9 RESET") then p:=x"ABC"; end if;
    sprite:=x"000";
    if x>=36 and x<132 and y>=320 and y<400 then sprite:=dino_pixel((x-36)/4,(y-320)/4); end if;
    if sprite/=x"000" then p:=sprite; end if;
    if text_pixel(x,y,24,420,1,"SAVE THE NEST") then p:=x"CF9"; end if;

    if state/=TITLE then
      -- Address only the cell under the pixel; no 120 parallel egg renderers.
      for layer in 0 to 1 loop
        relative_y:=y-TOP_Y-ceiling+12;
        if layer=1 then relative_y:=relative_y-fall_offset; end if;
        if relative_y>=0 and relative_y<ROWS*24 then
          row:=relative_y/24;
          gx:=x-184-(row mod 2)*14+14;
          if gx>=0 and gx<COLS*28 then
            col:=gx/28; index:=row*COLS+col;
            cx:=cell_x(index); cy:=cell_y(index,ceiling);
            if layer=0 then colour:=board(index); else colour:=falling(index); cy:=cy+fall_offset; end if;
            if colour/=0 and egg_pixel(x,y,cx,cy) then
              p:=egg_rgb(colour);
              if x>=cx-5 and x<=cx-2 and y>=cy-6 and y<=cy-3 then p:=x"FFE"; end if;
              -- Distinct markings make the four colours distinguishable too.
              if y=cy+3 and x>cx-colour*2 and x<cx+colour*2 then p:=x"345"; end if;
            end if;
          end if;
        end if;
      end loop;
      if state=AIM then
        for dot in 1 to 10 loop
          gx:=LAUNCH_X+(VX(angle)*dot*3)/256;
          gy:=LAUNCH_Y+(VY(angle)*dot*3)/256;
          if gx<LEFT_X then gx:=2*LEFT_X-gx;
          elsif gx>RIGHT_X then gx:=2*RIGHT_X-gx; end if;
          if x>=gx-1 and x<=gx+1 and y>=gy-1 and y<=gy+1 then p:=x"ABC"; end if;
        end loop;
      end if;
      if x>=272 and x<320 and y>=414 and y<454 then
        sprite:=dino_pixel((x-272)/2,(y-414)/2);
        if sprite/=x"000" then p:=sprite; end if;
      end if;
      if state=AIM or state=SHOOT then
        if egg_pixel(x,y,projectile_x,projectile_y) then p:=egg_rgb(current_colour); end if;
      end if;
      if x>=304 and x<=336 and y>=451 and y<=453 then p:=x"CF9"; end if;
    end if;

    if state=TITLE or state=WIN or state=LOSE then
      if x>=180 and x<460 and y>=160 and y<340 then p:=x"234"; end if;
      if x>=180 and x<460 and (y=160 or y=339) then p:=x"6D8"; end if;
      if state=TITLE then
        if text_pixel(x,y,224,184,3,"DINO POP") then p:=x"CF9"; end if;
        if text_pixel(x,y,218,226,1,"MATCH EGGS SAVE THE NEST") then p:=x"FFE"; end if;
      elsif state=WIN then
        if text_pixel(x,y,236,184,3,"YOU WIN") then p:=x"CF9"; end if;
        if text_pixel(x,y,248,226,1,"THE NEST IS SAFE") then p:=x"FFE"; end if;
      else
        if text_pixel(x,y,212,184,3,"GAME OVER") then p:=x"F68"; end if;
        if text_pixel(x,y,230,226,1,"THE CEILING CAUGHT YOU") then p:=x"FFE"; end if;
      end if;
      if text_pixel(x,y,218,268,1,"KEY0 LEFT   KEY1 RIGHT") then p:=x"ABC"; end if;
      if text_pixel(x,y,218,288,1,"SW0 DOWN THEN UP TO FIRE") then p:=x"ABC"; end if;
      if text_pixel(x,y,218,314,1,"SW1 DOWN THEN UP TO PLAY") then p:=x"FD5"; end if;
    end if;
    if visible='0' then p:=x"000"; end if;
    rgb<=p;
  end process;
end;
