const Scholarship = require('../models/Scholarship');
const ScholarshipSourceStatus = require('../models/ScholarshipSourceStatus');
const ScholarshipFetchJob = require('../models/ScholarshipFetchJob');
const ScholarshipChangeHistory = require('../models/ScholarshipChangeHistory');
const { runFetch } = require('../services/scholarshipFetcherService');

// @desc    Get dashboard overview stats
// @route   GET /api/data-monitor/overview
// @access  Private
const getOverview = async (req, res) => {
    try {
        const total = await Scholarship.countDocuments();
        const active = await Scholarship.countDocuments({ status: 'ACTIVE' });
        const expired = await Scholarship.countDocuments({ 
            $or: [{ status: 'EXPIRED' }, { deadline: 'Expired' }] 
        });

        const lastJob = await ScholarshipFetchJob.findOne({ isDryRun: false }).sort('-startedAt');

        res.status(200).json({
            success: true,
            data: {
                totalScholarships: total,
                activeScholarships: active,
                expiredScholarships: expired,
                otherScholarships: total - active - expired,
                lastFetch: lastJob ? {
                    status: lastJob.status,
                    startedAt: lastJob.startedAt,
                    recordsDiscovered: lastJob.recordsDiscovered,
                    new: lastJob.recordsInserted,
                    updated: lastJob.recordsUpdated,
                    errors: lastJob.sourcesFailed
                } : null
            }
        });
    } catch (error) {
        console.error('Error fetching overview:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Get source health
// @route   GET /api/data-monitor/sources
// @access  Private
const getSources = async (req, res) => {
    try {
        const sources = await ScholarshipSourceStatus.find().sort('sourceName');
        res.status(200).json({ success: true, data: sources });
    } catch (error) {
        console.error('Error fetching sources:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Get fetch history
// @route   GET /api/data-monitor/fetch-history
// @access  Private
const getFetchHistory = async (req, res) => {
    try {
        const history = await ScholarshipFetchJob.find({ isDryRun: false }).sort('-startedAt').limit(10);
        res.status(200).json({ success: true, data: history });
    } catch (error) {
        console.error('Error fetching history:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Get recent changes
// @route   GET /api/data-monitor/changes
// @access  Private
const getRecentChanges = async (req, res) => {
    try {
        const changes = await ScholarshipChangeHistory.find()
            .populate('scholarshipId', 'title')
            .sort('-detectedAt')
            .limit(20);
        res.status(200).json({ success: true, data: changes });
    } catch (error) {
        console.error('Error fetching changes:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Trigger manual refresh
// @route   POST /api/data-monitor/refresh
// @access  Private
const refreshData = async (req, res) => {
    try {
        // Run asynchronously, don't wait for completion
        runFetch({ triggerType: 'manual', triggeredBy: req.user.id }).catch(err => console.error(err));
        res.status(202).json({ success: true, message: 'Fetch job queued successfully' });
    } catch (error) {
        console.error('Error queuing fetch:', error);
        res.status(500).json({ success: false, message: 'Server error queuing fetch' });
    }
};

module.exports = {
    getOverview,
    getSources,
    getFetchHistory,
    getRecentChanges,
    refreshData
};
