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

fn record_prices(init: u64, totals: &mut Vec<u16>) {
    let mut secret = init;
    let mut last_price: i8 = (init % 10) as i8;
    let mut idx: u32 = 0;

    // The top bit being set implies the value has not yet been set
    // Need 20 bits to allow for 5 bits the largest possible delta (-9) to be encoded into the
    // index.  The actual value will be bigger and non-zero so the value type is u16.
    let mut max_bananas: Vec<u16> = vec![0x8000u16; 0x00100000];

    for i in 0..2000 {
        secret = evolve_secret(secret);
        let price = (secret % 10) as i8;

        let diff = price - last_price;
        last_price = price;

        idx <<= 5;
        idx |= (diff as u32) & 0x1Fu32;
        idx &= 0x000FFFFFu32;

        if i >= 3 {
            let idx_right_type = idx as usize;

            // Enough info to start recording best prices found
            // Only the first price should be recorded
            if max_bananas[idx_right_type] & 0x8000u16 != 0 {
                max_bananas[idx_right_type] = price as u16;
            }
        }
    }

    // At this point every possible sequence of 4 consecutive price diffs has had
    // its corresponding max price found encoded into max_bananas
    //
    // Clear the 'value not set' flag so that it's not confused with a valid price
    for x in max_bananas.iter_mut() {
        *x &= 0x7FFFu16;
    }

    // Update total counter
    for i in 0..totals.len() {
        totals[i] += max_bananas[i];
    }
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

    let mut total_bananas: Vec<u16> = vec![0u16; 0x00100000];
    for line in lines {
        record_prices(line, &mut total_bananas);
    }

    let max_possible: u16 = *total_bananas.iter().max().unwrap();
    let max_position: i32 = (total_bananas.iter()
        .position(|x| *x == max_possible).unwrap()) as i32;

    // Each position is 5 bits of 20 total in use
    let v1 : i8 =  ((max_position              << 12) >> 27) as i8;
    let v2 : i8 = (((max_position & 0x7C00i32) << 17) >> 27) as i8;
    let v3 : i8 = (((max_position & 0x03E0i32) << 22) >> 27) as i8;
    let v4 : i8 = (((max_position & 0x001Fi32) << 27) >> 27) as i8;

    println!("Sum at {} gets us {}", max_position as u16, max_possible);
    println!("This is sequence {},{},{},{}", v1, v2, v3, v4);
}
