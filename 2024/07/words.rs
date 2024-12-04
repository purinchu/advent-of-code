use std::env;
use std::fs;

fn build_grid(lines: Vec<String>) -> (usize, Vec<u8>)
{
    let line_len = lines[0].len();
    let mut result: Vec<u8> = Vec::with_capacity(lines.len() * line_len);

    for (_i, line) in lines.iter().enumerate() {
        for (_j, ch) in line.bytes().enumerate() {
            result.push(ch)
        };
    };

    return (line_len, result);
}

fn alldir_words_of_length(grid: &Vec<u8>, line_len: usize, row_count: usize, i: usize, j: usize, n: usize) -> Vec<String>
{
    let mut result: Vec<String> = vec![];

    for dy in -1i32..=1 {
        // Ensure sufficient room
        if dy < 0 && j < (n - 1) {
            continue;
        }

        if dy > 0 && j > (row_count - n) {
            continue;
        }

        for dx in -1i32..=1 {
            if dx == 0 && dy == 0 {
                continue;
            }

            // Ensure sufficient room
            if dx < 0 && i < (n - 1) {
                continue;
            }

            if dx > 0 && i > (line_len - n) {
                continue;
            }

            let mut count: i32 = 0;
            let mut new_word = String::from("");
            while count < (n as i32) {
                let ni: i32 = (i as i32) + dx * count;
                let nj: i32 = (j as i32) + dy * count;

//              println!("Searching {},{}. i={}, j={}, n={}", ni, nj, i, j, n);
                let ch = grid[(nj * (line_len as i32) + ni) as usize] as char;

                new_word.push(ch);

                count += 1;
            }

            result.push(new_word);
        }
    }

    return result;
}

fn main() {
    let default_filename: &'static str = "../07/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.len() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[1].clone(),
    };

    let lines: Vec<String> = fs::read_to_string(&in_file)
        .expect("Should have been able to read the file")
        .lines()
        .map(String::from)
        .collect();

    let row_count = *(&lines.len());
    let (line_len, grid) = build_grid(lines);
    let mut sum = 0;

    // TODO: Turn the Vec into a specific "Grid" struct and give appropriate getters?
    for j in 0..row_count {
        for i in 0..line_len {
            let cur_char = grid[j * line_len + i] as char;
            if cur_char != 'X' {
                continue;
            }

            // Look in all 8 directions
            let opts = alldir_words_of_length(&grid, line_len, row_count, i, j, 4);
            sum += opts.iter().filter(|o| *o == "XMAS").count();
        }
    }

    println!("Sum: {}", sum);
}
