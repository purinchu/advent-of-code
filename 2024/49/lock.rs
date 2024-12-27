use std::env;
use std::fs;

// Advent of Code: 2024, day 25, part 1

// Goal is to find overlap between locks and keys
fn main() {
    let default_filename: &'static str = "../49/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.len() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[1].clone(),
    };

    let lines = fs::read_to_string(&in_file)
        .expect("Should have been able to read the file")
        .split("\n\n")
        .map(String::from)
        .collect::<Vec<_>>();

    let mut keys:  Vec<Vec<u16>> = vec![];
    let mut locks: Vec<Vec<u16>> = vec![];

    for l in lines.iter() {
        let rows = l.split("\n").map(String::from).collect::<Vec<_>>();
        let mut obj: Vec<u16> = vec![0u16; rows[0].len()];

        for (row_idx, r) in rows.iter().enumerate() {
            for (idx, c) in r.char_indices() {
                if c == '#' {
                    obj[idx] |= 1 << row_idx;
                }
            }
        }

        if rows[0].chars().all(|ch| ch == '#') {
            locks.push(obj);
        } else {
            keys.push(obj);
        }
    }

    let mut count = 0;
    for k in &keys {
        for l in &locks {
            if k.iter().zip(l.iter()).all(|(kb,lb)| kb & lb == 0) {
                count += 1;
            }
        }
    }

    println!("{} lock/key pairs have no overlap", count);
}
