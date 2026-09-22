const crypto = require('crypto');
const Scholarship = require('../models/Scholarship');
const ScholarshipFetchJob = require('../models/ScholarshipFetchJob');
const ScholarshipSourceStatus = require('../models/ScholarshipSourceStatus');
const sourcesConfig = require('../config/scholarshipSources');
const bcmbcmwFetcher = require('./sources/bcmbcmwFetcher');

let isFetching = false;
let currentJobId = null;
let currentProgress = {
    status: 'idle',
    currentSource: null,
    sourcesCompleted: 0,
    sourcesTotal: 0,
    recordsDiscovered: 0,
    recordsInserted: 0,
    recordsUpdated: 0
};

// Helper to filter out null/undefined properties to prevent erasing valid data
const getSafeUpdateObj = (newRecord) => {
    const updateObj = {};
    for (const key in newRecord) {
        if (newRecord[key] !== null && newRecord[key] !== undefined) {
            updateObj[key] = newRecord[key];
        }
    }
    return updateObj;
};

// Retry wrapper
const fetchWithRetry = async (fetcherFn, source, maxRetries = 2) => {
    let attempt = 0;
    while (attempt <= maxRetries) {
        try {
            return await fetcherFn(source);
        } catch (error) {
            const isTemporary = error.message.includes('timeout') || error.message.includes('50') || error.message.includes('429');
            if (isTemporary && attempt < maxRetries) {
                attempt++;
                console.log(`[ScholarshipFetcher] Attempt ${attempt} failed for ${source.name}. Retrying in 3s...`);
                await new Promise(res => setTimeout(res, 3000));
            } else {
                throw error;
            }
        }
    }
};

const runFetch = async (options = {}) => {
    const { dryRun = false, targetSourceName = null, triggerType = 'scheduled', triggeredBy = 'system' } = options;

    if (isFetching) {
        return { success: false, message: "Scholarship fetch is already running", jobId: currentJobId };
    }

    isFetching = true;
    currentJobId = crypto.randomUUID();
    
    // Determine target sources for tracking
    const targetSources = sourcesConfig.filter(s => {
        if (targetSourceName) return s.name === targetSourceName;
        return true;
    });

    currentProgress = {
        status: 'running',
        currentSource: null,
        sourcesCompleted: 0,
        sourcesTotal: targetSources.length,
        recordsDiscovered: 0,
        recordsInserted: 0,
        recordsUpdated: 0
    };

    let jobRecord;
    if (!dryRun) {
        jobRecord = await ScholarshipFetchJob.create({
            jobId: currentJobId,
            status: 'running',
            startedAt: new Date(),
            triggerType,
            triggeredBy,
            isDryRun: false
        });
    }

    const summary = {
        jobId: currentJobId,
        sourcesAttempted: 0,
        sourcesSuccessful: 0,
        sourcesFailed: 0,
        recordsDiscovered: 0,
        recordsInserted: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        failedSources: []
    };

    try {
        for (const source of targetSources) {
            if (!source.enabled && source.name !== targetSourceName) {
                console.log(`[ScholarshipFetcher] Skipping disabled source: ${source.name}`);
                summary.recordsSkipped++;
                currentProgress.sourcesCompleted++;
                continue;
            }

            currentProgress.currentSource = source.name;
            summary.sourcesAttempted++;
            console.log(`[ScholarshipFetcher] Starting source: ${source.name} (${source.baseUrl})`);

            let sourceStatus = await ScholarshipSourceStatus.findOne({ sourceName: source.name });
            if (!sourceStatus) {
                sourceStatus = new ScholarshipSourceStatus({
                    sourceName: source.name,
                    sourceUrl: source.baseUrl,
                    enabled: source.enabled
                });
            }

            sourceStatus.lastCheckedAt = new Date();

            try {
                let fetchResult = { records: [], contentHash: null };

                if (source.baseUrl.includes('bcmbcmw.tn.gov.in')) {
                    const records = await fetchWithRetry(bcmbcmwFetcher, source, process.env.SCHOLARSHIP_FETCH_MAX_RETRIES || 2);
                    const hash = crypto.createHash('sha256').update(JSON.stringify(records)).digest('hex');
                    fetchResult = { records, contentHash: hash };
                } else {
                    throw new Error(`No parser implemented for source: ${source.baseUrl}`);
                }

                console.log(`[ScholarshipFetcher] Source returned HTTP 200. Found ${fetchResult.records.length} records.`);
                
                let sourceInserted = 0;
                let sourceUpdated = 0;
                let sourceSkipped = 0;

                if (fetchResult.records.length === 0) {
                    sourceStatus.lastRunStatus = 'SUCCESS_WITH_WARNINGS';
                } else {
                    sourceStatus.lastRunStatus = 'SUCCESS';
                }

                sourceStatus.lastContentHash = fetchResult.contentHash;

                for (const record of fetchResult.records) {
                    summary.recordsDiscovered++;
                    currentProgress.recordsDiscovered++;
                    
                    const existing = await Scholarship.findOne({ 
                        $or: [
                            { sourceUrl: record.sourceUrl, title: record.title }
                        ]
                    });

                    if (existing) {
                        const safeUpdate = getSafeUpdateObj(record);
                        safeUpdate.lastUpdated = new Date();
                        if (!dryRun) {
                            await Scholarship.updateOne({ _id: existing._id }, { $set: safeUpdate });
                        }
                        sourceUpdated++;
                        summary.recordsUpdated++;
                        currentProgress.recordsUpdated++;
                    } else {
                        if (!dryRun) {
                            await Scholarship.create(record);
                        }
                        sourceInserted++;
                        summary.recordsInserted++;
                        currentProgress.recordsInserted++;
                    }
                }

                summary.sourcesSuccessful++;
                sourceStatus.lastSuccessfulAt = new Date();
                sourceStatus.recordsFound = fetchResult.records.length;
                sourceStatus.recordsInserted = sourceInserted;
                sourceStatus.recordsUpdated = sourceUpdated;
                sourceStatus.consecutiveFailures = 0;
                sourceStatus.lastError = null;

            } catch (err) {
                console.error(`[ScholarshipFetcher] Source failed: ${source.name} - ${err.message}`);
                summary.sourcesFailed++;
                summary.failedSources.push({ name: source.name, reason: err.message });
                
                sourceStatus.lastFailedAt = new Date();
                sourceStatus.lastRunStatus = 'FAILED';
                sourceStatus.lastError = err.message;
                sourceStatus.consecutiveFailures += 1;
            }

            if (!dryRun) {
                await sourceStatus.save();
            }
            
            currentProgress.sourcesCompleted++;
        }

        if (!dryRun && jobRecord) {
            jobRecord.status = summary.sourcesFailed > 0 ? 'completed_with_errors' : 'completed';
            jobRecord.completedAt = new Date();
            jobRecord.sourcesAttempted = summary.sourcesAttempted;
            jobRecord.sourcesSuccessful = summary.sourcesSuccessful;
            jobRecord.sourcesFailed = summary.sourcesFailed;
            jobRecord.recordsDiscovered = summary.recordsDiscovered;
            jobRecord.recordsInserted = summary.recordsInserted;
            jobRecord.recordsUpdated = summary.recordsUpdated;
            jobRecord.recordsSkipped = summary.recordsSkipped;
            jobRecord.failedSources = summary.failedSources;
            await jobRecord.save();
        }

    } catch (error) {
        console.error(`[ScholarshipFetcher] Critical failure: ${error.message}`);
        if (!dryRun && jobRecord) {
            jobRecord.status = 'failed';
            jobRecord.errorSummary = error.message;
            jobRecord.completedAt = new Date();
            await jobRecord.save();
        }
    } finally {
        isFetching = false;
        currentJobId = null;
        currentProgress.status = summary.sourcesFailed > 0 ? 'completed_with_errors' : 'completed';
    }

    return {
        success: true,
        jobId: summary.jobId,
        status: summary.sourcesFailed > 0 ? 'completed_with_errors' : 'completed',
        summary
    };
};

const getStatus = () => {
    return {
        isRunning: isFetching,
        jobId: currentJobId,
        ...currentProgress
    };
};

module.exports = {
    runFetch,
    getStatus
};
