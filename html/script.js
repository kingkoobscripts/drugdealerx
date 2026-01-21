window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        document.body.classList.add('visible');
        
        // Update Personal Stats
        document.getElementById('rep-value').innerText = data.data.reputation;
        document.getElementById('sold-value').innerText = data.data.totalSold;
        document.getElementById('money-value').innerText = '$' + data.data.totalValue.toLocaleString();

        // Update Leaderboard
        const list = document.getElementById('leaderboard-list');
        list.innerHTML = '';

        data.data.leaderboard.forEach((entry, index) => {
            const item = document.createElement('div');
            item.className = 'leader-item';
            item.innerHTML = `
                <div class="leader-rank">#${index + 1}</div>
                <div class="leader-name">${entry.citizenid}</div>
                <div class="leader-value">$${entry.total_value.toLocaleString()}</div>
            `;
            list.appendChild(item);
        });
    }

    if (data.action === 'close') {
        document.body.classList.remove('visible');
    }
});

function closeUI() {
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