#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 8, part 2

const fs = require('node:fs');

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

try {
    const in_file = process.argv[2] || '../15/input';

    const file = fs.readFileSync(in_file, { encoding: 'utf8' });
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }
    const pixels = file.replaceAll("\n","");

    const [h, w] = [6, 25]; // from problem definition
    const layer_size = h * w;
    const num_layers = pixels.length / layer_size;

    const indices = [...seq(0, num_layers)];
    let layers = indices.map(i => pixels.slice(layer_size * i, layer_size * (i + 1)));

    const layer_scores = layers.map(layer => [...layer.matchAll(/0/g)].length);

    layers.reverse();

    let out = ""+layers[0];
    for (const l of layers) {
        let str = "";
        for (let i = 0; i < l.length; i++) {
            str = str.concat(l[i] != 2 ? l[i] : out[i]);
        }

        out = str;
    }

    out = out.replaceAll('0', ' ');
    for (let i = 0; i < h; i++) {
        let s = out.slice(i * w, (i + 1) * w);
        print(`${s}`);
    }
} catch (err) {
    console.error(`Caught exception: "${err.message}"\n${err.stack}\n`);
    process.exit(1);
}

