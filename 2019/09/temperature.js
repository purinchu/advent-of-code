#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 5, part 1

function loadIntcode() {
    const in_file = scriptArgs[1] || '../09/input';
    return std.loadFile(in_file)
        .replaceAll("\n", ",")
        .split(",")
        .filter(x => x.length > 0)
        .map(x => parseInt(x, 10))
    ;
}

function nextIp(ip, opcode) {
    const ip_tab = [
        1, 4, // ADD
        2, 4, // MUL
        3, 2, // IN
        4, 2, // OUT
        99, 1 // HLT
    ];

    for (let i = 0; i < ip_tab.length / 2; i++) {
        if (ip_tab[2*i] == opcode) {
            return ip + ip_tab[2*i+1];
        }
    }

    print (`WARNING: UNDEFINED OPCODE LEN FOR ${opcode} AT ${ip}`);
    return 4;
}

function readParameter(intcode, addr, mode) {
    if (mode === 0) {
        // position mode (i.e. indirect)
        return intcode[addr];
    }
    if (mode === 1) {
        // immediate mode
        return addr;
    }
    throw `Invalid mode ${mode} reading ${addr}`;
}

function evaluate(intcode) {
    const debug = false;
    let ip = 0;
    let cur_opcode = 0;
    let last_arith = 0;
    let run = true;

    try {
        while(run) {
            cur_opcode = intcode[ip];
            const op_str = cur_opcode.toString().padStart(6,'0');
            const ip_str = `[${(""+ip).padStart(6,'0')}]`;

            if (op_str.length !== 6) {
                throw `Opcode string ${op_str} wrong size`;
            }

            const param_mode_1 = parseInt(op_str[3], 10);
            const param_mode_2 = parseInt(op_str[2], 10);
            const param_mode_3 = parseInt(op_str[1], 10);

            // remove param flags from inst opcode
            cur_opcode = parseInt(op_str.slice(4), 10);

            switch(cur_opcode) {
                case 1: // ADD DEST, SRC1, SRC2
                {
                    const pos1 = intcode[ip + 1];
                    const pos2 = intcode[ip + 2];
                    const dest = intcode[ip + 3]; // never imm mode

                    if (debug) {
                        print (`${ip_str}: ${op_str}/ADD  [${dest}] <- [${pos1}] + [${pos2}]`);
                    }

                    if (ip + 3 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    if (Math.max(Math.max(pos1, pos2), dest) >= intcode.length) {
                        // overflow of opcode referent page
                        throw `SIGSEGV reading indirect memory from one of ${pos1}/${pos2}/${dest}`;
                    }

                    const param1 = readParameter(intcode, pos1, param_mode_1);
                    const param2 = readParameter(intcode, pos2, param_mode_2);
                    const sum = param1 + param2;

                    intcode[dest] = sum;
                    last_arith = sum;

                    break;
                }

                case 2: // MUL DEST, SRC1, SRC2
                {
                    const pos1 = intcode[ip + 1];
                    const pos2 = intcode[ip + 2];
                    const dest = intcode[ip + 3]; // never imm mode

                    if (debug) {
                        print (`${ip_str}: ${op_str}/MUL  [${dest}] <- [${pos1}] * [${pos2}]`);
                    }

                    if (ip + 3 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    if (Math.max(Math.max(pos1, pos2), dest) >= intcode.length) {
                        // overflow of opcode referent page
                        throw `SIGSEGV reading indirect memory from one of ${pos1}/${pos2}/${dest}`;
                    }

                    const param1 = readParameter(intcode, pos1, param_mode_1);
                    const param2 = readParameter(intcode, pos2, param_mode_2);
                    const prod = param1 * param2;

                    intcode[dest] = prod;
                    last_arith = prod;

                    break;
                }

                case 3: // IN DEST
                {
                    const dest = intcode[ip + 1];

                    if (debug) {
                        print(`${ip_str}: ${op_str}/IN  [${dest}]`);
                    }

                    std.out.printf(`\x1b[45m\x1b[4;30m\x1b[0;93mSGC-REQUEST:\x1b[0m ENTER AN INTEGER: `);
                    std.out.flush();

                    const line = std.in.getline();
                    let val = parseInt(line, 10);

                    while (Number.isNaN(val)) {
                        std.out.printf(`\x1b[1;91m\x1b[47mSGC-ERROR: INVALID INTEGER.\x1b[0m REENTER: `);
                        std.out.flush();

                        val = parseInt(std.in.getline(), 10);
                    }

                    intcode[dest] = val;
                    break;
                }

                case 4: // OUT SRC
                {
                    const dest = intcode[ip + 1];
                    const out = readParameter(intcode, dest, param_mode_1);

                    if (debug) {
                        print(`${ip_str}: ${op_str}/OUT  [${dest}]`);
                    }

                    std.out.puts(`SGC-OUTPUT: \x1b[1;32m${out}\x1b[0m\n`);
                    break;
                }

                case 99: // HALT
                {
                    if (debug) {
                        print(`${ip_str}: ${op_str}/HLT`);
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
        if (err instanceof Error) {
            std.err.puts(`Caught exception at ${ip}: "${err.message}"\n${err.stack}\n`);
        } else {
            std.err.puts(`Caught exception at ${ip}: "${err}"\n`);
        }

        return [false, 0];
    }

    return [true, intcode[0]];
}

try {
    const intcode = loadIntcode();
    print(`Loaded intcode of length ${intcode.length}`);

    let [result, out] = evaluate(intcode);

    if (result) {
        print (`SGC-COMPLETE`);
        std.exit(0);
    }

    print (`SGC-ERROR UNKNOWN`);
    std.exit(1);

} catch (err) {
    std.err.puts(`Caught exception: "${err.message}"\n${err.stack}\n`);
    std.exit(1);
}

