use std::env;
use std::fs;
use std::sync::mpsc;
use std::thread;

// Advent of Code: 2024, day 4, part 2

#[derive(Clone)]
struct Grid {
    line_len: usize,
    row_count: usize,
    chars: Vec<char>,
}

#[derive(Clone,Copy,Debug,PartialEq,Eq,Hash)]
enum Direction {
    Up, Down, Left, Right,
}

impl Direction {
    fn rotate_right(&self) -> Direction {
        use Direction::*;
        return match &self {
            Up    => Right,
            Right => Down,
            Down  => Left,
            Left  => Up,
        }
    }

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

    fn bitflag(&self) -> u32 {
        use Direction::*;
        return match &self {
            Up    => 1u32,
            Right => 2u32,
            Down  => 4u32,
            Left  => 8u32,
        }
    }
}

impl Grid {
    fn ch(&self, i: usize, j: usize) -> char {
        return self.chars[j * self.line_len + i] as char;
    }

    fn set_ch(&mut self, i: usize, j: usize, ch: char) {
        self.chars[j * self.line_len + i] = ch;
    }

    #[allow(dead_code)]
    fn dump_grid(&self) {
        for l in 0..self.row_count {
            println!("{}", &(self.chars[(l*self.line_len)..((l+1)*self.line_len)]).iter().collect::<String>());
        }
    }

    // Find x,y position of *first* cell filled with char.
    fn find_one(&self, ch: char) -> Option<(usize, usize)> {
        let maybe_pos = self.chars.iter().position(|c| (*c as char) == ch);

        if let Some(pos) = maybe_pos {
            let y = pos / self.line_len;
            let x = pos % self.line_len;
            return Some((x, y));
        } else {
            return None
        }
    }

    fn is_in_bounds(&self, i: usize, j: usize) -> bool {
        if i >= self.line_len || j >= self.row_count {
            return false;
        }
        return true;
    }

    // starting from (i,j), walks in a straight line in direction @dir, calling the closure @f on
    // each cell (including the first) until the closure returns false.
    // Returns true if the closure terminated the walk, false if the walk went
    // out of bounds
    fn walk_to_find<F>(&self, i: usize, j: usize, dir: Direction, mut f: F)
        -> bool
        where F: FnMut(usize, usize, char) -> bool
    {
        let mut x: i32 = i as i32;
        let mut y: i32 = j as i32;
        let (dx, dy) = dir.deltas();

        if !f(i, j, self.ch(i, j)) {
            return true;
        }

        x += dx;
        y += dy;
        let mut nx = x as usize;
        let mut ny = y as usize;

        if !self.is_in_bounds(nx, ny) {
            return false;
        }

        while f(nx, ny, self.ch(nx, ny)) {
            x += dx;
            y += dy;

            nx = x as usize;
            ny = y as usize;

            if !self.is_in_bounds(nx, ny) {
                return false;
            }
        }

        return true;
    }
}

fn build_grid(lines: Vec<String>) -> Grid
{
    let line_len = lines[0].len();
    let row_count = lines.len();
    let mut result: Vec<char> = Vec::with_capacity(row_count * line_len);

    for line in lines {
        for ch in line.chars() {
            result.push(ch)
        };
    };

    return Grid { line_len, row_count, chars: result };
}

fn find_walked_cells(grid: Grid, mut x: usize, mut y: usize) -> Vec<[usize; 2]>
{
    // used to record actions to take on grid later without the closure
    // capturing grid, as grid itself is mutable when it calls the closure
    let mut cells: Vec<[usize; 2]> = vec![];
    let mut dir = Direction::Up;

    // The closure records positions with an 'X' so that the iter/filter below can count
    // them up
    loop {
        {
            let mut process = |i: usize, j: usize, ch: char| {
                if ch != '#' {
                    cells.push([i, j]);
                    return true;
                } else {
                    return false;
                }
            };

            if grid.walk_to_find(x, y, dir, &mut process) {
                dir = dir.rotate_right();
            } else {
                break;
            }
        }

        x = cells.last().unwrap()[0];
        y = cells.last().unwrap()[1];
    }

    // we may have retraced our steps even if we didn't cause a cycle
    cells.sort();
    cells.dedup();

    return cells;
}

// returns true if the given grid would cause a loop during a walk starting from x,y
fn check_for_loop(grid: &Grid, mut x: usize, mut y: usize) -> bool
{
    // used to record actions to take on grid later without the closure
    // capturing grid, as grid itself is mutable when it calls the closure
    let mut dir = Direction::Up;
    let mut dir_flag = dir.bitflag();
    let mut cycle_found = false;

    // The closure records positions *AND* directions.  If we ever come back
    // on the same cell (pos+dir) we know we're in a cycle.
    let mut stop = false;
    let mut cells_seen = vec![0; grid.row_count * grid.line_len];
    let (mut lastx, mut lasty) = (x, y);

    while !stop && !cycle_found {
        { // separate scope to drop the closure consuming x/y to overwrite after
            let mut process = |i: usize, j: usize, ch: char| {
                if cells_seen[j * grid.line_len + i] & dir_flag == dir_flag {
                    cycle_found = true;
                    return false;
                } else if ch != '#' && ch != '*' {
                    cells_seen[j * grid.line_len + i] |= dir_flag;
                    lastx = i;
                    lasty = j;
                    return true;
                } else {
                    return false;
                }
            };

            if grid.walk_to_find(x, y, dir, &mut process) {
                dir = dir.rotate_right();
                dir_flag = dir.bitflag();
            } else {
                stop = true;
            }
        }

        x = lastx;
        y = lasty;
    }

    return cycle_found;
}

fn parallel_check_for_cycles(grid: &Grid, cells: &Vec<[usize; 2]>, start: (usize, usize)) -> usize
{
    let (tx, rx) = mpsc::channel::<usize>();
    let num_threads = thread::available_parallelism().unwrap();
    let (startx, starty) = start;

    for chunk in cells.chunks((cells.len() / num_threads) + 1) {
        // Use one thread for every chunk
        let tx = tx.clone();
        thread::scope(|s| {
            s.spawn(|| {
                let mut grid = grid.clone();
                let mut num_positions = 0;

                for cell in chunk {
                    grid.set_ch(cell[0], cell[1], '*');

                    if check_for_loop(&grid, startx, starty) {
                        num_positions += 1;
                    }

                    grid.set_ch(cell[0], cell[1], '.');
                }

                tx.send(num_positions).unwrap();
            });
        });
    };

    drop(tx); // We won't actually use the transmitter we created as a base

    return rx.iter().sum();
}

fn main() {
    let default_filename: &'static str = "../11/input";
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

    let mut grid = build_grid(lines);

    let res_pos = grid.find_one('^');

    if res_pos.is_none() {
        panic!("Could not find start position!");
    }

    let (startx, starty) = res_pos.unwrap();

    grid.set_ch(startx, starty, '.'); // avoid confusion with existing ^

    let cells: Vec<[usize; 2]> = find_walked_cells(grid.clone(), startx, starty)
        .into_iter()
        .filter(|c| c[0] != startx || c[1] != starty)
        .collect::<Vec<_>>();

    let start = (startx, starty);
    let num_positions = parallel_check_for_cycles(&grid, &cells, start);

    println!("Number of loop-causing barriers: {}", num_positions);
}
