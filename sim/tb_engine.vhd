library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;
use std.env.all;

entity tb_engine is end;
architecture test of tb_engine is
  signal clk : std_logic := '0';
  signal reset, tick, start, fire, left, right, load : std_logic := '0';
  signal g, falling, fixture : grid_t := EMPTY_GRID;
  signal state, fixture_state : state_t := AIM;
  signal angle, fixture_angle : integer range 0 to 16 := 8;
  signal px, fx : integer range 0 to 639 := LAUNCH_X;
  signal py, fy : integer range 0 to 511 := LAUNCH_Y;
  signal colour, next_colour, fc : colour_t := 1;
  signal score, fs : integer range 0 to 99999 := 0;
  signal ceiling, fceiling : integer range 0 to 360 := 0;
  signal shots, fshots : integer range 0 to 4 := 0;
  signal offset : integer range 0 to 512;
  signal root : integer range 0 to CELLS-1 := 0;
  signal hit : integer range -1 to CELLS-1 := -1;
  signal state_code : integer range 0 to 12;
begin
  clk<=not clk after 10 ns;
  state_code<=state_t'pos(state);
  dut: entity work.game_engine generic map(TEST_MODE=>true) port map(
    clk,reset,tick,start,fire,left,right,g,falling,state,angle,px,py,colour,next_colour,
    score,ceiling,shots,offset,load,fixture,fixture_state,fc,root,fceiling,fshots,fs,fx,fy,fixture_angle,hit);
  process
    variable b : grid_t;
    variable old_x,old_y,expected,n : integer;
    variable saw_fall : boolean;
    procedure cycle(n : positive := 1) is
    begin for i in 1 to n loop wait until rising_edge(clk); wait for 1 ns; end loop; end;
    procedure pulse(signal p : out std_logic) is
    begin p<='1'; cycle; p<='0'; cycle; end;
    procedure inject(new_board : grid_t; s : state_t := AIM; cell : integer := 0;
                     c : colour_t := 1; ce : integer := 0; sh : integer := 0;
                     pts : integer := 0; x : integer := LAUNCH_X; y : integer := LAUNCH_Y;
                     a : integer := 8; h : integer := -1) is
    begin
      fixture<=new_board; fixture_state<=s; root<=cell; fc<=c; fceiling<=ce;
      fshots<=sh; fs<=pts; fx<=x; fy<=y; fixture_angle<=a; hit<=h;
      pulse(load);
    end;
    procedure settled is
    begin
      for t in 0 to 6000 loop
        if state=AIM or state=WIN or state=LOSE then return; end if;
        cycle;
      end loop;
      assert false report "Resolution timed out" severity failure;
    end;
    procedure frame is
    begin pulse(tick); cycle(130); end;
  begin
    pulse(reset); assert state=TITLE severity failure;
    pulse(fire); assert state=TITLE report "Fire starts title" severity failure;
    pulse(start); assert state=AIM and g=initial_grid and score=0 severity failure;
    pulse(left); assert angle=7 severity failure;
    pulse(right); assert angle=8 severity failure;
    for k in 1 to 20 loop pulse(left); end loop;
    assert angle=0 report "Left angle limit" severity failure;
    for k in 1 to 20 loop pulse(right); end loop;
    assert angle=16 report "Right angle limit" severity failure;
    left<='1'; right<='1'; cycle; left<='0';right<='0';
    assert angle=16 report "Simultaneous controls must cancel" severity failure;
    pulse(fire); assert state=SHOOT severity failure;
    old_x:=px; old_y:=py; pulse(fire); pulse(left); cycle(150);
    assert px=old_x and py=old_y and angle=16 report "Busy controls / frame gating" severity failure;
    pulse(start); assert state=AIM and shots=0 severity failure;
    report "PASS controls, angle limits, busy gating, restart";

    b:=EMPTY_GRID; b(0):=1;
    inject(b,SHOOT,x=>183,y=>438,a=>0); frame;
    assert px>LEFT_X and px<190 report "Left bounce reflection" severity failure;
    old_x:=px; frame; assert px>old_x report "Left bounce direction" severity failure;
    inject(b,SHOOT,x=>457,y=>438,a=>16); frame;
    assert px<RIGHT_X and px>450 report "Right bounce reflection" severity failure;
    old_x:=px; frame; assert px<old_x report "Right bounce direction" severity failure;
    report "PASS both wall bounces";

    -- Ceiling chooses nearest empty top cell; two eggs never clear.
    inject(b,SHOOT,x=>cell_x(5),y=>TOP_Y+1,a=>8,c=>2); frame; settled;
    assert g(5)=2 and g(0)=1 and score=0 and shots=1 severity failure;
    b:=EMPTY_GRID; b(0):=1; b(1):=1;
    inject(b,MATCH_SCAN,cell=>1); settled;
    assert g=b and score=0 report "Two eggs cleared" severity failure;
    report "PASS ceiling attachment and group of two";

    -- Same-distance top neighbours: lower row-major index wins.
    b:=EMPTY_GRID;
    inject(b,ATTACH,c=>2,x=>(cell_x(2)+cell_x(3))/2,y=>TOP_Y,h=>-1); settled;
    assert g(2)=2 and g(3)=0 report "Tie break is not row-major" severity failure;
    -- Collision attachment uses the actual SHOOT scan, then neighbouring slot.
    b:=EMPTY_GRID; b(4):=1;
    inject(b,SHOOT,c=>2,x=>cell_x(14),y=>TOP_Y+28); frame; settled;
    assert g(14)=2 and g(4)=1 report "Occupied egg collision attachment" severity failure;
    b:=(others=>2);
    inject(b,ATTACH,h=>55); settled;
    assert state=LOSE report "Blocked attachment not terminal" severity failure;
    report "PASS collision attachment, tie break, blocked attachment";

    -- Match crosses an even/odd row and removes a disconnected lower egg.
    b:=EMPTY_GRID; b(0):=1; b(1):=1; b(10):=1; b(20):=2; b(9):=3;
    inject(b,MATCH_SCAN,cell=>10); saw_fall:=false;
    for t in 0 to 4000 loop
      if state=FALL then saw_fall:=true; exit; end if;
      cycle;
    end loop;
    assert saw_fall and g(20)=0 and falling(20)=2 and g(9)=3 and score=50
      report "Match/support/drop mismatch" severity failure;
    old_y:=offset; cycle(100); assert offset=old_y severity failure;
    pulse(fire); assert state=FALL severity failure;
    for k in 1 to 41 loop frame; end loop; settled;
    assert state=AIM and falling=EMPTY_GRID and colour=3 and next_colour=3
      report "Fall completion or extinct colour selection" severity failure;
    report "PASS staggered match, falling animation, colour filtering, scoring";

    b:=EMPTY_GRID; b(0):=1; b(1):=1; b(10):=1;
    inject(b,MATCH_SCAN,cell=>10,sh=>4,pts=>99980); settled;
    assert state=WIN and ceiling=0 and score=99999
      report "Win precedence or score saturation" severity failure;
    b:=(others=>1);
    inject(b,MATCH_SCAN); settled;
    assert state=WIN and score=1200 report "Full queue flood fill" severity failure;
    report "PASS all-clear, fifth-shot win precedence, score saturation, full queue";

    b:=EMPTY_GRID; b(0):=1;
    for shot in 0 to 4 loop
      inject(b,ADVANCE,sh=>shot); settled;
      if shot=4 then expected:=24; else expected:=0; end if;
      assert ceiling=expected and shots=(shot+1) mod 5 and state=AIM
        report "Five-shot descent" severity failure;
    end loop;
    inject(b,ADVANCE,ce=>312,sh=>4); settled;
    assert state=LOSE and ceiling=336 report "Descending danger line" severity failure;
    b:=EMPTY_GRID; b(110):=1;
    inject(b,CHECK,ce=>72); settled;
    assert state=LOSE report "Existing danger line" severity failure;
    pulse(reset); assert state=TITLE and score=0 and g=EMPTY_GRID severity failure;
    report "PASS ceiling cadence, loss, reset";
    -- Exercise complete frame-driven flight and resolution at every launch angle.
    for a in 0 to 16 loop
      inject(initial_grid,AIM,a=>a,c=>(a mod 4)+1);
      pulse(fire);
      for f in 1 to 400 loop
        frame;
        exit when state=AIM or state=WIN or state=LOSE;
      end loop;
      assert state=AIM report "Initial-level shot failed at angle " & integer'image(a) severity failure;
      assert shots=1 and ceiling=0 report "Shot resolved more than once" severity failure;
    end loop;
    -- The staggered-neighbour graph must be bounded and symmetric.
    for i in 0 to CELLS-1 loop
      for d in 0 to 5 loop
        n:=neighbour(i,d); saw_fall:=false;
        if n>=0 then
          for back in 0 to 5 loop
            if neighbour(n,back)=i then saw_fall:=true; end if;
          end loop;
          assert saw_fall report "Asymmetric hex grid" severity failure;
        end if;
      end loop;
    end loop;
    report "PASS 17 complete trajectories and grid neighbour invariants";
    report "tb_engine PASS"; stop;
    wait;
  end process;
  process begin wait for 10 ms; assert false report "Watchdog" severity failure; end process;
end;
