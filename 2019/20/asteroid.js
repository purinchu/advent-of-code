#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 10, part 2

const fs = require('node:fs');
const process = require('node:process');

function * seq(start = 0, end = Infinity, step = 1) {
    for(let i = start; i < end; i += step) {
        yield i;
    }
}

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

function idx_from_pos(x, y, w) {
    return y * w + x;
}

function num_visible_from(field, x1, y1, w, h) {
    // sort other asteroids by distance so we can look for potential
    // occlusions first
    let dist_array = [];

    const ast = [x1, y1];

    for (const other of field) {
        const [x2, y2] = other;
        const distance = Math.abs(x2-x1) + Math.abs(y2-y1);

        if (distance == 0) {
            continue;
        }

        dist_array[distance] ||= [];
        dist_array[distance].push([x2, y2]);
    }

    // forEach is deliberate to skip undefined entries in this sparse array
    let blocked = new Set();
    let visible = new Set();

    dist_array.forEach((vals, dist) => {
        for (const v of vals) {
            const [x2, y2] = v;
            let [dx, dy] = [x2 - x1, y2 - y1];
            const div = gcd(Math.abs(dx), Math.abs(dy));

            dx /= div;
            dy /= div;

            if (blocked.has(idx_from_pos(x2, y2, w))) {
                continue;
            }

            visible.add(idx_from_pos(x2, y2, w));

            let y = y2;
            let x = x2;

            while ((x >= 0) && (x < w) && (y >= 0) && (y < h)) {
                blocked.add(idx_from_pos(x, y, w));
                x += dx;
                y += dy;
            }
        }
    });

    return visible.size;
}

try {
    const in_file = process.argv[2] || '../19/input';

    const file = fs.readFileSync(in_file, { encoding: 'utf8' });
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }

    let puzzle = new Set();

    const rows = file.split("\n").filter(x => x.length > 0);
    const w = rows[0].length;
    const h = rows.length;

    for (let y = 0; y < rows.length; y++) {
        const row = rows[y];
        for (let x = 0; x < row.length; x++) {
            if (row[x] == '#') {
                puzzle.add([x, y]);
            }
        }
    }

    let best = undefined;
    let count_max = 0;
    let max_ast = 0;

    for (const ast of puzzle) {
        const num_visible = num_visible_from(puzzle, ast[0], ast[1], w, h);
        if (num_visible > max_ast) {
            max_ast = num_visible;
            best = ast;
            count_max = 0;
        }

        if (num_visible == max_ast) {
            count_max += 1;
        }
    }

    if (count_max == 1) {
        print (`There were ${max_ast} asteroids visible from ${best}`);
    } else {
        throw new Error(`Found improper number of maxes ${count_max}`);
    }

    // Bin up asteroids by the angle they would be in from us.
    let dest_ast = new Map();
    for (const ast of puzzle) {
        if (ast == best) {
            continue;
        }

        let [dx, dy] = [ast[0] - best[0], ast[1] - best[1]];

        // Must be done before GCD
        const dist = Math.abs(dx) + Math.abs(dy);

        // This ensures we group into the right cluster of asteroids
        const gcd_val = gcd(Math.abs(dx), Math.abs(dy));
        dx /= gcd_val;
        dy /= gcd_val;

        const key = [dx, dy].join(',');
        if (!dest_ast.has(key)) {
            dest_ast.set(key, []);
        }

        let list = dest_ast.get(key);
        const trig = Math.atan2(dy, dx);

        let quad = 'IV';
        if (dx >= 0 && dy < 0) {
            quad = 'I';
        } else if (dx >= 0 && dy >= 0) {
            quad = 'IV';
        } else if (dx < 0 && dy < 0) {
            quad = 'II';
        } else {
            quad = 'III'
        }

        list.push([ast[0], ast[1], dx, dy, dist, trig, quad]);
    }

    for (const val of dest_ast.values()) {
        // sort by x[4], the distance field, nearest to farthest
        val.sort((a, b) => a[4] - b[4]);
    }

    const asteroids_to_waporize = dest_ast.values().reduce(
        (acc, v) => acc + v.length, 0);

    print (`There are ${asteroids_to_waporize} to vaporize`);

    let dest_keys = Array.from(dest_ast.keys());
    dest_keys.sort((a, b) => {
        let [dx_a, dy_a] = a.split(',').map(x => Number.parseInt(x, 10));
        let [dx_b, dy_b] = b.split(',').map(x => Number.parseInt(x, 10));

        // Deliberately confused x/y to reflect a rotation
        const ang_a = Math.atan2(dx_a, dy_a);
        const ang_b = Math.atan2(dx_b, dy_b);

        return ang_b - ang_a;
    });

    let num_waporized = 0;
    let lucky_x = 0;
    let lucky_y = 0;

    while (num_waporized < asteroids_to_waporize) {
        for (const k of dest_keys) {
            let ast_in_beam = dest_ast.get(k);
            if (ast_in_beam.length == 0) {
                continue;
            }

            const [x, y, dx, dy, dist, trig, quad] = ast_in_beam.shift();
            num_waporized += 1;
            if (asteroids_to_waporize < 40) {
                print (`${num_waporized}: KA-PLOW! Vaporized asteroid at ${x},${y}`);
            }

            if (num_waporized == 200) {
                [lucky_x, lucky_y] = [x, y];
            }

            if (num_waporized == asteroids_to_waporize) {
                print (`Everything has been blown up`);
                break;
            }
        }
    }

    if (num_waporized >= 200) {
        print (`Place your bets. Asteroid ${lucky_x * 100 + lucky_y} was the 200th!`);
    }
} catch (err) {
    console.error(`Caught exception: "${err.message}"\n${err.stack}\n`);
    process.exit(1);
}

