use std::env;
use std::fs;

// Advent of Code: 2024 day 20, part 1

#[derive(Clone)]
struct Grid {
    w: usize,
    h: usize,
    chars: Vec<u8>,
}

// i, j, cost
type Node = (usize, usize, i32);

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

    fn id_from_node(&self, node: Node) -> usize {
        let (i, j, _) = node;

        return j * self.w + i;
    }

    // starting from (i,j), finds neighbors based on a provided closure, and
    // for each cell visited calls a second closure.
    fn visit_from<N, V>(&self, i: usize, j: usize, neighbors: N, mut visit: V)
        -> i32
        where
            N: Fn(&Grid, Node) -> Vec<Node>,
            V: FnMut(Node) -> bool
    {
        let mut queue: Vec<Node> = vec![];
        let mut visited = vec![false; self.w * self.h];

        // start node
        queue.push((i, j, 0));

        while let Some(node) = queue.pop() {
            let (x, y, cost) = node;
            let visit_idx = self.id_from_node(node);

            if !self.is_in_bounds(x, y) || visited[visit_idx] {
                continue;
            }

            visited[visit_idx] = true;
            if visit(node) {
                return cost;
            }

            let mut new_neighbors = neighbors(&self, node);
            new_neighbors.retain(|node| !visited[self.id_from_node(*node)]);

            queue.append(&mut new_neighbors);
            queue.sort_by_key(|(_, _, cost)| *cost);
            queue.reverse();
        }

        return -1;
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

fn big_cheats_found(g: &Grid, start: (usize, usize), end: (usize, usize)) -> i32 {
    let w = g.w;
    let mut costs: Vec<i32> = vec![(2 * w * w) as i32; w * w * 2];
    let mut ends_to_find = 2; // with cheat or without cheat

    let visit = |node| {
        let (i, j, cost) = node;
        let idx = g.id_from_node(node);

        if cost < costs[idx] {
            costs[idx] = cost;
        }

        if end == (i, j) {
            ends_to_find -= 1;
        }

        // return true if we've found both possible end nodes
        return ends_to_find == 0;
    };

    let d = |x: usize, dx: i32| {
        return (x as i32 + dx) as usize;
    };

    let neighbors = |g: &Grid, node| {
        let (i, j, cost) = node;
        let new_cost = cost + 1;

        // we can always travel four cardinal directions
        let mut ns: Vec<Node> = vec![
            (d(i, -1), j, new_cost),
            (d(i, 1), j, new_cost),
            (i, d(j, -1), new_cost),
            (i, d(j, 1), new_cost),
        ];

        ns.retain(|(i, j, _)| g.ch_or(*i, *j, b'#') == b'.');

        return ns;
    };

    // Fill in our cost table
    g.visit_from(start.0, start.1, neighbors, visit);

    let mut big_wins = 0; // Number of cheats that save 100ps or more

    // Every empty cell will be walked by problem definition. So just iterate
    // them all and itemize all the cheats.
    for n in g.find_all(b'.') {
        let (i, j) = n;
        let idx = g.id_from_pos(i, j);
        let start_cost = costs[idx];
        let end_cost = start_cost + 2;

        // Just go through all the possible cheats...

        let mut ns: Vec<Node> = vec![
            (d(i, -2),   j,      start_cost + 2),
            (d(i,  2),   j,      start_cost + 2),
            (  i,      d(j, -2), start_cost + 2),
            (  i,      d(j,  2), start_cost + 2),
            (d(i,  1), d(j, -1), start_cost + 2),
            (d(i, -1), d(j, -1), start_cost + 2),
            (d(i,  1), d(j,  1), start_cost + 2),
            (d(i, -1), d(j,  1), start_cost + 2),
        ];

        ns.retain(|(i, j, _)| g.ch_or(*i, *j, b'#') == b'.');

        for n2 in ns.iter() {
            let orig_cost = costs[g.id_from_node(*n2)];
//          let (ii, jj, _) = n2;

            if end_cost < orig_cost {
//              println!("Going {},{} to {},{} saves {} ps!", i, j, ii, jj, orig_cost - end_cost);

                let savings = orig_cost - end_cost;
                if savings >= 100 {
                    big_wins += 1;
                }
            }
        }
    }

    return big_wins;
}

fn main() {
    let default_filename: &'static str = "../39/input";
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

    grid.dump_grid();

    let start = grid.find_one(b'S').unwrap();
    let end   = grid.find_one(b'E').unwrap();
    grid.set_ch(start.0, start.1, b'.');
    grid.set_ch(end.0,   end.1,   b'.');

    let big_wins = big_cheats_found(&grid, start, end);
    println!("Found {} big savings", big_wins);
}
