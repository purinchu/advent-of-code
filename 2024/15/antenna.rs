use std::env;
use std::fs;

// Advent of Code: 2024, day 8, part 1

// Goal is to find 'antinodes' of each antenna grouping that is present on the map, even if
// inaccessible.  The number of unique locations of antinodes is the puzzle solution.
#[derive(Clone,Debug)]
struct Antenna {
    group: char,
    x: usize,
    y: usize,
}

#[derive(Clone)]
struct Grid {
    line_len: usize,
    row_count: usize,
    chars: Vec<char>,
    antenna: Vec<Antenna>,
}

#[allow(dead_code)]
impl Grid {
    fn ch(&self, i: usize, j: usize) -> char {
        return self.chars[j * self.line_len + i] as char;
    }

    fn set_ch(&mut self, i: usize, j: usize, ch: char) {
        self.chars[j * self.line_len + i] = ch;
    }

    #[allow(dead_code)]
    fn dump_grid(&self) {
        println!("{}x{} grid", self.line_len, self.row_count);
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
}

// I couldn't think of any fancy algorithm for this and I'm not using crates.  Luckily my input
// liked me!  Only 3- and 4-sized groups in the input along with the sample.
fn combinations(n: usize, r: usize) -> Vec<Vec<usize>>
{
    let combos_3_2: Vec<Vec<usize>> = vec![
        vec![0, 1],
        vec![0, 2],
        vec![1, 2],
    ];

    let combos_4_2: Vec<Vec<usize>> = vec![
        vec![0, 1],
        vec![0, 2],
        vec![0, 3],
        vec![1, 2],
        vec![1, 3],
        vec![2, 3],
    ];

    if n == 3 && r == 2 {
        return combos_3_2;
    }

    if n == 4 && r == 2 {
        return combos_4_2;
    }

    panic!("Unimplemented");
}

fn build_grid(lines: Vec<String>) -> Grid
{
    let line_len = lines[0].len();
    let row_count = lines.len();
    let mut result: Vec<char> = Vec::with_capacity(row_count * line_len);
    let mut antenna: Vec<Antenna> = Vec::with_capacity(row_count * line_len);

    for (j, line) in lines.into_iter().enumerate() {
        for (i, ch) in line.chars().enumerate() {
            result.push(ch);
            if ch.is_ascii_alphanumeric() {
                antenna.push(Antenna { group: ch, x: i, y: j });
            }
        };
    };

    return Grid { line_len, row_count, chars: result, antenna };
}

fn main() {
    let default_filename: &'static str = "../15/input";
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
    let mut antipode_pos = Vec::<(usize, usize)>::with_capacity(32);

    let mut ant_groups = grid.antenna.iter().map(|x| x.group).collect::<Vec<_>>();
    ant_groups.sort();
    ant_groups.dedup();

    for grp in &ant_groups {
        let ants = &grid.antenna.iter().filter(|x| x.group == *grp).collect::<Vec<_>>();
        let n = ants.len();
        println!("Antenna group: {} ({})", grp, n);
        for combo in combinations(n, 2) {
            let ant_l = ants[combo[0]];
            let ant_r = ants[combo[1]];

            let dx: i32 = ant_l.x as i32 - ant_r.x as i32;
            let dy: i32 = ant_l.y as i32 - ant_r.y as i32;

            let ant1x = ant_l.x as i32 + dx;
            let ant1y = ant_l.y as i32 + dy;
            let ant2x = ant_r.x as i32 - dx;
            let ant2y = ant_r.y as i32 - dy;

            if grid.is_in_bounds(ant1x as usize, ant1y as usize) {
                antipode_pos.push((ant1x as usize, ant1y as usize));
            }

            if grid.is_in_bounds(ant2x as usize, ant2y as usize) {
                antipode_pos.push((ant2x as usize, ant2y as usize));
            }
        }
    }

    antipode_pos.sort();
    antipode_pos.dedup();

//  let mut grid2 = grid.clone();
//  for (anti_x, anti_y) in &antipode_pos {
//      println!("Antipode at {}, {}", anti_x, anti_y);
//      grid2.set_ch(*anti_x, *anti_y, '#');
//  }

//  grid2.dump_grid();
    println!("Number of antipodes: {}", antipode_pos.len());
}
