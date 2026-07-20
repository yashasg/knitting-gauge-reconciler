/**
 * gauge-math.test.js
 * Self-contained tests for the knitting gauge reconciler math.
 *
 * Run: node prototype/tests/gauge-math.test.js
 * Exit 0 = all non-pending tests passed. Exit 1 = one or more failures.
 *
 * Ground truth: .squad/decisions/decisions.md
 *   - Jacquard's six test scenarios (Test Scenarios section)
 *   - Ada's "Corrected Formula Direction" table
 *
 * NOTE on scale names:
 *   - stitchWidthScale is ps/ys: the width produced by the same stitch count.
 *   - computeActStitches uses ys/ps: the cast-on count multiplier.
 *   - Scenario 6's increase spacing is 6 × 32/24 = 8.0 rows.
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ─── Pure math (extracted from prototype/index.html compute()) ──────────────

/**
 * readNumPure — DOM-free analogue of readNum(el, def).
 * Returns `val` if it is a finite positive number; otherwise returns `def`.
 */
function readNumPure(val, def) {
  const v = parseFloat(val);
  return (isFinite(v) && v > 0) ? v : def;
}

/**
 * computeGaugeMath — pure version of compute() with DOM access stripped.
 *
 * Inputs:
 *   ps  = pattern stitches/10cm
 *   pr  = pattern rows/10cm
 *   ys  = your stitches/10cm
 *   yr  = your rows/10cm
 *   patYoke, patBody, patSleeve = pattern section depths in cm
 *   patIncs = pattern increase spacing in rows
 *
 * Returns all intermediate values so tests can assert at any level.
 */
function computeGaugeMath({ ps, pr, ys, yr, patYoke, patBody, patSleeve, patIncs }) {
  // Horizontal: fraction of pattern width produced by same stitch count at your gauge.
  // ps/ys < 1 → your gauge has more stitches/10cm (smaller stitches) → same count makes narrower fabric.
  const stitchWidthScale = ps / ys;

  // Row density ratio: your_row / pattern_row.
  // > 1 → you knit more rows per cm (denser). Used for hero display + increase spacing.
  const rowCountScale = yr / pr;

  // Physical section cm = pattern values (unchanged); row counts adapt to your gauge.
  const actYoke   = patYoke;
  const actBody   = patBody;
  const actSleeve = patSleeve;
  const actYokeRows   = actYoke   * yr / 10;
  const actBodyRows   = actBody   * yr / 10;
  const actSleeveRows = actSleeve * yr / 10;
  // Increase-row spacing: scale by your_row/pattern_row so physical gap is preserved.
  const actIncs   = patIncs   * rowCountScale;

  return {
    stitchWidthScale, rowCountScale,
    actYoke, actBody, actSleeve,
    actYokeRows, actBodyRows, actSleeveRows,
    actIncs
  };
}

/** fmtCm — round to 1 decimal place (mirrors HTML fmtCm). */
function fmtCm(x) { return Math.round(x * 10) / 10; }

/**
 * fmtRows — round to nearest integer, minimum 1 (mirrors HTML fmtRows).
 * Rounding rule: Math.round → half-up (6.5 → 7, 6.4 → 6).
 */
function fmtRows(x) { return Math.max(1, Math.round(x)); }

/** fmtPct — whole-number percentage (mirrors HTML fmtPct). */
function fmtPct(x) { return Math.round(x * 100); }

function loadPrototypeHelper(name) {
  const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
  const match = html.match(new RegExp(`function ${name}\\(scale\\)\\{([\\s\\S]*?)\\n  \\}`));
  const dependencies = html.match(/(const statusBoundaryTolerance[\s\S]*?function isMatch\(scale\)\{[^\n]*\})/);
  if (!match || !dependencies) throw new Error(`Missing prototype helper: ${name}`);
  return new Function('scale', `${dependencies[1]}\n${match[1]}`);
}

const pillFor = loadPrototypeHelper('pillFor');
const pillRowFor = loadPrototypeHelper('pillRowFor');

/**
 * computeActStitches — adjusted cast-on stitch count.
 * Formula: actStitches = patStitches × (ys / ps), then Math.round()
 */
function computeActStitches(ps, ys, patStitches) {
  return Math.round(patStitches * (ys / ps));
}

// ─── Test harness ────────────────────────────────────────────────────────────

let passed = 0;
let failed = 0;
let pendingCount = 0;

/**
 * assertEqual(actual, expected, label, tolerance)
 * tolerance defaults to 1e-9 for floats; pass 0 for strict integer equality.
 */
function assertEqual(actual, expected, label, tolerance = 1e-9) {
  const ok = Math.abs(actual - expected) <= tolerance;
  if (ok) {
    console.log(`  ✓ ${label}`);
    passed++;
  } else {
    console.log(`  ✗ ${label} (expected ${expected}, got ${actual})`);
    failed++;
  }
}

function assertSame(actual, expected, label) {
  if (actual === expected) {
    console.log(`  ✓ ${label}`);
    passed++;
  } else {
    console.log(`  ✗ ${label} (expected ${expected}, got ${actual})`);
    failed++;
  }
}

/** pending — marks a test that is not yet implemented; visible but not failing. */
function pending(label) {
  console.log(`  ⏳ PENDING: ${label}`);
  pendingCount++;
}

function describe(name, fn) {
  console.log(`\n${name}`);
  fn();
}

// ─── Pattern defaults (shared across all scenarios) ──────────────────────────

const PAT = { ps: 32, pr: 24, patYoke: 20, patBody: 50, patSleeve: 45, patIncs: 6 };

// ─── Jacquard Test Scenarios ──────────────────────────────────────────────────

describe('Scenario 1: Perfect Match (32/24 vs 32/24)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 32, yr: 24 });
  assertEqual(r.stitchWidthScale, 1.0,  'stitchWidthScale = 1.0');
  assertEqual(r.rowCountScale,    1.0,  'rowCountScale = 1.0');
  assertEqual(r.actYoke,          20.0, 'actYoke = 20.0 cm');
  assertEqual(r.actBody,          50.0, 'actBody = 50.0 cm');
  assertEqual(r.actSleeve,        45.0, 'actSleeve = 45.0 cm');
  assertEqual(fmtRows(r.actYokeRows),   48,  '20 cm at 24 rows/10 cm = 48 rows', 0);
  assertEqual(fmtRows(r.actBodyRows),   120, '50 cm at 24 rows/10 cm = 120 rows', 0);
  assertEqual(fmtRows(r.actSleeveRows), 108, '45 cm at 24 rows/10 cm = 108 rows', 0);
  assertEqual(r.actIncs,          6.0,  'actIncs = 6.0 rows (exact)');
  assertEqual(fmtRows(r.actIncs), 6,    'fmtRows(actIncs) = 6', 0);
});

describe('Scenario 2: Denser Row Only (32/24 vs 32/32)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 32, yr: 32 });
  assertEqual(r.stitchWidthScale,    1.0,          'stitchWidthScale = 1.0');
  assertEqual(r.rowCountScale,       32 / 24,      'rowCountScale = yr/pr = 1.333…');
  assertEqual(fmtCm(r.actYoke),      20.0,         'actYoke = 20.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actBody),      50.0,         'actBody = 50.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actSleeve),    45.0,         'actSleeve = 45.0 cm (unchanged)', 0);
  assertEqual(fmtRows(r.actYokeRows),   64,        '20 cm at 32 rows/10 cm = 64 rows', 0);
  assertEqual(fmtRows(r.actBodyRows),   160,       '50 cm at 32 rows/10 cm = 160 rows', 0);
  assertEqual(fmtRows(r.actSleeveRows), 144,       '45 cm at 32 rows/10 cm = 144 rows', 0);
  assertEqual(r.actIncs,             6 * (32 / 24),'actIncs = 8.0 rows (exact)');
  assertEqual(fmtRows(r.actIncs),    8,            'fmtRows(actIncs) = 8', 0);
});

describe('Scenario 3: Looser Row Only (32/24 vs 32/20)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 32, yr: 20 });
  assertEqual(r.stitchWidthScale,    1.0,          'stitchWidthScale = 1.0');
  assertEqual(r.rowCountScale,       20 / 24,      'rowCountScale = yr/pr = 0.833…');
  assertEqual(fmtCm(r.actYoke),      20.0,         'actYoke = 20.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actBody),      50.0,         'actBody = 50.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actSleeve),    45.0,         'actSleeve = 45.0 cm (unchanged)', 0);
  assertEqual(fmtRows(r.actYokeRows),   40,        '20 cm at 20 rows/10 cm = 40 rows', 0);
  assertEqual(fmtRows(r.actBodyRows),   100,       '50 cm at 20 rows/10 cm = 100 rows', 0);
  assertEqual(fmtRows(r.actSleeveRows), 90,        '45 cm at 20 rows/10 cm = 90 rows', 0);
  assertEqual(r.actIncs,             6 * (20 / 24),'actIncs = 5.0 rows (exact)');
  assertEqual(fmtRows(r.actIncs),    5,            'fmtRows(actIncs) = 5', 0);
});

describe('Scenario 4: Denser Stitch Only (32/24 vs 36/24)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 36, yr: 24 });
  // stitchWidthScale = ps/ys = 32/36 ≈ 0.889 (matches code and Jacquard scenario 4)
  assertEqual(r.stitchWidthScale, 32 / 36,  'stitchWidthScale = ps/ys = 0.889… (display metric)');
  assertEqual(fmtPct(r.stitchWidthScale), 89, 'fmtPct(stitchWidthScale) = 89%', 0);
  assertEqual(r.rowCountScale,    1.0,      'rowCountScale = 1.0 (row gauge matches)');
  assertEqual(fmtCm(r.actYoke),   20.0,     'actYoke unchanged = 20.0 cm', 0);
  assertEqual(fmtCm(r.actBody),   50.0,     'actBody unchanged = 50.0 cm', 0);
  assertEqual(fmtCm(r.actSleeve), 45.0,     'actSleeve unchanged = 45.0 cm', 0);
  assertEqual(fmtRows(r.actYokeRows),   48,  '20 cm at 24 rows/10 cm = 48 rows', 0);
  assertEqual(fmtRows(r.actBodyRows),   120, '50 cm at 24 rows/10 cm = 120 rows', 0);
  assertEqual(fmtRows(r.actSleeveRows), 108, '45 cm at 24 rows/10 cm = 108 rows', 0);
  assertEqual(fmtRows(r.actIncs), 6,        'fmtRows(actIncs) = 6', 0);
  // adjusted cast-on: ys=36, ps=32, patStitches=128 → 128 × (36/32) = 144
  assertEqual(computeActStitches(32, 36, 128), 144, 'computeActStitches(32, 36, 128) = 144');
});

describe('Scenario 5: Looser Stitch Only / Hisahashisaka\'s Case (32/24 vs 28/24)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 28, yr: 24 });
  // stitchWidthScale is the display width ratio (ps/ys); cast-on uses ys/ps below.
  assertEqual(r.stitchWidthScale, 32 / 28,  'stitchWidthScale = ps/ys = 1.143… (code: wider per count)');
  assertEqual(fmtPct(r.stitchWidthScale), 114, 'fmtPct(stitchWidthScale) = 114%', 0);
  assertEqual(r.rowCountScale,    1.0,      'rowCountScale = 1.0 (row gauge matches)');
  assertEqual(fmtCm(r.actYoke),   20.0,     'actYoke unchanged = 20.0 cm', 0);
  assertEqual(fmtCm(r.actBody),   50.0,     'actBody unchanged = 50.0 cm', 0);
  assertEqual(fmtCm(r.actSleeve), 45.0,     'actSleeve unchanged = 45.0 cm', 0);
  assertEqual(fmtRows(r.actYokeRows),   48,  '20 cm at 24 rows/10 cm = 48 rows', 0);
  assertEqual(fmtRows(r.actBodyRows),   120, '50 cm at 24 rows/10 cm = 120 rows', 0);
  assertEqual(fmtRows(r.actSleeveRows), 108, '45 cm at 24 rows/10 cm = 108 rows', 0);
  assertEqual(fmtRows(r.actIncs), 6,        'fmtRows(actIncs) = 6', 0);
  // adjusted cast-on: ys=28, ps=32, patStitches=128 → 128 × (28/32) = 112
  assertEqual(computeActStitches(32, 28, 128), 112, 'computeActStitches(32, 28, 128) = 112 [hisahashisaka case]');
});

describe('Scenario 6: Both Denser (32/24 vs 36/32)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 36, yr: 32 });
  assertEqual(r.stitchWidthScale, 32 / 36,      'stitchWidthScale = ps/ys = 0.889…');
  assertEqual(r.rowCountScale,    32 / 24,      'rowCountScale = yr/pr = 1.333…');
  assertEqual(fmtCm(r.actYoke),   20.0,         'actYoke = 20.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actBody),   50.0,         'actBody = 50.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actSleeve), 45.0,         'actSleeve = 45.0 cm (unchanged)', 0);
  assertEqual(fmtRows(r.actYokeRows),   64,     '20 cm at 32 rows/10 cm = 64 rows', 0);
  assertEqual(fmtRows(r.actBodyRows),   160,    '50 cm at 32 rows/10 cm = 160 rows', 0);
  assertEqual(fmtRows(r.actSleeveRows), 144,    '45 cm at 32 rows/10 cm = 144 rows', 0);
  // actIncs = 6 × (32/24) = 8.0
  assertEqual(r.actIncs,          6 * (32 / 24),'actIncs = 8.0 rows (exact)');
  assertEqual(fmtRows(r.actIncs), 8,            'fmtRows(actIncs) = 8', 0);
  // adjusted cast-on: ys=36, ps=32, patStitches=128 → 128 × (36/32) = 144
  assertEqual(computeActStitches(32, 36, 128), 144, 'computeActStitches(32, 36, 128) = 144');
});

// ─── Edge Cases ───────────────────────────────────────────────────────────────

describe('Edge: readNumPure fallback to defaults', () => {
  const DEF = 32;
  assertEqual(readNumPure(32, DEF),   32,  'valid positive int → returned as-is');
  assertEqual(readNumPure(0, DEF),    DEF, 'zero → fallback to default');
  assertEqual(readNumPure(-5, DEF),   DEF, 'negative → fallback to default');
  assertEqual(readNumPure('abc', DEF),DEF, 'NaN string → fallback to default');
  assertEqual(readNumPure('', DEF),   DEF, 'empty string → fallback to default');
  assertEqual(readNumPure(0.1, DEF),  0.1, 'small positive float → returned');
});

describe('Edge: very large drift — row gauge 2× denser (yr = 2 × pr)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 32, yr: 48 });
  assertEqual(r.rowCountScale,   2.0,  'rowCountScale = 2.0');
  assertEqual(fmtCm(r.actYoke),  20.0, 'actYoke = 20.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actBody),  50.0, 'actBody = 50.0 cm (unchanged)', 0);
  assertEqual(fmtRows(r.actIncs),12,   'fmtRows(actIncs) = 12', 0);
});

describe('Edge: very large drift — row gauge 2× looser (yr = pr / 2)', () => {
  const r = computeGaugeMath({ ...PAT, ys: 32, yr: 12 });
  assertEqual(r.rowCountScale,   0.5,  'rowCountScale = 0.5');
  assertEqual(fmtCm(r.actYoke),  20.0, 'actYoke = 20.0 cm (unchanged)', 0);
  assertEqual(fmtCm(r.actBody),  50.0, 'actBody = 50.0 cm (unchanged)', 0);
  assertEqual(fmtRows(r.actIncs), 3,   'fmtRows(actIncs) = 3', 0);
});

describe('Edge: fmtRows rounding boundary cases', () => {
  // Math.round in JS rounds half-up (0.5 → 1, 6.5 → 7, not 6)
  assertEqual(fmtRows(6.5), 7, 'fmtRows(6.5) = 7  [half-up rounding]', 0);
  assertEqual(fmtRows(6.4), 6, 'fmtRows(6.4) = 6  [rounds down]', 0);
  assertEqual(fmtRows(6.6), 7, 'fmtRows(6.6) = 7  [rounds up]', 0);
  assertEqual(fmtRows(0.4), 1, 'fmtRows(0.4) = 1  [minimum clamp to 1]', 0);
  assertEqual(fmtRows(0.0), 1, 'fmtRows(0.0) = 1  [minimum clamp to 1]', 0);
});

describe('Edge: status bands are symmetric at exact boundaries', () => {
  assertSame(pillFor(0.971).label, 'Match', 'stitch -2.9% is Match');
  assertSame(pillFor(1.029).label, 'Match', 'stitch +2.9% is Match');
  assertSame(pillFor(0.97).label, 'Tighter than pattern', 'stitch -3% enters middle band');
  assertSame(pillFor(1.03).label, 'Looser than pattern', 'stitch +3% enters middle band');
  assertSame(pillFor(0.901).label, 'Tighter than pattern', 'stitch -9.9% stays in middle band');
  assertSame(pillFor(1.099).label, 'Looser than pattern', 'stitch +9.9% stays in middle band');
  assertSame(pillFor(0.90).label, 'Much tighter', 'stitch -10% enters Much band');
  assertSame(pillFor(1.10).label, 'Much looser', 'stitch +10% enters Much band');
  assertSame(pillRowFor(0.97).label, 'Looser than pattern', 'row -3% enters middle band');
  assertSame(pillRowFor(1.03).label, 'Denser than pattern', 'row +3% enters middle band');
  assertSame(pillRowFor(0.901).label, 'Looser than pattern', 'row -9.9% stays in middle band');
  assertSame(pillRowFor(1.099).label, 'Denser than pattern', 'row +9.9% stays in middle band');
  assertSame(pillRowFor(0.90).label, 'Much looser', 'row -10% enters Much band');
  assertSame(pillRowFor(1.10).label, 'Much denser', 'row +10% enters Much band');
});

describe('Edge: floating-point precision — perfect match gives exact input values', () => {
  const r = computeGaugeMath({ ps: 32, pr: 24, ys: 32, yr: 24,
                                patYoke: 20, patBody: 50, patSleeve: 45, patIncs: 6 });
  // Matched gauge leaves physical section dimensions unchanged.
  assertEqual(r.actYoke,   20.0, 'actYoke === 20.0 exactly (no 19.999...)');
  assertEqual(r.actBody,   50.0, 'actBody === 50.0 exactly');
  assertEqual(r.actSleeve, 45.0, 'actSleeve === 45.0 exactly');
  assertEqual(r.actIncs,    6.0, 'actIncs === 6.0 exactly');
});

describe('Edge: floating-point precision — stitch match, arbitrary row drift', () => {
  // Non-power-of-2 gauge values that are prone to FP representation errors
  const r = computeGaugeMath({ ps: 30, pr: 22, ys: 30, yr: 22,
                                patYoke: 18.5, patBody: 52.3, patSleeve: 41.0, patIncs: 7 });
  assertEqual(r.actYoke,  18.5,     'actYoke = 18.5 exactly (no FP drift)');
  assertEqual(r.actBody,  52.3,     'actBody = 52.3 exactly');
  assertEqual(r.actIncs,   7.0,     'actIncs = 7.0 exactly');
});

// ─── Summary ─────────────────────────────────────────────────────────────────

console.log(`\nRESULTS: ${passed} passed, ${failed} failed, ${pendingCount} pending.`);
process.exit(failed > 0 ? 1 : 0);
