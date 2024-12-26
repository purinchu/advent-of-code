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

fn record_prices(init: u64) -> Vec<u16> {
    let mut secret = init;
    let mut last_price: i8 = (init % 10) as i8;
    let mut idx: u16 = 0;

    let mut max_bananas: Vec<u16> = vec![0xFFFFu16; 65536];

    for i in 0..2000 {
        secret = evolve_secret(secret);
        let price = (secret % 10) as i8;

        let diff = price - last_price;
        last_price = price;

        idx <<= 4;
        idx |= (diff as u16) & 0x0Fu16;
        idx &= 0xFFFFu16;

        if i >= 3 {
            let idx_right_type = idx as usize;

            // Enough info to start recording best prices found
            // Only the first price should be recorded
            if max_bananas[idx_right_type] == 0xFFFFu16 {
                max_bananas[idx_right_type] = price as u16;
            }
        }
    }

    // Reset max price we can sell for to 0 for entries we didn't find
    for x in max_bananas.iter_mut() {
        if *x == 0xFFFFu16 {
            *x = 0;
        }
    }

    return max_bananas;
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

    let max_improvements: Vec<Vec<u16>> = lines.iter()
        .map(|seed| record_prices(*seed))
        .collect::<Vec<_>>();

    let improvement_totals: Vec<u16> = max_improvements.iter().cloned()
        .reduce(|acc, row| {
            let sum: Vec<u16> = acc.iter().zip(row.iter()).map(|(l,r)| l+r).collect::<Vec<_>>();
            return sum
        })
        .unwrap()
        ;

    let max_possible: u16 = *improvement_totals.iter().max().unwrap();
    let max_position: i16 = (improvement_totals.iter()
        .position(|x| *x == max_possible).unwrap()) as i16;

    let v1 : i8 =  ((max_position)                    >> 12) as i8;
    let v2 : i8 = (((max_position & 0x0F00i16) << 4 ) >> 12) as i8;
    let v3 : i8 = (((max_position & 0x00F0i16) << 8 ) >> 12) as i8;
    let v4 : i8 = (((max_position & 0x000Fi16) << 12) >> 12) as i8;

    println!("Sum at {} gets us {}", max_position as u16, max_possible);
    println!("This is sequence {},{},{},{}", v1, v2, v3, v4);
}
