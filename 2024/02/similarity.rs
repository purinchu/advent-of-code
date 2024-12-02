use std::env;
use std::fs;

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

    let mut left: Vec<i32> = Vec::with_capacity(lines.len());

    // If there are more than 100,000 potential values we have problems
    let mut counts: Vec<i32> = vec![0; 100000];

    for line in lines.iter() {
        let mut words = line.split_whitespace();
        let left_val : i32 = words.next().unwrap().parse().unwrap();
        let right_val: usize = words.next().unwrap().parse().unwrap();

        assert!(right_val < 100000);

        left.push(left_val);
        counts[right_val] += 1;
    }

    let sum: i32 = left.iter()
        .map(|val| val * counts[*val as usize])
        .sum();

    println!("{}", sum);
}
