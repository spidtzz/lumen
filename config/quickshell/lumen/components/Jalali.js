.pragma library
// Gregorian <-> Shamsi (Jalali) conversion, from the UI demo's date picker.

function div(a, b) { return ~~(a / b); }
function mod(a, b) { return a - ~~(a / b) * b; }

const JB = [-61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178];

function jalCal(jy) {
    let bl = JB.length, gy = jy + 621, leapJ = -14, jp = JB[0], jm, jump = 0, leap, leapG, march, n, i;
    for (i = 1; i < bl; i += 1) {
        jm = JB[i]; jump = jm - jp;
        if (jy < jm) break;
        leapJ = leapJ + div(jump, 33) * 8 + div(mod(jump, 33), 4);
        jp = jm;
    }
    n = jy - jp;
    leapJ = leapJ + div(n, 33) * 8 + div(mod(n, 33) + 3, 4);
    if (mod(jump, 33) === 4 && jump - n === 4) leapJ += 1;
    leapG = div(gy, 4) - div((div(gy, 100) + 1) * 3, 4) - 150;
    march = 20 + leapJ - leapG;
    if (jump - n < 6) n = n - jump + div(jump + 4, 33) * 33;
    leap = mod(mod(n + 1, 33) - 1, 4);
    if (leap === -1) leap = 4;
    return { leap: leap, gy: gy, march: march };
}

function g2d(gy, gm, gd) {
    let d = div((gy + div(gm - 8, 6) + 100100) * 1461, 4) + div(153 * mod(gm + 9, 12) + 2, 5) + gd - 34840408;
    return d - div(div(gy + 100100 + div(gm - 8, 6), 100) * 3, 4) + 752;
}

function d2g(jdn) {
    let j = 4 * jdn + 139361631;
    j = j + div(div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
    const i = div(mod(j, 1461), 4) * 5 + 308;
    const gd = div(mod(i, 153), 5) + 1, gm = mod(div(i, 153), 12) + 1;
    return { y: div(j, 1461) - 100100 + div(8 - gm, 6), m: gm, d: gd };
}

function d2j(jdn) {
    let gy = d2g(jdn).y, jy = gy - 621, r = jalCal(jy), jdn1f = g2d(gy, 3, r.march), k = jdn - jdn1f;
    if (k >= 0) {
        if (k <= 185) return { y: jy, m: 1 + div(k, 31), d: mod(k, 31) + 1 };
        k -= 186;
    } else {
        jy -= 1; k += 179;
        if (r.leap === 1) k += 1;
    }
    return { y: jy, m: 7 + div(k, 30), d: mod(k, 30) + 1 };
}

const MONTHS_FA = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
const MONTHS_EN = ["Farvardin", "Ordibehesht", "Khordad", "Tir", "Mordad", "Shahrivar", "Mehr", "Aban", "Azar", "Dey", "Bahman", "Esfand"];
const DIGITS_FA = "۰۱۲۳۴۵۶۷۸۹";

function faDigits(v) { return String(v).replace(/\d/g, x => DIGITS_FA.charAt(+x)); }

// fromDate(new Date()) -> { y, m, d }
function fromDate(date) {
    return d2j(g2d(date.getFullYear(), date.getMonth() + 1, date.getDate()));
}

// "16 Aban 1405" or, with persian = true, "۱۶ آبان ۱۴۰۵"
function format(date, persian) {
    const j = fromDate(date);
    return persian ? faDigits(j.d) + " " + MONTHS_FA[j.m - 1] + " " + faDigits(j.y)
                   : j.d + " " + MONTHS_EN[j.m - 1] + " " + j.y;
}
