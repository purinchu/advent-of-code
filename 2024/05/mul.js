const fs = require('node:fs')

function read_muls(data)
{
    const re = /mul\([0-9]{1,3},[0-9]{1,3}\)/g;
    return Array.from(data.matchAll(re));
}

try {
    const fname = (process.argv.length >= 3) ? process.argv[2] : '../05/input';
    const data = fs.readFileSync(fname, 'utf8');

    const mul_list = read_muls(data);
    let sum_of_products = 0;
    for (m of mul_list) {
        // result is mul(xxx,xxx). Remove the mul( and ) and split on comma to get numbers
        const baseNums = m[0].replace("mul(","").replace(")","").split(',').map(x => x*1);
        sum_of_products += baseNums[0] * baseNums[1];
    }

    console.log(sum_of_products);
} catch (err) {
    console.error(err);
}
