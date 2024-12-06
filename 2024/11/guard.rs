use std::env;
use std::fs;

// Advent of Code: 2024, day 4, part 2

struct Grid {
    line_len: usize,
    row_count: usize,
    chars: Vec<char>,
}

#[derive(Clone,Copy,Debug)]
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

    // starting from (i,j), walks in a straight line in direction @dir until
    // finding the cell filled with @ch.  If found, returns the last empty
    // location before the filled cell. If not found, returns None
    // Locations traveled are replaced with 'X' in the grid!
    fn walk_to_find(&mut self, i: usize, j: usize, dir: Direction, ch: char)
        -> Option<(usize, usize)>
    {
        let mut x: i32 = i as i32;
        let mut y: i32 = j as i32;
        let (dx, dy) = dir.deltas();

        self.set_ch(i, j, 'X');

        x += dx;
        y += dy;
        let mut nx = x as usize;
        let mut ny = y as usize;

        if !self.is_in_bounds(nx, ny) {
            return None
        }

        while self.ch(nx, ny) != ch {
            self.set_ch(nx, ny, 'X');

            x += dx;
            y += dy;

            nx = x as usize;
            ny = y as usize;

            if !self.is_in_bounds(nx, ny) {
                return None
            }
        }

        return Some(((x - dx) as usize, (y - dy) as usize));
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

    if let Some((x, y)) = res_pos {
        let mut dir = Direction::Up;
        let mut x = x;
        let mut y = y;

        loop {
            // The 'magic' is in walk_to_find overwriting encountered (and unobstructed) cells with
            // 'X' so that the iter/filter below can count them up
            if let Some((nx, ny)) = grid.walk_to_find(x, y, dir, '#') {
                dir = dir.rotate_right();
                x = nx;
                y = ny;
            } else {
                break;
            }
        }
    } else {
        panic!("Could not find start position!");
    }

    println!("{}", grid.chars.iter().filter(|&ch| *ch == 'X').count());
}
