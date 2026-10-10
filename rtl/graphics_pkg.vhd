library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;

package graphics_pkg is
  function text_pixel(x,y,ox,oy,scale : integer; message : string) return boolean;
  function digit_pixel(x,y,ox,oy,scale,value,digits : integer) return boolean;
  function egg_pixel(x,y,cx,cy : integer) return boolean;
  function dino_pixel(x,y : integer) return rgb_t;
end;
package body graphics_pkg is
  subtype glyph_t is std_logic_vector(34 downto 0);
  function glyph(c : character) return glyph_t is
  begin
    case c is
      when 'A' => return "01110100011000111111100011000110001";
      when 'B' => return "11110100011000111110100011000111110";
      when 'C' => return "01111100001000010000100001000001111";
      when 'D' => return "11110100011000110001100011000111110";
      when 'E' => return "11111100001000011110100001000011111";
      when 'F' => return "11111100001000011110100001000010000";
      when 'G' => return "01111100001000010111100011000101111";
      when 'H' => return "10001100011000111111100011000110001";
      when 'I' => return "11111001000010000100001000010011111";
      when 'J' => return "00111000100001000010100101001001100";
      when 'K' => return "10001100101010011000101001001010001";
      when 'L' => return "10000100001000010000100001000011111";
      when 'M' => return "10001110111010110101100011000110001";
      when 'N' => return "10001110011010110011100011000110001";
      when 'O' => return "01110100011000110001100011000101110";
      when 'P' => return "11110100011000111110100001000010000";
      when 'Q' => return "01110100011000110001101011001001101";
      when 'R' => return "11110100011000111110101001001010001";
      when 'S' => return "01111100001000001110000010000111110";
      when 'T' => return "11111001000010000100001000010000100";
      when 'U' => return "10001100011000110001100011000101110";
      when 'V' => return "10001100011000110001100010101000100";
      when 'W' => return "10001100011000110101101011010101010";
      when 'X' => return "10001100010101000100010101000110001";
      when 'Y' => return "10001100010101000100001000010000100";
      when 'Z' => return "11111000010001000100010001000011111";
      when '0' => return "01110100011001110101110011000101110";
      when '1' => return "00100011000010000100001000010001110";
      when '2' => return "01110100010000100010001000100011111";
      when '3' => return "11110000010000101110000010000111110";
      when '4' => return "00010001100101010010111110001000010";
      when '5' => return "11111100001000011110000010000111110";
      when '6' => return "01110100001000011110100011000101110";
      when '7' => return "11111000010001000100010000100001000";
      when '8' => return "01110100011000101110100011000101110";
      when '9' => return "01110100011000101111000010000101110";
      when '-' => return "00000000000000011111000000000000000";
      when '+' => return "00000001000010011111001000010000000";
      when others => return (others=>'0');
    end case;
  end;
  function text_pixel(x,y,ox,oy,scale : integer; message : string) return boolean is
    variable gx,gy,index : integer;
    variable bits : glyph_t;
  begin
    if x<ox or y<oy or x>=ox+message'length*6*scale or y>=oy+7*scale then return false; end if;
    gx:=(x-ox)/scale; gy:=(y-oy)/scale; index:=gx/6;
    if gx mod 6=5 then return false; end if;
    bits:=glyph(message(message'low+index));
    return bits(34-gy*5-(gx mod 6))='1';
  end;
  function digit_pixel(x,y,ox,oy,scale,value,digits : integer) return boolean is
    variable divisor : integer := 1;
    variable d : integer;
  begin
    for i in 0 to digits-1 loop
      d:=(value/divisor) mod 10;
      if text_pixel(x,y,ox+(digits-1-i)*6*scale,oy,scale,"" & character'val(character'pos('0')+d)) then return true; end if;
      divisor:=divisor*10;
    end loop;
    return false;
  end;
  function egg_pixel(x,y,cx,cy : integer) return boolean is
    variable half_width : integer;
    variable v : integer;
  begin
    if y>=cy then v:=y-cy; else v:=cy-y; end if;
    case v is
      when 0 to 2 => half_width:=11;
      when 3 to 5 => half_width:=10;
      when 6 to 8 => half_width:=9;
      when 9 to 10 => half_width:=7;
      when 11 => half_width:=4;
      when others => return false;
    end case;
    if y<cy-3 then half_width:=half_width-1; end if;
    return x>=cx-half_width and x<=cx+half_width;
  end;
  -- Original 24x20 indexed sprite. 0 transparent, 1 outline, 2 skin,
  -- 3 belly, 4 eye, 5 cheek. No borrowed commercial game artwork.
  type sprite_t is array(0 to 19) of string(1 to 24);
  constant DINO : sprite_t := (
    "000000000001111111000000",
    "000000000012222222100000",
    "000000000122222222210000",
    "000000000122224122221000",
    "000000000122224122221000",
    "000000000122222225221000",
    "000000000122222222221000",
    "000000000122211111110000",
    "000000001222233331000000",
    "010000012222233331000000",
    "121000122222233332110000",
    "122101222222233332221000",
    "122212222222233332110000",
    "012222222222233331000000",
    "001222222222233331000000",
    "000112222222333310000000",
    "000001222222221100000000",
    "000001222112221000000000",
    "000012221001222100000000",
    "000011111001111100000000");
  function dino_pixel(x,y : integer) return rgb_t is
  begin
    if x<0 or x>=24 or y<0 or y>=20 then return x"000"; end if;
    case DINO(y)(x+1) is
      when '1' => return x"163";
      when '2' => return x"6D8";
      when '3' => return x"CF9";
      when '4' => return x"FFE";
      when '5' => return x"F98";
      when others => return x"000";
    end case;
  end;
end;
