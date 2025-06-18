#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 12, part 1

const fs = require('node:fs');
const process = require('node:process');

function trap(msg) {
    throw new Error(msg);
}

function print(msg) {
    console.log(msg);
}

try {
    const in_file = process.argv[2] || '../21/input';

    const file = fs.readFileSync(in_file, { encoding: 'utf8' });
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }

    const num_steps = parseInt(process.argv[3] || '10');

    let puzzle = new Set();
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

    const pad3_to_3 = (vec) => {
        const strs = Array.from(vec).map(x => (""+x).padStart(3, " "));
        return strs.join(", ");
    };

    let show_state = () => {
        for (let i = 0; i < positions.length; i++) {
            const [x, y, z] = positions[i];
            const [dx, dy, dz] = velocities[i];

            print(`pos=< ${pad3_to_3(positions[i])}>, vel=< ${pad3_to_3(velocities[i])}>`);
        }

        print(''); // extra line for spacing
    };

    print(`After 0 steps:`);
    show_state();

    for (let i = 0; i < num_steps; i++) {
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

    }

    print(`After ${num_steps} steps:`);
    show_state();

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

