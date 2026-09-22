const { runFetch, getStatus } = require('../services/scholarshipFetcherService');
const ScholarshipFetchJob = require('../models/ScholarshipFetchJob');
const ScholarshipSourceStatus = require('../models/ScholarshipSourceStatus');
const Scholarship = require('../models/Scholarship');

// @desc    Manually trigger the scholarship fetch pipeline (supports ?dryRun=true)
// @route   POST /api/admin/scholarships/fetch
// @access  Private/Admin
const triggerFetch = async (req, res) => {
    const isDryRun = req.query.dryRun === 'true';

    const status = getStatus();
    if (status.isRunning) {
        return res.status(400).json({
            success: false,
            message: 'A scholarship fetch is already running',
            jobId: status.jobId
        });
    }

    try {
        // Run asynchronously, return immediately if we wanted to background it,
        // but for now we wait for completion per user prompt structure (unless it takes too long).
        // Since we fetch 1 source right now, waiting is fine.
        const result = await runFetch({ dryRun: isDryRun, triggerType: 'manual' });
        
        if (!result.success) {
            return res.status(400).json(result);
        }

        res.status(200).json(result);
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to complete scholarship fetch',
            error: error.message
        });
    }
};

// @desc    Trigger fetch for a specific source
// @route   POST /api/admin/scholarships/fetch/source/:sourceName
// @access  Private/Admin
const triggerFetchSource = async (req, res) => {
    const isDryRun = req.query.dryRun === 'true';
    const targetSourceName = req.params.sourceName;

    const status = getStatus();
    if (status.isRunning) {
        return res.status(400).json({
            success: false,
            message: 'A scholarship fetch is already running',
            jobId: status.jobId
        });
    }

    try {
        const result = await runFetch({ dryRun: isDryRun, triggerType: 'manual', targetSourceName });
        res.status(200).json(result);
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get live progress of the fetch process
// @route   GET /api/admin/scholarships/fetch/status
// @access  Private/Admin
const getLiveFetchStatus = async (req, res) => {
    const status = getStatus();
    res.status(200).json({ success: true, ...status });
};

// @desc    Get the status of a specific fetch job
// @route   GET /api/admin/scholarships/fetch/:jobId
// @access  Private/Admin
const getJobStatus = async (req, res) => {
    // Check reserved keywords
    if (req.params.jobId === 'latest') return getLatestJob(req, res);
    if (req.params.jobId === 'status') return getLiveFetchStatus(req, res);

    try {
        const job = await ScholarshipFetchJob.findOne({ jobId: req.params.jobId });
        if (!job) {
            return res.status(404).json({ success: false, message: 'Job not found' });
        }
        res.status(200).json({ success: true, job });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get the latest fetch job
// @route   GET /api/admin/scholarships/fetch/latest
// @access  Private/Admin
const getLatestJob = async (req, res) => {
    try {
        const job = await ScholarshipFetchJob.findOne().sort({ startedAt: -1 });
        res.status(200).json({ success: true, job: job || null });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get the status of all sources
// @route   GET /api/admin/scholarships/sources
// @access  Private/Admin
const getSourcesStatus = async (req, res) => {
    try {
        const sources = await ScholarshipSourceStatus.find();
        res.status(200).json({ success: true, sources });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get history of fetch jobs
// @route   GET /api/admin/scholarships/fetch-history
// @access  Private/Admin
const getFetchHistory = async (req, res) => {
    try {
        const history = await ScholarshipFetchJob.find().sort({ startedAt: -1 }).limit(10);
        res.status(200).json({ success: true, history });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get database stats for scholarships
// @route   GET /api/admin/scholarships/stats
// @access  Private/Admin
const getDatabaseStats = async (req, res) => {
    try {
        const total = await Scholarship.countDocuments();
        const active = await Scholarship.countDocuments({ isActive: true });
        const inactive = total - active;

        // Date boundaries
        const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

        const last24HoursUpdated = await Scholarship.countDocuments({ lastUpdated: { $gte: oneDayAgo } });
        const last7DaysUpdated = await Scholarship.countDocuments({ lastUpdated: { $gte: sevenDaysAgo } });

        // Aggregate by source
        const bySourceAgg = await Scholarship.aggregate([
            { $group: { _id: "$sourceName", count: { $sum: 1 } } }
        ]);
        
        const bySource = {};
        bySourceAgg.forEach(doc => {
            bySource[doc._id || 'Unknown'] = doc.count;
        });

        res.status(200).json({
            success: true,
            total,
            active,
            inactive,
            last24HoursUpdated,
            last7DaysUpdated,
            bySource
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Admin dashboard summary
// @route   GET /api/admin/scholarships/dashboard
// @access  Private/Admin
const getDashboardStats = async (req, res) => {
    try {
        const latestJob = await ScholarshipFetchJob.findOne().sort({ startedAt: -1 });
        const lastSuccessful = await ScholarshipFetchJob.findOne({ status: 'completed' }).sort({ startedAt: -1 });
        const sources = await ScholarshipSourceStatus.find();
        
        const failedSources = sources.filter(s => s.lastRunStatus === 'FAILED').map(s => s.sourceName);

        res.status(200).json({
            success: true,
            lastFetch: latestJob,
            lastSuccessfulFetch: lastSuccessful,
            status: getStatus().isRunning ? 'running' : 'idle',
            failedSources,
            nextScheduledFetch: 'Sunday at midnight'
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

module.exports = {
    triggerFetch,
    triggerFetchSource,
    getJobStatus,
    getLiveFetchStatus,
    getLatestJob,
    getSourcesStatus,
    getFetchHistory,
    getDatabaseStats,
    getDashboardStats
};
