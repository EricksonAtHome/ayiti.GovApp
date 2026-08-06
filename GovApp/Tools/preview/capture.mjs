/**
 * Renders index.html in headless Chrome to produce the images in the README.
 *
 * These are renderings of GovApp's design tokens, not captures of the running
 * app — an iOS app cannot be built or run on Linux, which is where this repo's
 * automation executes.
 *
 *   npm install && node capture.mjs
 *
 * Outputs to ../../../docs/: five PNGs plus walkthrough.mp4 and .gif, both
 * built with ffmpeg from the frame sequence.
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
const ANSWER = `Paspò ou an **pare depi 2 jou**.

Pou vin chèche l:
- Biwo imigrasyon Pòtoprens, Delmas 33
- Lendi a vandredi, 8:00–14:00
- Pote kat idantite ou ak resi a`;

const ASKED = { author: 'citizen', text: QUESTION };
const ANSWERED = { author: 'assistant', text: ANSWER };

/** Applies a patch to the page's preview state and re-renders. */
const set = (page, patch) =>
  page.evaluate((p) => {
    Object.assign(window.GovAppPreview.state, p);
    window.GovAppPreview.render();
  }, patch);

/** Onboarding backgrounds must be in cache before a frame is captured. */
const preloadPhotos = (page) =>
  page.evaluate(
    () =>
      Promise.all(
        window.GovAppPreview.photos.map(
          (src) =>
            new Promise((done) => {
              const img = new Image();
              img.onload = done;
              img.onerror = done;
              img.src = src;
            }),
        ),
      ),
  );

const shoot = async (page, path) => (await page.$('.device')).screenshot({ path });

async function screenshots(page) {
  await page.goto(`${page_url}?screen=onboarding`, { waitUntil: 'load' });
  await preloadPhotos(page);

  for (const slide of [0, 1, 2]) {
    await set(page, { screen: 'onboarding', slide, showProfileOnLastSlide: false });
    await shoot(page, resolve(docs, `screen-onboarding-${slide + 1}.png`));
    console.log(`wrote docs/screen-onboarding-${slide + 1}.png`);
  }

  // Sign-in is captured mid-entry so the masked PIN and enabled button show.
  await set(page, { screen: 'signin', hid: HID, pin: PIN });
  await shoot(page, resolve(docs, 'screen-signin.png'));
  console.log('wrote docs/screen-signin.png');

  await set(page, { screen: 'chat', username: CITIZEN, govURLID: GOV_URL, messages: [] });
  await shoot(page, resolve(docs, 'screen-chat-empty.png'));
  console.log('wrote docs/screen-chat-empty.png');

  await set(page, { messages: [ASKED, ANSWERED] });
  await shoot(page, resolve(docs, 'screen-chat.png'));
  console.log('wrote docs/screen-chat.png');
}

/**
 * The frame script. Each entry is a state patch plus how many frames to hold
 * it, so the recording is deterministic rather than wall-clock dependent.
 */
function storyboard() {
  const beats = [];
  const hold = (frames, patch = {}) => beats.push({ patch, frames });

  // Swipe through onboarding.
  hold(30, {
    screen: 'onboarding',
    slide: 0,
    username: CITIZEN,
    govURLID: GOV_URL,
    showProfileOnLastSlide: true,
    hid: '',
    pin: '',
    messages: [],
    draft: '',
  });
  hold(28, { slide: 1 });
  hold(34, { slide: 2 });

  // Tap "Kontinye".
  hold(10, { screen: 'signin' });
  for (let i = 1; i <= HID.length; i++) hold(2, { hid: HID.slice(0, i) });
  hold(6);
  for (let i = 1; i <= PIN.length; i++) hold(3, { pin: PIN.slice(0, i) });
  hold(10);

  // Tap "Konekte".
  hold(18, { working: true });

  // The chat opens on its empty state: greeting plus suggestion chips.
  hold(34, { screen: 'chat', working: false, messages: [] });

  // Ask GOVTalk a question.
  for (let i = 1; i <= QUESTION.length; i++) hold(1, { draft: QUESTION.slice(0, i) });
  hold(10);
  hold(24, { draft: '', replying: true, messages: [ASKED] });
  hold(54, { replying: false, messages: [ASKED, ANSWERED] });

  return beats;
}

async function walkthrough(page) {
  await rm(frames, { recursive: true, force: true });
  await mkdir(frames, { recursive: true });
  await page.goto(`${page_url}?screen=onboarding`, { waitUntil: 'load' });
  await preloadPhotos(page);

  let index = 0;
  for (const beat of storyboard()) {
    await set(page, beat.patch);
    for (let i = 0; i < beat.frames; i++) {
      await shoot(page, resolve(frames, `${String(index++).padStart(5, '0')}.png`));
    }
  }
  console.log(`captured ${index} frames`);

  await run('ffmpeg', [
    '-y', '-framerate', String(FPS),
    '-i', resolve(frames, '%05d.png'),
    '-vf', 'scale=540:-2',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', '-crf', '23',
    resolve(docs, 'walkthrough.mp4'),
  ]);
  console.log('wrote docs/walkthrough.mp4');

  // A GIF as well, because GitHub renders those inline in a README.
  const palette = resolve(frames, 'palette.png');
  const gifFilters = 'fps=12,scale=270:-1:flags=lanczos';
  await run('ffmpeg', [
    '-y', '-i', resolve(frames, '%05d.png'),
    '-vf', `${gifFilters},palettegen=max_colors=128`, palette,
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
