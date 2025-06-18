#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 12, part 2

const fs = require('node:fs');
const process = require('node:process');

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

try {
    const in_file = process.argv[2] || '../23/input';

    const file = fs.readFileSync(in_file, { encoding: 'utf8' });
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }

    let positions = new Array();  // Array of 3-elem arrays that represent a moon position
    let velocities = new Array(); // Array of 3-elem arrays that represent a moon position
    let pairs = new Array();

    const rows = file.split("\n");
    for (const row of rows) {
        if (row == "") {
            continue;
        }

        const pos_str = row.replace("<", "").replace(">", "");
        const pos_elems = row.split(',')
            .map(x => parseInt(x.slice(x.indexOf('=') + 1)));
        positions.push(pos_elems);
        velocities.push([0, 0, 0]);
    }

    for (let i = 0; i < positions.length; i++) {
        // don't compare a moon to itself or double-count a pair, we want only unique pairs
        for (var j = i + 1; j < positions.length; j++) {
            pairs.push([i, j]);
        }
    }

    const pad3_to_4 = (vec) => {
        const strs = Array.from(vec).map(x => (""+x).padStart(4, " "));
        return strs.join(", ");
    };

    let show_state = () => {
        for (let i = 0; i < positions.length; i++) {
            const [x, y, z] = positions[i];
            const [dx, dy, dz] = velocities[i];

            print(`pos=< ${pad3_to_4(positions[i])}>, vel=< ${pad3_to_4(velocities[i])}>`);
        }

        print(''); // extra line for spacing
    };

    print(`After 0 steps:`);
    show_state();

    // We need to find repeating cycles in our universe of moons. Conveniently,
    // the 3 dimensions are completely independent computationally, and even
    // more "conveniently", the 3 dimensions' cycles will be independent and
    // all start from the initial state by M-A-G-I-C...
    let cur_step = 0, cycles_needed = 3;
    let cycle_at = [ 0, 0, 0 ];

    // only positions are copied, initial state of all velocities is 0
    const initial_state = structuredClone(positions);

    while (cycles_needed > 0) {
        for (const [i, j] of pairs) {
            // apply gravity to update velocity
            const pos_l = positions[i];
            const pos_r = positions[j];

            const dx = (pos_r[0] > pos_l[0]) ? 1 : ((pos_r[0] == pos_l[0]) ? 0 : -1);
            const dy = (pos_r[1] > pos_l[1]) ? 1 : ((pos_r[1] == pos_l[1]) ? 0 : -1);
            const dz = (pos_r[2] > pos_l[2]) ? 1 : ((pos_r[2] == pos_l[2]) ? 0 : -1);

            velocities[i][0] += dx; velocities[j][0] -= dx;
            velocities[i][1] += dy; velocities[j][1] -= dy;
            velocities[i][2] += dz; velocities[j][2] -= dz;
        }

        for (let i = 0; i < positions.length; i++) {
            // apply velocity to update position
            for (var k = 0; k < 3; k++) {
                positions[i][k] += velocities[i][k];
            }
        }

        cur_step++; // must happen before cycle check for count to be right

        // check for cycles
        for (let dim = 0; dim < 3; dim++) {
            if (cycle_at[dim] > 0) {
                continue;
            }

            let cycle_found = true;
            for (let i = 0; i < positions.length; i++) {
                if (positions[i][dim] !== initial_state[i][dim] || velocities[i][dim] !== 0) {
                    cycle_found = false;
                    break;
                }
            }

            if (cycle_found) {
                cycles_needed--;
                cycle_at[dim] = cur_step;
            }
        }
    }

    print(`After ${cur_step} steps:`);
    show_state();

    const lcm1 = lcm(cycle_at[0], cycle_at[1]);
    const lcm2 = lcm(lcm1, cycle_at[2]);
    print (`Cycles were ${cycle_at}, lcm=${lcm2}`);

    // calculate total energy by summing abs value of positions and velocities
    // this must be done as a sum of products of the pos-sum and velo-sums
    const energies_p = positions.map (pos => pos.reduce((sum, val) => { return sum + Math.abs(val); }, 0));
    const energies_k = velocities.map(vel => vel.reduce((sum, val) => { return sum + Math.abs(val); }, 0));

    let energy_t = 0;
    for (let i = 0; i < energies_p.length; i++) {
        energy_t += energies_p[i] * energies_k[i];
    }

    print (`Total energy was ${energy_t}`);

} catch (err) {
    console.error(`Caught exception: "${err.message}"\n${err.stack}\n`);
    process.exit(1);
}

