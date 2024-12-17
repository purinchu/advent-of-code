use std::env;
use std::fs;

// Advent of Code: 2024 day 16, part 2

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
            N: Fn(&Grid, usize, usize, Direction, i32) -> Vec<Node>,
            V: FnMut(usize, usize, Direction, i32, usize, Direction) -> ()
    {
        use Direction::*;

        let mut queue: Vec<Node> = vec![];
        let mut visited = vec![false; self.w * self.h * 16];

        // start node
        queue.push((i, j, Right, 0, Right, self.w * j + i));

        while let Some(node) = queue.pop() {
            let (x, y, dir, cost, parent_dir, parent) = node;
            let visit_idx = (self.id_from_pos(x, y) << 4) | (dir.id() << 2) | parent_dir.id();

            if !self.is_in_bounds(x, y) || visited[visit_idx] {
                continue;
            }

            visit(x, y, dir, cost, parent, parent_dir);
            visited[visit_idx] = true;

            let mut new_neighbors = neighbors(&self, x, y, dir, cost);
            new_neighbors.retain(|(x, y, dir, _, pdir, _)| {
                    let visit_idx = (self.id_from_pos(*x, *y) << 4) | (dir.id() << 2) | pdir.id();
                    !visited[visit_idx]
                });
            queue.append(&mut new_neighbors);
            queue.sort_by_key(|(_, _, _, cost, _, _)| *cost);
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
    let w = grid.w;

    let start = grid.find_one(b'S').unwrap();
    let end   = grid.find_one(b'E').unwrap();

    let (x, y) = start;

    let find_neighbors = |g: &Grid, i, j, dir: Direction, cost| {
        let mut res: Vec<Node> = vec![];
        let parent_idx = j * w + i;

        // Can go 3 different ways, straight or a 90-degree turn

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

            let mut next_ch = g.ch(x as usize, y as usize);
            while next_ch == b'.' && !intersection_found {
                path_found = true;

                // if no intersection, keep going
                let (lx, ly) = newdir.turn_l().deltas();
                let (rx, ry) = newdir.turn_r().deltas();

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

            if next_ch == b'#' && !intersection_found {
                continue; // dead end
            }

            if next_ch == b'E' {
                // We found it! But keep the extra step we took
                let newnode = (x as usize, y as usize, newdir, newcost, dir, parent_idx);
                res.push(newnode);
            } else if path_found {
                let newnode = ((x - dx) as usize, (y - dy) as usize, newdir, newcost - 1, dir, parent_idx);
                res.push(newnode);
            }
        }

        return res;
    };

    // We need to record minimum-cost paths, but also need to keep track of how we got to each
    // node, since having to turn will change the cost without changing the position, which will
    // play into tracing predecessors of the end node.
    let mut costs = vec![0x7FFFFFFFi32; grid.w * grid.h * 4];

    type Preds = Vec<(usize, Direction, usize)>; // idx, dir_reached, parent_idx
    let mut preds: Vec<Preds> = vec![];
    let mut pred_visits: Vec<usize> = vec![];

    // We don't care how we get to the end, so we can't care about direction here without making
    // later logic harder. Just track it separately.
    let mut end_cost = 0x7FFFFFFFi32;
    let (end_x, end_y) = end;

    // pre-init preds
    for _ in 0..(grid.w*grid.h*4) {
        preds.push(Preds::new());
    }

    let visit_node = |i, j, dir: Direction, cost, parent_idx, pdir: Direction| {
        let idx = (j * w + i) << 2 | dir.id();

        if i == end_x && j == end_y {
//          println!("END NODE VISITED. Cost = {}. pdir={:?}", cost, pdir);
            if cost < end_cost {
                pred_visits.clear();
                end_cost = cost;
            }
            if cost <= end_cost {
                pred_visits.push(idx);
            }
        }

        if cost > costs[idx] {
            return;
        }

        costs[idx] = cost;

        // While we'd only need up to one predecessor node if we're just worried about minimum
        // overall cost, we may have multiple preds of different cost that all map to the same
        // final cost, so we have to track multiple potential predecessors.
        let pred_list: &mut Preds  = &mut preds[idx];
        pred_list.push((idx, dir, (parent_idx << 2) | pdir.id()));
    };

    grid.visit_from(x, y, find_neighbors, visit_node);

    for idx in pred_visits.iter() {
        println!("Cost to end: ({},{}) {}", end_x, end_y, costs[*idx]);
    }

    // We'll just track every grid cell we touch in a separate list and dedup
    let mut path_trace: Vec<usize> = vec![];

    while let Some(path_pred_idx) = pred_visits.pop() {
        // this is node we hit, find parent

        path_trace.push(path_pred_idx >> 2);

        for parent in preds[path_pred_idx].iter() {
            let (path_pred_idx2, dir2, parent_idx) = parent;

            if path_pred_idx2 == parent_idx {
//              println!("Found start, terminating");

                path_trace.push(*parent_idx >> 2);
                break;
            }

            let (mut x, mut y) = grid.pos_from_id((*path_pred_idx2) >> 2);
            let (px, py) = grid.pos_from_id((*parent_idx) >> 2);

//          println!("Reached ({},{}) by going {:?} from parent ({},{})", x, y, dir2, px, py);
            pred_visits.push(*parent_idx);

            // Now trace all the way from here to parent
            let (dx, dy) = dir2.deltas();
            while x != px || y != py {
                path_trace.push(grid.id_from_pos(x, y));
                x = ((x as i32) - dx) as usize;
                y = ((y as i32) - dy) as usize;
            }

            path_trace.push(grid.id_from_pos(px, py));
        }
    }

    path_trace.sort();
    path_trace.dedup();

    println!("There were {} unique cells in the path trace(s).", path_trace.len());
}
