use std::env;
use std::fs;
use std::collections::HashMap;

// Advent of Code: 2024, day 19, part 1

// Goal is to find number of ways to craft towel designs based on available
// towel subpart options
type DesignMap = HashMap<String, u64>;

fn count_options(design: &str, towels: &Vec<&str>, mut cache: &mut DesignMap) -> u64 {
    let mut count = 0u64;
    if cache.contains_key(design) {
        return cache[design];
    }

    for t in towels.iter() {
        if *t == design {
            count += 1;
            break;
        }

        if design.starts_with(t) {
            let rest = design.strip_prefix(t).unwrap();
            count += count_options(rest, &towels, &mut cache);
        }
    }

    cache.insert(String::from(design), count);
    return count;
}

fn split_at_empty_line(mut lines: Vec<String>) -> (Vec<String>, Vec<String>) {
    let idx = lines.iter().position(|el| el.is_empty()).unwrap();

    // +1 so we can pop off the empty line
    let designs = lines.split_off(idx+1);
    lines.pop();

    return (lines, designs);
}

fn main() {
    let default_filename: &'static str = "../37/input";
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

    let (hdr, designs) = split_at_empty_line(lines);

    let mut towels = hdr[0].split(", ").collect::<Vec<_>>();
    towels.sort(); // This seems to be load-bearing!

    let mut cache = DesignMap::new();

    let num_options: usize = designs.iter()
        .map(|d| count_options(d, &towels, &mut cache))
        .filter(|count| *count > 0u64)
        .count();

    println!("{} total designs possible", num_options);
}
