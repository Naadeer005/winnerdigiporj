library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package game_pkg is
  constant COLS : positive := 10;
  constant ROWS : positive := 12;
  constant CELLS : positive := COLS * ROWS;
  constant LAUNCH_X : integer := 320;
  constant LAUNCH_Y : integer := 438;
  constant LEFT_X : integer := 182;
  constant RIGHT_X : integer := 458;
  constant TOP_Y : integer := 62;
  constant DANGER_Y : integer := 400;
  subtype colour_t is integer range 0 to 4;
  type grid_t is array (0 to CELLS-1) of colour_t;
  constant EMPTY_GRID : grid_t := (others => 0);
  type state_t is (TITLE, AIM, SHOOT, ATTACH, MATCH_SCAN, CLEAR,
                   SUPPORT_SCAN, FALL, ADVANCE, CHECK, WIN, LOSE);
  type queue_t is array (0 to CELLS-1) of integer range 0 to CELLS-1;
  type velocity_t is array (0 to 16) of integer range -1536 to 1536;
  -- 6 pixels/frame, signed pixel units with eight fractional bits.
  constant VX : velocity_t := (-1381,-1273,-1141,-987,-814,-625,-423,-214,0,214,423,625,814,987,1141,1273,1381);
  constant VY : velocity_t := (-673,-859,-1028,-1177,-1303,-1403,-1477,-1521,-1536,-1521,-1477,-1403,-1303,-1177,-1028,-859,-673);
  subtype rgb_t is std_logic_vector(11 downto 0);
  function initial_grid return grid_t;
  function cell_x(i : integer) return integer;
  function cell_y(i, ceiling : integer) return integer;
  function neighbour(i, direction : integer) return integer;
  function distance2(x1,y1,x2,y2 : integer) return integer;
  function choose_colour(g : grid_t; seed : integer) return colour_t;
  function capped_score(score, delta : integer) return integer;
  function egg_rgb(c : colour_t) return rgb_t;
end package;

package body game_pkg is
  function initial_grid return grid_t is
    variable g : grid_t := EMPTY_GRID;
  begin
    for r in 0 to 3 loop
      for c in 0 to COLS-1 loop g(r*COLS+c) := (c/2+r) mod 4+1; end loop;
    end loop;
    return g;
  end;
  function cell_x(i : integer) return integer is
  begin return 184 + (i mod COLS)*28 + ((i/COLS) mod 2)*14; end;
  function cell_y(i, ceiling : integer) return integer is
  begin return TOP_Y + (i/COLS)*24 + ceiling; end;
  function neighbour(i, direction : integer) return integer is
    variable r : integer := i/COLS;
    variable c : integer := i mod COLS;
    variable parity : integer := r mod 2;
  begin
    case direction is
      when 0 => c := c-1;
      when 1 => c := c+1;
      when 2 => r := r-1; c := c+parity-1;
      when 3 => r := r-1; c := c+parity;
      when 4 => r := r+1; c := c+parity-1;
      when others => r := r+1; c := c+parity;
    end case;
    if r<0 or r>=ROWS or c<0 or c>=COLS then return -1; end if;
    return r*COLS+c;
  end;
  function distance2(x1,y1,x2,y2 : integer) return integer is
  begin return (x1-x2)*(x1-x2)+(y1-y2)*(y1-y2); end;
  function choose_colour(g : grid_t; seed : integer) return colour_t is
    variable present : std_logic_vector(4 downto 1) := (others=>'0');
    variable candidate : integer;
  begin
    for i in 0 to CELLS-1 loop
      if g(i)/=0 then present(g(i)):='1'; end if;
    end loop;
    for k in 0 to 3 loop
      candidate := (seed+k) mod 4+1;
      if present(candidate)='1' then return candidate; end if;
    end loop;
    return 1;
  end;
  function capped_score(score, delta : integer) return integer is
  begin
    if score+delta>99999 then return 99999; end if;
    return score+delta;
  end;
  function egg_rgb(c : colour_t) return rgb_t is
  begin
    case c is
      when 1 => return x"F68";
      when 2 => return x"5DF";
      when 3 => return x"FD5";
      when 4 => return x"A8F";
      when others => return x"000";
    end case;
  end;
end package body;
