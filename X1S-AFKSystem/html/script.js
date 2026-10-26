const overlay = document.getElementById('afk-overlay');
const panel = document.getElementById('afk-panel');
const ring = document.getElementById('ring-progress');
const timeEl = document.getElementById('afk-time');
const dot = document.getElementById('afk-dot');
const backBtn = document.getElementById('afk-back');

const RING_CIRCUMFERENCE = 2 * Math.PI * 70; // matches r="70" on the SVG circle

const COLORS = {
    normal: '#35e6ff',
    warn: '#ffb020',
    danger: '#ff3b3b',
};

let totalSeconds = 300;

function formatTime(sec) {
    sec = Math.max(0, Math.round(sec));
    const m = Math.floor(sec / 60).toString().padStart(2, '0');
    const s = (sec % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
}

function colorFor(fraction) {
    if (fraction <= 0.2) return COLORS.danger;
    if (fraction <= 0.5) return COLORS.warn;
    return COLORS.normal;
}

function hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function applyState(remaining, total) {
    if (total) totalSeconds = total;
    const fraction = totalSeconds > 0 ? Math.max(0, Math.min(1, remaining / totalSeconds)) : 0;
    const color = colorFor(fraction);

    timeEl.textContent = formatTime(remaining);

    const offset = RING_CIRCUMFERENCE * (1 - fraction);
    ring.style.strokeDashoffset = offset;

    const root = document.documentElement.style;
    root.setProperty('--accent', color);
    root.setProperty('--accent-dim', hexToRgba(color, 0.15));
    root.setProperty('--border', hexToRgba(color, 0.35));

    panel.style.boxShadow =
        `0 0 0 1px rgba(255,255,255,0.03), 0 20px 60px rgba(0,0,0,0.6), 0 0 40px ${hexToRgba(color, 0.33)}`;

    overlay.classList.toggle('danger', fraction <= 0.2);
}

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'show') {
        applyState(data.remaining, data.total);
        overlay.classList.add('visible');
    }

    if (data.action === 'update') {
        applyState(data.remaining, totalSeconds);
    }

    if (data.action === 'hide') {
        overlay.classList.remove('visible');
    }
});

function sendBack() {
    fetch(`https://${GetParentResourceName()}/back`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
}

backBtn.addEventListener('click', sendBack);

document.addEventListener('keydown', function (e) {
    if (!overlay.classList.contains('visible')) return;
    if (e.key === 'Enter') sendBack();
});
