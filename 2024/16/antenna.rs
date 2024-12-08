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

fn project_out(pt: (usize, usize), d: (i32, i32), count: usize) -> (usize, usize)
{
    let (x, y) = pt;
    let (dx, dy) = d;
    return ((x as i32 + dx * count as i32) as usize, (y as i32 + dy * count as i32) as usize);
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

        for i in 0..ants.len() {
            for j in (i+1)..ants.len() {
                let (ant_l, ant_r) = (ants[i], ants[j]);

                let dx = ant_l.x as i32 - ant_r.x as i32;
                let dy = ant_l.y as i32 - ant_r.y as i32;

                // Start from 0 because every antenna is also an antipode.
                antipode_pos.extend((0..)
                    .map(|i| project_out((ant_l.x, ant_l.y), (dx, dy), i))
                    .take_while(|(x,y)| is_in_bounds(*x, *y, w, h))
                );

                antipode_pos.extend((0..)
                    .map(|i| project_out((ant_r.x, ant_r.y), (-dx, -dy), i))
                    .take_while(|(x,y)| is_in_bounds(*x, *y, w, h))
                );
            }
        }
    }

    antipode_pos.sort();
    antipode_pos.dedup(); // multiple groups may have antipode in same spot

    println!("{}", antipode_pos.len());
}
