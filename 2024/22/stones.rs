use std::env;
use std::fs;
use std::collections::HashMap;

// Advent of Code: 2024, day 11, part 2

// Goal is to find number of stones after several steps where stones can
// change and divide.
type StoneMap = HashMap<(u64, u32), u64>;

fn count_stones(cache: &mut StoneMap, i: u64, steps_left: u32) -> u64 {
    if steps_left == 0 {
        return 1; // done, you gave me one stone and that's all I have
    }

    let key = (i, steps_left);
    if cache.contains_key(&key) {
        return cache[&key];
    }

    // not cached, calculate it
    let (stone1, stone2) = if i == 0 {
        (1, None)
    } else {
        let stone_str = i.to_string();
        let len = stone_str.len();

        if len % 2 == 0 {
            let s1: u64 = stone_str[0..(len/2)].parse::<u64>().unwrap();
            let s2: u64 = stone_str[(len/2)..].parse::<u64>().unwrap();
            (s1, Some(s2))
        } else {
            (i * 2024, None)
        }
    };

    let count: u64 = count_stones(cache, stone1, steps_left - 1) +
        if let Some(r_stone) = stone2 {
            count_stones(cache, r_stone, steps_left - 1)
        } else { 0 };
    cache.insert(key, count);

    return count;
}

fn main() {
    let default_filename: &'static str = "../21/input";
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

    assert!(lines.len() == 1);

    let mut cache = StoneMap::new();

    let num_stones: u64 = lines[0]
        .split_whitespace()
        .map(str::parse::<u64>)
        .map(Result::unwrap)
        .map(|s| count_stones(&mut cache, s, 75))
        .sum()
        ;
    println!("{}", num_stones);
}
