// Web Preview Mode Helper
const isWebPreview = !window.invokeNative;

document.addEventListener('DOMContentLoaded', () => {
    if (isWebPreview) {
        document.body.classList.add('visible');
        setupClock();
        // Mock data for browser testing
        updateUI({
            reputation: 1250,
            totalSold: 45,
            totalValue: 125400,
            leaderboard: [
                { citizenid: "ABC12345", total_value: 500000 },
                { citizenid: "XYZ98765", total_value: 250000 },
                { citizenid: "DEV00001", total_value: 100000 }
            ]
        });
    }
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

// Tab Switching Logic
const navItems = document.querySelectorAll('.nav-item');
const tabs = document.querySelectorAll('.tab-content');

navItems.forEach(item => {
    item.addEventListener('click', () => {
        const target = item.getAttribute('data-tab');
        
        navItems.forEach(i => i.classList.remove('active'));
        tabs.forEach(t => t.classList.remove('active'));
        
        item.classList.add('active');
        document.getElementById(target).classList.add('active');
    });
});

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        document.body.classList.add('visible');
        setupClock();
        updateUI(data.data);
    }

    if (data.action === 'close') {
        document.body.classList.remove('visible');
    }
});

function updateUI(data) {
    // Update Personal Stats
    document.getElementById('rep-value').innerText = data.reputation.toLocaleString();
    document.getElementById('sold-value').innerText = data.totalSold.toLocaleString();
    document.getElementById('money-value').innerText = '$' + data.totalValue.toLocaleString();

    // Update Leaderboard
    const list = document.getElementById('leaderboard-list');
    list.innerHTML = '';

    if (data.leaderboard && data.leaderboard.length > 0) {
        data.leaderboard.forEach((entry, index) => {
            const item = document.createElement('div');
            item.className = 'leader-item';
            item.innerHTML = `
                <div class="leader-rank">#${index + 1}</div>
                <div class="leader-name">${entry.citizenid}</div>
                <div class="leader-value">$${entry.total_value.toLocaleString()}</div>
            `;
            list.appendChild(item);
        });
    } else {
        list.innerHTML = '<div style="text-align:center; color:rgba(255,255,255,0.2); margin-top:20px;">No network data available</div>';
    }
}

function closeUI() {
    if (isWebPreview) {
        document.body.classList.remove('visible');
        return;
    }
    fetch('https://' + GetParentResourceName() + '/close', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeUI();
    }
});