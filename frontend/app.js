// Same-origin call: CloudFront routes /api/* to Lambda (Django), so no CORS.
const out = document.getElementById("out");
const btn = document.getElementById("ping");

async function ping() {
  out.textContent = "loading…";
  try {
    const res = await fetch("/api/hello/", { headers: { Accept: "application/json" } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    out.textContent = JSON.stringify(data, null, 2);
  } catch (err) {
    // Thrown errors are captured by the RUM "errors" telemetry.
    out.textContent = `error: ${err.message}`;
    throw err;
  }
}

btn.addEventListener("click", ping);
await ping();
