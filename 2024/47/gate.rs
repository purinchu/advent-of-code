use std::env;
use std::fs;
use std::collections::HashMap;

// Advent of Code: 2024, day 24, part 1

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

    let wires = read_wiring(presets, wiring);

    let mut all_z = wires.keys().filter(|x| x.starts_with("z")).collect::<Vec<_>>();
    all_z.sort();

    let mut val: u64 = 0;
    let mut i = 0;

    for z in all_z.iter() {
        let cur_bit = eval(&wires, z.to_string()) as u64;

        println!("{} = {}", z, cur_bit);

        val = val | (cur_bit << i);
        i += 1;
    }

    println!("Overall val: {}", val);
}
