const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function testTowerPlacement() {
  console.log('Starting Block Defense tower placement test v2...');

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 }
  });

  const page = await context.newPage();

  const screenshotDir = '/home/ben/projects/game/block-defense/test-screenshots';
  if (!fs.existsSync(screenshotDir)) {
    fs.mkdirSync(screenshotDir, { recursive: true });
  }

  const results = {
    success: false,
    steps: [],
    screenshots: [],
    errors: [],
    observations: []
  };

  try {
    // Step 1: Navigate to the game
    console.log('Step 1: Navigating to game URL...');
    await page.goto('https://block-defense.freesmileguide.com', {
      waitUntil: 'networkidle',
      timeout: 30000
    });
    results.steps.push('Navigated to game URL');

    // Step 2: Wait for game to load
    console.log('Step 2: Waiting for game to load...');
    await page.waitForTimeout(4000);

    // Step 3: Take initial screenshot
    console.log('Step 3: Taking initial screenshot...');
    const screenshot1 = path.join(screenshotDir, 'v2-01-initial.png');
    await page.screenshot({ path: screenshot1, fullPage: false });
    results.screenshots.push(screenshot1);
    results.steps.push('Initial screenshot captured');

    // Check page content
    const bodyText = await page.textContent('body');
    const hasGold = bodyText.includes('Gold:');
    const hasHP = bodyText.includes('HP:');
    const hasWave = bodyText.includes('WAVE');
    results.observations.push(`Found Gold UI: ${hasGold}, HP UI: ${hasHP}, Wave UI: ${hasWave}`);

    // Step 4: Try to find and click the Wood button
    console.log('Step 4: Looking for Wood tower button...');

    // Try to find button by text
    let woodButtonClicked = false;
    try {
      const woodButton = await page.locator('button:has-text("Wood")').first();
      if (await woodButton.isVisible({ timeout: 2000 })) {
        const boundingBox = await woodButton.boundingBox();
        results.observations.push(`Found Wood button at: ${JSON.stringify(boundingBox)}`);
        await woodButton.click();
        woodButtonClicked = true;
        results.steps.push('Clicked Wood button via locator');
        console.log('Clicked Wood button via locator');
      }
    } catch (e) {
      console.log('Wood button not found with text locator:', e.message);
      results.observations.push(`Wood button locator failed: ${e.message}`);
    }

    // Fallback: try clicking at bottom left where button should be
    if (!woodButtonClicked) {
      console.log('Trying to click Wood button at estimated position...');
      await page.mouse.click(40, 680); // Adjusted to bottom-left area
      results.steps.push('Clicked at estimated Wood button position (40, 680)');
    }

    await page.waitForTimeout(1000);

    const screenshot2 = path.join(screenshotDir, 'v2-02-after-wood-click.png');
    await page.screenshot({ path: screenshot2, fullPage: false });
    results.screenshots.push(screenshot2);
    console.log(`Saved: ${screenshot2}`);

    // Step 5: Click on the canvas/game grid
    console.log('Step 5: Clicking on game grid...');

    // Try to find the canvas element
    const canvas = await page.locator('canvas').first();
    if (await canvas.isVisible()) {
      const canvasBounds = await canvas.boundingBox();
      results.observations.push(`Canvas found at: ${JSON.stringify(canvasBounds)}`);

      // Click in the center-left area of the canvas (should be grass)
      const clickX = canvasBounds.x + canvasBounds.width * 0.35;
      const clickY = canvasBounds.y + canvasBounds.height * 0.45;
      results.observations.push(`Clicking canvas at: (${clickX}, ${clickY})`);

      await page.mouse.click(clickX, clickY);
      results.steps.push(`Clicked on canvas at (${Math.round(clickX)}, ${Math.round(clickY)})`);
    } else {
      // Fallback position
      await page.mouse.click(350, 320);
      results.steps.push('Clicked at fallback position (350, 320)');
    }

    await page.waitForTimeout(1500);

    const screenshot3 = path.join(screenshotDir, 'v2-03-after-grid-click.png');
    await page.screenshot({ path: screenshot3, fullPage: false });
    results.screenshots.push(screenshot3);
    console.log(`Saved: ${screenshot3}`);

    // Step 6: Check for any popup or dialog
    console.log('Step 6: Checking for popup...');

    const afterClickText = await page.textContent('body');
    const hasUpgrade = afterClickText.includes('Upgrade');
    const hasScrap = afterClickText.includes('Scrap');
    const hasPlace = afterClickText.includes('Place');
    results.observations.push(`After click - Found Upgrade: ${hasUpgrade}, Scrap: ${hasScrap}, Place: ${hasPlace}`);

    // Try to find and click any visible buttons
    const allButtons = await page.locator('button').all();
    results.observations.push(`Found ${allButtons.length} buttons on page`);

    for (let i = 0; i < allButtons.length; i++) {
      const button = allButtons[i];
      if (await button.isVisible()) {
        const text = await button.textContent();
        const boundingBox = await button.boundingBox();
        results.observations.push(`Button ${i}: "${text}" at ${JSON.stringify(boundingBox)}`);
      }
    }

    // Look for Upgrade or Place button
    let actionButtonClicked = false;
    try {
      const upgradeButton = await page.locator('button:has-text("Upgrade")').first();
      if (await upgradeButton.isVisible({ timeout: 1000 })) {
        await upgradeButton.click();
        actionButtonClicked = true;
        results.steps.push('Clicked Upgrade button');
        console.log('Clicked Upgrade button');
      }
    } catch (e) {
      console.log('Upgrade button not found');
    }

    if (!actionButtonClicked) {
      try {
        const placeButton = await page.locator('button:has-text("Place")').first();
        if (await placeButton.isVisible({ timeout: 1000 })) {
          await placeButton.click();
          actionButtonClicked = true;
          results.steps.push('Clicked Place button');
          console.log('Clicked Place button');
        }
      } catch (e) {
        console.log('Place button not found');
      }
    }

    await page.waitForTimeout(1000);

    const screenshot4 = path.join(screenshotDir, 'v2-04-after-action.png');
    await page.screenshot({ path: screenshot4, fullPage: false });
    results.screenshots.push(screenshot4);
    console.log(`Saved: ${screenshot4}`);

    // Step 7: Final state check
    console.log('Step 7: Checking final state...');
    await page.waitForTimeout(1000);

    const finalText = await page.textContent('body');
    const finalGoldMatch = finalText.match(/Gold:\s*💰\s*(\d+)/);
    if (finalGoldMatch) {
      results.observations.push(`Final gold amount: ${finalGoldMatch[1]}`);
    }

    const screenshot5 = path.join(screenshotDir, 'v2-05-final.png');
    await page.screenshot({ path: screenshot5, fullPage: false });
    results.screenshots.push(screenshot5);
    results.steps.push('Final state captured');
    console.log(`Saved: ${screenshot5}`);

    results.success = true;

  } catch (error) {
    console.error('Error during test:', error.message);
    results.errors.push(error.message);
    results.steps.push(`Error: ${error.message}`);

    try {
      const errorScreenshot = path.join(screenshotDir, 'v2-error.png');
      await page.screenshot({ path: errorScreenshot, fullPage: false });
      results.screenshots.push(errorScreenshot);
    } catch (screenshotError) {
      console.error('Could not take error screenshot');
    }
  } finally {
    await browser.close();
  }

  // Write results to JSON file
  const resultsPath = path.join(screenshotDir, 'test-results-v2.json');
  fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
  console.log(`\n=== TEST RESULTS ===`);
  console.log(`Results saved to: ${resultsPath}`);
  console.log(`\nSuccess: ${results.success}`);
  console.log(`Steps: ${results.steps.length}`);
  console.log(`Screenshots: ${results.screenshots.length}`);
  console.log(`Observations: ${results.observations.length}`);
  console.log(`Errors: ${results.errors.length}`);

  console.log('\nObservations:');
  results.observations.forEach(o => console.log(`  - ${o}`));

  return results;
}

testTowerPlacement().catch(console.error);
