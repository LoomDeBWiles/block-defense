const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  const results = {
    enemiesSpawn: false,
    enemiesMove: false,
    towerFires: false,
    projectilesHit: false,
    goldIncreases: false,
    hpDecreases: false,
    consoleErrors: [],
    screenshots: []
  };

  // Collect console messages
  page.on('console', msg => {
    console.log(`Browser console [${msg.type()}]:`, msg.text());
    if (msg.type() === 'error' || msg.type() === 'warning') {
      results.consoleErrors.push(`[${msg.type()}] ${msg.text()}`);
    }
  });

  try {
    console.log('Step 1: Navigate to https://block-defense.freesmileguide.com');
    await page.goto('https://block-defense.freesmileguide.com/', { waitUntil: 'networkidle' });

    console.log('Step 2: Wait 15 seconds for WebGL to load');
    await page.waitForTimeout(15000);

    console.log('Step 3: Screenshot - initial state');
    const screenshotPath1 = '/home/ben/projects/game/block-defense/test-screenshots/combat-01-initial.png';
    await page.screenshot({ path: screenshotPath1 });
    results.screenshots.push(screenshotPath1);

    console.log('Step 4: Click Wood button at (40, 680)');
    await page.mouse.click(40, 680);
    await page.waitForTimeout(2000);

    console.log('Step 5: Click grass tile at (400, 300) - upper right area');
    await page.mouse.click(400, 300);
    await page.waitForTimeout(2000);

    console.log('Step 6: Screenshot - after tile click');
    const screenshotPath2 = '/home/ben/projects/game/block-defense/test-screenshots/combat-02-tile-click.png';
    await page.screenshot({ path: screenshotPath2 });
    results.screenshots.push(screenshotPath2);

    console.log('Step 7: Check for Place button');
    const placeButton = await page.locator('button:has-text("Place")').first();
    let placeButtonCount = await placeButton.count();

    console.log(`  Place button count: ${placeButtonCount}`);

    // If no button found, try different coordinates
    if (placeButtonCount === 0) {
      console.log('  No popup found, trying different tile at (250, 250)');
      await page.mouse.click(250, 250);
      await page.waitForTimeout(2000);

      const screenshotPath2b = '/home/ben/projects/game/block-defense/test-screenshots/combat-02b-retry.png';
      await page.screenshot({ path: screenshotPath2b });
      results.screenshots.push(screenshotPath2b);

      placeButtonCount = await placeButton.count();
      console.log(`  Place button count (retry): ${placeButtonCount}`);
    }

    if (placeButtonCount > 0) {
      console.log('  ✓ Place button found, clicking');
      await placeButton.click();
      await page.waitForTimeout(1000);
      console.log('  ✓ Tower placed');
    } else {
      console.log('  ✗ Place button not found after retries');
      // Try clicking by coordinates instead
      console.log('  Attempting to click Place button by coordinates at (640, 400)');
      await page.mouse.click(640, 400);
      await page.waitForTimeout(1000);
    }

    console.log('Step 8: Screenshot - tower placed');
    const screenshotPath3 = '/home/ben/projects/game/block-defense/test-screenshots/combat-03-tower-placed.png';
    await page.screenshot({ path: screenshotPath3 });
    results.screenshots.push(screenshotPath3);

    console.log('Step 9: Click START WAVE button at (1200, 680)');
    await page.mouse.click(1200, 680);
    await page.waitForTimeout(2000);

    console.log('Step 10: Screenshot - wave started');
    const screenshotPath4 = '/home/ben/projects/game/block-defense/test-screenshots/combat-04-wave-started.png';
    await page.screenshot({ path: screenshotPath4 });
    results.screenshots.push(screenshotPath4);

    console.log('Step 11: Monitor combat for 15 seconds (screenshots every 3 seconds)');

    for (let i = 1; i <= 5; i++) {
      await page.waitForTimeout(3000);
      const screenshotPath = `/home/ben/projects/game/block-defense/test-screenshots/combat-05-combat-${i}.png`;
      await page.screenshot({ path: screenshotPath });
      results.screenshots.push(screenshotPath);
      console.log(`  Screenshot ${i}/5 taken`);
    }

    console.log('Step 12: Final screenshot');
    const screenshotPathFinal = '/home/ben/projects/game/block-defense/test-screenshots/combat-06-final.png';
    await page.screenshot({ path: screenshotPathFinal });
    results.screenshots.push(screenshotPathFinal);

    console.log('\nStep 13: Analyze combat behavior');
    console.log('  Note: Visual analysis required from screenshots');
    console.log('  - Check for enemy spawn and movement');
    console.log('  - Check for tower firing projectiles');
    console.log('  - Check for projectile hits');
    console.log('  - Check for gold increase');
    console.log('  - Check for HP decrease if enemies reach castle');

    // Since this is a WebGL/Godot game, we can't easily query game state
    // We'll need to manually review the screenshots
    console.log('\n  Manual review required for:');
    console.log('    1. Do enemies spawn and move along path?');
    console.log('    2. Does tower fire at enemies?');
    console.log('    3. Do projectiles hit enemies?');
    console.log('    4. Does gold increase when enemies die?');
    console.log('    5. Does HP decrease if enemies reach castle?');

  } catch (error) {
    console.error('Test error:', error.message);
    results.consoleErrors.push(`Test error: ${error.message}`);
  } finally {
    await browser.close();
  }

  // Print results
  console.log('\n=== RESULTS ===');
  console.log(`Screenshots taken: ${results.screenshots.length}`);
  results.screenshots.forEach((path, idx) => {
    console.log(`  ${idx + 1}. ${path}`);
  });
  console.log(`Console errors: ${results.consoleErrors.length > 0 ? JSON.stringify(results.consoleErrors, null, 2) : 'None'}`);
  console.log('\n=== MANUAL REVIEW REQUIRED ===');
  console.log('Please review the screenshots to verify:');
  console.log('  1. Enemies spawn and move along path');
  console.log('  2. Tower fires at enemies');
  console.log('  3. Projectiles hit enemies');
  console.log('  4. Gold increases when enemies die');
  console.log('  5. HP decreases if enemies reach castle');
  console.log('');
})();
