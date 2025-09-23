function showCreateSection() {
  document.getElementById('choiceSection').style.display = 'none';
  document.getElementById('createSection').style.display = 'block';
  document.getElementById('joinSection').style.display = 'none';
}

function showJoinSection() {
  document.getElementById('choiceSection').style.display = 'none';
  document.getElementById('createSection').style.display = 'none';
  document.getElementById('joinSection').style.display = 'block';
}

function hideAllSections() {
  document.getElementById('choiceSection').style.display = 'block';
  document.getElementById('createSection').style.display = 'none';
  document.getElementById('joinSection').style.display = 'none';
  document.getElementById('inviteDisplay').style.display = 'none';
}

async function createNetwork() {
  const instanceName = document.getElementById('createInstanceName').value.trim();
  if (!instanceName) {
    alert('Please enter a name for this instance');
    return;
  }
  
  document.getElementById('statusMessage').innerHTML = 'Creating network...';
  try {
    const result = await window.electronAPI.setupNetwork({
      action: 'create',
      instanceName: instanceName
    });
    
    document.getElementById('inviteCode').textContent = result.networkSeed;
    document.getElementById('inviteDisplay').style.display = 'block';
    
    // Auto-scroll to bottom
    setTimeout(() => {
      document.getElementById('statusMessage').scrollIntoView({ behavior: 'smooth', block: 'end' });
    }, 100);
    
    setTimeout(() => {
      document.getElementById('statusMessage').innerHTML = 'Network created! <button onclick="launchApp()">Launch App</button>';
    }, 2000);
  } catch (error) {
    console.error('Error creating network:', error);
    document.getElementById('statusMessage').innerHTML = 'Error: ' + error.message;
  }
}

async function joinNetwork() {
  const instanceName = document.getElementById('joinInstanceName').value.trim();
  const inviteCode = document.getElementById('inviteCodeInput').value.trim();
  
  if (!instanceName) {
    alert('Please enter a name for this instance');
    return;
  }
  if (!inviteCode) {
    alert('Please enter an invite code');
    return;
  }
  
  document.getElementById('statusMessage').innerHTML = 'Joining network...';
  try {
    await window.electronAPI.setupNetwork({
      action: 'join',
      instanceName: instanceName,
      networkSeed: inviteCode
    });
    
    // Auto-scroll to bottom
    setTimeout(() => {
      document.getElementById('statusMessage').scrollIntoView({ behavior: 'smooth', block: 'end' });
    }, 100);
    
    setTimeout(() => {
      document.getElementById('statusMessage').innerHTML = 'Network joined! <button onclick="launchApp()">Launch App</button>';
    }, 2000);
  } catch (error) {
    console.error('Error joining network:', error);
    document.getElementById('statusMessage').innerHTML = 'Error: ' + error.message;
  }
}

async function launchApp() {
  try {
    document.getElementById('statusMessage').innerHTML = 'Launching...';
    await window.electronAPI.launch({ type: 'random' });
  } catch (error) {
    console.error('Error launching:', error);
    document.getElementById('statusMessage').innerHTML = 'Error launching. Please close and restart manually.';
  }
}
