use std::env;
use std::fs;
use std::fs::File;
use std::io::Read;
use std::collections::HashMap;

// Advent of Code: 2024, day 24, part 2

// Goal is to find outputs of wired-up binary gates
#[derive(Debug,Clone)]
struct Output {
    op: u8,
    is_term: bool,
    is_set: bool,
    dep1: String,
    dep2: String,
}

type OutputMap = HashMap<String, Output>;

fn split_at_empty_line(mut lines: Vec<String>) -> (Vec<String>, Vec<String>) {
    let idx = lines.iter().position(|el| el.is_empty()).unwrap();

    // +1 so we can pop off the empty line
    let designs = lines.split_off(idx+1);
    lines.pop();

    return (lines, designs);
}

fn read_wiring(presets: Vec<String>, wiring: Vec<String>) -> OutputMap {
    let mut map: OutputMap = OutputMap::new();

    for preset in presets {
        let mut entry = preset.split(": ");
        let name = entry.next().unwrap();
        let val  = entry.next().unwrap();

        map.insert(name.to_string(), Output {
            op: b'1', is_term: true,
            is_set: val == "1",
            dep1: String::new(), dep2: String::new(),
        });
    }

    for wires in wiring {
        let entry = wires.split(" ").collect::<Vec<_>>();

        let op = match entry[1] {
            "XOR" => b'^',
            "AND" => b'&',
            "OR"  => b'|',
            _     => panic!("???"),
        };

        map.insert(entry[4].to_string(), Output {
            op, is_term: false, is_set: false,
            dep1: entry[0].to_string(), dep2: entry[2].to_string(),
        });
    }

    return map;
}

fn eval(map: &OutputMap, node: String) -> u32 {
    let entry = map[&node].clone(); // crash if it's not there
    let dval1 = if entry.is_term { 0u32 } else { eval(map, entry.dep1) };
    let dval2 = if entry.is_term { 0u32 } else { eval(map, entry.dep2) };
    let val = match entry.op {
        b'^' => dval1 ^ dval2,
        b'&' => dval1 & dval2,
        b'|' => dval1 | dval2,
        b'1' => if entry.is_set { 1u32 } else { 0u32 },
        _    => panic!("????"),
    };

    return val;
}

fn set_x(mut wires: &mut OutputMap, val: u64) {
    let mut all_x = wires.keys()
        .filter(|x| x.starts_with("x"))
        .map(|x| x.clone())
        .collect::<Vec<_>>();
    all_x.sort();

    let mut i = 0;

    for x in all_x.iter() {
        let mut cur_entry = wires.get_mut(x).unwrap();
        if (val & (1u64 << i)) != 0 {
            cur_entry.is_set = true;
        } else {
            cur_entry.is_set = false;
        }

        i += 1;
    }
}

fn set_y(mut wires: &mut OutputMap, val: u64) {
    let mut all_y = wires.keys()
        .filter(|x| x.starts_with("y"))
        .map(|x| x.clone())
        .collect::<Vec<_>>();
    all_y.sort();

    let mut i = 0;

    for y in all_y.iter() {
        let mut cur_entry = wires.get_mut(y).unwrap();
        if (val & (1u64 << i)) != 0 {
            cur_entry.is_set = true;
        } else {
            cur_entry.is_set = false;
        }

        i += 1;
    }
}

fn get_z(wires: &OutputMap) -> u64 {
    let mut all_z = wires.keys().filter(|x| x.starts_with("z")).collect::<Vec<_>>();
    all_z.sort();

    let mut val: u64 = 0;
    let mut i = 0;

    for z in all_z.iter() {
        let cur_bit = eval(&wires, z.to_string()) as u64;

        val = val | (cur_bit << i);
        i += 1;
    }

    return val;
}

fn main() {
    let default_filename: &'static str = "../47/input";
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

    let (presets, wiring) = split_at_empty_line(lines);

    let mut wires = read_wiring(presets, wiring);

    let max_bit_rank = 44; // 0-indexed, i.e. 0..=44 can be set

    let mut f = File::open("/dev/urandom").unwrap();
    let mut buf = [0u8; 8];
    let mut ever_wrong = 0u64;

    for _i in 0..20 {
        f.read_exact(&mut buf).unwrap();
        let x = u64::from_le_bytes(buf) & ((1u64 << max_bit_rank) - 1);
        f.read_exact(&mut buf).unwrap();
        let y = u64::from_le_bytes(buf) & ((1u64 << max_bit_rank) - 1);
        let right_z = x + y;

        set_x(&mut wires, x);
        set_y(&mut wires, y);
        let actual_z = get_z(&wires);

        println!("    {:048b} +", x);
        println!("    {:048b} =", y);
        println!("    {:-<48}", "-");
        println!("    {:048b} z", actual_z);
        println!("df: {:048b}", (right_z ^ actual_z));
        println!("");

        ever_wrong = ever_wrong | (right_z ^ actual_z);
    }

    println!("Bits ever wrong: {:048b}", ever_wrong);

    let mut count = 0;
    while ever_wrong & 1 == 0 {
        count += 1;
        ever_wrong >>= 1;
    }

    println!("Least bit incorrect: {}", count);
}
