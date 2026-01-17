const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  const results = {
    initialLoad: false,
    towerPlaced: false,
    waveStarted: false,
    goldEarned: false,
    saveLogsFound: false,
    reloadComplete: false,
    goldPersisted: false,
    wavePersisted: false,
    towersPersisted: false,
    consoleMessages: [],
    consoleErrors: [],
    goldBeforeReload: null,
    goldAfterReload: null,
    waveBeforeReload: null,
    waveAfterReload: null
  };

  // Collect console messages
  page.on('console', msg => {
    const text = msg.text();
    console.log(`Browser console [${msg.type()}]:`, text);
    results.consoleMessages.push(`[${msg.type()}] ${text}`);

    if (msg.type() === 'error' || msg.type() === 'warning') {
      results.consoleErrors.push(`[${msg.type()}] ${text}`);
    }
  });

  try {
    console.log('\n=== PHASE 1: Initial Load and Gameplay ===');
    console.log('Step 1: Navigate to site');
    await page.goto('https://block-defense.freesmileguide.com/', { waitUntil: 'networkidle' });
    results.initialLoad = true;

    console.log('Step 2: Wait 15 seconds for WebGL to load');
    await page.waitForTimeout(15000);

    console.log('Step 3: Take initial screenshot');
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/test-screenshots/save-01-initial.png' });

    // Check if there's any initial gold/stats displayed
    console.log('Step 4: Check initial UI state');
    const bodyText = await page.evaluate(() => document.body.innerText);
    console.log('  Page text includes gold indicator:', bodyText.includes('Gold') || bodyText.includes('gold'));

    console.log('Step 5: Place a tower');
    // Click Wood button at bottom-left
    await page.mouse.click(40, 680);
    await page.waitForTimeout(1000);

    // Click on a valid tile
    await page.mouse.click(250, 350);
    await page.waitForTimeout(2000);

    // Click Place button if popup appears
    const placeButton = await page.locator('button:has-text("Place")').first();
    const placeButtonCount = await placeButton.count();
    if (placeButtonCount > 0) {
      await placeButton.click();
      results.towerPlaced = true;
      console.log('  ✓ Tower placed successfully');
      await page.waitForTimeout(1000);
    } else {
      console.log('  ✗ Could not place tower (no Place button found)');
    }

    console.log('Step 6: Take screenshot after tower placement');
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/test-screenshots/save-02-tower-placed.png' });

    console.log('Step 7: Start wave');
    // Look for Start Wave button
    const startWaveButton = await page.locator('button:has-text("Start Wave")').first();
    const startWaveCount = await startWaveButton.count();
    if (startWaveCount > 0) {
      await startWaveButton.click();
      results.waveStarted = true;
      console.log('  ✓ Wave started');
      await page.waitForTimeout(2000);
    } else {
      console.log('  ✗ Could not start wave (no Start Wave button found)');
    }

    console.log('Step 8: Wait 10 seconds for enemies to spawn and die');
    await page.waitForTimeout(10000);

    console.log('Step 9: Take screenshot showing gold earned');
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/test-screenshots/save-03-gold-earned.png' });

    // Try to extract gold amount from UI
    console.log('Step 10: Extract current gold amount');
    const goldAmount = await page.evaluate(() => {
      // Try to find gold display in UI
      const bodyText = document.body.innerText;
      const goldMatch = bodyText.match(/Gold[:\s]+(\d+)/i) || bodyText.match(/(\d+)\s+Gold/i);
      return goldMatch ? parseInt(goldMatch[1]) : null;
    });
    results.goldBeforeReload = goldAmount;
    console.log(`  Gold before reload: ${goldAmount !== null ? goldAmount : 'Could not detect'}`);

    if (goldAmount !== null && goldAmount > 0) {
      results.goldEarned = true;
    }

    // Extract wave info
    console.log('Step 11: Extract current wave');
    const waveInfo = await page.evaluate(() => {
      const bodyText = document.body.innerText;
      const waveMatch = bodyText.match(/Wave[:\s]+(\d+)/i) || bodyText.match(/(\d+)\s+Wave/i);
      return waveMatch ? parseInt(waveMatch[1]) : null;
    });
    results.waveBeforeReload = waveInfo;
    console.log(`  Wave before reload: ${waveInfo !== null ? waveInfo : 'Could not detect'}`);

    console.log('Step 12: Check console for save-related logs');
    const saveLogs = results.consoleMessages.filter(msg =>
      msg.toLowerCase().includes('save') ||
      msg.toLowerCase().includes('persist') ||
      msg.toLowerCase().includes('localstorage')
    );
    console.log(`  Save-related console messages: ${saveLogs.length}`);
    saveLogs.forEach(log => console.log(`    ${log}`));
    results.saveLogsFound = saveLogs.length > 0;

    // Check localStorage
    console.log('Step 13: Check localStorage before reload');
    const localStorageBefore = await page.evaluate(() => {
      const saveKey = 'block_defense_save';
      const data = localStorage.getItem(saveKey);
      return data ? JSON.parse(data) : null;
    });
    console.log('  localStorage data:', JSON.stringify(localStorageBefore, null, 2));

    console.log('\n=== PHASE 2: Reload and Check Persistence ===');
    console.log('Step 14: Reload page');
    await page.reload({ waitUntil: 'networkidle' });
    results.reloadComplete = true;

    console.log('Step 15: Wait 15 seconds for WebGL to load again');
    await page.waitForTimeout(15000);

    console.log('Step 16: Take screenshot after reload');
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/test-screenshots/save-04-after-reload.png' });

    console.log('Step 17: Check if gold persisted');
    const goldAfterReload = await page.evaluate(() => {
      const bodyText = document.body.innerText;
      const goldMatch = bodyText.match(/Gold[:\s]+(\d+)/i) || bodyText.match(/(\d+)\s+Gold/i);
      return goldMatch ? parseInt(goldMatch[1]) : null;
    });
    results.goldAfterReload = goldAfterReload;
    console.log(`  Gold after reload: ${goldAfterReload !== null ? goldAfterReload : 'Could not detect'}`);

    console.log('Step 18: Check if wave persisted');
    const waveAfterReload = await page.evaluate(() => {
      const bodyText = document.body.innerText;
      const waveMatch = bodyText.match(/Wave[:\s]+(\d+)/i) || bodyText.match(/(\d+)\s+Wave/i);
      return waveMatch ? parseInt(waveMatch[1]) : null;
    });
    results.waveAfterReload = waveAfterReload;
    console.log(`  Wave after reload: ${waveAfterReload !== null ? waveAfterReload : 'Could not detect'}`);

    console.log('Step 19: Check localStorage after reload');
    const localStorageAfter = await page.evaluate(() => {
      const saveKey = 'block_defense_save';
      const data = localStorage.getItem(saveKey);
      return data ? JSON.parse(data) : null;
    });
    console.log('  localStorage data:', JSON.stringify(localStorageAfter, null, 2));

    console.log('Step 20: Analyze persistence behavior');
    // According to PLANMAP_SAVE.md, the game should NOT persist mid-game state
    // It should only persist: unlocked_tiers, highest_wave, total_gold_earned, games_played, games_won, towers_built

    // Expected behavior: gold should reset to starting amount (not persist current session gold)
    // Expected behavior: wave should reset to 1 (not persist current wave)
    // Expected behavior: towers should be cleared (not persist placed towers)

    if (results.goldBeforeReload !== null && results.goldAfterReload !== null) {
      if (results.goldBeforeReload === results.goldAfterReload) {
        console.log('  ⚠ WARNING: Current session gold persisted (expected to reset)');
        results.goldPersisted = true;
      } else {
        console.log('  ✓ Current session gold reset as expected');
        results.goldPersisted = false;
      }
    }

    if (results.waveBeforeReload !== null && results.waveAfterReload !== null) {
      if (results.waveBeforeReload === results.waveAfterReload) {
        console.log('  ⚠ WARNING: Current wave persisted (expected to reset)');
        results.wavePersisted = true;
      } else {
        console.log('  ✓ Current wave reset as expected');
        results.wavePersisted = false;
      }
    }

    // Check if localStorage contains the expected fields
    if (localStorageAfter) {
      const expectedFields = ['version', 'unlocked_tiers', 'highest_wave', 'total_gold_earned', 'games_played', 'games_won', 'towers_built'];
      const hasAllFields = expectedFields.every(field => field in localStorageAfter);
      console.log(`  localStorage has all expected fields: ${hasAllFields}`);

      if (!hasAllFields) {
        const missingFields = expectedFields.filter(field => !(field in localStorageAfter));
        console.log(`  ✗ Missing fields: ${missingFields.join(', ')}`);
      }
    } else {
      console.log('  ✗ No localStorage data found after reload');
    }

  } catch (error) {
    console.error('Test error:', error.message);
    console.error(error.stack);
    results.consoleErrors.push(`Test error: ${error.message}`);
  } finally {
    await browser.close();
  }

  // Print final results
  console.log('\n=== FINAL RESULTS ===');
  console.log(`1. Initial load: ${results.initialLoad ? 'YES' : 'NO'}`);
  console.log(`2. Tower placed: ${results.towerPlaced ? 'YES' : 'NO'}`);
  console.log(`3. Wave started: ${results.waveStarted ? 'YES' : 'NO'}`);
  console.log(`4. Gold earned: ${results.goldEarned ? 'YES' : 'NO'} (${results.goldBeforeReload})`);
  console.log(`5. Save logs found: ${results.saveLogsFound ? 'YES' : 'NO'}`);
  console.log(`6. Reload complete: ${results.reloadComplete ? 'YES' : 'NO'}`);
  console.log(`7. Gold after reload: ${results.goldAfterReload}`);
  console.log(`8. Wave after reload: ${results.waveAfterReload}`);
  console.log(`9. Console errors: ${results.consoleErrors.length > 0 ? JSON.stringify(results.consoleErrors, null, 2) : 'None'}`);

  console.log('\n=== PERSISTENCE ANALYSIS ===');
  console.log('Expected behavior (according to PLANMAP_SAVE.md):');
  console.log('  - Current session gold should NOT persist (should reset to starting amount)');
  console.log('  - Current wave should NOT persist (should reset to 1)');
  console.log('  - Placed towers should NOT persist (should reset to empty grid)');
  console.log('  - Only lifetime stats should persist (total_gold_earned, highest_wave, etc.)');
  console.log('');
  console.log('Actual behavior:');
  console.log(`  - Session gold persisted: ${results.goldPersisted ? 'YES (UNEXPECTED!)' : 'NO (correct)'}`);
  console.log(`  - Current wave persisted: ${results.wavePersisted ? 'YES (UNEXPECTED!)' : 'NO (correct)'}`);

  const hasUnexpectedBehavior = results.goldPersisted || results.wavePersisted;
  const verdict = hasUnexpectedBehavior ? 'BUG FOUND' : 'WORKING AS EXPECTED';
  console.log(`\nVERDICT: ${verdict}`);

  if (!hasUnexpectedBehavior && results.consoleErrors.length === 0) {
    console.log('Save/Load system appears to be working correctly.');
  }
})();
