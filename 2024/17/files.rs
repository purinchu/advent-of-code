use std::env;
use std::fs;

// Advent of Code: 2024, day 9, part 1

// Goal is to find the checksum of a filesystem after defragmenting the files.
fn main() {
    let default_filename: &'static str = "../17/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.len() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[1].clone(),
    };

    let line = fs::read_to_string(&in_file).unwrap();
    let file_chars = line.chars().collect::<Vec<_>>();

    let mut id: u32 = 0;
    let mut checksum: u64 = 0;
    let mut disk: Vec<Option<u32>> = vec![]; // Some(id) if filled, None if empty

    for chunk in file_chars.chunks(2) {
        let filesize = (chunk[0] as usize) - ('0' as usize);
        let emptysize = if chunk[1] >= '0' && chunk[1] <= '9' {
            (chunk[1] as usize) - ('0' as usize)
        } else { 0 };

        assert!(filesize <= 9);
        assert!(emptysize <= 9);

        for i in 0..filesize {
            disk.push(Some(id));
        }

        for i in 0..emptysize {
            disk.push(None);
        }

        id += 1;
    }

    println!("Disk is now of size {}", disk.len());

    // sort the disk such that the first empty block is after the last filled
    // block
    loop {
        let first_empty_pos = disk.iter().position(|x| x.is_none()).unwrap();
        let last_fill_pos = disk.iter().rposition(|x| x.is_some()).unwrap();

        if first_empty_pos > last_fill_pos {
            break;
        }

        disk.swap(first_empty_pos, last_fill_pos);
    }

    println!("Defrag complete");

    let sum: u64 = disk.iter().enumerate().take_while(|(_, x)| x.is_some()).map(|(i, x)| (i as u64) * x.unwrap() as u64).sum();

    println!("Checksum is {}", sum);
}
