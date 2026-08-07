async function pingFlow(page, vuContext, events, test) {
  const { step } = test;

  await step("load_home", async () => {
    await page.goto("/");
    await page.waitForSelector("#ping", { state: "visible" });
  });

  await step("initial_api_render", async () => {
    await page.waitForFunction(() => {
      const el = document.getElementById("out");
      return el?.textContent && el.textContent.trim() !== "—" &&
             el.textContent !== "loading…";
    }, { timeout: 15000 });
  });

  await step("click_ping_render", async () => {
    await page.click("#ping");
    await page.waitForFunction(() => {
      const el = document.getElementById("out");
      return el?.textContent.includes("Hello");
    }, { timeout: 15000 });
  });
}

module.exports = { pingFlow };
