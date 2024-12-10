use std::env;
use std::fs;

// Advent of Code: 2024 day 10, part 2

#[derive(Clone)]
struct Grid {
    line_len: usize,
    row_count: usize,
    chars: Vec<char>,
}

#[derive(Clone,Copy,Debug,PartialEq,Eq,Hash,PartialOrd,Ord)]
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

    fn paths_from(&self) -> &[Direction] {
        use Direction::*;
        return match &self {
            Up    => &[Up, Left, Right],
            Right => &[Up, Down, Right],
            Down  => &[Down, Left, Right],
            Left  => &[Up, Down, Left],
        }
    }
}

#[allow(dead_code)]
impl Grid {
    fn ch(&self, i: usize, j: usize) -> char {
        return self.chars[j * self.line_len + i] as char;
    }

    fn set_ch(&mut self, i: usize, j: usize, ch: char) {
        self.chars[j * self.line_len + i] = ch;
    }

    fn dump_grid(&self) {
        for l in 0..self.row_count {
            println!("{}", &(self.chars[(l*self.line_len)..((l+1)*self.line_len)]).iter().collect::<String>());
        }
    }

    // Find x,y position of *first* cell filled with char.
    fn find_one(&self, ch: char) -> Option<(usize, usize)> {
        return self.chars.iter()
            .position(|c| (*c as char) == ch)
            .map(|idx| self.pos_from_id(idx));
    }

    // Find x,y position of all cells filled with char.
    fn find_all(&self, ch: char) -> Vec<(usize, usize)> {
        return self.chars.iter()
            .enumerate()
            .filter(|(_, c)| **c == ch)
            .map(|(i, _)| self.pos_from_id(i))
            .collect::<Vec<_>>();
    }

    fn id_from_pos(&self, i: usize, j: usize) -> usize {
        let l = self.line_len;
        return j * l + i;
    }

    fn pos_from_id(&self, idx: usize) -> (usize, usize) {
        let l = self.line_len;
        return (idx % l, idx / l);
    }

    fn is_in_bounds(&self, i: usize, j: usize) -> bool {
        return i < self.line_len && j < self.row_count;
    }
}

fn neighbors_of_in_dir(dir: Direction, i: usize, j: usize) -> Vec<(Direction, usize, usize)> {
    let new_dirs = dir.paths_from();
    let new_cells = new_dirs.iter().map(|d| {
        let deltas = d.deltas();
        let (dx, dy) = deltas;
        let nx = i as i32 + dx;
        let ny = j as i32 + dy;
        return (*d, nx as usize, ny as usize);
    }).collect::<Vec<_>>();

    return new_cells;
}

fn build_grid(lines: Vec<String>) -> Grid {
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
    let default_filename: &'static str = "../19/input";
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

    let grid = build_grid(lines);
    let trailheads = grid.find_all('0');
    let mut score = 0;

    for (x, y) in trailheads.iter() {
        let mut queue: Vec<(Direction, usize, usize)> = vec![];
        let mut final_rating = 1; // number of concurrent trails being traced at once

        // direction ignored for trailhead
        queue.push((Direction::Up, *x, *y));

        while let Some(node) = queue.pop() {
            let (dir, x, y) = node;

            let cur_height = grid.ch(x, y);
            if cur_height == '9' {
//              println!("Top of the trail at {}, {}. Rating = {}", x, y, final_rating);
                continue;
            }

            let next_height = (cur_height as u8 + 1) as char;
            let ns = if cur_height != '0' {
                neighbors_of_in_dir(dir, x, y)
            } else {
                // start node needs special-handling because we need to head in up to 4 directions,
                // not 3.
                let mut tmp = neighbors_of_in_dir(Direction::Up, x, y);
                tmp.extend(neighbors_of_in_dir(Direction::Down, x, y));
                tmp.extend(neighbors_of_in_dir(Direction::Left, x, y));
                tmp.extend(neighbors_of_in_dir(Direction::Right, x, y));
                tmp.sort();
                tmp.dedup(); // need to avoid overlap of the neighbors of all dirs
                tmp
            };

            // we need to know how many elems we added so retain old length
            let old_len = queue.len();
            queue.extend(ns.iter()
                .filter(|(_, x, y)| grid.is_in_bounds(*x, *y))
                .filter(|(_, x, y)| grid.ch(*x, *y) == next_height));

            // The '1' accounts for the fact we already are an in-edge by definition, so having 1
            // out-edge means no increase in number of trails.
            final_rating += (queue.len() - old_len) as i32 - 1;
        }

//      println!("All trails traced, final rating for the trailhead is {}", final_rating);
        score += final_rating;
    }

    println!("Final score: {}", score);
}
