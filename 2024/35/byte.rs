use std::env;
use std::fs;

// Advent of Code: 2024 day 18, part 1

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

    fn turn_r(&self) -> Direction {
        use Direction::*;
        return match &self {
            Up    => Right,
            Right => Down,
            Down  => Left,
            Left  => Up,
        }
    }

    fn turn_l(&self) -> Direction {
        use Direction::*;
        return match &self {
            Up    => Left,
            Right => Up,
            Down  => Right,
            Left  => Down,
        }
    }

    fn id(&self) -> usize {
        use Direction::*;
        return match &self {
            Up    => 0,
            Right => 1,
            Down  => 2,
            Left  => 3,
        }
    }
}

type Node = (usize, usize, Direction, i32, Direction, usize);

#[allow(dead_code)]
impl Grid {
    fn ch(&self, i: usize, j: usize) -> u8 {
        return self.chars[self.id_from_pos(i, j)];
    }

    fn ch_or(&self, i: usize, j: usize, def: u8) -> u8 {
        if self.is_in_bounds(i, j) {
            let idx = self.id_from_pos(i, j);
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
            for ch in &self.chars[low..high] {
                if *ch == b'.' {
                    print!("\x1b[1;30m{}\x1b[0m", *ch as char);
                } else if *ch == b'#' {
                    print!("\x1b[1;36m{}\x1b[0m", *ch as char);
                } else if *ch == b'@' {
                    print!("\x1b[0;102m\x1b[1;95m{}\x1b[0m", *ch as char);
                } else {
                    print!("{}", *ch as char);
                }
            }

            println!("");
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
        -> i32
        where
            N: Fn(&Grid, usize, usize, Direction, i32) -> Vec<Node>,
            V: FnMut(usize, usize, Direction, i32, usize, Direction) -> bool
    {
        use Direction::*;

        let mut queue: Vec<Node> = vec![];
        let mut visited = vec![false; self.w * self.h * 16];

        // start node
        queue.push((i, j, Up, 0, Up, self.w * j + i));

        while let Some(node) = queue.pop() {
            let (x, y, dir, cost, parent_dir, parent) = node;
            let visit_idx = (self.id_from_pos(x, y) << 4) | (dir.id() << 2) | parent_dir.id();

            if !self.is_in_bounds(x, y) || visited[visit_idx] {
                continue;
            }

//          println!("({},{}) visit, cost = {}", x, y, cost);
            visited[visit_idx] = true;
            if visit(x, y, dir, cost, parent, parent_dir) {
                return cost;
            }

            let mut new_neighbors = neighbors(&self, x, y, dir, cost);
            new_neighbors.retain(|(x, y, dir, _, pdir, _)| {
                    let visit_idx = (self.id_from_pos(*x, *y) << 4) | (dir.id() << 2) | pdir.id();
                    return !visited[visit_idx]
                });
//          println!("\tneighbors = {:?}", new_neighbors);
            queue.append(&mut new_neighbors);
            queue.sort_by_key(|(_, _, _, cost, _, _)| *cost);
            queue.reverse();
        }

        return -1;
    }
}

fn build_grid(w: usize) -> Grid {
    let h = w;
    let result: Vec<u8> = vec![b'.'; w * h];

    return Grid { w, h, chars: result };
}

fn main() {
    let default_filename: &'static str = "../35/input";
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

    let w = 71; // (0..=70)
    let mut grid = build_grid(w);

    let start = (0, 0);
    let end   = (w - 1, w - 1);

    for pair in lines.into_iter().take(1024) {
        let pairv = pair
            .split(',')
            .map(str::parse::<usize>)
            .map(Result::unwrap)
            .collect::<Vec<_>>();
        grid.set_ch(pairv[0], pairv[1], b'#');
    }

    grid.dump_grid();

    let mut costs: Vec<i32> = vec![(2 * w * w) as i32; w * w];

    let visit = |i, j, _dir: Direction, cost, _, _| {
        let idx = grid.id_from_pos(i, j);

        if cost < costs[idx] {
            costs[idx] = cost;
        }

        return end == (i, j);
    };

    let neighbors = |g: &Grid, i, j, dir, base_cost| {
        use Direction::*;
        let mut ns: Vec<Node> = vec![
            ((i as i32 - 1) as usize, j as usize, Up, base_cost + 1, Up, 0),
            ((i + 1) as usize, j as usize, Up, base_cost + 1, Up, 0),
            (i as usize, (j as i32 - 1) as usize, Up, base_cost + 1, Up, 0),
            (i as usize, (j + 1) as usize, Up, base_cost + 1, Up, 0),
        ];

        ns.retain(|(i, j, _, _, _, _)| g.ch_or(*i, *j, b'#') == b'.');

        return ns;
    };

    let cost = grid.visit_from(start.0, start.1, neighbors, visit);
    println!("Final cost is {}", cost);
}
