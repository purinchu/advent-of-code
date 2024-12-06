use std::collections;
use std::env;
use std::fs;

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
    let mut cycle_found = false;

    // The closure records positions *AND* directions.  If we ever come back
    // on the same cell (pos+dir) we know we're in a cycle.
    let mut stop = false;
    let mut cells_seen = collections::HashSet::new();
    let (mut lastx, mut lasty) = (x, y);

    while !stop && !cycle_found {
        { // separate scope to drop the closure consuming x/y to overwrite after
            let mut process = |i: usize, j: usize, ch: char| {
                if cells_seen.contains(&(i, j, dir)) {
                    cycle_found = true;
                    return false;
                } else if ch != '#' && ch != '*' {
                    cells_seen.insert((i, j, dir));
                    lastx = i;
                    lasty = j;
                    return true;
                } else {
                    return false;
                }
            };

            if grid.walk_to_find(x, y, dir, &mut process) {
                dir = dir.rotate_right();
            } else {
                stop = true;
            }
        }

        x = lastx;
        y = lasty;
    }

    return cycle_found;
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

    let cells: Vec<[usize; 2]> = find_walked_cells(grid.clone(), startx, starty);
    let mut num_positions = 0;

    for cell in cells.iter() {
        if cell[0] == startx && cell[1] == starty {
            continue; // Can't sneak an obstacle here
        }

        grid.set_ch(cell[0], cell[1], '*');

        if check_for_loop(&grid, startx, starty) {
            num_positions += 1;
        }

        grid.set_ch(cell[0], cell[1], '.');
    }

    println!("Number of loop-causing barriers: {}", num_positions);
}
