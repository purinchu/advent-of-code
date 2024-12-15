use std::env;
use std::fs;

// Advent of Code: 2024 day 15, part 1

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

#[allow(dead_code)]
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

    fn set_ch(&mut self, i: usize, j: usize, ch: u8) {
        let idx = self.id_from_pos(i, j);
        self.chars[idx] = ch;
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

    // starting from (i,j), finds neighbors based on a provided closure, and
    // for each cell visited calls a second closure.
    fn visit_from<N, V>(&self, i: usize, j: usize, neighbors: N, mut visit: V)
        -> ()
        where
            N: Fn(usize, usize) -> Vec<(usize, usize)>,
            V: FnMut(usize, usize) -> ()
    {
        let mut queue: Vec<(usize, usize)> = vec![];
        let mut visited = vec![false; self.w * self.h];

        // direction ignored for trailhead
        queue.push((i, j));

        while let Some(node) = queue.pop() {
            let (x, y) = node;

            if !self.is_in_bounds(x, y) || visited[self.id_from_pos(x, y)] {
                continue;
            }

            visit(x, y);
            visited[self.id_from_pos(x, y)] = true;

            queue.extend(neighbors(x, y));
        }
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
    let mut result: Vec<u8> = Vec::with_capacity(w * h);

    for line in lines {
        for ch in line.bytes() {
            result.push(ch)
        };
    };

    return Grid { w, h, chars: result };
}

fn split_at_empty_line(mut lines: Vec<String>) -> (Vec<String>, Vec<String>) {
    let idx = lines.iter().position(|el| el.is_empty()).unwrap();

    // +1 so we can pop off the empty line
    let printouts = lines.split_off(idx+1);
    lines.pop();

    return (lines, printouts);
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
    grid.dump_grid();

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

        if next_char == b'O' {
            // move boxes if we can. Walk_to_find stops on the empty/blocker cell
            let (ex, ey) = grid.walk_to_find(nx, ny, movement, |_, _, newch| newch == b'O');
            if grid.ch(ex, ey) == b'.' {
                // found empty cell, swap and move robot
//              println!("  moving boxes and moving robot");

                let cur_idx = grid.id_from_pos(x, y);   // robot cur pos
                let adj_idx = grid.id_from_pos(nx, ny); // robot next pos
                let far_idx = grid.id_from_pos(ex, ey); // empty cell to push into
                grid.chars.swap(adj_idx, far_idx); // swap box into empty space
                grid.chars.swap(cur_idx, adj_idx);

                (x, y) = (nx, ny);
            } else {
                // some kind of other blocker, we're stuck
//              println!("  boxes and robot blocked");
            }
        } else if next_char == b'.' {
            // we can move directly
//          println!("  moving robot");

            let cur_idx = grid.id_from_pos(x, y);   // robot cur pos
            let adj_idx = grid.id_from_pos(nx, ny); // robot next pos
            grid.chars.swap(cur_idx, adj_idx);

            (x, y) = (nx, ny);
        } else {
            // blocked, ignore
//          println!("  robot blocked");
        }

//      println!("");
//      grid.dump_grid();

//      let delay = time::Duration::from_millis(900);
//      thread::sleep(delay);

//      print!("\x1b[2J"); // Erase entire screen
    }

//  print!("\x1b[?1049l"); // Restore normal ANSI screen

    // Find all boxes and convert their X/Y into 'GPS' coords
    let sum: usize = grid.find_all(b'O').iter()
        .map(|(i, j)| j * 100 + i)
        .sum();
    println!("GPS: {}", sum);
}
