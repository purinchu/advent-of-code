use std::env;
use std::fs;

#[derive(Debug,PartialEq,Clone,Copy)]
enum ParseState {
    Base,
    InDo,
    InDont,
    InMulStart,
    InMulNum1,
    InMulNum2,
}

fn main() {
    let default_filename: &'static str = "../05/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.len() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[1].clone(),
    };

    let line = fs::read_to_string(&in_file).unwrap();

    let mut sum_of_products = 0;
    let mut cur_state = ParseState::Base;
    let mut cur_num1 = 0;
    let mut cur_num2 = 0;
    let mut next_char = 'm';
    let mut enabled = 1;

    for ch in line.chars() {
        if ch == 'm' {
            cur_state = ParseState::InMulStart;
            next_char = 'u';
        } else if ch == 'd' {
            cur_state = ParseState::InDo;
            next_char = 'o';
        } else if cur_state == ParseState::InMulStart && ch == next_char {
            if next_char == '(' {
                cur_state = ParseState::InMulNum1;
                cur_num1 = 0;
            } else {
                next_char = match ch {
                    'm' => 'u',
                    'u' => 'l',
                    'l' => '(',
                    _   => 'z',
                };
            }
        } else if cur_state == ParseState::InMulNum1 && ch.is_ascii_digit() {
            cur_num1 *= 10;
            cur_num1 += ch.to_digit(10).unwrap();
        } else if cur_state == ParseState::InMulNum1 && ch == ',' {
            cur_state = ParseState::InMulNum2;
            cur_num2 = 0;
        } else if cur_state == ParseState::InMulNum2 && ch.is_ascii_digit() {
            cur_num2 *= 10;
            cur_num2 += ch.to_digit(10).unwrap();
        } else if cur_state == ParseState::InMulNum2 && ch == ')' {
            sum_of_products += enabled * (cur_num1 * cur_num2);
            cur_state = ParseState::Base;
            next_char = 'm';
        } else if cur_state == ParseState::InDo && ch == next_char {
            if ch == ')' {
                enabled = 1;
                cur_state = ParseState::Base;
                next_char = 'm';
            } else {
                next_char = match ch {
                    'o' => '(',
                    '(' => ')',
                    _   => 'z',
                }
            }
        } else if cur_state == ParseState::InDo && ch == 'n' {
            cur_state = ParseState::InDont;
            next_char = '\'';
        } else if cur_state == ParseState::InDont && ch == next_char {
            if ch == ')' {
//              enabled = 0;
                cur_state = ParseState::Base;
                next_char = 'm';
            } else {
                next_char = match ch {
                    '\'' => 't',
                    't' => '(',
                    '(' => ')',
                    _   => 'z',
                }
            }
        } else {
            next_char = 'z'; // will be reset shortly
        }

        if next_char == 'z' {
            cur_state = ParseState::Base;
            next_char = 'm';
        }

//      println!("Char was {}. Cur state is {:?}, Next char is {}, Mul-enabled? {}", ch, cur_state, next_char, enabled);
    }

    println!("{}", sum_of_products);
}
