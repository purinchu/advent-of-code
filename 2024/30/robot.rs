use std::env;
use std::fs;
//use std::{time,thread}; // for terminal animation

// Advent of Code: 2024 day 15, part 2

#[derive(Clone)]
struct Grid {
    w: usize,
    h: usize,
    chars: Vec<u8>,
}

#[derive(Clone,Copy,Debug,PartialEq,Eq,Hash)]
enum Direction {
    Up, Down, Left, Right,
}

impl Direction {
    // Returns x, y deltas to apply to travel in the given direction
    fn deltas(&self) -> (i32, i32) {
        use Direction::*;
        return match &self {
            Up    => (0, -1),
            Right => (1,  0),
            Down  => (0,  1),
            Left  => (-1, 0),
        }
    }
}

impl Grid {
    fn ch(&self, i: usize, j: usize) -> u8 {
        return self.chars[self.id_from_pos(i, j)];
    }

    fn ch_or(&self, i: usize, j: usize, def: u8) -> u8 {
        let idx = self.id_from_pos(i, j);
        if idx < self.chars.len() {
            return self.chars[idx];
        } else {
            return def;
        }
    }

    fn dump_grid(&self) {
        for l in 0..self.h {
            let low = l * self.w;
            let high = (l + 1) * self.w;
            println!("{}", std::str::from_utf8(&(self.chars[low..high])).unwrap());
        }
    }

    // Find x,y position of *first* cell filled with char.
    fn find_one(&self, ch: u8) -> Option<(usize, usize)> {
        return self.chars.iter()
            .position(|c| *c == ch)
            .map(|idx| self.pos_from_id(idx));
    }

    // Find x,y position of all cells filled with char.
    fn find_all(&self, ch: u8) -> Vec<(usize, usize)> {
        return self.chars.iter()
            .enumerate()
            .filter(|(_, c)| **c == ch)
            .map(|(i, _)| self.pos_from_id(i))
            .collect::<Vec<_>>();
    }

    fn id_from_pos(&self, i: usize, j: usize) -> usize {
        let l = self.w;
        return j * l + i;
    }

    fn pos_from_id(&self, idx: usize) -> (usize, usize) {
        let l = self.w;
        return (idx % l, idx / l);
    }

    fn is_in_bounds(&self, i: usize, j: usize) -> bool {
        return i < self.w && j < self.h;
    }

    // starting from (i,j), walks in a straight line in direction @dir, calling the closure @f on
    // each cell (including the first) until the closure returns false.
    // Returns the position reached that caused the closure to return false.
    fn walk_to_find<F>(&self, i: usize, j: usize, dir: Direction, mut f: F)
        -> (usize, usize)
        where F: FnMut(usize, usize, u8) -> bool
    {
        let (dx, dy) = dir.deltas();
        let (mut nx, mut ny) = (i, j);

        loop {
            if !self.is_in_bounds(nx, ny) || !f(nx, ny, self.ch(nx, ny)) {
                return (nx, ny);
            }

            nx = (nx as i32 + dx) as usize;
            ny = (ny as i32 + dy) as usize;
        }
    }
}

fn build_grid(lines: Vec<String>) -> Grid {
    let w = lines[0].len();
    let h = lines.len();
    let mut result: Vec<u8> = Vec::with_capacity(2 * w * h);

    for line in lines {
        for ch in line.bytes() {
            match ch {
                b'#' => { result.push(ch);   result.push(ch)   },
                b'O' => { result.push(b'['); result.push(b']') },
                b'.' => { result.push(ch);   result.push(ch)   },
                b'@' => { result.push(ch);   result.push(b'.') },
                _    => panic!("Unhandled char"),
            }
        };
    };

    return Grid { w: 2 * w, h, chars: result };
}

fn split_at_empty_line(mut lines: Vec<String>) -> (Vec<String>, Vec<String>) {
    let idx = lines.iter().position(|el| el.is_empty()).unwrap();

    // +1 so we can pop off the empty line
    let printouts = lines.split_off(idx+1);
    lines.pop();

    return (lines, printouts);
}

// Returns true if the box at (i, j) can be moved up or down into empty space at row
fn can_move_row(g: &Grid, i: usize, j: usize, row: usize) -> bool {
    let ch = g.ch(i, j);
    assert!(ch == b'[' || ch == b']');

    // x-coord to look at above or below
    let (li, ri) = if ch == b'[' {
        (i, (i + 1) as usize)
    } else {
        ((i - 1) as usize, i)
    };

    // base case
    let l_ch = g.ch(li, row);
    let r_ch = g.ch(ri, row);
    if l_ch == b'.' && r_ch == b'.' {
        return true;
    } else if l_ch == b'#' || r_ch == b'#' {
        return false;
    }

    // At least one of the occupied cells must be a box.
    assert!((l_ch == b'[' || l_ch == b']') || (r_ch == b'[' || r_ch == b']'));

    // y-coord is same for both left/right
    let far_row = ((j as i32) + 2i32 * (row as i32 - j as i32)) as usize;

    let can_move_row_l = g.ch(li, row) == b'.' || can_move_row(&g, li, row, far_row);
    let can_move_row_r = g.ch(ri, row) == b'.' || can_move_row(&g, ri, row, far_row);

    return can_move_row_l && can_move_row_r;
}

// Moves the box at (i, j) away up/down, recursively. YOU MUST CHECK THIS IS POSSIBLE first as
// there's no undo.
fn do_move_row(mut g: &mut Grid, i: usize, j: usize, row: usize) {
    let ch = g.ch(i, j);
    assert!(ch == b'[' || ch == b']');

    // x-coord to look at above
    let (li, ri) = if ch == b'[' {
        (i, (i + 1) as usize)
    } else {
        ((i - 1) as usize, i)
    };

    let far_row = ((j as i32) + 2i32 * (row as i32 - j as i32)) as usize;

    // move things first
    if g.ch(li, row) != b'.' {
        do_move_row(&mut g, li, row, far_row);
    }

    if g.ch(ri, row) != b'.' {
        do_move_row(&mut g, ri, row, far_row);
    }

    // now we should have room
    let l_ch = g.ch(li, row);
    let r_ch = g.ch(ri, row);
    assert!(l_ch == b'.' && r_ch == b'.');

    let l_up_idx = g.id_from_pos(li, row);
    let r_up_idx = g.id_from_pos(ri, row);
    let l_idx = g.id_from_pos(li, j);
    let r_idx = g.id_from_pos(ri, j);

    g.chars.swap(l_idx, l_up_idx);
    g.chars.swap(r_idx, r_up_idx);
}

fn main() {
    let default_filename: &'static str = "../29/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.len() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[1].clone(),
    };

    let lines = fs::read_to_string(&in_file)
        .expect("Should have been able to read the file")
        .lines()
        .map(String::from)
        .collect::<Vec<_>>();
    let (grid_lines, dirs) = split_at_empty_line(lines);

    let mut grid = build_grid(grid_lines);
    let (mut x, mut y) = grid.find_one(b'@').unwrap();

    println!("Robot starts at {},{}", x, y);

//  print!("\x1b[?1049h"); // ANSI alternate screen mode

//  let mut i = 0;
    let bigdirs = dirs[..].concat();
    for d in bigdirs.bytes() {
        let movement = match d {
            b'<' => Direction::Left,
            b'>' => Direction::Right,
            b'^' => Direction::Up,
            b'v' => Direction::Down,
            _    => panic!("Invalid dir"),
        };

        let (dx, dy) = movement.deltas();
        let (nx, ny) = ((x as i32 + dx) as usize, (y as i32 + dy) as usize);
        let next_char = grid.ch_or(nx, ny, b'#');

//      println!("{}: Moving robot {:?} into {}", i, movement, next_char as char);
//      i += 1;

        if next_char == b'#' {
            // blocked
            continue;
        }

        let cur_idx = grid.id_from_pos(x, y);   // robot cur pos
        let adj_idx = grid.id_from_pos(nx, ny); // robot next pos

        if next_char == b']' || next_char == b'[' {
            if d == b'<' || d == b'>' {
                // horizontal box movement
                let (mut ex, mut ey) = grid.walk_to_find(nx, ny, movement,
                    |_, _, newch| newch == b'[' || newch == b']');

                if grid.ch(ex, ey) != b'.' {
                    // blocked
//                  println!("  boxes and robot blocked");
                    continue;
                }

                // found empty cell, swap and move robot
//              println!("  moving boxes and moving robot");

                // move cells one by one into empty space
                while grid.ch(nx, ny) != b'.' {
                    let far_idx = grid.id_from_pos(ex, ey); // empty cell to push into
                    let far_adj_idx = grid.id_from_pos(
                        (ex as i32 - dx) as usize,
                        (ey as i32 - dy) as usize);
                    grid.chars.swap(far_idx, far_adj_idx);

                    ex = (ex as i32 - dx) as usize;
                    ey = (ey as i32 - dy) as usize;
                }
            } else {
                // vertical box movement
                let ny2 = (ny as i32 + dy) as usize;
                if !can_move_row(&grid, nx, ny, ny2) {
                    // blocked
                    continue;
                }

//              println!("  moving boxes and moving robot");
                do_move_row(&mut grid, nx, ny, ny2);
            }
        } else {
            assert!(next_char == b'.');
        }

        grid.chars.swap(cur_idx, adj_idx);
        (x, y) = (nx, ny);

//      println!("");
//      grid.dump_grid();

//      let delay = time::Duration::from_millis(300);
//      thread::sleep(delay);

//      print!("\x1b[2J"); // Erase entire screen
    }

//  print!("\x1b[?1049l"); // Restore normal ANSI screen

    // Find all boxes and convert their X/Y into 'GPS' coords
    grid.dump_grid();
    let sum: usize = grid.find_all(b'[').iter()
        .map(|(i, j)| j * 100 + i)
        .sum();
    println!("GPS: {}", sum);
}
