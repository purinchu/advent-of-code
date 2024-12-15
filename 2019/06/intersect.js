#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 3, part 2

function loadInput() {
    const in_file = scriptArgs[1] || '../05/input';
    const lines = std.loadFile(in_file)
        .split("\n")
        .filter((x) => x.length > 0);
    const wires = lines.map((l) => l.split(','));
    return wires;
}

function isBetween(num, min, max) {
    return num >= min && num <= max;
}

function buildSegments(wire) {
    let x = 0;
    let y = 0;
    let verts = new Map();
    let horiz = new Map();

    for (const w of wire) {
        const dir = w[0];
        const amt = parseInt(w.substring(1), 10);
        let dx, dy = 0;

        switch (dir) {
            case 'R': dx =  amt; dy = 0; break;
            case 'L': dx = -amt; dy = 0; break;
            case 'U': dx = 0; dy = -amt; break;
            case 'D': dx = 0; dy =  amt; break;
        }

        const nx = x + dx, ny = y + dy;
        if (dir === 'U' || dir === 'D') {
            let seg_list = verts.get(x) || [ ]
            seg_list.push([Math.min(y, ny), Math.max(y, ny)]);
            verts.set(x, seg_list);
        } else {
            let seg_list = horiz.get(y) || [ ]
            seg_list.push([Math.min(x, nx), Math.max(x, nx)]);
            horiz.set(y, seg_list);
        }

        x += dx;
        y += dy;
    }

    return [horiz, verts];
}

function traceSegments(wire, imap) {
    let x = 0;
    let y = 0;
    let steps = 0;

    for (const w of wire) {
        const dir = w[0];
        const amt = parseInt(w.substring(1), 10);
        let dx, dy = 0;
        let nx = x, ny = y;

        switch (dir) {
            case 'R': dx =  1; dy =  0; nx += amt; break;
            case 'L': dx = -1; dy =  0; nx -= amt; break;
            case 'U': dx =  0; dy = -1; ny -= amt; break;
            case 'D': dx =  0; dy =  1; ny += amt; break;
        }

        x += dx; y += dy; steps += 1;

        // need to actually touch the intersection for this logic to work. So it's slower
        // by just step 1 by 1 until we find an intersection.
        while (true) {
            const key = `${x}/${y}`;

            if (imap.has(key)) {
                imap.set(key, imap.get(key) + steps);
            }

            if (x == nx && y == ny) {
                break;
            }

            x += dx; y += dy; steps += 1;
        }
    }
}

try {
    const wires = loadInput();
    const [horiz1, verts1] = buildSegments(wires[0]);
    const [horiz2, verts2] = buildSegments(wires[1]);

    const hkeys1 = Array.from(horiz1.keys()).toSorted();
    const hkeys2 = Array.from(horiz2.keys()).toSorted();
    const vkeys1 = Array.from(verts1.keys()).toSorted();
    const vkeys2 = Array.from(verts2.keys()).toSorted();

    let intersects = [ ];

    // search for vertical intersections in the other wires with our
    // horizontal segments
    for (const hseg_key of hkeys1) {
        const hsegs = horiz1.get(hseg_key);

        for (const [x1, x2] of hsegs) {
            for (const vseg_key of vkeys2) {
                if (vseg_key < x1 || vseg_key > x2) {
                    continue;
                }

                const vsegs = verts2.get(vseg_key);

                for (const [y1, y2] of vsegs) {
                    if (isBetween(hseg_key, y1, y2) && isBetween(vseg_key, x1, x2)) {
                        intersects.push([vseg_key, hseg_key]);
                    }
                }
            }
        }
    }

    // now search for horizontal intersections in the other wire compared to
    // vertical segments of the first wire
    for (const vseg_key of vkeys1) {
        const vsegs = verts1.get(vseg_key);

        for (const [y1, y2] of vsegs) {
            for (const hseg_key of hkeys2) {
                if (hseg_key < y1 || hseg_key > y2) {
                    continue;
                }

                const hsegs = horiz2.get(hseg_key);

                for (const [x1, x2] of hsegs) {
                    if (isBetween(vseg_key, x1, x2) && isBetween(hseg_key, y1, y2)) {
                        intersects.push([vseg_key, hseg_key]);
                    }
                }
            }
        }
    }

    const distances = intersects
        .filter(([x, y]) => x != 0 || y != 0)
        .map(([x, y]) => [x, y, Math.abs(x) + Math.abs(y)])
        .toSorted((a, b) => a[2] - b[2]);

    let imap = new Map();
    for (const i of distances) {
        const [x, y, dist] = i;
        const key = `${x}/${y}`;
        imap.set(key, 0);
    }

    // retrace steps to record number of steps required upon reaching
    // intersection
    traceSegments(wires[0], imap);
    traceSegments(wires[1], imap);

    // It is required to give a sort func, otherwise it will string sort
    const steps = Array.from(imap.values()).toSorted((a, b) => a - b);
    print (`Minimum was ${steps[0]}`);

} catch (err) {
    std.err.puts(`Caught exception: "${err.message}"\n${err.stack}\n`);
    std.exit(1);
}

