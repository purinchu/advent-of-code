use std::env;
use std::fs;

// Advent of Code: 2024 day 16, part 1

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
        -> ()
        where
            N: Fn(&Grid, usize, usize, Direction, i32) -> Vec<(usize, usize, Direction, i32)>,
            V: FnMut(usize, usize, i32) -> ()
    {
        use Direction::*;

        let mut queue: Vec<(usize, usize, Direction, i32)> = vec![];
        let mut visited = vec![false; self.w * self.h * 4];

        // direction ignored for trailhead
        queue.push((i, j, Right, 0));

        while let Some(node) = queue.pop() {
            let (x, y, dir, cost) = node;
            let visit_idx = (self.id_from_pos(x, y) << 2) | dir.id();

            if !self.is_in_bounds(x, y) || visited[visit_idx] {
                continue;
            }

            visit(x, y, cost);
            visited[visit_idx] = true;

            let mut new_neighbors = neighbors(&self, x, y, dir, cost);
            new_neighbors.retain(|(x, y, dir, _)| {
                    let visit_idx = (self.id_from_pos(*x, *y) << 2) | dir.id();
                    !visited[visit_idx]
                });
            queue.append(&mut new_neighbors);
            queue.sort_by_key(|(_, _, _, cost)| *cost);
            queue.reverse();
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

fn main() {
    let default_filename: &'static str = "../31/input";
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

    let start = grid.find_one(b'S').unwrap();
    let end   = grid.find_one(b'E').unwrap();

//  println!("Must go from ({},{}) to ({},{})", start.0, start.1, end.0, end.1);

    let (x, y) = start;
    let w = grid.w;
    let mut costs = vec![0x7FFFFFFFi32; grid.w * grid.h];

    let find_neighbors = |g: &Grid, i, j, dir: Direction, cost| {
        let mut res: Vec<(usize, usize, Direction, i32)> = vec![];
        // Can go 3 different ways, straight or a 90-degree turn

//      println!("Looking for neighbors from ({},{}) ({:?}) cost={}", i, j, dir, cost);

        let dirs_search = vec![dir, dir.turn_r(), dir.turn_l()];
        for newdir in dirs_search {
            let (dx, dy) = newdir.deltas();
            let mut x: i32 = i as i32;
            let mut y: i32 = j as i32;
            let mut newg = g.clone();

            let mut newcost = cost + 1000;
            if newdir == dir {
                newcost = cost;
            }

            // iterate while a path exists
            let mut path_found = false;
            let mut intersection_found = false;

            newg.set_ch(i, j, b'O');

            x += dx;
            y += dy;
            newcost += 1;

//          println!("  Considering ({},{}) ({}) going {:?}", x, y, g.ch(x as usize, y as usize) as char, newdir);

            let mut next_ch = g.ch(x as usize, y as usize);
            while next_ch == b'.' && !intersection_found {
                path_found = true;

                // if no intersection, keep going
                let (lx, ly) = newdir.turn_l().deltas();
                let (rx, ry) = newdir.turn_r().deltas();

//              let lxx = (x + lx) as usize;
//              let lyy = (y + ly) as usize;
//              let rxx = (x + rx) as usize;
//              let ryy = (y + ry) as usize;

//              println!("    It works. {},{}. Left is {}. Right is {}", x, y, g.ch(lxx, lyy) as char, g.ch(rxx, ryy) as char);

                if  g.ch((x + lx) as usize, (y + ly) as usize) == b'.' ||
                    g.ch((x + rx) as usize, (y + ry) as usize) == b'.'
                {
                    intersection_found = true;
                }

                newg.set_ch(x as usize, y as usize, b'x');

                x += dx;
                y += dy;
                newcost += 1;

                next_ch = g.ch(x as usize, y as usize);
            }

            if next_ch == b'E' {
                // We found it!
                let newnode = (x as usize, y as usize, newdir, newcost);
//              println!("    WE FOUND IT {:?}", newnode);
                res.push(newnode);

//              newg.dump_grid();
//              println!("");

                continue;
            }

            if next_ch == b'#' && !intersection_found {
                // ran into a brick wall, abort
//              println!("    Dead end.");
                continue;
            }

            if path_found || next_ch == b'E' {
                let newnode = ((x - dx) as usize, (y - dy) as usize, newdir, newcost - 1);
//              println!("    {:?}", newnode);
                res.push(newnode);

//              newg.dump_grid();
//              println!("");
            }
        }

        return res;
    };

    let (end_x, end_y) = end;
    let visit_node = |i, j, cost| {
        let old_cost: i32 = costs[j * w + i];
        costs[j * w + i] = old_cost.min(cost);
        if i == end_x && j == end_y {
//          println!("END NODE VISITED. Cost = {}", cost);
        }
    };

    grid.visit_from(x, y, find_neighbors, visit_node);

    println!("Cost to end: {}", costs[end_y * w + end_x]);
}
