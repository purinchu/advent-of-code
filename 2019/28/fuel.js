#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 14, part 2

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
        const inputs = reqt.split(', ').map((in_str) => {
            const [input_qty_str, input_name] = in_str.split(' ');
            const input_qty = parseInt(input_qty_str, 10);
            return [input_name, input_qty];
        });
        const [qty, name] = output.split(' ');

        out.set(name, { 'qty': parseInt(qty, 10), 'inputs': inputs });
    }

    return out;
}

// makes more as needed and updates the running total of items made to return
// overall total produced chemicals (including recursive production)
function make_more(recipe_map, name, min_needed, running_total) {
    let produced_total = new Map();
    let cur_run = running_total.get(name) ?? 0;

    if (!running_total.has(name)) {
        running_total.set(name, 0);
    }

    if (name == 'ORE') {
        // base case, this can always be made
        const amt_to_make = Math.max(0, min_needed - running_total.get('ORE'));
        produced_total.set('ORE', amt_to_make);
        running_total.set('ORE', running_total.get('ORE') + amt_to_make);

        return produced_total;
    }

    // Something other than ORE, how much do we need...
    const {qty: qty, inputs: inputs} = recipe_map.get(name);
    const num_batches = Math.ceil(min_needed / qty);

    for (const [input_name, input_qty] of inputs) {
        if (!running_total.has(input_name)) {
            running_total.set(input_name, 0);
        }

        const avail = running_total.get(input_name);
        const needed = input_qty * num_batches;

        while (running_total.get(input_name) < needed) {
            const sub_total = make_more(recipe_map, input_name, needed - avail, running_total);
            for (const [name, sub_qty] of sub_total.entries()) {
                const prev_total = produced_total.get(name) ?? 0;
                produced_total.set(name, prev_total + sub_qty);
            }
        }

        // use it
        running_total.set(input_name, running_total.get(input_name) - needed);
        const prev_total = produced_total.get(input_name) ?? 0;
    }

    // update final total
    running_total.set(name, running_total.get(name) + qty * num_batches);
    produced_total.set(name, (produced_total.get(name) ?? 0) + qty * num_batches);

    return produced_total;
}

// Returns the numeric quantity of ORE and amount of leftover stores generated
// after generating {amt} FUEL, given that some inputs are already available as
// given in available_inputs.
function min_ore_to_make_fuel(recipe_map, available_inputs, amt = 1) {
    let running_total = structuredClone(available_inputs);
    let total_produced = make_more(recipe_map, 'FUEL', amt, running_total);
    const ore_made = total_produced.get('ORE');

    return [ore_made, running_total];
}

async function main(in_file) {
    const file = await fs.open(in_file);
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }

    const recipe_map = await load_file(file);
    const total_ore  = 1_000_000_000_000;
    let running_total = new Map();

    // First see about how much we need for just 1 FUEL. That will help us
    // set lower bound
    const [min_ore_needed, leftovers] = min_ore_to_make_fuel(recipe_map, running_total, 1);
    print (`Need ${min_ore_needed} ORE to make 1 FUEL`);

    // We can make at least this much and probably more FUEL
    let lbound = Math.floor(total_ore / min_ore_needed);
    let ubound = 2 * lbound;

    print (`Can make at least ${lbound} FUEL with ${total_ore} ORE`);

    // Binary search between lower and upper possible bound

    let mid = (ubound + lbound) >> 1;
    while (mid >= lbound && mid < ubound) {
        running_total = new Map();
        const [ore_needed, leftovers] = min_ore_to_make_fuel(recipe_map, running_total, mid);

        // if too much, remove upper part of search space and vice versa
        if (ore_needed > total_ore) {
            // mid is too high
            ubound = mid;
        } else {
            // mid is too low or just barely high enough
            lbound = mid;
        }

        mid = (ubound + lbound) >> 1;
        if (mid == lbound) {
            // ran out of search space
            break;
        }
    }

    print (`I think we can make up to ${mid} FUEL with ${total_ore} ORE`);
}

try {
    const ore_needed = await main(process.argv[2] || '../27/input');
} catch (err) {
    console.error(`Caught exception: "${err.message}"\n${err.stack}\n`);
    process.exit(1);
}

