use std::env;
use std::fs;

// Advent of Code: 2024 day 14, part 1

fn robots_from_input(lines: Vec<String>) -> Vec<Vec<i32>> {
    let mut robots: Vec<Vec<i32>> = vec![];

    for l in lines.iter() {
        let parts = l.split(|el: char| { !el.is_numeric() && el != '-' })
            .filter(|res| !res.is_empty())
            .map(str::parse::<i32>)
            .map(Result::unwrap)
            .collect::<Vec<_>>();
        robots.push(parts);
    }

    return robots;
}

#[allow(dead_code)]
fn show_robots(pos: &Vec<(i32, i32)>, w: i32, h: i32) {
    let mut grid = vec![0; (w * h) as usize];

    for (x, y) in pos.iter() {
        let idx = y * w + x;
        grid[idx as usize] += 1;
    }

    for j in 0..h {
        for i in 0..w {
            let idx = j * w + i;
            let count = grid[idx as usize];
            if count > 0 {
                print!("{}", count);
            } else {
                print!(".");
            }
        }
        println!("");
    }
    println!("");
}

fn main() {
    let default_filename: &'static str = "../27/input";
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

    let robots = robots_from_input(lines);
    let h: i32 = 103;
    let w: i32 = 101;
    let max_steps = 100;

    let mut positions:  Vec<(i32, i32)> = robots.iter()
        .map(|arr| (arr[0], arr[1]))
        .collect();
    let velocities: Vec<(i32, i32)> = robots.iter()
        .map(|arr| (arr[2], arr[3]))
        .collect();

    // Simulate robot motion
    for _i in 1..=max_steps {
        for idx in 0..positions.len() {
            let (x, y) = positions[idx];
            let (dx, dy) = velocities[idx];
            let (mut nx, mut ny) = ((x + dx) % w, (y + dy) % h);

            if nx < 0 {
                nx += w * ((-nx / w) + 1);
            }
            if ny < 0 {
                ny += h * ((-ny / h) + 1);
            }

            assert!(nx >= 0);
            assert!(ny >= 0);
            assert!(nx < w);
            assert!(ny < h);

            positions[idx] = (nx, ny);
        }

//      show_robots(&positions, w, h);
    }

//  show_robots(&positions, w, h);

    // Calc quadrants
    let mw = w/2;  // idx to ignore
    let mh = h/2;  // idx to ignore

    let sums = positions.iter()
        .map(|&(x, y)| {
            let res = if x < mw && y < mh {
                (1, 0, 0, 0)
            } else if x > mw && y < mh {
                (0, 1, 0, 0)
            } else if x < mw && y > mh {
                (0, 0, 1, 0)
            } else if x > mw && y > mh {
                (0, 0, 0, 1)
            } else {
                (0, 0, 0, 0)
            };
            res
        })
        .fold((0, 0, 0, 0), |acc, x| {
            let (a1, a2, a3, a4) = acc;
            let (x1, x2, x3, x4) = x;
            (a1 + x1, a2 + x2, a3 + x3, a4 + x4)
        });
    let (s1, s2, s3, s4) = sums;
    let prod = s1 * s2 * s3 * s4;
    println!("Safety score: {} ({}, {}, {}, {})", prod, s1, s2, s3, s4);
}
