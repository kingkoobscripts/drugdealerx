const isWebPreview = !window.invokeNative;

document.addEventListener('DOMContentLoaded', () => {
    setupClock();
    
    if (isWebPreview) {
        document.body.classList.add('visible');
        updateUI({
            reputation: 2450,
            totalSold: 182,
            totalValue: 842500,
            leaderboard: [
                { citizenid: "GHOST_99", total_value: 1200000 },
                { citizenid: "SILENCE_X", total_value: 950000 },
                { citizenid: "VOID_WALKER", total_value: 842500 },
                { citizenid: "NEON_VIPER", total_value: 420000 },
                { citizenid: "REAPER_01", total_value: 150000 }
            ]
        });
    }
});

// Tab Navigation
const dockItems = document.querySelectorAll('.dock-item[data-tab]');
const pages = document.querySelectorAll('.app-page');

dockItems.forEach(item => {
    item.addEventListener('click', () => {
        const target = item.getAttribute('data-tab');
        
        // Update Dock
        dockItems.forEach(i => i.classList.remove('active'));
        item.classList.add('active');

        // Update Pages
        pages.forEach(p => p.classList.remove('active'));
        document.getElementById(target).classList.add('active');
    });
});

function setupClock() {
    const timeEl = document.getElementById('current-time');
    const update = () => {
        const now = new Date();
        timeEl.innerText = now.getHours().toString().padStart(2, '0') + ':' + 
                          now.getMinutes().toString().padStart(2, '0');
    };
    setInterval(update, 1000);
    update();
}

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        document.body.classList.add('visible');
        updateUI(data.data);
    }

    if (data.action === 'close') {
        document.body.classList.remove('visible');
    }
});

function updateUI(data) {
    // Animate Numbers
    animateValue("money-value", 0, data.totalValue, 1500);
    animateValue("rep-value", 0, data.reputation, 1000);
    animateValue("sold-value", 0, data.totalSold, 1000);

    // Update Progress Bars
    document.getElementById('rep-fill').style.width = Math.min((data.reputation / 5000) * 100, 100) + '%';
    document.getElementById('sold-fill').style.width = Math.min((data.totalSold / 1000) * 100, 100) + '%';

    // Update Leaderboard
    const list = document.getElementById('leaderboard-list');
    list.innerHTML = '';

    if (data.leaderboard && data.leaderboard.length > 0) {
        data.leaderboard.forEach((entry, index) => {
            const row = document.createElement('div');
            row.className = 'leader-row';
            row.innerHTML = `
                <div class="rank-num">#${index + 1}</div>
                <div class="id-text">${entry.citizenid}</div>
                <div class="val-text">$${entry.total_value.toLocaleString()}</div>
            `;
            list.appendChild(row);
        });
    }
}

function animateValue(id, start, end, duration) {
    const obj = document.getElementById(id);
    if (!obj) return;
    
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        const current = Math.floor(progress * (end - start) + start);
        obj.innerHTML = current.toLocaleString();
        if (progress < 1) {
            window.requestAnimationFrame(step);
        }
    };
    window.requestAnimationFrame(step);
}

function closeUI() {
    if (isWebPreview) {
        document.body.classList.remove('visible');
        return;
    }
    fetch('https://' + GetParentResourceName() + '/close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeUI();
    }
});