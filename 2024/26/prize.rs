use std::env;
use std::fs;

// Advent of Code: 2024, day 13, part 1

#[derive(Debug,Copy,Clone)]
struct Prize {
    x1: i64,
    y1: i64,
    x2: i64,
    y2: i64,
    x_tot: i64,
    y_tot: i64,
}

fn into_paragraphs(lines: Vec<String>) -> Vec<Vec<String>> {
    return lines
        .split(|l| l.is_empty())
        .map(|sl| sl.to_vec())
        .collect::<Vec<_>>();
}

fn prize_from_para(para: &Vec<String>) -> Prize {
    let xpos1 = para[0].find('X').unwrap();
    let xpos2 = para[1].find('X').unwrap();
    let xy1 = para[0][xpos1..].split(", ").collect::<Vec<_>>();
    let xy2 = para[1][xpos2..].split(", ").collect::<Vec<_>>();

    let x1 = xy1[0][2..].parse::<i64>().unwrap();
    let y1 = xy1[1][2..].parse::<i64>().unwrap();
    let x2 = xy2[0][2..].parse::<i64>().unwrap();
    let y2 = xy2[1][2..].parse::<i64>().unwrap();

    let prize = para[2].find('X').unwrap();
    let xy_tot = para[2][prize..].split(", ").collect::<Vec<_>>();
    let x_tot = xy_tot[0][2..].parse::<i64>().unwrap() + 10000000000000;
    let y_tot = xy_tot[1][2..].parse::<i64>().unwrap() + 10000000000000;

    return Prize{x1, y1, x2, y2, x_tot, y_tot};
}

// I don't like the numbering in the problem, it's linalg but with inverse
// polarity.
// x1 * A + x2 * B = x_tot, but A and B are vars and x's are const.
// Likewise with y
fn clicks_to_prize(p: &Prize) -> Option<(i64, i64)> {
    // x1 * A + x2 * B = x_tot (1)
    // y1 * A + y2 * B = y_tot (2)
    // Subtract (y1/x1) * (1) from (2) to find B.
    let bb =
        (p.y_tot as f64 - (p.y1 as f64 * p.x_tot as f64 / p.x1 as f64))
        / (p.y2 as f64 - p.y1 as f64 * p.x2 as f64 / p.x1 as f64);
    let aa = (p.x_tot as f64 - p.x2 as f64 * bb as f64) / p.x1 as f64;

//  println!("{:?} -> aa = {}, bb = {}", p, aa, bb);
    let a_int = aa.round() as i64;
    let b_int = bb.round() as i64;

    if a_int * p.x1 + b_int * p.x2 == p.x_tot && a_int * p.y1 + b_int * p.y2 == p.y_tot {
        return Some((a_int, b_int));
    } else {
        return None
    }
}

fn main() {
    let default_filename: &'static str = "../25/input";
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
    let prizes = into_paragraphs(lines)
        .iter()
        .map(prize_from_para)
        .collect::<Vec<_>>();

    let tokens_needed = prizes.iter()
        .map(clicks_to_prize)
        .filter(|x| x.is_some())
        .map(Option::unwrap)
        .filter(|(a, b)| *a >= 0 && *b >= 0)
        .map(|(a, b)| 3 * a + b)
        .sum::<i64>();

    println!("Tokens needed: {}", tokens_needed);
}
