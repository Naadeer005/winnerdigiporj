library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.game_pkg.all;

entity game_engine is
  generic(TEST_MODE : boolean := false);
  port(clk, reset, frame_tick, start_pulse, fire_pulse, left_pulse, right_pulse : in std_logic;
       board, falling : out grid_t; state : out state_t;
       angle : out integer range 0 to 16;
       projectile_x : out integer range 0 to 639;
       projectile_y : out integer range 0 to 511;
       current_colour, next_colour : out colour_t;
       score : out integer range 0 to 99999;
       ceiling : out integer range 0 to 360;
       shots : out integer range 0 to 4;
       fall_offset : out integer range 0 to 512;
       -- Test-only injection is constant-eliminated in the hardware instance.
       fixture_load : in std_logic := '0'; fixture_board : in grid_t := EMPTY_GRID;
       fixture_state : in state_t := AIM;
       fixture_colour : in colour_t := 1;
       fixture_cell : in integer range 0 to CELLS-1 := 0;
       fixture_ceiling : in integer range 0 to 360 := 0;
       fixture_shots : in integer range 0 to 4 := 0;
       fixture_score : in integer range 0 to 99999 := 0;
       fixture_x : in integer range 0 to 639 := LAUNCH_X;
       fixture_y : in integer range 0 to 511 := LAUNCH_Y;
       fixture_angle : in integer range 0 to 16 := 8;
       fixture_hit : in integer range -1 to CELLS-1 := -1);
end;

architecture rtl of game_engine is
  signal g, drops : grid_t := EMPTY_GRID;
  signal s : state_t := TITLE;
  signal aim_index : integer range 0 to 16 := 8;
  signal px : integer range 0 to 163839 := LAUNCH_X*256;
  signal py : integer range 0 to 131071 := LAUNCH_Y*256;
  signal dx, dy : integer range -1536 to 1536 := 0;
  signal active_colour, queued_colour : colour_t := 1;
  signal points : integer range 0 to 99999 := 0;
  signal ceiling_offset : integer range 0 to 360 := 0;
  signal shot_count : integer range 0 to 4 := 0;
  signal drop_offset : integer range 0 to 512 := 0;
  signal rng : unsigned(15 downto 0) := x"ACE1";
  signal queue : queue_t := (others=>0);
  signal visited : std_logic_vector(CELLS-1 downto 0) := (others=>'0');
  signal head, tail : integer range 0 to CELLS := 0;
  signal direction : integer range 0 to 5 := 0;
  signal scan : integer range 0 to CELLS := 0;
  signal phase : integer range 0 to 3 := 0;
  signal root : integer range 0 to CELLS-1 := 0;
  signal hit : integer range -1 to CELLS-1 := -1;
  signal best : integer range -1 to CELLS-1 := -1;
  signal best_distance : integer range 0 to 1048575 := 1048575;
  signal any_drop, any_egg, danger : boolean := false;
begin
  board<=g; falling<=drops; state<=s; angle<=aim_index;
  projectile_x<=px/256; projectile_y<=py/256;
  current_colour<=active_colour; next_colour<=queued_colour;
  score<=points; ceiling<=ceiling_offset; shots<=shot_count; fall_offset<=drop_offset;
  process(clk)
    variable nx, ny, n, dist, chosen : integer;
    variable valid : boolean;
    variable initial : grid_t;
  begin
    if rising_edge(clk) then
      rng<=rng(14 downto 0) & (rng(15) xor rng(13) xor rng(12) xor rng(10));
      if reset='1' then
        s<=TITLE; g<=EMPTY_GRID; drops<=EMPTY_GRID; points<=0;
        ceiling_offset<=0; shot_count<=0; drop_offset<=0; aim_index<=8;
        px<=LAUNCH_X*256; py<=LAUNCH_Y*256; dx<=0; dy<=0;
        phase<=0; scan<=0; head<=0; tail<=0; direction<=0;
        hit<=-1; best<=-1; best_distance<=1048575; root<=0;
        visited<=(others=>'0'); active_colour<=1; queued_colour<=2;
        any_drop<=false; any_egg<=false; danger<=false;
      elsif start_pulse='1' then
        initial:=initial_grid; g<=initial; drops<=EMPTY_GRID; s<=AIM;
        points<=0; ceiling_offset<=0; shot_count<=0; aim_index<=8; drop_offset<=0;
        active_colour<=choose_colour(initial,to_integer(rng(1 downto 0)));
        queued_colour<=choose_colour(initial,to_integer(rng(3 downto 2)));
        px<=LAUNCH_X*256; py<=LAUNCH_Y*256; phase<=0; scan<=0;
        head<=0; tail<=0; direction<=0; visited<=(others=>'0');
      elsif TEST_MODE and fixture_load='1' then
        g<=fixture_board; drops<=EMPTY_GRID; s<=fixture_state;
        active_colour<=fixture_colour; queued_colour<=fixture_colour;
        root<=fixture_cell; ceiling_offset<=fixture_ceiling;
        shot_count<=fixture_shots; points<=fixture_score;
        px<=fixture_x*256; py<=fixture_y*256; aim_index<=fixture_angle;
        dx<=VX(fixture_angle); dy<=VY(fixture_angle); hit<=fixture_hit;
        phase<=0; scan<=0; head<=0; tail<=0; direction<=0;
        visited<=(others=>'0'); best<=-1; best_distance<=1048575;
        any_drop<=false; any_egg<=false; danger<=false; drop_offset<=0;
      else
        case s is
          when TITLE | WIN | LOSE => null;
          when AIM =>
            if left_pulse='1' and right_pulse='0' and aim_index>0 then aim_index<=aim_index-1;
            elsif right_pulse='1' and left_pulse='0' and aim_index<16 then aim_index<=aim_index+1; end if;
            if fire_pulse='1' then
              px<=LAUNCH_X*256; py<=LAUNCH_Y*256; dx<=VX(aim_index); dy<=VY(aim_index);
              phase<=0; s<=SHOOT;
            end if;
          when SHOOT =>
            if phase=0 then
              if frame_tick='1' then
                nx:=px+dx; ny:=py+dy;
                if nx<LEFT_X*256 then nx:=2*LEFT_X*256-nx; dx<=-dx;
                elsif nx>RIGHT_X*256 then nx:=2*RIGHT_X*256-nx; dx<=-dx; end if;
                if ny<0 then ny:=0; end if;
                px<=nx; py<=ny; scan<=0; hit<=-1; best_distance<=1048575; phase<=1;
              end if;
            elsif phase=1 then
              if scan<CELLS then
                dist:=distance2(px/256,py/256,cell_x(scan),cell_y(scan,ceiling_offset));
                if g(scan)/=0 and dist<=28*28 and dist<best_distance then
                  hit<=scan; best_distance<=dist;
                end if;
                scan<=scan+1;
              else phase<=2; end if;
            else
              if hit/=-1 or py/256<=TOP_Y+ceiling_offset then
                s<=ATTACH; scan<=0; best<=-1; best_distance<=1048575;
              end if;
              phase<=0;
            end if;
          when ATTACH =>
            if scan<CELLS then
              valid:=false;
              if hit=-1 then valid:=scan<COLS;
              else
                for d in 0 to 5 loop if neighbour(hit,d)=scan then valid:=true; end if; end loop;
              end if;
              dist:=distance2(px/256,py/256,cell_x(scan),cell_y(scan,ceiling_offset));
              if valid and g(scan)=0 and dist<best_distance then best<=scan; best_distance<=dist; end if;
              scan<=scan+1;
            elsif best=-1 then s<=LOSE;
            else
              g(best)<=active_colour; root<=best; s<=MATCH_SCAN; phase<=0;
            end if;
          when MATCH_SCAN =>
            if phase=0 then
              visited<=(others=>'0'); visited(root)<='1'; queue(0)<=root;
              head<=0; tail<=1; direction<=0; phase<=1;
            elsif head<tail then
              n:=neighbour(queue(head),direction);
              if n>=0 then
                if visited(n)='0' and g(n)=active_colour then
                  assert tail<CELLS report "Match queue overflow" severity failure;
                  queue(tail)<=n; tail<=tail+1; visited(n)<='1';
                end if;
              end if;
              if direction=5 then direction<=0; head<=head+1; else direction<=direction+1; end if;
            else
              scan<=0; phase<=0;
              if tail>=3 then s<=CLEAR; else s<=ADVANCE; end if;
            end if;
          when CLEAR =>
            if scan<CELLS then
              if visited(scan)='1' then g(scan)<=0; points<=capped_score(points,10); end if;
              scan<=scan+1;
            else
              s<=SUPPORT_SCAN; phase<=0; scan<=0; head<=0; tail<=0; direction<=0;
              visited<=(others=>'0'); drops<=EMPTY_GRID; any_drop<=false;
            end if;
          when SUPPORT_SCAN =>
            if phase=0 then
              if scan<COLS then
                if g(scan)/=0 then queue(tail)<=scan; tail<=tail+1; visited(scan)<='1'; end if;
                scan<=scan+1;
              else phase<=1; end if;
            elsif phase=1 then
              if head<tail then
                n:=neighbour(queue(head),direction);
                if n>=0 then
                  if visited(n)='0' and g(n)/=0 then
                    assert tail<CELLS report "Support queue overflow" severity failure;
                    queue(tail)<=n; tail<=tail+1; visited(n)<='1';
                  end if;
                end if;
                if direction=5 then direction<=0; head<=head+1; else direction<=direction+1; end if;
              else scan<=0; phase<=2; end if;
            else
              if scan<CELLS then
                if g(scan)/=0 and visited(scan)='0' then
                  drops(scan)<=g(scan); g(scan)<=0; points<=capped_score(points,20); any_drop<=true;
                end if;
                scan<=scan+1;
              else
                phase<=0; drop_offset<=0;
                if any_drop then s<=FALL; else s<=ADVANCE; end if;
              end if;
            end if;
          when FALL =>
            if frame_tick='1' then
              if drop_offset>=480 then drops<=EMPTY_GRID; s<=ADVANCE; phase<=0;
              else drop_offset<=drop_offset+12; end if;
            end if;
          when ADVANCE =>
            -- First detect a cleared board: win takes precedence over descent.
            if phase=0 then scan<=0; any_egg<=false; phase<=1;
            elsif scan<CELLS then
              if g(scan)/=0 then any_egg<=true; end if;
              scan<=scan+1;
            elsif not any_egg then s<=WIN;
            else
              if shot_count=4 and ceiling_offset>336 then s<=LOSE;
              else
                if shot_count=4 then shot_count<=0; ceiling_offset<=ceiling_offset+24;
                else shot_count<=shot_count+1; end if;
                s<=CHECK;
              end if;
              scan<=0; danger<=false; phase<=0;
            end if;
          when CHECK =>
            if scan<CELLS then
              if g(scan)/=0 and cell_y(scan,ceiling_offset)+12>=DANGER_Y then danger<=true; end if;
              scan<=scan+1;
            elsif danger then s<=LOSE;
            else
              -- Keep the preview colour unless that colour has disappeared.
              chosen:=choose_colour(g,queued_colour-1); active_colour<=chosen;
              queued_colour<=choose_colour(g,to_integer(rng(1 downto 0)));
              px<=LAUNCH_X*256; py<=LAUNCH_Y*256; s<=AIM; phase<=0;
            end if;
        end case;
      end if;
    end if;
  end process;
end;
