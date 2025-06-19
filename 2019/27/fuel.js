#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 14, part 1

import fs from 'node:fs/promises';
import process from 'node:process';

function trap(msg) {
    throw new Error(msg);
}

function print(msg) {
    console.log(msg);
}

function gcd(n1, n2) {
    if (n2 === 0) {
        return n1;
    }
    return gcd(n2, n1 % n2);
}

function lcm(n1, n2) {
    return Math.abs(n1 * n2) / gcd(n1, n2);
}

async function load_file(fh) {
    let out = new Map();

    // 2 AB, 3 BC => 1 FUEL
    for await (const row of fh.readLines({ encoding: 'utf8' })) {
        const [reqt, output] = row.split(' => ');
        const inputs = reqt.split(', ');
        const [qty, name] = output.split(' ');

        out.set(name, { 'qty': parseInt(qty, 10), 'inputs': inputs });
    }

    return out;
}

// makes more as needed and updates the running total of items made to return
// overall total
function make_more(recipe_map, name, min_needed, running_total) {
    let our_total = new Map();
    let cur_run = running_total.get(name) ?? 0;

//  print (`Making ${min_needed} more ${name} (${cur_run} avail currently)`);

    if (!running_total.has(name)) {
        running_total.set(name, 0);
    }

    if (name == 'ORE') {
        // base case, this can always be made
        running_total.set('ORE', running_total.get('ORE') + min_needed);
        return our_total;
    }

    // Something other than ORE, how much do we need...
    const {qty: qty, inputs: inputs} = recipe_map.get(name);

    for (const input_item of inputs) {
        const [input_qty_str, input_name] = input_item.split(' ');
        const input_qty = parseInt(input_qty_str, 10);

        if (!running_total.has(input_name)) {
            running_total.set(input_name, 0);
        }

        const avail = running_total.get(input_name);
//      print (`  Looking at ${input_name} (${input_qty} needed, ${avail} avail)`);

        while(running_total.get(input_name) < input_qty) {
            const sub_total = make_more(recipe_map, input_name, input_qty - avail, running_total);
            for (const [name, sub_qty] of sub_total.entries()) {
                const prev_total = our_total.get(name) ?? 0;
                our_total.set(name, prev_total + sub_qty);
            }
        }

        // use it
//      print (`  Used ${input_qty} ${input_name} as part of making ${qty} ${name}`);
        running_total.set(input_name, running_total.get(input_name) - input_qty);
        const prev_total = our_total.get(input_name) ?? 0;
        our_total.set(input_name, prev_total + input_qty);
    }

    // update final total
//  print (` Now making ${qty} ${name}`);
    running_total.set(name, running_total.get(name) + qty);
    return our_total;
}

async function main(in_file) {
    const file = await fs.open(in_file);
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }

    // Array of 3-elem arrays that represent a moon position or velocity
    const recipe_map = await load_file(file);
    let running_total = new Map();
    for (const [k, v] of recipe_map.entries()) {
        print (`${k} has ${v.inputs} to make ${v.qty}`);
    }

    const sub_total = make_more(recipe_map, 'FUEL', 1, running_total);

    return running_total.get('ORE') + sub_total.get('ORE');
}

try {
    const ore_needed = await main(process.argv[2] || '../23/input');
    print (`Total ORE was ${ore_needed}`);
} catch (err) {
    console.error(`Caught exception: "${err.message}"\n${err.stack}\n`);
    process.exit(1);
}

