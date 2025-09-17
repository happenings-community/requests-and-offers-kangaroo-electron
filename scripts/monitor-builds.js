#!/usr/bin/env node
/**
 * Build monitoring script for Requests & Offers deployment
 * Monitors GitHub Actions builds and provides real-time status updates
 */

const { execSync } = require('child_process');
const fs = require('fs');

// ANSI color codes
const colors = {
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    purple: '\x1b[35m',
    cyan: '\x1b[36m',
    reset: '\x1b[0m'
};

// Print colored output
function printStatus(status, message) {
    const timestamp = new Date().toLocaleTimeString();
    switch (status) {
        case 'error':
            console.log(`${colors.red}❌ [${timestamp}] ERROR: ${message}${colors.reset}`);
            break;
        case 'warning':
            console.log(`${colors.yellow}⚠️  [${timestamp}] WARNING: ${message}${colors.reset}`);
            break;
        case 'success':
            console.log(`${colors.green}✅ [${timestamp}] ${message}${colors.reset}`);
            break;
        case 'info':
            console.log(`${colors.blue}📋 [${timestamp}] ${message}${colors.reset}`);
            break;
        case 'progress':
            console.log(`${colors.cyan}⏳ [${timestamp}] ${message}${colors.reset}`);
            break;
    }
}

// Execute command and return result
function execCommand(command, options = {}) {
    try {
        return execSync(command, { 
            encoding: 'utf8', 
            stdio: options.silent ? 'pipe' : 'inherit',
            ...options 
        });
    } catch (error) {
        if (!options.ignoreError) {
            throw error;
        }
        return null;
    }
}

// Check if GitHub CLI is available
function checkGitHubCLI() {
    try {
        execCommand('gh --version', { silent: true });
        return true;
    } catch (error) {
        printStatus('error', 'GitHub CLI (gh) is not installed or not available');
        printStatus('info', 'Please install GitHub CLI: https://cli.github.com/');
        return false;
    }
}

// Get the latest workflow run
function getLatestRun() {
    try {
        const result = execCommand('gh run list --limit 1 --json status,conclusion,databaseId,headBranch,createdAt,jobs,name', { silent: true });
        const runs = JSON.parse(result);
        return runs.length > 0 ? runs[0] : null;
    } catch (error) {
        printStatus('error', `Failed to get workflow runs: ${error.message}`);
        return null;
    }
}

// Get detailed job information for a run
function getJobDetails(runId) {
    try {
        const result = execCommand(`gh run view ${runId} --json jobs`, { silent: true });
        const runData = JSON.parse(result);
        return runData.jobs || [];
    } catch (error) {
        printStatus('warning', `Failed to get job details: ${error.message}`);
        return [];
    }
}

// Check if run is relevant to our deployment
function isRelevantRun(run, version) {
    if (!run) return false;
    
    // Check if run is from release branch or contains version in name
    const isReleaseBranch = run.headBranch === 'release';
    const containsVersion = version && run.name && run.name.includes(version);
    const isRecent = new Date() - new Date(run.createdAt) < 30 * 60 * 1000; // Within 30 minutes
    
    return isReleaseBranch && isRecent;
}

// Display job status with platform names
function displayJobStatus(jobs) {
    const platformMap = {
        'windows-2022': '🖥️  Windows',
        'macos-13': '🍎 macOS x64',
        'macos-latest': '🍎 macOS ARM64',
        'ubuntu-22.04': '🐧 Linux'
    };
    
    console.log('\n📊 Build Status:');
    console.log('================');
    
    jobs.forEach(job => {
        const platformName = platformMap[job.runner_name] || job.runner_name;
        const status = job.status;
        const conclusion = job.conclusion;
        
        let statusIcon = '⏳';
        let statusColor = colors.cyan;
        
        if (status === 'completed') {
            if (conclusion === 'success') {
                statusIcon = '✅';
                statusColor = colors.green;
            } else if (conclusion === 'failure') {
                statusIcon = '❌';
                statusColor = colors.red;
            } else if (conclusion === 'cancelled') {
                statusIcon = '🚫';
                statusColor = colors.yellow;
            }
        } else if (status === 'in_progress') {
            statusIcon = '🔄';
            statusColor = colors.blue;
        } else if (status === 'queued') {
            statusIcon = '⏸️';
            statusColor = colors.purple;
        }
        
        const duration = job.completed_at && job.started_at 
            ? ` (${Math.round((new Date(job.completed_at) - new Date(job.started_at)) / 1000 / 60)}m${Math.round(((new Date(job.completed_at) - new Date(job.started_at)) / 1000) % 60)}s)`
            : '';
        
        console.log(`${statusColor}${statusIcon} ${platformName}: ${status}${conclusion ? ` (${conclusion})` : ''}${duration}${colors.reset}`);
    });
    
    console.log('');
}

// Main monitoring function
async function monitorBuilds(version) {
    console.log('🔍 GitHub Actions Build Monitor');
    console.log('==============================');
    console.log(`Monitoring builds for version: ${version || 'latest'}\n`);
    
    if (!checkGitHubCLI()) {
        process.exit(1);
    }
    
    let attempts = 0;
    const maxAttempts = 60; // 30 minutes max (30 second intervals)
    let lastRunId = null;
    let buildStarted = false;
    
    printStatus('info', 'Looking for relevant workflow runs...');
    
    while (attempts < maxAttempts) {
        try {
            const latestRun = getLatestRun();
            
            if (!latestRun) {
                printStatus('warning', 'No workflow runs found');
                break;
            }
            
            // Check if this is a relevant run for our deployment
            if (!buildStarted && !isRelevantRun(latestRun, version)) {
                printStatus('info', `Waiting for deployment build to start... (${attempts + 1}/${maxAttempts})`);
                await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
                attempts++;
                continue;
            }
            
            buildStarted = true;
            
            // If this is a new run, reset the display
            if (lastRunId !== latestRun.databaseId) {
                lastRunId = latestRun.databaseId;
                printStatus('info', `Found build: ${latestRun.name} (#${latestRun.databaseId})`);
                printStatus('info', `Branch: ${latestRun.headBranch}`);
                printStatus('info', `Started: ${new Date(latestRun.createdAt).toLocaleString()}`);
            }
            
            // Get detailed job information
            const jobs = getJobDetails(latestRun.databaseId);
            
            // Clear screen and display current status
            console.clear();
            console.log('🔍 GitHub Actions Build Monitor');
            console.log('==============================');
            console.log(`Version: ${version || 'latest'}`);
            console.log(`Build: ${latestRun.name} (#${latestRun.databaseId})`);
            console.log(`Branch: ${latestRun.headBranch}`);
            console.log(`Started: ${new Date(latestRun.createdAt).toLocaleString()}`);
            
            if (jobs.length > 0) {
                displayJobStatus(jobs);
            }
            
            // Check if build is complete
            if (latestRun.status === 'completed') {
                if (latestRun.conclusion === 'success') {
                    printStatus('success', 'All builds completed successfully! 🎉');
                    
                    // Show summary
                    const successfulJobs = jobs.filter(job => job.conclusion === 'success').length;
                    const totalJobs = jobs.length;
                    console.log(`\n📈 Summary: ${successfulJobs}/${totalJobs} jobs completed successfully`);
                    
                    printStatus('info', 'Next steps:');
                    console.log('  1. Verify assets are uploaded to the release');
                    console.log('  2. Update Homebrew formula if needed');
                    console.log('  3. Test installations on different platforms');
                    
                    return true;
                } else {
                    printStatus('error', `Build failed with conclusion: ${latestRun.conclusion}`);
                    
                    // Show failed jobs
                    const failedJobs = jobs.filter(job => job.conclusion === 'failure');
                    if (failedJobs.length > 0) {
                        console.log('\n❌ Failed jobs:');
                        failedJobs.forEach(job => {
                            console.log(`  - ${job.name}`);
                        });
                        
                        printStatus('info', 'To view detailed logs:');
                        console.log(`  gh run view ${latestRun.databaseId} --log-failed`);
                    }
                    
                    return false;
                }
            }
            
            // Still in progress
            const completedJobs = jobs.filter(job => job.status === 'completed').length;
            const totalJobs = jobs.length;
            printStatus('progress', `Build in progress... ${completedJobs}/${totalJobs} jobs completed (attempt ${attempts + 1}/${maxAttempts})`);
            
            await new Promise(resolve => setTimeout(resolve, 30000)); // Wait 30 seconds
            attempts++;
            
        } catch (error) {
            printStatus('error', `Error monitoring builds: ${error.message}`);
            attempts++;
            
            if (attempts < maxAttempts) {
                printStatus('info', 'Retrying in 30 seconds...');
                await new Promise(resolve => setTimeout(resolve, 30000));
            }
        }
    }
    
    printStatus('warning', 'Timeout waiting for builds to complete');
    printStatus('info', 'You can continue monitoring manually at:');
    console.log('https://github.com/happenings-community/requests-and-offers-kangaroo-electron/actions');
    
    return false;
}

// CLI interface
if (require.main === module) {
    const version = process.argv[2];
    
    if (!version) {
        console.log('Usage: node monitor-builds.js <version>');
        console.log('Example: node monitor-builds.js 0.1.0-alpha.8');
        process.exit(1);
    }
    
    monitorBuilds(version)
        .then(success => {
            process.exit(success ? 0 : 1);
        })
        .catch(error => {
            printStatus('error', `Monitoring failed: ${error.message}`);
            process.exit(1);
        });
}

module.exports = { monitorBuilds };