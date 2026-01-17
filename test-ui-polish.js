const { chromium } = require('playwright');

async function testUIPolish() {
  console.log('Starting UI Polish Test...');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 }
  });
  const page = await context.newPage();

  try {
    // Step 1: Navigate to the game
    console.log('Navigating to https://block-defense.freesmileguide.com...');
    await page.goto('https://block-defense.freesmileguide.com', {
      waitUntil: 'networkidle',
      timeout: 30000
    });

    // Step 2: Wait 15 seconds for WebGL to load
    console.log('Waiting 15 seconds for WebGL to load...');
    await page.waitForTimeout(15000);

    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-01-initial-load.png' });
    console.log('Screenshot 1: Initial load');

    // Step 3: Test HUD elements
    console.log('\n=== Testing HUD Elements ===');

    // Check if HUD shows Gold, HP, Wave
    const hudText = await page.evaluate(() => {
      const elements = Array.from(document.querySelectorAll('*')).filter(el => {
        const text = el.textContent;
        return text && (text.includes('Gold') || text.includes('HP') || text.includes('Wave'));
      });
      return elements.map(el => ({ tag: el.tagName, text: el.textContent.trim().substring(0, 100) }));
    });
    console.log('HUD elements found:', hudText);

    // Step 4: Test tower button selection/highlighting
    console.log('\n=== Testing Tower Button Selection ===');

    // Look for tower buttons
    const buttons = await page.evaluate(() => {
      const buttons = Array.from(document.querySelectorAll('button, [role="button"], .button'));
      return buttons.map(btn => ({
        text: btn.textContent.trim(),
        classes: btn.className,
        id: btn.id
      }));
    });
    console.log('Buttons found:', buttons);

    // Click first tower button (Wood Tower based on previous screenshots)
    console.log('Attempting to click tower button...');
    await page.click('canvas', { position: { x: 100, y: 650 } }); // Approximate position from screenshots
    await page.waitForTimeout(500);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-02-tower-selected.png' });
    console.log('Screenshot 2: After tower button click');

    // Check for hover state by moving mouse over button area
    await page.mouse.move(100, 650);
    await page.waitForTimeout(300);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-03-tower-hover.png' });
    console.log('Screenshot 3: Tower button hover state');

    // Step 5: Test placement on invalid tiles
    console.log('\n=== Testing Invalid Tile Placement ===');

    // Try clicking on path (center area based on previous screenshots)
    await page.click('canvas', { position: { x: 400, y: 350 } });
    await page.waitForTimeout(500);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-04-path-click.png' });
    console.log('Screenshot 4: Clicked on path tile');

    // Try clicking on castle (right side based on previous screenshots)
    await page.click('canvas', { position: { x: 800, y: 350 } });
    await page.waitForTimeout(500);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-05-castle-click.png' });
    console.log('Screenshot 5: Clicked on castle tile');

    // Step 6: Test Escape key cancellation
    console.log('\n=== Testing Escape Key ===');

    // Select tower again
    await page.click('canvas', { position: { x: 100, y: 650 } });
    await page.waitForTimeout(300);

    // Press Escape
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-06-after-escape.png' });
    console.log('Screenshot 6: After pressing Escape');

    // Step 7: Test window resize
    console.log('\n=== Testing Window Resize ===');

    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.waitForTimeout(1000);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-07-resize-large.png' });
    console.log('Screenshot 7: Resized to 1920x1080');

    await page.setViewportSize({ width: 800, height: 600 });
    await page.waitForTimeout(1000);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-08-resize-small.png' });
    console.log('Screenshot 8: Resized to 800x600');

    // Step 8: Test ghost tower animation
    console.log('\n=== Testing Ghost Tower Preview ===');

    await page.setViewportSize({ width: 1280, height: 720 });
    await page.waitForTimeout(500);

    // Select tower and move mouse to show ghost
    await page.click('canvas', { position: { x: 100, y: 650 } });
    await page.waitForTimeout(300);

    // Move to valid placement area
    await page.mouse.move(200, 300);
    await page.waitForTimeout(300);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-09-ghost-valid.png' });
    console.log('Screenshot 9: Ghost tower on valid tile');

    // Move to invalid area (path)
    await page.mouse.move(400, 350);
    await page.waitForTimeout(300);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-10-ghost-invalid.png' });
    console.log('Screenshot 10: Ghost tower on invalid tile');

    // Step 9: Test placement animation
    console.log('\n=== Testing Placement Animation ===');

    // Click on valid tile
    await page.mouse.move(200, 300);
    await page.click('canvas');
    await page.waitForTimeout(100);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-11-placement-start.png' });
    console.log('Screenshot 11: Placement animation start');

    await page.waitForTimeout(400);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-12-placement-mid.png' });
    console.log('Screenshot 12: Placement animation mid');

    await page.waitForTimeout(400);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-13-placement-end.png' });
    console.log('Screenshot 13: Placement animation end');

    console.log('\n=== Test Complete ===');
    console.log('All screenshots saved to .playwright-mcp/ directory');

  } catch (error) {
    console.error('Error during test:', error);
    await page.screenshot({ path: '/home/ben/projects/game/block-defense/.playwright-mcp/polish-error.png' });
  } finally {
    await browser.close();
  }
}

testUIPolish().catch(console.error);
