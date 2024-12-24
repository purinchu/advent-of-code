use std::collections::HashSet;
use std::convert::TryInto;
use std::env;
use std::fs;

// Advent of Code: 2024 day 22, part 2

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

fn price_history(init: u64) -> Vec<u32> {
    let mut secret = init;
    let mut prices: Vec<u32> = Vec::with_capacity(2001);

    prices.push((init % 10) as u32);

    for _ in 0..2000 {
        secret = evolve_secret(secret);
        prices.push((secret % 10) as u32);
    }

    return prices;
}

fn price_diffs(prices: &Vec<u32>) -> Vec<i32> {
    let result = prices.windows(2)
        .map(|win| win[1] as i32 - win[0] as i32)
        .collect::<Vec<_>>();
    return result;
}

fn price_for_seq(prices: &Vec<u32>, diffs: &Vec<i32>, seq: &[i32; 4]) -> Option<u32> {
    for i in 3..diffs.len() {
        let cur_seq = &diffs[(i-3)..=i];

        if seq == cur_seq {
            return Some(prices[i + 1]);
        }
    }

    return None;
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

    let histories = lines.iter()
        .map(|seed| price_history(*seed))
        .collect::<Vec<_>>();

    let diffs = histories.iter().map(price_diffs).collect::<Vec<_>>();

    println!("{} prices, {} diffs for first buyer", histories[0].len(), diffs[0].len());

    // Look for all possible price change sequences
    let mut sequences = HashSet::new();

    for diff_seq in diffs.iter() {
        for seq in diff_seq.windows(4) {
            sequences.insert(seq);
        }
    }

//  println!("Buyer 1 price: {}", histories[1][0]);
//  for i in 0..diffs[1].len() {
//      println!("Buyer 1 price: {} ({})", histories[1][i+1], diffs[1][i]);
//  }

    println!("There are {} unique sequences", sequences.len());
    let mut max = 0;
    for seq in sequences.iter() {
        let sized_seq = seq[0..4].try_into().unwrap();
        let bananas: u32 = histories.iter().enumerate()
            .map(|(i, prices)| price_for_seq(&prices, &diffs[i], sized_seq))
            .filter(Option::is_some)
            .map(Option::unwrap)
            .sum();

        if bananas > max {
            println!("{:?}: Buyers would total {} bananas.", seq, bananas);
            max = bananas;
        }
    }

    println!("Max bananas are {}", max);
}
