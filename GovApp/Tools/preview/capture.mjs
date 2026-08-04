/**
 * Renders index.html in headless Chrome to produce the images in the README.
 *
 * These are renderings of GovApp's design tokens, not captures of the running
 * app — an iOS app cannot be built or run on Linux, which is where this repo's
 * automation executes.
 *
 *   npm install && node capture.mjs
 *
 * Outputs to ../../../docs/: three PNGs plus walkthrough.mp4 (built with
 * ffmpeg from the frame sequence).
 */

import { execFile } from 'node:child_process';
import { mkdir, rm, readdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { promisify } from 'node:util';

import puppeteer from 'puppeteer-core';

const run = promisify(execFile);
const here = dirname(fileURLToPath(import.meta.url));
const page_url = pathToFileURL(resolve(here, 'index.html')).href;
const docs = resolve(here, '../../../docs');
const frames = resolve(here, '.frames');

const CHROME = process.env.CHROME_PATH ?? '/usr/local/bin/google-chrome';
const DEVICE = { width: 393, height: 852, deviceScaleFactor: 2 };
const FPS = 20;

const CITIZEN = 'Jean Baptiste';
const GOV_URL = 'gov.ayiti.io/jbaptiste';
const HID = 'HT-4417-9082';
const PIN = '4471';
const QUESTION = 'Kilè paspò mwen an ap pare?';
const ANSWER = 'Paspò ou an pare depi 2 jou. Ou ka vin chèche l nan biwo '
  + 'imigrasyon Pòtoprens, lendi a vandredi, 8:00–14:00.';

/** Applies a patch to the page's preview state and re-renders. */
const set = (page, patch) =>
  page.evaluate((p) => {
    Object.assign(window.GovAppPreview.state, p);
    window.GovAppPreview.render();
  }, patch);

/** Sign-in is captured mid-entry so the masked PIN and enabled button show. */
const seeds = {
  welcome: { username: CITIZEN, govURLID: GOV_URL },
  signin: { hid: HID, pin: PIN },
  chat: { username: CITIZEN, govURLID: GOV_URL },
};

async function screenshots(page) {
  for (const [screen, seed] of Object.entries(seeds)) {
    await page.goto(`${page_url}?screen=${screen}`, { waitUntil: 'load' });
    await set(page, seed);
    const element = await page.$('.device');
    await element.screenshot({ path: resolve(docs, `screen-${screen}.png`) });
    console.log(`wrote docs/screen-${screen}.png`);
  }
}

/**
 * The frame script. Each entry is a state patch plus how many frames to hold
 * it, so the recording is deterministic rather than wall-clock dependent.
 */
function storyboard() {
  const beats = [];
  const hold = (frames, patch = {}) => beats.push({ patch, frames });

  hold(24, { screen: 'welcome', username: CITIZEN, govURLID: GOV_URL });

  // Tap "login".
  hold(10, { screen: 'signin', hid: '', pin: '' });
  for (let i = 1; i <= HID.length; i++) hold(2, { hid: HID.slice(0, i) });
  hold(6);
  for (let i = 1; i <= PIN.length; i++) hold(3, { pin: PIN.slice(0, i) });
  hold(10);

  // Tap "Konekte".
  hold(18, { working: true });
  hold(26, {
    screen: 'chat',
    working: false,
    messages: [{ author: 'assistant', text: `Bonjou ${CITIZEN}! Kijan m ka ede w jodi a?` }],
  });

  // Type a question.
  for (let i = 1; i <= QUESTION.length; i++) hold(1, { draft: QUESTION.slice(0, i) });
  hold(10);

  // Send it.
  hold(22, {
    draft: '',
    replying: true,
    messages: [
      { author: 'assistant', text: `Bonjou ${CITIZEN}! Kijan m ka ede w jodi a?` },
      { author: 'citizen', text: QUESTION },
    ],
  });
  hold(46, {
    replying: false,
    messages: [
      { author: 'assistant', text: `Bonjou ${CITIZEN}! Kijan m ka ede w jodi a?` },
      { author: 'citizen', text: QUESTION },
      { author: 'assistant', text: ANSWER },
    ],
  });

  return beats;
}

async function walkthrough(page) {
  await rm(frames, { recursive: true, force: true });
  await mkdir(frames, { recursive: true });
  await page.goto(`${page_url}?screen=welcome`, { waitUntil: 'load' });

  let index = 0;
  for (const beat of storyboard()) {
    await set(page, beat.patch);
    const element = await page.$('.device');
    for (let i = 0; i < beat.frames; i++) {
      await element.screenshot({
        path: resolve(frames, `${String(index++).padStart(5, '0')}.png`),
      });
    }
  }
  console.log(`captured ${index} frames`);

  const mp4 = resolve(docs, 'walkthrough.mp4');
  await run('ffmpeg', [
    '-y', '-framerate', String(FPS),
    '-i', resolve(frames, '%05d.png'),
    '-vf', 'scale=540:-2',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', '-crf', '23',
    mp4,
  ]);
  console.log('wrote docs/walkthrough.mp4');

  // A GIF as well, because GitHub renders those inline in a README.
  const palette = resolve(frames, 'palette.png');
  const gifFilters = 'fps=12,scale=270:-1:flags=lanczos';
  await run('ffmpeg', [
    '-y', '-i', resolve(frames, '%05d.png'),
    '-vf', `${gifFilters},palettegen=max_colors=64`, palette,
  ]);
  await run('ffmpeg', [
    '-y', '-framerate', String(FPS),
    '-i', resolve(frames, '%05d.png'), '-i', palette,
    '-lavfi', `${gifFilters}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3`,
    '-loop', '0', resolve(docs, 'walkthrough.gif'),
  ]);
  console.log('wrote docs/walkthrough.gif');

  await rm(frames, { recursive: true, force: true });
}

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: 'new',
  args: ['--no-sandbox', '--force-device-scale-factor=2', '--hide-scrollbars'],
});

try {
  await mkdir(docs, { recursive: true });
  const page = await browser.newPage();
  await page.setViewport(DEVICE);
  await screenshots(page);
  await walkthrough(page);
  console.log((await readdir(docs)).join('\n'));
} finally {
  await browser.close();
}
