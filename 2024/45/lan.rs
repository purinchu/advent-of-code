use std::collections::HashMap;
use std::env;
use std::fs;

// Advent of Code: 2024 day 23, part 1

type Graph = HashMap<String, Vec<String>>;

fn is_connected(g: &Graph, n1: &String, n2: &String) -> bool {
    let (a, b) = if n1 < n2 { (n1, n2) } else { (n2, n1) };

    return match g.get(a) {
        Some(list) => list.contains(b),
        None => false,
    };
}

fn all_connected(g: &Graph, n1: &String, n2: &String, n3: &String) -> bool {
    return is_connected(g, n1, n2) &&
        is_connected(g, n1, n3) &&
        is_connected(g, n2, n3);
}

fn read_graph(lines: Vec<String>) -> Graph {
    let mut graph = Graph::new();

    for line in lines {
        let l = String::from(&line[0..2]);
        let r = String::from(&line[3..5]);

        // The one < the other will be the key, the other will be in the value
        // (the list of the key's connections)
        let (a, b) = if l < r { (l, r) } else { (r, l) };

        let deps = graph.entry(a).or_insert(Vec::<String>::new());
        (*deps).push(b);
    }

    for (_, list) in graph.iter_mut() {
        list.sort();
    }

    return graph;
}

fn main() {
    let default_filename: &'static str = "../45/input";
    let args: Vec<String> = env::args().collect();
    let in_file: String = match args.iter().filter(|a| !a.starts_with("-")).count() {
        // No args provided save argv[0]
        1 => String::from(default_filename),
        _ => args[args.len() - 1].clone(),
    };

    let mut lines = fs::read_to_string(&in_file)
        .expect("Should have been able to read the file")
        .lines()
        .map(String::from)
        .collect::<Vec<_>>();

    let g = read_graph(lines);
    let mut count = 0;

    for (n1, conns) in g.iter() {
        for (idx, n2) in conns.iter().enumerate() {
            if idx >= conns.len() {
                continue;
            }

            for n3 in conns[(idx+1)..].iter() {
                let names = vec![n1, n2, n3];
                if names.iter().all(|x| !x.starts_with('t')) {
                    continue;
                }

                if all_connected(&g, n1, n2, n3) {
                    count += 1;
                }
            }
        }
    }

    println!("{}", count);
}
