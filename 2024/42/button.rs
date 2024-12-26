use std::collections::HashMap;
use std::env;
use std::fs;

// Advent of Code: 2024 day 21, part 2

type Pos = (usize, usize);
type PosSet = HashMap<u8, Pos>;
type MoveCache = HashMap<String, Vec<String>>;
type CodeCache = HashMap<String, usize>;

struct Puzzle {
    pos_set: PosSet,
    move_cache: MoveCache,
    code_cache: CodeCache,
}

impl Puzzle {
    fn resolve_to_zero(&self, dx: i32, dy: i32, start: Pos) -> Vec<String> {
        let mut res: Vec<String> = vec![];
        let (row, col) = start;

        if dx == 0 && dy == 0 {
            return res;
        }

        // See paired Ruby script for more comments about why
        let mut x_str = if dx < 0 { "<" } else { ">" };
        let tmp = &x_str.repeat(dx.abs() as usize);
        x_str = tmp;

        let mut y_str = if dy < 0 { "^" } else { "v" };
        let tmp2 = &y_str.repeat(dy.abs() as usize);
        y_str = tmp2;

        let minc = col.min((col as i32 + dx) as usize);

        if dx != 0 && (dy == 0 || col == 0 || minc > 0 || row != 3) {
            res.push(x_str.to_owned() + y_str);
        }

        let minr = row.min((row as i32 + dy) as usize);
        let maxr = row.max((row as i32 + dy) as usize);

        if dy != 0 && (dx == 0 || row == 3 || (minr > 3 || maxr < 3) || col != 0) {
            res.push(y_str.to_owned() + x_str);
        }

        if res.len() == 0 {
            panic!("Empty result!");
        }

        return res;
    }

    fn shortest_move_commands(&mut self, start: u8, stop: u8)
        -> Vec<String>
    {
        let mut res: Vec<String> = vec![];

        if start == stop {
            res.push("A".to_string());
            return res;
        }

        let key = start.to_string() + &stop.to_string();
        if self.move_cache.contains_key(&key) {
            return self.move_cache[&key].clone();
        }

        // I messed this up in transcription from Ruby in gen_pos_set, so
        // fixup by swapping col/row here (but only here)
        let (start_col, start_row) = self.pos_set[&start];
        let (stop_col, stop_row)   = self.pos_set[&stop];
        let dx = stop_col as i32 - start_col as i32;
        let dy = stop_row as i32 - start_row as i32;

        let mut opts = self.resolve_to_zero(dx, dy, (start_row, start_col));
        for o in opts.iter_mut() {
            o.push('A');
        }

        let min_size = opts.iter().map(String::len).min().unwrap();
        opts.retain(|x| x.len() == min_size);

        self.move_cache.insert(key, opts.clone());
        return opts;
    }

    fn do_code_step(&mut self, cur_ch: u8, level: usize, next_ch: u8, rest: &str) -> usize {
        // At level 0 we no longer recursively sub-expand strings to find their
        // min lengths, but instead return directly. But we still must account for
        // the rest of the string either way.

        let res = self.shortest_move_commands(cur_ch, next_ch);

        let remainder = if rest.is_empty() {
            0
        } else {
            let bs = rest.as_bytes();
            self.do_code_step(next_ch, level, bs[0], &rest[1..])
        };

        let key = level.to_string() + "/" + &cur_ch.to_string() + &next_ch.to_string() + rest;
        if self.code_cache.contains_key(&key) {
            return self.code_cache[&key];
        }

        let min_len = match level {
            0 => res.iter().map(String::len).min().unwrap(),
            _ => res.iter().map (|x| {
                     let our_bs = x.as_bytes();
                     self.do_code_step(b'A', level - 1, our_bs[0], &x[1..])
                 }).min().unwrap()
        };

        let result = min_len + remainder;
        self.code_cache.insert(key, result);

        return result;
    }

}

fn gen_pos_set() -> PosSet {
    let mut pos = PosSet::new();

    // 7 8 9  <-- layout
    // 4 5 6
    // 1 2 3
    //   0 A
    //
    // and
    //
    //   ^ A  <-- note this 'A' *OVERLAPs* the one above
    // < v >

    // these were inadvertently col,row order when they should have been
    // row,col order.  Fixed in the one consumer of this function.
    pos.insert(b'7', (0, 0));
    pos.insert(b'8', (1, 0));
    pos.insert(b'9', (2, 0));

    pos.insert(b'4', (0, 1));
    pos.insert(b'5', (1, 1));
    pos.insert(b'6', (2, 1));

    pos.insert(b'1', (0, 2));
    pos.insert(b'2', (1, 2));
    pos.insert(b'3', (2, 2));

    pos.insert(b'^', (1, 3)); // overlap
    pos.insert(b'0', (1, 3));
    pos.insert(b'A', (2, 3));

    pos.insert(b'<', (0, 4));
    pos.insert(b'v', (1, 4));
    pos.insert(b'>', (2, 4));

    return pos;
}

fn main() {
    let default_filename: &'static str = "../41/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.iter().filter(|a| !a.starts_with("-")).count() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[args.len() - 1].clone(),
    };

    let lines = fs::read_to_string(&in_file)
        .expect("Should have been able to read the file")
        .lines()
        .map(String::from)
        .collect::<Vec<_>>();

    let pos_set = gen_pos_set();
    let move_cache = MoveCache::new();
    let code_cache = CodeCache::new();
    let mut p = Puzzle { pos_set, move_cache, code_cache };

    let mut sum = 0;

    for code in lines.iter() {
        let bs = code.as_bytes();
        let min_len = p.do_code_step(b'A', 25, bs[0], &code[1..]);
        println!("{} min len? {}", code, min_len);

        let code_num = &code[0..3].parse::<usize>().unwrap();
        sum = sum + code_num * min_len;
    }

    println!("Sum is {}", sum);
}
