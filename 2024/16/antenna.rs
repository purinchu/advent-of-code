use std::env;
use std::fs;

// Advent of Code: 2024, day 8, part 2

// Goal is to find 'antinodes' of each antenna grouping that is present on the map, even if
// inaccessible.  The number of unique locations of antinodes is the puzzle solution.
#[derive(Debug)]
struct Antenna {
    group: char,
    x: usize,
    y: usize,
}

fn is_in_bounds(i: usize, j: usize, w: usize, h: usize) -> bool {
    return i < w && j < h;
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

fn find_antennae(lines: Vec<String>) -> Vec<Antenna>
{
    let mut antenna: Vec<Antenna> = Vec::with_capacity(64);

    for (j, line) in lines.into_iter().enumerate() {
        for (i, ch) in line.chars().enumerate() {
            if ch.is_ascii_alphanumeric() {
                antenna.push(Antenna { group: ch, x: i, y: j });
            }
        };
    };

    return antenna;
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

    let h = lines.len();
    let w = lines[0].len();
    let antenna = find_antennae(lines);
    let mut antipode_pos = Vec::<(usize, usize)>::with_capacity(32);

    let mut ant_groups = antenna.iter().map(|x| x.group).collect::<Vec<_>>();
    ant_groups.sort();
    ant_groups.dedup();

    for grp in &ant_groups {
        let ants = &antenna.iter().filter(|x| x.group == *grp).collect::<Vec<_>>();
        let n = ants.len();

        for combo in combinations(n, 2) {
            let ant_l = ants[combo[0]];
            let ant_r = ants[combo[1]];

            // Every antenna is also an antipode. Dups will be handled later.
            antipode_pos.push((ant_l.x, ant_l.y));
            antipode_pos.push((ant_r.x, ant_r.y));

            let dx: i32 = ant_l.x as i32 - ant_r.x as i32;
            let dy: i32 = ant_l.y as i32 - ant_r.y as i32;

            let mut count = 1;
            loop {
                let anti_x = ant_l.x as i32 + dx * count;
                let anti_y = ant_l.y as i32 + dy * count;

                if is_in_bounds(anti_x as usize, anti_y as usize, w, h) {
                    antipode_pos.push((anti_x as usize, anti_y as usize));
                    count += 1;
                } else {
                    break;
                }
            }

            count = 1;
            loop {
                let anti_x = ant_r.x as i32 - dx * count;
                let anti_y = ant_r.y as i32 - dy * count;

                if is_in_bounds(anti_x as usize, anti_y as usize, w, h) {
                    antipode_pos.push((anti_x as usize, anti_y as usize));
                    count += 1;
                } else {
                    break;
                }
            }
        }
    }

    antipode_pos.sort();
    antipode_pos.dedup();

    println!("{}", antipode_pos.len());
}
