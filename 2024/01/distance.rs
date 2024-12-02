use std::env;
use std::fs;
use std::iter::zip;

fn main() {
    let default_filename: &'static str = "../01/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.len() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[1].clone(),
    };

    let lines: Vec<String> = fs::read_to_string(in_file.clone())
        .expect("Should have been able to read the file")
        .lines()
        .map(String::from)
        .collect();

    let mut left: Vec<i32> = vec![];
    let mut right: Vec<i32> = vec![];

    for line in lines.iter() {
        let mut words = line.split_whitespace();
        let left_val : i32 = words.next().unwrap().parse().unwrap();
        let right_val: i32 = words.next().unwrap().parse().unwrap();

        left.push(left_val);
        right.push(right_val);
    }

    // sorts in-place
    left.sort();
    right.sort();

    let sum: i32 = zip(left.iter(), right.iter())
        .map(|(l, r)| (l - r).abs())
        .sum();

    println!("{}", sum);
}
