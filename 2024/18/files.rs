use std::env;
use std::fs;

// Advent of Code: 2024, day 9, part 2

fn load_file(file_data: Vec<char>) -> (Vec<Option<u32>>, u32)
{
    let mut id: u32 = 0;
    let mut disk: Vec<Option<u32>> = vec![]; // Some(id) if filled, None if empty

    for chunk in file_data.chunks(2) {
        let filesize = (chunk[0] as usize) - ('0' as usize);
        let emptysize = if chunk[1] >= '0' && chunk[1] <= '9' {
            (chunk[1] as usize) - ('0' as usize)
        } else { 0 };

        assert!(filesize <= 9);
        assert!(emptysize <= 9);

        for _ in 0..filesize {
            disk.push(Some(id));
        }

        for _ in 0..emptysize {
            disk.push(None);
        }

        id += 1;
    }

    return (disk, id - 1);
}

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
    let (mut disk, last_id) = load_file(file_chars);

    println!("Disk is size {}", disk.len());

    // sort the disk such that most recently-added files get added to the first
    // available free space, as long as there is free space.
    let sentinel: u32 = 0xFFFFFFFF;
    for i in 0..=last_id {
        let file_id = last_id - i;

        let start_of_last = disk.iter().position(|x| x.unwrap_or(sentinel) == file_id).unwrap();
        let start_len = &disk[start_of_last..].iter().take_while(|x| x.unwrap_or(sentinel) == file_id).count();

        // Find first stretch of consecutive free space of length start_len
        let start_of_blank = disk[0..(disk.len()-start_len)].iter()
            .enumerate()
            .find(|(i, _)| disk[*i..(*i+start_len)].iter().all(|x| x.is_none()));

        if let Some((blank_start, _)) = start_of_blank {
            if blank_start < start_of_last {
                // not guaranteed the free space is to the left of the taken space

                for i in 0..*start_len {
                    disk.swap(start_of_last + i, blank_start + i);
                }
            }
        }
    }

    let sum: u64 = disk.iter()
        .enumerate()
        .filter(|(_, x)| x.is_some())
        .map(|(i, x)| (i as u64) * x.unwrap() as u64)
        .sum();

    println!("Checksum is {}", sum);
}
