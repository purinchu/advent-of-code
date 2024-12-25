#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 7, part 2

class IntcodeSimulator {
    intcode    = 0;
    backup     = [ ];
    ip         = 0;
    insns      = 0;
    run        = true;
    paused     = false;
    name       = 'SGC';

    input      = [ ];
    output     = [ ];
    out_cb     = null;

    debug      = false;
    read_stdin = true;

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
        this.input = input;
        this.output = [ ];
        this.run = true;
        this.paused = false;

        if (this.debug) {
            print(`${this.name}-RESET COMPLETE`);
        }
    }

    loadIntcode(in_file) {
        const file = std.loadFile(in_file)
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

    // returns a [bool, val] combo. The bool is true if the value is valid,
    // false if the machine should pause and retry later.
    readInput() {
        if (this.read_stdin) {
            std.out.printf(`\x1b[45m\x1b[4;30m\x1b[0;93m${this.name}-REQUEST:\x1b[0m ENTER AN INTEGER: `);
            std.out.flush();

            const line = std.in.getline();
            let val = parseInt(line, 10);

            while (Number.isNaN(val)) {
                std.out.printf(`\x1b[1;91m\x1b[47m${this.name}-ERROR: INVALID INTEGER.\x1b[0m REENTER: `);
                std.out.flush();

                val = parseInt(std.in.getline(), 10);
            }

            return [true, val];
        } else {
            if (this.input.length == 0) {
                if (this.debug) {
                    print (`\x1b[1;91m${this.name}\x1b[0m: INPUT QUEUE EMPTY, EXECUTION PAUSED`);
                }

                this.paused = true;
                return [false, 0];
            }

            return [true, this.input.shift()];
        }
    }

    appendToInput(val) {
        this.input.push(val);

        if (this.paused && this.debug) {
            print (`\x1b[1;91m${this.name}\x1b[0m: INPUT RECEIVED, RESUMING`);
        }

        this.paused = false;
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

    readParameter(addr, mode) {
        switch(mode) {
            case 0: return this.intcode[addr]; // position mode
            case 1: return addr;               // immediate mode
        }

        this.trap(`Invalid mode ${mode} reading ${addr}`);
    }

    dbg(ip, op_str, opcode, n) {
        if (!this.debug) {
            return;
        }

        const pmode = [parseInt(op_str[3], 10), parseInt(op_str[2], 10), parseInt(op_str[1], 10)];
        const ip_str = `[${(""+ip).padStart(6,'0')}]`;
        const o = opcode.padEnd(4, ' ');

        std.out.puts (`${this.name}/${ip_str}: ${op_str}/${o} `);

        for (var i = 1; i <= n; i++) {
            if (i == n) {
                std.out.puts (' -> ');
            } else if (i > 1) {
                std.out.puts (' -op- ');
            }

            const parm = this.intcode[this.ip + i];
            if (pmode[i-1] === 1) {
                std.out.puts (`#\x1b[1;36m${parm}\x1b[0m`);
            } else {
                std.out.puts (`[${parm}](\x1b[1;36m${this.intcode[parm]}\x1b[0m)`);
            }
        }

        print (``);
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

        if (this.ip + 3 >= this.intcode.length) {
            this.trap(`SIGSEGV writing to ${dest}`);
        }

        const param1 = this.readParameter(pos1, param_mode_1);
        const param2 = this.readParameter(pos2, param_mode_2);
        const result = fn(param1, param2);

        this.intcode[dest] = result;
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
                this.dbg(this.ip, op_str, 'ADD', 3);
                this.handle_bin_op('ADD', (l,r) => l + r);
                break;
            }

            case 2: { // MUL DEST, SRC1, SRC2
                this.dbg(this.ip, op_str, 'MUL', 3);
                this.handle_bin_op('MUL', (l,r) => l * r);
                break;
            }

            case 3: { // IN DEST
                const dest = this.intcode[this.ip + 1];

                this.dbg(this.ip, op_str, 'IN', 1);

                const [ok, val] = this.readInput();
                if (ok) {
                    this.intcode[dest] = val;
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
                    std.out.puts(`${this.name}-OUTPUT: \x1b[1;32m${out}\x1b[0m\n`);
                }
                break;
            }

            case 5: { // JS SRC TGT (Jump if set)
                const val = this.intcode[this.ip + 1];
                const tgt = this.intcode[this.ip + 2];

                this.dbg(this.ip, op_str, 'JS', 2);

                if (this.ip + 2 >= this.intcode.length) {
                    // overflow of code page
                    this.trap(`SIGSEGV reading memory at ${this.ip}-${this.ip+3}`);
                }

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

                if (this.ip + 2 >= this.intcode.length) {
                    // overflow of code page
                    this.trap(`SIGSEGV reading memory at ${this.ip}-${this.ip+3}`);
                }

                const param1 = this.readParameter(val, param_mode_1);
                const param2 = this.readParameter(tgt, param_mode_2);

                if (param1 === 0) {
                    this.ip = param2;
                    jump_taken = true;
                }

                break;
            }

            case 7: { // LT LPARM, RPARM, DEST
                this.dbg(this.ip, op_str, 'LT', 3);
                this.handle_bin_op('LT', (l,r) => (l < r) ? 1 : 0);
                break;
            }

            case 8: { // EQ LPARM, RPARM, DEST
                this.dbg(this.ip, op_str, 'EQ', 3);
                this.handle_bin_op('EQ', (l,r) => (l === r) ? 1 : 0);
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
                std.err.puts(`Caught exception at ${ip}: "${err.message}"\n${err.stack}\n`);
            } else {
                std.err.puts(`Caught exception at ${ip}: "${err}"\n`);
            }

            return [false, 0];
        }

        return [true, this.intcode[0]];
    }
}

function permutations(vals) {
   if (vals.length === 0) {
       return [];
   }

   if (vals.length === 1) {
       return [vals];
   }

   let resultArr = [];

   for (let i = 0; i < vals.length; i++) {
       const currentElement = vals[i];

       const otherElements = vals.slice(0,i).concat(vals.slice(i+1));
       const swappedPermutation = permutations(otherElements);

       for(let j = 0; j < swappedPermutation.length; j++) {
           resultArr.push([currentElement].concat(swappedPermutation[j]));
       }
   }

   return resultArr;
}

function testPhaseSetting(in_file, phases) {
    const names = ['A', 'B', 'C', 'D', 'E'];
    let amps = names.map((n) => new IntcodeSimulator(in_file, n));

    for (let i = 0; i < phases.length; i++) {
        amps[i].setSimulatedInput(true);
        amps[i].appendToInput(phases[i]);
    }

    for (let i = 0; i < amps.length - 1; i++) {
        amps[i].setOutputCallback(out => amps[i + 1].appendToInput(out));
    }

    let last_output = 0;
    amps[amps.length - 1].setOutputCallback((out) => {
        amps[0].appendToInput(out);
        last_output = out;
    });

    amps[0].appendToInput(0);

    while(!amps[amps.length - 1].isHalted()) {
        for (let i = 0; i < amps.length; i++) {
            if (amps[i].isHalted() || amps[i].isPaused()) {
                continue;
            }

            amps[i].step_insn();
        }

        if(amps.every(x => x.isPaused())) {
            throw new Error("Every amp paused itself!");
        }
    }

    return last_output;
}

try {
    const in_file = scriptArgs[1] || '../13/input';

    const phases = permutations([5, 6, 7, 8, 9]);
    let highest_out = 0;

    for (const p of phases) {
        const out = testPhaseSetting(in_file, p);
        highest_out = Math.max(out, highest_out);
    }

    print(`Highest output seen was ${highest_out}`);
    std.exit(0);

} catch (err) {
    std.err.puts(`Caught exception: "${err.message}"\n${err.stack}\n`);
    std.exit(1);
}

