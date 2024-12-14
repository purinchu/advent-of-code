#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 2, part 2

function loadIntcode() {
    const in_file = scriptArgs[1] || '../03/input';
    return std.loadFile(in_file)
        .replaceAll("\n", ",")
        .split(",")
        .filter(x => x.length > 0)
        .map(x => parseInt(x, 10))
    ;
}

function nextIp(ip, opcode) {
    const ip_tab = [
        1, 4,
        2, 4,
        99, 1
    ];

    for (let i = 0; i < ip_tab.length / 2; i++) {
        if (ip_tab[2*i] == opcode) {
            return ip + ip_tab[2*i+1];
        }
    }

    print (`WARNING: UNDEFINED OPCODE LEN FOR ${opcode} AT ${ip}`);
    return 4;
}

function evaluate(intcode) {
    const debug = false;
    let ip = 0;
    let cur_opcode = 0;
    let last_arith = 0;
    let run = true;

    try {
        while(run) {
            cur_opcode = 0+intcode[ip];
            const ip_str = `[${(""+ip).padStart(6,'0')}]`;

            switch(cur_opcode) {
                case 1: // ADD DEST, SRC1, SRC2
                {
                    const pos1 = 0+intcode[ip + 1];
                    const pos2 = 0+intcode[ip + 2];
                    const dest = 0+intcode[ip + 3];

                    if (debug) {
                        print (`${ip_str}: ADD  [${dest}] <- [${pos1}] + [${pos2}]`);
                    }

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

                    if (debug) {
                        print (`${ip_str}: MUL  [${dest}] <- [${pos1}] * [${pos2}]`);
                    }

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
                    if (debug) {
                        print(`${ip_str}: HLT`);
                    }

                    run = false;

                    break;
                }

                default:
                    throw `Unknown opcode ${cur_opcode}`;
            }

            ip = nextIp(ip, cur_opcode);
        }
    }
    catch (err) {
        print(`Caught exception at ${ip}: ${err}`);
        return [false, 0];
    }

    return [true, intcode[0]];
}

function evaluateWithVerb(intcode, noun, verb) {
    // Problem defines to hot-fix memory values before execution:
    intcode[1] = 0+noun;
    intcode[2] = 0+verb;

    return evaluate(intcode);
}

try {
    const intcode = loadIntcode();
    print(`Loaded intcode of length ${intcode.length}`);

    for (let noun = 0; noun < 100; noun++) {
        print (`Trying noun ${noun}`);
        for (let verb = 0; verb < 100; verb++) {
            const intcode_copy = [...intcode];
            let [result, out] = evaluateWithVerb(intcode_copy, noun, verb);

            if (result && out == 19690720) {
                print (`Need to set noun ${noun} and verb ${verb}`);
                print (`AKA ${100 * noun + verb}`);

                std.exit(0);
            }
        }
    }

    print (`Could not find noun/verb!!`);
    std.exit(1);

} catch (err) {
    std.err.printf("Caught exception %s\n", err.toString());
    std.exit(1);
}

