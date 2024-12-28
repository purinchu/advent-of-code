#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 8, part 1

function * seq(start = 0, end = Infinity, step = 1) {
    for(let i = start; i < end; i += step) {
        yield i;
    }
}

function trap(msg) {
    throw new Error(msg);
}

try {
    const in_file = scriptArgs[1] || '../15/input';

    const file = std.loadFile(in_file)
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }
    const pixels = file.replaceAll("\n","");

    const [h, w] = [6, 25]; // from problem definition
    const layer_size = h * w;
    const num_layers = pixels.length / layer_size;

    const indices = [...seq(0, num_layers)];
    const layers = indices.map(i => pixels.slice(layer_size * i, layer_size * (i + 1)));

    const layer_scores = layers.map(layer => [...layer.matchAll(/0/g)].length);

    let min_idx = layer_size;
    let min = layer_size;
    for (const idx of indices) {
        if (layer_scores[idx] < min) {
            min = layer_scores[idx];
            min_idx = idx;
        }
    }

    print(`Layer ${min_idx} has the fewest zeroes.`);

    const zero_layer = layers[min_idx];
    const num_one = Array.from(zero_layer.matchAll(/1/g)).length;
    const num_two = Array.from(zero_layer.matchAll(/2/g)).length;

    print(`This layer has a product of ${num_one} * ${num_two} = ${num_one  * num_two}`);

    std.exit(0);

} catch (err) {
    std.err.puts(`Caught exception: "${err.message}"\n${err.stack}\n`);
    std.exit(1);
}

