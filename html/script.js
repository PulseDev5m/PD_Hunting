'use strict';

let playerStats      = null;
let animalConfig     = {};
let milestonesConfig = {};

document.addEventListener('DOMContentLoaded', () => {
    setupTabs();
    setupButtons();
});

window.addEventListener('message', (e) => {
    const msg = e.data;
    switch (msg.action) {
        case 'open':
            openUI();
            break;
        case 'updateStats':
            animalConfig     = msg.animalCfg  || {};
            milestonesConfig = msg.milestones  || {};
            playerStats      = msg.data;
            renderStats(msg.data);
            renderAnimals(msg.data);
            renderGoals(msg.data);
            break;
        case 'updateLeaderboard':
            renderLeaderboard(msg.rows);
            break;
        case 'sellResult':
            handleSellResult(msg.result);
            break;
    }
});

function openUI() {
    document.getElementById('app').classList.remove('hidden');
}

function closeUI() {
    document.getElementById('app').classList.add('hidden');
    fetch(`https://${getResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function setupTabs() {
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById('tab-' + tab.dataset.tab).classList.add('active');
        });
    });
}

function setupButtons() {
    document.getElementById('closeBtn').addEventListener('click', closeUI);
    document.getElementById('overlay').addEventListener('click', closeUI);
    document.getElementById('refreshLeaderboard').addEventListener('click', () => {
        fetch(`https://${getResourceName()}/requestLeaderboard`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    });
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeUI();
});

function renderStats(data) {
    document.getElementById('stat-total').textContent      = fmtNum(data.total_sold);
    document.getElementById('stat-milestones').textContent = fmtNum(data.milestones);
    document.getElementById('stat-earnings').textContent   = '$' + fmtNum(data.total_earnings);
    document.getElementById('stat-cycle').textContent      = `${data.current_cycle}/${data.animalsPerMilestone}`;

    const pct = (data.current_cycle / data.animalsPerMilestone) * 100;
    document.getElementById('progress-fill').style.width = Math.min(pct, 100) + '%';
    document.getElementById('progress-text').textContent  = `${data.current_cycle} / ${data.animalsPerMilestone}`;

    document.getElementById('milestone-remaining').textContent =
        `${data.remaining} animal${data.remaining !== 1 ? 's' : ''} to next milestone`;

    const preview = document.getElementById('milestone-reward-preview');
    preview.innerHTML = '';
    if (data.nextMilestone) {
        const r = data.nextMilestone.data;
        preview.innerHTML = `
            <span class="reward-chip">${r.label}</span>
            <span class="reward-chip">$${fmtNum(r.money)}</span>
            ${r.item ? `<span class="reward-chip">${r.item}</span>` : ''}
        `;
    } else {
        preview.innerHTML = '<span class="reward-chip">Keep hunting for rewards!</span>';
    }
}

function renderAnimals(data) {
    const grid       = document.getElementById('animal-grid');
    const animals    = data.animals_data || {};
    const hasAnimals = Object.keys(animals).some(k => animals[k] > 0);

    if (!hasAnimals) {
        grid.innerHTML = '<div class="empty-state">No animals harvested yet. Head out to the wilderness!</div>';
        return;
    }

    grid.innerHTML = '';
    for (const [model, count] of Object.entries(animals)) {
        if (count <= 0) continue;
        const cfg      = animalConfig[model] || { label: model, price: 0 };
        const card     = document.createElement('div');
        card.className = 'animal-card';
        card.innerHTML = `
            <div class="animal-card-icon">${cfg.icon}</div>
            <div class="animal-card-name">${cfg.label}</div>
            <div class="animal-card-count">${fmtNum(count)}</div>
            <div class="animal-card-value">$${fmtNum(cfg.price)} each · $${fmtNum(cfg.price * count)} total</div>
        `;
        grid.appendChild(card);
    }
}

function renderGoals(data) {
    const list   = document.getElementById('goals-list');
    const sorted = Object.entries(milestonesConfig).sort((a, b) => parseInt(a[0]) - parseInt(b[0]));

    if (sorted.length === 0) {
        list.innerHTML = '<div class="empty-state">No milestone rewards configured.</div>';
        return;
    }

    list.innerHTML = '';
    for (const [num, reward] of sorted) {
        const milestoneNum = parseInt(num);
        const achieved     = data.milestones >= milestoneNum;
        const item         = document.createElement('div');
        item.className     = 'goal-item' + (achieved ? ' achieved' : '');
        item.innerHTML     = `
            <div class="goal-num">${milestoneNum}</div>
            <div class="goal-divider"></div>
            <div class="goal-info">
                <div class="goal-title">${reward.label}</div>
                <div class="goal-details">
                    $${fmtNum(reward.money)} bonus
                    ${reward.item ? ` · ${reward.item}` : ''}
                    · <em>${milestoneNum * 20} total animals</em>
                </div>
            </div>
            <div class="goal-badge ${achieved ? 'unlocked' : ''}">${achieved ? 'ACHIEVED' : 'LOCKED'}</div>
        `;
        list.appendChild(item);
    }
}

function renderLeaderboard(rows) {
    const tbody      = document.getElementById('leaderboard-body');

    if (!rows || rows.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="empty-state">No hunters on the board yet.</td></tr>';
        return;
    }

    tbody.innerHTML = rows.map((row, i) => `
        <tr class="${i < 3 ? `rank-${i+1}` : ''}">
            <td>${escapeHtml(row.name || 'Unknown')}</td>
            <td>${fmtNum(row.total_sold)}</td>
            <td>${fmtNum(row.milestones)}</td>
            <td>$${fmtNum(row.total_earnings)}</td>
        </tr>
    `).join('');
}

function handleSellResult(result) {
    if (result.playerData) {
        renderStats(result.playerData);
        renderAnimals(result.playerData);
        renderGoals(result.playerData);
    }
}

function fmtNum(n) {
    return Number(n || 0).toLocaleString();
}

function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function getResourceName() {
    return typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'hunting_script';
}