use std::env;
use std::fs;

#[derive(Debug,PartialEq,Clone,Copy)]
enum TrendType {
    Zero,
    UpwardOK,
    DownwardOK,
    UpwardHigh,
    DownwardHigh,
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
        let deltas: Vec<i32> = nums.windows(2)
            .map(|w| w[1] - w[0])
            .collect();
        let trends: Vec<TrendType> = deltas.iter()
            .map(|d| {
                use TrendType::*;
                match d {
                    0 => Zero,
                    1..=3 => UpwardOK,
                    -3..=-1 => DownwardOK,
                    ex => if *ex > 0 {
                        UpwardHigh
                    } else {
                        DownwardHigh
                    }
                }
            })
            .collect();

        // Can't get the types right on reduce so loop manually through the
        // trends
        let mut safe: bool = true;
        trends.windows(2)
            .for_each(|w| {
                use TrendType::*;
                match w[0] {
                    Zero => safe = false,
                    UpwardHigh => safe = false,
                    DownwardHigh => safe = false,
                    _ => safe = safe && (w[0] == w[1])
                }
                ()
            });

        if safe {
            num_safe += 1;
        }

//        println!("{:?}", nums);
//        println!("Deltas: {:?}", deltas);
//        println!("Trends: {:?}", trends);
//        println!("Safe?: {:?}", safe);
    }

    println!("{}", num_safe)
}
