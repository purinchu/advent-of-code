use std::env;
use std::fs;

// Advent of Code: 2024 day 22, part 1

fn mix(num: u64, val: u64) -> u64 {
    return num ^ val;
}

fn prune(num: u64) -> u64 {
    return num & 0x00FFFFFFu64;
}

fn evolve_secret(num: u64) -> u64 {
    let tmp = num * 64;
    let mut new_secret = prune(mix(num, tmp));

    let tmp2 = new_secret >> 5; // div by 32
    new_secret = prune(mix(new_secret, tmp2));

    let tmp3 = new_secret << 11; // mul by 2048
    new_secret = prune(mix(new_secret, tmp3));

    return new_secret;
}

fn main() {
    let default_filename: &'static str = "../43/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.iter().filter(|a| !a.starts_with("-")).count() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[args.len() - 1].clone(),
    };

    let lines = fs::read_to_string(&in_file)
        .expect("Should have been able to read the file")
        .lines()
        .map(str::parse::<u64>)
        .map(Result::unwrap)
        .collect::<Vec<_>>();

    let sum: u64 = lines.iter()
        .map(|seed| { let mut s = *seed; for _ in 0..2000 { s = evolve_secret(s) }; s} )
        .sum();
    println!("{}", sum);
}
