use std::env;
use std::fs;

// Advent of Code: 2024 day 17, part 2

fn split_at_empty_line(mut lines: Vec<String>) -> (Vec<String>, Vec<String>) {
    let idx = lines.iter().position(|el| el.is_empty()).unwrap();

    // +1 so we can pop off the empty line
    let printouts = lines.split_off(idx+1);
    lines.pop();

    return (lines, printouts);
}

fn load_program(lines: Vec<String>) -> (Vec<i64>, Vec<u16>) {
    let (reg_lines, prg_lines) = split_at_empty_line(lines);

    let mut regs: Vec<i64> = vec![];

    for r in reg_lines {
        regs.push(r[12..].parse::<i64>().unwrap());
    }

    let prg = prg_lines[0][9..].split(',')
        .map(str::parse::<u16>)
        .map(Result::unwrap)
        .collect::<Vec<_>>();

    return (regs, prg);
}

fn read_param(reg: &Vec<i64>, param: u16) -> i64 {
    if param >= 0 && param <= 3 {
        return param as i64;
    }

    if param >= 4 && param <= 6 {
        return reg[(param & 0x03) as usize];
    }

    panic!("Unsupported param type");
}

fn step(reg: &mut Vec<i64>, ip: u16, code: &Vec<u16>) -> (u16,Option<u16>) {
    let opcode = code[ip as usize];
    let param  = code[ip as usize + 1];

//    print!("IP: {}. Reg: {:?}   ", ip, reg);

    match opcode {
        0 => { // adv
            let num   = reg[0];
            let denom = read_param(&reg, param) as u32;
            let res   = num >> denom;

//            println!("ADV {}: {} / {} => {}", param, num, denom, res);

            reg[0] = res;
            return (ip + 2, None);
        },

        1 => { // bxl
            let x1 = reg[1];
            let x2 = param as i64;
            let res = x1 ^ x2;

//            println!("BXL {}: {} ^ {} => {}", param, x1, x2, res);

            reg[1] = res;
            return (ip + 2, None);
        },

        2 => { // bst
            let x1 = read_param(&reg, param);
            let res = x1 & 0x07;

//            println!("BST {}: {} & 0x07 => {}", param, x1, res);

            reg[1] = res;
            return (ip + 2, None);
        },

        3 => { // jnz
            let tgt = if reg[0] != 0 { param } else { ip + 2 };

//            println!("JNZ {}: A == {} => {}", param, reg[0], tgt);

            if reg[0] != 0 {
                return (tgt, None);
            }
            return (ip + 2, None);
        },

        4 => { // bxc
            let res = reg[1] ^ reg[2];

//            println!("BXC _: {} ^ {} => {}", reg[1], reg[2], res);

            reg[1] = res;
            return (ip + 2, None);
        },

        5 => { // out
            let val = read_param(&reg, param) & 0x07;

//            println!("OUT {}: ", val);

//            println!("*** {}", val);

            return (ip + 2, Some(val as u16));
        },

        6 => { // bdv
            let num   = reg[0];
            let denom = 2i64.pow(read_param(&reg, param) as u32);
            let res   = num / denom;

//            println!("BDV {}: {} / {} => {}", param, num, denom, res);

            reg[1] = res;
            return (ip + 2, None);
        },

        7 => { // cdv
            let num   = reg[0];
            let denom = 2i64.pow(read_param(&reg, param) as u32);
            let res   = num / denom;

//            println!("CDV {}: {} / {} => {}", param, num, denom, res);

            reg[2] = res;
            return (ip + 2, None);
        },

        _ => panic!("Unhandled opcode"),
    }
}

// Evaluate given program until halted, or until max_out output has occurred.
// Returns program output
fn evaluate(reg: &Vec<i64>, program: &Vec<u16>) -> Vec<u16> {
    let mut ip: u16 = 0;
    let mut out_list: Vec<u16> = vec![];
    let mut registers = reg.clone();

    while (ip as usize) < program.len() {
        let out;
        (ip, out) = step(&mut registers, ip, &program);
        if let Some(val) = out {
            if out_list.len() >= program.len() {
                return out_list;
            }

            out_list.push(val as u16);
        }
    }

    return out_list;
}

fn find_digits(reg: &Vec<i64>, program: &Vec<u16>) -> i64 {
    let mut opts: Vec<i64> = vec![];

    for digit in 0..8 {
        opts.push(digit);
    }

    println!("{:?}", program);

    let mut best_a = 0;

    while let Some(a) = opts.pop() {
        if best_a != 0 && a > best_a {
            continue;
        }

        let mut reg2 = reg.clone();
        reg2[0] = a;

        let output = evaluate(&reg2, &program);

        if *program == output {
            // We found a match but maybe not the lowest.
            if best_a == 0 {
                best_a = a;
            }

            best_a = best_a.min(a);
        }

        if program.ends_with(&output) {
            // not a match but opens possibilities
            for digit in 0..8 {
                let new_a = (a << 3) + digit;
                if best_a == 0 || new_a < best_a {
                    opts.push((a << 3) + digit);
                }
            }
        }
    }

    return best_a;
}

fn main() {
    let default_filename: &'static str = "../33/input";
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
    let (registers, program) = load_program(lines);

    println!("Registers: {:?}. Program: {:?}", registers, program);

    let output = evaluate(&registers, &program);

    let a = find_digits(&registers, &program);
    println!("A = {}", a);
}
