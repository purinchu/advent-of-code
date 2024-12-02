use std::env;
use std::fs;

#[derive(Debug,PartialEq,Clone,Copy)]
enum TrendType {
    Upward,
    Downward,
    Unsafe,
}

fn is_trend_safe(nums: &Vec<i32>) -> bool {
    let deltas: Vec<i32> = nums.windows(2)
        .map(|w| w[1] - w[0])
        .collect();

    let trends: Vec<TrendType> = deltas.iter()
        .map(|d| {
            match d {
                1..=3   => TrendType::Upward,
                -3..=-1 => TrendType::Downward,
                _       => TrendType::Unsafe,
            }
        })
        .collect();

    if trends.contains(&TrendType::Unsafe) {
        return false;
    }

    if trends.contains(&TrendType::Upward) && trends.contains(&TrendType::Downward) {
        return false;
    }

    // trends must contain exactly one of Upward/Downward.
    return true;
}

fn main() {
    let default_filename: &'static str = "../03/input";
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

    let mut num_safe: i32 = 0;

    // Each line is a whitespace-separate list of numbers
    for line in lines.iter() {
        let nums: Vec<i32> = line.split_whitespace()
            .map(|x| { let i: i32 = x.parse().unwrap(); i })
            .collect();

        if is_trend_safe(&nums) {
            num_safe += 1;
        } else {
            // check for Problem Dampener
            let mut elided_lists: Vec<Vec<i32>> = Vec::with_capacity(nums.len());
            for i in 0..nums.len() {
                let mut new_list: Vec<i32> = nums.clone();
                new_list.remove(i);
                elided_lists.push(new_list);
            }

            if elided_lists.iter().any(|l| is_trend_safe(&l)) {
                num_safe += 1;
            }
        }
    }

    println!("{}", num_safe)
}
