use std::env;
use std::fs;

// Advent of Code: 2024 day 12, part 1

// This one is a bit complicated!
// Need to:
//  - Pathfind to group cells into regions
//  - Apply calculations to these cells based on whether touching or not
#[derive(Clone)]
struct Grid {
    w: usize,
    h: usize,
    chars: Vec<u8>,
}

#[allow(dead_code)]
impl Grid {
    fn ch(&self, i: usize, j: usize) -> u8 {
        return self.chars[j * self.w + i];
    }

    fn set_ch(&mut self, i: usize, j: usize, ch: u8) {
        self.chars[j * self.w + i] = ch;
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
}

fn neighbors_of(grid: &Grid, i: usize, j: usize) -> Vec<(usize, usize)> {
    // A neighbor is defined as having the same character
    let cur_ch = grid.ch(i, j);
    let new_dirs = [
        ((i as i32 + 1) as usize, j),
        ((i as i32 - 1) as usize, j),
        (i, (j as i32 + 1) as usize),
        (i, (j as i32 - 1) as usize),
    ];

    return new_dirs.iter().cloned()
        .filter(|(x, y)| grid.is_in_bounds(*x, *y))
        .filter(|(x, y)| cur_ch == grid.ch(*x, *y))
        .collect::<Vec<_>>();
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
    let default_filename: &'static str = "../23/input";
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

    let mut region_id = vec![0; grid.w * grid.h];
    let mut cur_region_id = 1;

    // Look for unregioned cells and do a pathfinding on each one to identify
    // regions.  Each region will be the same cell type, but there may be
    // multiple disjoint regions of a given cell type.
    while let Some(to_search) = region_id.iter().position(|&r_id| r_id == 0) {
        let (x, y) = grid.pos_from_id(to_search);
        grid.visit_from(x, y,
            |i, j| neighbors_of(&grid, i, j), // generate neighbors
            |i, j| region_id[grid.id_from_pos(i, j)] = cur_region_id);
        cur_region_id += 1;
    }

    println!("Visited {} regions.", cur_region_id - 1);

    let region_ids = {
        let mut x = region_id.clone();
        x.sort();
        x.dedup();
        x
    };

    let region_areas = region_ids.iter()
        .map(|x| region_id.iter().filter(|&ch| ch == x).count())
        .collect::<Vec<_>>();

    // Instead of perimeters, we need number of sides (e.g. a large rect region still only has 4
    // sides). I'm not going to pretend to have solved this myself because geometry is not my
    // thing. TL;DR: Count the corners.

    let mut region_corner_counts = vec![0; region_ids.len()];
    for (idx, reg) in region_id.iter().enumerate() {
        let (x, y) = grid.pos_from_id(idx);
        let ch = grid.ch(x, y);

        for i in -1..=1 {
            for j in -1..=1 {
                if i == 0 || j == 0 {
                    continue;
                }

                let x1 = (x as i32 + i) as usize;
                let y1 = y;

                let x2 = x;
                let y2 = (y as i32 + j) as usize;

                if (!grid.is_in_bounds(x1, y1) || grid.ch(x1, y1) != ch) &&
                    (!grid.is_in_bounds(x2, y2) || grid.ch(x2, y2) != ch)
                {
                    // this checks whether there's a corner in direction
                    // of these two points.  E.g. for top left where ch=X
                    // .O.
                    // OXX
                    // .X.
                    region_corner_counts[*reg - 1] += 1;
                }

                if grid.is_in_bounds(x1, y1) && grid.ch(x1, y1) == ch &&
                    grid.is_in_bounds(x2, y2) && grid.ch(x2, y2) == ch &&
                    grid.is_in_bounds(x1, y2) && grid.ch(x1, y2) != ch
                {
                    // this checks whether there's a corner away from direction
                    // of these two points.  E.g. for top left where ch=X
                    // OX.
                    // XX.
                    // ...
                    region_corner_counts[*reg - 1] += 1;
                }
            }
        }
    }

    let total_price: usize = region_areas.iter().zip(region_corner_counts.iter())
        .map(|(&area, &peri)| area * peri)
        .sum();

    println!("Price: {}", total_price);
}
