use std::collections::HashMap;
use std::env;
use std::fs;

// Advent of Code: 2024 day 23, part 2

type Graph = HashMap<String, Vec<String>>;

fn is_connected(g: &Graph, n1: &str, n2: &str) -> bool {
    let (a, b) = if n1 < n2 { (n1, n2) } else { (n2, n1) };

    return match g.get(a) {
        Some(list) => list.iter().any(|x| x == b),
        None => false,
    };
}

fn all_connected(g: &Graph, nodes: &[&str]) -> bool {
    // base case is if there are two nodes
    if nodes.len() == 2 {
        return is_connected(g, nodes[0], nodes[1]);
    }

    // Otherwise bite off a node and then ensure the rest are connected to each other, and to the
    // node

    let (n, rest) = (nodes[0], &nodes[1..]);
    if !all_connected(g, rest) {
        return false;
    }

    return rest.iter().all(|x| is_connected(g, n, x));
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

fn combinations_of<'a>(n: usize, v: &'a [&'a str]) -> Vec<Vec<&'a str>> {
    let mut res: Vec<Vec<&str>> = vec![];

    // base case
    if n == 1 {
        for s in v {
            let combo_list: Vec<&str> = vec![s];
            res.push(combo_list);
        }

        return res;
    }

    // handle our one node by pushing to the end of every array
    // in the list we get
    for i in 0..=(v.len()-n) {
        let mut inner_res = combinations_of(n - 1, &v[(i+1)..]);
        for list in inner_res.iter_mut() {
            list.push(v[i]);
        }

        res.append(&mut inner_res);
    }

    return res;
}

fn main() {
    let default_filename: &'static str = "../45/input";
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

    let g = read_graph(lines);

    // Loop through progressively smaller combination counts until we find the first (and hopefully
    // only) clique, which will be the largest.
    let mut num_combos = g.values().map(|x| x.len()).max().unwrap();

    loop {
        for (n1, conns) in g.iter() {
            let mut nodes: Vec<&str> = vec![&n1];
            nodes.extend(conns.iter().map(|x| &x[..]));

            // Not every node is connected to lots of others
            if num_combos >= nodes.len() {
                continue;
            }

            for c in combinations_of(num_combos, &nodes) {
                if all_connected(&g, &c) {
                    let mut res = c.clone();
                    res.sort();

                    println!("Found a match with {}", res.join(","));
                    return;
                }
            }
        }

        num_combos -= 1;
        if num_combos < 10 {
            println!("Something went wrong I guess!");
            return;
        }
    }
}
