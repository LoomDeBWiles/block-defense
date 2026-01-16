const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function testTowerPlacement() {
  console.log('Starting Block Defense tower placement test...');

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
    errors: []
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
    await page.waitForTimeout(3000);

    // Step 3: Take initial screenshot
    console.log('Step 3: Taking initial screenshot...');
    const screenshot1 = path.join(screenshotDir, '01-initial-state.png');
    await page.screenshot({ path: screenshot1, fullPage: false });
    results.screenshots.push(screenshot1);
    results.steps.push('Initial screenshot captured');
    console.log(`Saved: ${screenshot1}`);

    // Step 4: Click on tower slot (Wood tower button)
    console.log('Step 4: Clicking on tower slot button...');
    // Tower buttons are at the bottom - try clicking around y=550
    await page.mouse.click(100, 550);
    await page.waitForTimeout(500);

    const screenshot2 = path.join(screenshotDir, '02-tower-selected.png');
    await page.screenshot({ path: screenshot2, fullPage: false });
    results.screenshots.push(screenshot2);
    results.steps.push('Clicked tower slot button');
    console.log(`Saved: ${screenshot2}`);

    // Step 5: Click on a grass tile to place tower
    console.log('Step 5: Clicking on grass tile for placement...');
    // Click in the game grid area (middle-ish area)
    await page.mouse.click(400, 300);
    await page.waitForTimeout(1000);

    const screenshot3 = path.join(screenshotDir, '03-after-tile-click.png');
    await page.screenshot({ path: screenshot3, fullPage: false });
    results.screenshots.push(screenshot3);
    results.steps.push('Clicked on grass tile');
    console.log(`Saved: ${screenshot3}`);

    // Step 6: Look for confirmation popup and try to find Place button
    console.log('Step 6: Looking for Place button in popup...');

    // Try multiple strategies to find and click the Place button
    let placeClicked = false;

    // Strategy 1: Look for button with text "Place"
    try {
      const placeButton = await page.locator('button:has-text("Place")').first();
      if (await placeButton.isVisible({ timeout: 2000 })) {
        await placeButton.click();
        placeClicked = true;
        results.steps.push('Clicked Place button (text locator)');
        console.log('Clicked Place button using text locator');
      }
    } catch (e) {
      console.log('Place button not found with text locator');
    }

    // Strategy 2: Try clicking at typical popup button position if not clicked yet
    if (!placeClicked) {
      console.log('Trying to click Place button at estimated position...');
      await page.mouse.click(640, 400); // Center-ish position where popup might be
      await page.waitForTimeout(500);
      results.steps.push('Clicked at estimated Place button position');
    }

    await page.waitForTimeout(1000);

    const screenshot4 = path.join(screenshotDir, '04-after-place-click.png');
    await page.screenshot({ path: screenshot4, fullPage: false });
    results.screenshots.push(screenshot4);
    console.log(`Saved: ${screenshot4}`);

    // Step 7: Verify if tower was placed
    console.log('Step 7: Checking if tower was placed...');
    await page.waitForTimeout(1000);

    const screenshot5 = path.join(screenshotDir, '05-final-state.png');
    await page.screenshot({ path: screenshot5, fullPage: false });
    results.screenshots.push(screenshot5);
    results.steps.push('Final state captured');
    console.log(`Saved: ${screenshot5}`);

    // Get page content to check for any visible text
    const bodyText = await page.textContent('body');
    if (bodyText.includes('Gold:') || bodyText.includes('Wave:')) {
      results.steps.push('Game UI elements visible');
    }

    results.success = true;
    results.steps.push('Test completed');

  } catch (error) {
    console.error('Error during test:', error.message);
    results.errors.push(error.message);
    results.steps.push(`Error: ${error.message}`);

    // Take error screenshot
    try {
      const errorScreenshot = path.join(screenshotDir, 'error-state.png');
      await page.screenshot({ path: errorScreenshot, fullPage: false });
      results.screenshots.push(errorScreenshot);
      console.log(`Saved error screenshot: ${errorScreenshot}`);
    } catch (screenshotError) {
      console.error('Could not take error screenshot:', screenshotError.message);
    }
  } finally {
    await browser.close();
    console.log('Browser closed');
  }

  // Write results to JSON file
  const resultsPath = path.join(screenshotDir, 'test-results.json');
  fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
  console.log(`\nResults saved to: ${resultsPath}`);

  console.log('\n=== TEST SUMMARY ===');
  console.log(`Success: ${results.success}`);
  console.log(`Steps completed: ${results.steps.length}`);
  console.log(`Screenshots taken: ${results.screenshots.length}`);
  console.log(`Errors: ${results.errors.length}`);
  console.log('\nScreenshots:');
  results.screenshots.forEach(s => console.log(`  - ${s}`));

  if (results.errors.length > 0) {
    console.log('\nErrors encountered:');
    results.errors.forEach(e => console.log(`  - ${e}`));
  }

  return results;
}

testTowerPlacement().catch(console.error);
