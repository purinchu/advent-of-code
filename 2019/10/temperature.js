#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 5, part 2

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
        5, 3, // JS (not called if jump taken)
        6, 3, // JC (not called if jump taken)
        7, 4, // LT
        8, 4, // EQ
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

function dbg(intcode, ip, op_str, opcode, n) {
    if (true) {
        const pmode = [parseInt(op_str[3], 10), parseInt(op_str[2], 10), parseInt(op_str[1], 10)];
        const ip_str = `[${(""+ip).padStart(6,'0')}]`;
        const o = opcode.padEnd(4, ' ');

        std.out.puts (`${ip_str}: ${op_str}/${o} `);

        for (var i = 1; i <= n; i++) {
            if (i == n) {
                std.out.puts (' -> ');
            } else if (i > 1) {
                std.out.puts (' -op- ');
            }

            const parm = intcode[ip + i];
            if (pmode[i-1] === 1) {
                std.out.puts (`#\x1b[1;36m${parm}\x1b[0m`);
            } else {
                std.out.puts (`[${parm}](\x1b[1;36m${intcode[parm]}\x1b[0m)`);
            }
        }

        print (``);
    }
}

function evaluate(intcode) {
    const debug = true;
    let ip = 0;
    let cur_opcode = 0;
    let last_arith = 0;
    let run = true;

    try {
        while(run) {
            cur_opcode = intcode[ip];
            const op_str = cur_opcode.toString().padStart(6,'0');
            const ip_str = `[${(""+ip).padStart(6,'0')}]`;
            let jump_taken = false;

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

                    dbg(intcode, ip, op_str, 'ADD', 3);

                    if (ip + 3 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    if (dest >= intcode.length) {
                        throw `SIGSEGV writing to ${dest}`;
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

                    dbg(intcode, ip, op_str, 'MUL', 3);

                    if (ip + 3 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    if (dest >= intcode.length) {
                        throw `SIGSEGV writing to ${dest}`;
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

                    dbg(intcode, ip, op_str, 'IN', 1);

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

                    dbg(intcode, ip, op_str, 'OUT', 1);

                    std.out.puts(`SGC-OUTPUT: \x1b[1;32m${out}\x1b[0m\n`);
                    break;
                }

                case 5: // JS SRC TGT (Jump if set)
                {
                    const val = intcode[ip + 1];
                    const tgt = intcode[ip + 2];

                    dbg(intcode, ip, op_str, 'JS', 2);

                    if (ip + 2 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    const param1 = readParameter(intcode, val, param_mode_1);
                    const param2 = readParameter(intcode, tgt, param_mode_2);

                    if (param1 !== 0) {
                        ip = param2;
                        jump_taken = true;
                    }

                    break;
                }

                case 6: // JC SRC TGT (Jump if clear)
                {
                    const val = intcode[ip + 1];
                    const tgt = intcode[ip + 2];

                    dbg(intcode, ip, op_str, 'JC', 2);

                    if (ip + 2 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    const param1 = readParameter(intcode, val, param_mode_1);
                    const param2 = readParameter(intcode, tgt, param_mode_2);

                    if (param1 === 0) {
                        ip = param2;
                        jump_taken = true;
                    }

                    break;
                }

                case 7: // LT LPARM, RPARM, DEST
                {
                    const pos1 = intcode[ip + 1];
                    const pos2 = intcode[ip + 2];
                    const dest = intcode[ip + 3]; // never imm mode

                    dbg(intcode, ip, op_str, 'LT', 3);

                    if (ip + 3 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    if (dest >= intcode.length) {
                        throw `SIGSEGV writing to ${dest}`;
                    }

                    const param1 = readParameter(intcode, pos1, param_mode_1);
                    const param2 = readParameter(intcode, pos2, param_mode_2);
                    const res = (param1 < param2) ? 1 : 0;

                    intcode[dest] = res;

                    break;
                }

                case 8: // EQ LPARM, RPARM, DEST
                {
                    const pos1 = intcode[ip + 1];
                    const pos2 = intcode[ip + 2];
                    const dest = intcode[ip + 3]; // never imm mode

                    dbg(intcode, ip, op_str, 'EQ', 3);

                    if (ip + 3 >= intcode.length) {
                        // overflow of code page
                        throw `SIGSEGV reading memory at ${ip}-${ip+3}`;
                    }

                    if (dest >= intcode.length) {
                        throw `SIGSEGV writing to ${dest}`;
                    }

                    const param1 = readParameter(intcode, pos1, param_mode_1);
                    const param2 = readParameter(intcode, pos2, param_mode_2);
                    const res = (param1 === param2) ? 1 : 0;

                    intcode[dest] = res;

                    break;
                }

                case 99: // HALT
                {
                    dbg(intcode, ip, op_str, 'HLT', 0);

                    run = false;

                    break;
                }

                default:
                    throw `Unknown opcode ${cur_opcode}`;
            }

            if (!jump_taken) {
                ip = nextIp(ip, cur_opcode);
            }
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

