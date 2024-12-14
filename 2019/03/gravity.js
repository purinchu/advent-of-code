#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 2, part 1

function loadIntcode() {
    const in_file = scriptArgs[1] || '../03/input';
    return std.loadFile(in_file)
        .replaceAll("\n", ",")
        .split(",")
        .filter(x => x.length > 0)
        .map(x => parseInt(x, 10))
    ;
}

try {
    const intcode = loadIntcode();
    print(`Loaded intcode of length ${intcode.length}`);

    let ip = 0;
    let cur_opcode = 0;
    let last_arith = 0;
    let run = true;

    // Problem defines to hot-fix memory values before execution:
    intcode[1] = 12;
    intcode[2] = 2;
    print(`**** HOTFIX APPLIED ****`);

    while(run) {
        cur_opcode = 0+intcode[ip];
        const ip_str = `[${(""+ip).padStart(6,'0')}]`;

        switch(cur_opcode) {
            case 1: // ADD DEST, SRC1, SRC2
            {
                const pos1 = 0+intcode[ip + 1];
                const pos2 = 0+intcode[ip + 2];
                const dest = 0+intcode[ip + 3];

                print (`${ip_str}: ADD  [${dest}] <- [${pos1}] + [${pos2}]`);

                if (ip + 3 >= intcode.length) {
                    // overflow of code page
                    throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                }

                if (Math.max(Math.max(pos1, pos2), dest) >= intcode.length) {
                    // overflow of opcode referent page
                    throw `SIGSEGV reading indirect memory from one of ${pos1}/${pos2}/${dest}`;
                }

                const sum = intcode[pos1] + intcode[pos2];
                intcode[dest] = sum;
                last_arith = sum;

                break;
            }

            case 2: // MUL DEST, SRC1, SRC2
            {
                const pos1 = intcode[ip + 1];
                const pos2 = intcode[ip + 2];
                const dest = intcode[ip + 3];

                print (`${ip_str}: MUL  [${dest}] <- [${pos1}] * [${pos2}]`);

                if (ip + 3 >= intcode.length) {
                    // overflow of code page
                    throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                }

                if (Math.max(Math.max(pos1, pos2), dest) >= intcode.length) {
                    // overflow of opcode referent page
                    throw `SIGSEGV reading indirect memory from one of ${pos1}/${pos2}/${dest}`;
                }

                const prod = intcode[pos1] * intcode[pos2];
                intcode[dest] = prod;
                last_arith = prod;

                break;
            }

            case 99: // HALT
            {
                print(`${ip_str}: HLT`);
                run = false;
                break;
            }

            default:
                throw `Unknown opcode ${cur_opcode} at ${ip}`;
        }

        ip += 4; // Step ahead by 4 after a successful opcode operation
    }

    print(`Done at IP: ${ip}. Last arithmetic result: ${last_arith}`);
    print(`Code state: ${intcode.join(",")}`);
    std.exit(0);

} catch (err) {
    std.err.printf("Caught exception %s\n", err.toString());
    std.exit(1);
}

