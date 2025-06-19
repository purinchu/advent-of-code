#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 13, part 2

const fs = require('node:fs');
const process = require('node:process');
const { spawnSync } = require('node:child_process');
const { Buffer } = require('node:buffer');

function * seq(start = 0, end = Infinity, step = 1) {
    for(let i = start; i < end; i += step) {
        yield i;
    }
}

function print(msg) {
    console.log(msg);
}

class IntcodeSimulator {
    intcode    = 0;
    backup     = [ ];
    ip         = 0;
    base       = 0;
    insns      = 0;
    run        = true;
    paused     = false;
    name       = 'SGC';

    input      = [ ];
    output     = [ ];
    in_cb      = null;
    out_cb     = null;

    debug      = true;
    read_stdin = false;

    constructor(filename, name = 'SGC', debug = false) {
        this.backup = this.loadIntcode(filename);
        this.debug = debug;
        this.name  = name;

        if (debug) {
            print(`Loaded intcode of length ${this.backup.length}`);
        }

        this.reset();
    }

    reset(input = [ ]) {
        this.intcode = Array.from(this.backup);
        this.ip = 0;
        this.base = 0;
        this.input = input;
        this.output = [ ];
        this.run = true;
        this.paused = false;

        if (this.debug) {
            print(`${this.name}-RESET COMPLETE`);
        }
    }

    loadIntcode(in_file) {
        const file = fs.readFileSync(in_file, { encoding: 'utf8' });
        if (!file) {
            this.trap(`Unknown file ${in_file}!`);
        }

        return file.replaceAll("\n", ",")
            .split(",")
            .filter(x => x.length > 0)
            .map(x => parseInt(x, 10))
    }

    trap(msg) {
        throw new Error(`${this.name}: ${msg} at ${this.ip}`);
    }

    // to actually change the input, use reset()
    setSimulatedInput(use_sim_input) {
        this.read_stdin = !use_sim_input;
    }

    setName(n) {
        this.name = n;
    }

    isHalted() {
        return !this.run;
    }

    isPaused() {
        return this.paused;
    }

    resume() {
        this.paused = false;
    }

    poke(loc, val) {
        this.intcode[loc] = val;
    }

    // returns a [bool, val] combo. The bool is true if the value is valid,
    // false if the machine should pause and retry later.
    readInput() {
        if (!this.in_cb && !this.read_stdin) {
            if (this.input.length == 0) {
                if (this.debug) {
                    print (`\x1b[1;91m${this.name}\x1b[0m: INPUT QUEUE EMPTY, EXECUTION PAUSED`);
                }

                this.paused = true;
                return [false, 0];
            }

            return [true, this.input.shift()];
        }

        let line = '';
        if (this.read_stdin) {
            print(`\x1b[45m\x1b[4;30m\x1b[0;93m${this.name}-REQUEST:\x1b[0m ENTER AN INTEGER: `);

            line = this.trap(`Interactive input is unhandled`);
        } else {
            // use callback
            line = this.in_cb(this);
        }

        let val = parseInt(line, 10);

        while (Number.isNaN(val) && this.read_stdin) {
            print(`\x1b[1;91m\x1b[47m${this.name}-ERROR: INVALID INTEGER.\x1b[0m REENTER: `);

            val = parseInt(this.trap(`Interactive input is unhandled`),
                10);
        }

        return [true, val];
    }

    appendToInput(val) {
        this.input.push(val);

        if (this.paused && this.debug) {
            print (`\x1b[1;91m${this.name}\x1b[0m: INPUT RECEIVED, RESUMING`);
        }

        this.paused = false;
    }

    setInputCallback(cb) {
        this.in_cb = cb;
        this.read_stdin = false;
        this.input = [ ];
    }

    resultOutput() {
        return this.output;
    }

    setOutputCallback(cb) {
        this.out_cb = cb;
    }

    nextIp(ip, opcode) {
        const ip_tab = [
            1, 4, // ADD
            2, 4, // MUL
            3, 2, // IN
            4, 2, // OUT
            5, 3, // JS (not called if jump taken)
            6, 3, // JC (not called if jump taken)
            7, 4, // LT
            8, 4, // EQ
            9, 2, // ARB (adj rel. base)
            99, 1 // HLT
        ];

        for (let i = 0; i < ip_tab.length / 2; i++) {
            if (ip_tab[2*i] == opcode) {
                return ip + ip_tab[2*i+1];
            }
        }

        print (`${this.name}: WARNING: UNDEFINED OPCODE LEN FOR ${opcode} AT ${ip}`);
        return 4;
    }

    ensureMemoryReady(new_addr) {
        if (new_addr < this.intcode.length) {
            return;
        }

        const old_len = this.intcode.length;
        this.intcode.length = new_addr + 1;
        for (let i = old_len; i < this.intcode.length; i++) {
            this.intcode[i] = 0;
        }
    }

    readParameter(addr, mode) {
        let dest = 0;
        switch(mode) {
            case 0: dest = addr; break;             // position mode
            case 1: return addr;                    // immediate mode
            case 2: dest = this.base + addr; break; // relative mode
            default: this.trap(`Invalid mode ${mode} reading ${addr}`);
        }

        if (dest < 0) {
            this.trap(`Attempted to read into negative memory. ${addr}(${mode}) = ${dest}`);
        }

        this.ensureMemoryReady(dest);

        const res = this.intcode[dest];
        if (Number.isNaN(res)) {
            this.trap(`Value read at addr=${addr}(mode=${mode}) is denormal!`);
        }

        return this.intcode[dest];
    }

    // mode is never 'immediate' but can be the other possible modes
    writeParameter(addr, mode, val) {
        let dest = 0;
        switch(mode) {
            case 0: dest = addr; break;             // position mode
            case 1: this.trap(`Illegal write mode at ${addr}`); // immediate mode
            case 2: dest = this.base + addr; break; // relative mode
            default: this.trap(`Invalid mode ${mode} reading ${addr}`);
        }

        if (dest < 0) {
            this.trap(`Attempted to write into negative memory. ${addr}(${mode}) = ${dest}`);
        }

        this.ensureMemoryReady(dest);

        this.intcode[dest] = val;
    }

    dbg(ip, op_str, opcode, n) {
        if (!this.debug) {
            return;
        }

        const ops = new Map([
            ['1', '+'],
            ['2', '*'],
            ['7', '<'],
            ['8', '=='],
        ]);

        const pmode = [parseInt(op_str[3], 10), parseInt(op_str[2], 10), parseInt(op_str[1], 10)];
        const ip_str = `[${(""+ip).padStart(6,'0')}]`;
        const o = opcode.padEnd(4, ' ');

        const puts = function(text) { process.stdout.write(text) };
        puts(`${this.name}/${ip_str}: ${op_str}/${o} `);

        for (var i = 1; i <= n; i++) {
            if (i == n) {
                puts (' -> ');
            } else if (i > 1) {
                const op = ops.get(op_str[5]) || '-op-';
                puts (` ${op} `);
            }

            const parm = this.intcode[this.ip + i];
            if (pmode[i-1] === 1) {
                puts (`#\x1b[1;36m${parm}\x1b[0m`);
            } else if (pmode[i-1] === 0) {
                puts (`[${parm}](\x1b[1;36m${this.intcode[parm]}\x1b[0m)`);
            } else {
                puts (`[${parm}+\x1b[1;34m${this.base}\x1b[0m][\x1b[1;36m${this.intcode[this.base + parm]}\x1b[0m]`);
            }
        }

        puts ("\n");
    }

    // handles all forms that read two params and write to the third
    handle_bin_op(name, fn) {
        // dest is never in imm mode
        const cur_opcode = this.intcode[this.ip];
        const [pos1, pos2, dest] = this.intcode.slice(this.ip + 1, this.ip + 4);

        const op_str = cur_opcode.toString().padStart(6,'0');
        const param_mode_1 = parseInt(op_str[3], 10);
        const param_mode_2 = parseInt(op_str[2], 10);
        const param_mode_3 = parseInt(op_str[1], 10);

        const param1 = this.readParameter(pos1, param_mode_1);
        const param2 = this.readParameter(pos2, param_mode_2);

        this.dbg(this.ip, op_str, name, 3);

        const result = fn(param1, param2);

        this.writeParameter(dest, param_mode_3, result);
    }

    step_insn() {
        if (this.paused) {
            return;
        }

        this.insns += 1;

        let cur_opcode = this.intcode[this.ip];
        const op_str = cur_opcode.toString().padStart(6,'0');
        let jump_taken = false;

        const param_mode_1 = parseInt(op_str[3], 10);
        const param_mode_2 = parseInt(op_str[2], 10);
        const param_mode_3 = parseInt(op_str[1], 10);

        // remove param flags from inst opcode
        cur_opcode = parseInt(op_str.slice(4), 10);

        switch(cur_opcode) {
            case 1: { // ADD DEST, SRC1, SRC2
                // will handle dbg
                this.handle_bin_op('ADD', (l,r) => l + r);
                break;
            }

            case 2: { // MUL DEST, SRC1, SRC2
                // will handle dbg
                this.handle_bin_op('MUL', (l,r) => l * r);
                break;
            }

            case 3: { // IN DEST
                const dest = this.intcode[this.ip + 1];

                this.dbg(this.ip, op_str, 'IN', 1);

                const [ok, val] = this.readInput();
                if (ok) {
                    if (dest < 0) {
                        this.trap(`Attempted to write to negative memory, op=${op_str}, dest=${dest}`);
                    }

                    this.writeParameter(dest, param_mode_1, val);
                }
                break;
            }

            case 4: { // OUT SRC
                const dest = this.intcode[this.ip + 1];
                const out = this.readParameter(dest, param_mode_1);

                this.dbg(this.ip, op_str, 'OUT', 1);

                if (this.out_cb != null) {
                    this.out_cb(out);
                } else {
                    this.output.push(out);
                }

                if (this.read_stdin) {
                    print(`${this.name}-OUTPUT: \x1b[1;32m${out}\x1b[0m`);
                }
                break;
            }

            case 5: { // JS SRC TGT (Jump if set)
                const val = this.intcode[this.ip + 1];
                const tgt = this.intcode[this.ip + 2];

                this.dbg(this.ip, op_str, 'JS', 2);

                const param1 = this.readParameter(val, param_mode_1);
                const param2 = this.readParameter(tgt, param_mode_2);

                if (param1 !== 0) {
                    this.ip = param2;
                    jump_taken = true;
                }

                break;
            }

            case 6: { // JC SRC TGT (Jump if clear)
                const val = this.intcode[this.ip + 1];
                const tgt = this.intcode[this.ip + 2];

                this.dbg(this.ip, op_str, 'JC', 2);

                const param1 = this.readParameter(val, param_mode_1);
                const param2 = this.readParameter(tgt, param_mode_2);

                if (param1 === 0) {
                    this.ip = param2;
                    jump_taken = true;
                }

                break;
            }

            case 7: { // LT LPARM, RPARM, DEST
                // will handle dbg
                this.handle_bin_op('LT', (l,r) => (l < r) ? 1 : 0);
                break;
            }

            case 8: { // EQ LPARM, RPARM, DEST
                // will handle dbg
                this.handle_bin_op('EQ', (l,r) => (l === r) ? 1 : 0);
                break;
            }

            case 9: { // ABP PARM
                const offset = this.intcode[this.ip + 1];
                const param1 = this.readParameter(offset, param_mode_1);

                this.dbg(this.ip, op_str, 'ABP', 1);

                if (param_mode_2 != '0') {
                    this.trap(`Unsupported param mode ${param_mode_2} for ABP`);
                }

                this.base = this.base + param1;
                break;
            }

            case 99: { // HALT
                this.dbg(this.ip, op_str, 'HLT', 0);

                this.run = false;
                break;
            }

            default:
                this.trap(`Unknown opcode ${cur_opcode}`);
        }

        if (!jump_taken && !this.isPaused()) {
            this.ip = this.nextIp(this.ip, cur_opcode);
        }
    }

    evaluate() {
        try {
            this.run = true;

            while(this.run) {
                this.step_insn();
            }
        }
        catch (err) {
            const ip = this.ip;
            if (err instanceof Error) {
                console.error(`Caught exception at ${ip}: "${err.message}"\n${err.stack}\n`);
            } else {
                console.error(`Caught exception at ${ip}: "${err}"\n`);
            }

            return [false, 0];
        }

        return [true, this.output];
    }
}

try {
    const in_file = process.argv[2] || '../25/input';
    const intcode = new IntcodeSimulator(in_file, 'SGC');

    print("Loaded the intcode simulator");

    let board = new Map(); // maps "x,y" str to [0..4] to represent game state
    let out_buf = []; // buffers output until 3 elems are read in
    let score = 0;
    let last_ball_pos = [];
    let ball_pos = [];
    let dir = 'R';
    let paddle_pos = [];

//  let in_buf = Buffer.alloc(128); // HACK Used for sync user input
    const in_cb = (sim) => {
        let result = 0; // default neutral

        // first, print out game board
        print("\x1b[H\x1b[2J"); // clear screen
        for (let row = 0; row <= max_y; row++) {
            let row_str = '';
            for (let col = 0; col <= max_x; col++) {
                let cell_ch = '';
                const key = [col, row].join(',');

                switch (board.get(key)) {
                    case 0: cell_ch = ' '; break;
                    case 1: cell_ch = 'B'; break;
                    case 2: cell_ch = '`'; break;
                    case 3: cell_ch = '-'; break;
                    case 4: cell_ch = 'o'; break;
                }

                row_str += cell_ch;
            }

            print(row_str);
        }

        print(''); // empty line
        const score_out = score.toString().padStart(6, '0');
        print(`------ Score: ${score_out}, Ball: ${ball_pos} (${dir}) / Paddle: ${paddle_pos} ------- \n`);

        spawnSync('sleep', ['0.07s']);
//      fs.writeSync(process.stdout.fd, "Press Enter to advance");
//      const bytesRead = fs.readSync(1, in_buf);

        if (dir == 'R' && paddle_pos[0] < ball_pos[0]) {
            result = 1; // go right
        } else if (dir == 'L' && paddle_pos[0] > ball_pos[0]) {
            result = -1; // go left
        }

        return result;
    };

    let max_x = 0;
    let max_y = 0;

    const out_cb = (out) => {
        out_buf.push(out);
        if (out_buf.length === 3) {
            const [x, y, clr] = out_buf;
            const key = [x, y].join(',');

            if (x === -1 && y === 0) {
                // score update
                score = clr;
            } else {
                // update game state
                max_x = Math.max(max_x, x);
                max_y = Math.max(max_y, y);
                board.set(key, clr);
            }

            // check where ball and paddle are now at
            if (clr == 3) {
                paddle_pos = [x, y];
            }

            if (clr == 4) {
                last_ball_pos = ball_pos;
                ball_pos = [x, y];
                if (last_ball_pos.length > 0) {
                    dir = (last_ball_pos[0] > ball_pos[0]) ? 'L' : 'R'; // check x dir
                }
            }

            out_buf = [];
        }
    };

    intcode.setInputCallback(in_cb);
    intcode.setOutputCallback(out_cb);
    intcode.poke(0, 2); // this gives infinite quarters for the loaded arcade game

    spawnSync ('tput', ['smcup']); // set alt screen
    let res = 0, out = 0;
    try {
        [res, out] = intcode.evaluate();
    }
    finally {
        spawnSync ('tput', ['rmcup']); // clear alt screen
    }

    if (out_buf.length !== 0) {
        throw new Error(`Output was of improper length, some left over! ${out_buf}`);
    }

    print(`Result: ${res}. Output: ${out}. Final score: ${score}`);
} catch (err) {
    console.error(`Caught exception: "${err.message}"\n${err.stack}\n`);
    process.exit(1);
}
