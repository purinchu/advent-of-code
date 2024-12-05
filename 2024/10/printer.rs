use std::env;
use std::fs;
use std::collections::HashMap;
use std::cmp::Ordering;

// Advent of Code: 2024, day 5, part 2

fn split_at_empty_line(mut lines: Vec<String>) -> Option::<(Vec<String>, Vec<String>)>
{
    let split_pos = lines.iter().position(|el| el.is_empty());

    if let Some(idx) = split_pos {
        let printouts = lines.split_off(idx+1); // +1 so we can pop off the empty line
        lines.pop();
        return Some((lines, printouts));
    } else {
        return None;
    }
}

fn main() {
    let default_filename: &'static str = "../09/input";
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

    let (orderings, printouts) = split_at_empty_line(lines).unwrap();

    // We use this ordering map as a 'strike list'.  We store the after as the key, mapping to a
    // list of befores.  That way when we're scanning each printout, we can use the list in the map
    // value for each page we read to fill in a set of pages we *can't* encounter for the printout
    // to be safe.
    let mut ord_map = HashMap::new();
    for ord in orderings {
        let vals = ord.split('|')
            .map(&str::parse::<i32>)
            .map(&Result::unwrap)
            .collect::<Vec<_>>();

        let before: i32 = vals[0];
        let after: i32  = vals[1];

        ord_map.entry(after)
            .and_modify(|l: &mut Vec::<i32>| l.push(before))
            .or_insert(vec![before]);
    }

    let mut sum = 0;
    let mut middle_sum = 0;

    for slip in printouts {
        let pages = slip.split(',')
            .map(&str::parse::<i32>)
            .map(&Result::unwrap)
            .collect::<Vec<_>>();

        assert!(pages.len() % 2 != 0);

        let mut found_map = HashMap::new();
        let mut ok = true;

        for page_num in &pages {
            if found_map.contains_key(&page_num) {
//              println!("FAILED: Slip {}, page {} should have been earlier!", slip, page_num);
                ok = false;
                break;
            }

            // Not already in map, add all pages listed for the current page
            // as later failures if encountered
            if let Some(priors) = ord_map.get(&page_num) {
                for blocker in priors {
                    found_map.insert(blocker, false);
                }
            }
        }

        if !ok {
            sum += 1;

            // Need to re-sort the array
            let mut new_pages = pages.clone();
            new_pages.sort_by(|a, b| {
                if let Some(priors) = ord_map.get(&b) {
                    if priors.contains(&a) {
                        return Ordering::Less;
                    } else {
                        return Ordering::Equal;
                    }
                } else {
                    return Ordering::Equal;
                }
            });

//          println!("New sorting for {:?}: {:?}", pages, new_pages);

            middle_sum += new_pages[new_pages.len() / 2];
        }
    }

    println!("{} printouts are INcorrect", sum);
    println!("Middle-num-sum (post-fixup) is {}", middle_sum);
}
