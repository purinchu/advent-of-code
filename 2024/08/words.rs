use std::env;
use std::fs;

// Advent of Code: 2024, day 4, part 2

struct Grid {
    line_len: usize,
    row_count: usize,
    chars: Vec<u8>,
}

impl Grid {
    fn ch(&self, i: usize, j: usize) -> char {
        return self.chars[j * self.line_len + i] as char;
    }

    // Returns a string with the 4 characters in a X (cross) shape centered on i,j
    // i.e. upper left, upper right, lower left, lower right
    fn cross_at(&self, i: usize, j: usize) -> String {
        let mut res: String = String::from("");

        res.push(self.ch(i - 1, j - 1));
        res.push(self.ch(i - 1, j + 1));
        res.push(self.ch(i + 1, j - 1));
        res.push(self.ch(i + 1, j + 1));

        return res;
    }
}

fn build_grid(lines: Vec<String>) -> Grid
{
    let line_len = lines[0].len();
    let row_count = lines.len();
    let mut result: Vec<u8> = Vec::with_capacity(row_count * line_len);

    for line in lines {
        for ch in line.bytes() {
            result.push(ch)
        };
    };

    return Grid { line_len, row_count, chars: result };
}

fn main() {
    let default_filename: &'static str = "../07/input";
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

    let grid = build_grid(lines);
    let mut sum = 0;

    for j in 1..(grid.row_count-1) {
        for i in 1..(grid.line_len-1) {
            if grid.ch(i, j) != 'A' {
                continue;
            }

            let cross_str_src = grid.cross_at(i, j);

            // if first and last char are the same, the same string would be counted twice by the
            // sort, giving MAM and SAS when we need them to be MAS and MAS.
            if cross_str_src.bytes().nth(0) == cross_str_src.bytes().nth(3) {
                continue;
            }

            let mut cross_str = Vec::from(cross_str_src.as_bytes());
            cross_str.sort();

            if String::from_utf8(cross_str.to_vec()).unwrap() == "MMSS" {
//              println! ("Cross at {}, {}: {} (from {})", i, j, final_str, cross_str_src);
                sum += 1;
            }
        }
    }

    println!("Sum: {}", sum);
}
