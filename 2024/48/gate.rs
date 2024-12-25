use std::env;
use std::fs;
use std::collections::HashMap;

// Advent of Code: 2024, day 24, part 2

// Goal is to find outputs of wired-up binary gates
#[derive(Debug,Clone)]
#[allow(dead_code)]
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

fn has_op_fed_by(wires: &OutputMap, op: u8, input: &String) -> bool {
    return wires.iter()
        .any(|(_, node)|
            node.op == op && (node.dep1 == *input || node.dep2 == *input));
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

    // We know our input is a ripple carry adder, and apparently the input is constrained so that
    // some logic gates are always broken in specific ways

    let mut broken_outputs: Vec<String> = vec![];
    let last_z = wires.keys().filter(|x| x.starts_with('z')).max().unwrap();

    for (name, node) in wires.iter() {
        if name.starts_with('z') && name != last_z && node.op != b'^' {
            broken_outputs.push(name.clone());
        }

        let has_x = (node.dep1.starts_with('x') || node.dep2.starts_with('x'))
            && node.dep1 != "x00" && node.dep2 != "x00";
        let has_y = (node.dep1.starts_with('y') || node.dep2.starts_with('y'))
            && node.dep1 != "y00" && node.dep2 != "y00";

        if !name.starts_with('z') && !has_x && !has_y && node.op == b'^' {
            broken_outputs.push(name.clone());
        }

        // Indirect brokenness
        // https://www.reddit.com/r/adventofcode/comments/1hla5ql/2024_day_24_part_2_a_guide_on_the_idea_behind_the/m3kws15/
        if has_x && has_y && node.op == b'^' && !has_op_fed_by(&wires, b'^', name) {
            broken_outputs.push(name.clone());
        }

        if has_x && has_y && node.op == b'&' && !has_op_fed_by(&wires, b'|', name) {
            broken_outputs.push(name.clone());
        }
    }

    broken_outputs.sort();
    broken_outputs.dedup();
    println!("Broken outputs: {}", broken_outputs.join(","));
}
