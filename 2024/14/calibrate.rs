use std::env;
use std::fs;

// Advent of Code: 2024, day 7, part 2

fn check_total(val: u64, tot: u64, remainders: &[u64]) -> bool {
    if val > tot {
        return false;
    }
    if remainders.is_empty() {
        return val == tot;
    }

    if let Some((entry, rest)) = remainders.split_first() {
        let concat_val = (val.to_string() + &entry.to_string()).parse::<u64>().unwrap();
        return
            check_total(val + entry, tot, rest) ||
            check_total(val * entry, tot, rest) ||
            check_total(concat_val, tot, rest)
            ;
    }
    else {
        panic!("This should be impossible");
    }
}

fn test_line(line: &String) -> u64 {
    let tot_and_nums = line.split(": ").collect::<Vec<_>>();
    let total = tot_and_nums[0].parse::<u64>().unwrap();
    let nums = tot_and_nums[1]
        .split(' ')
        .map(str::parse::<u64>)
        .map(Result::unwrap)
        .collect::<Vec<_>>();

    if check_total(0, total, &nums) {
        return total;
    }

    return 0;
}

fn main() {
    let default_filename: &'static str = "../13/input";
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

    let sum: u64 = lines.iter().map(test_line).sum();

    println!("{}", sum);
}
