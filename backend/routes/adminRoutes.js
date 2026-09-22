const express = require('express');
const router = express.Router();
const { 
    triggerFetch, 
    triggerFetchSource,
    getJobStatus,
    getLiveFetchStatus,
    getLatestJob,
    getSourcesStatus,
    getFetchHistory,
    getDatabaseStats,
    getDashboardStats
} = require('../controllers/adminController');
const { protect } = require('../middleware/authMiddleware');

// Dashboard and Stats
router.get('/dashboard', protect, getDashboardStats);
router.get('/stats', protect, getDatabaseStats);

// Status and History
router.get('/sources', protect, getSourcesStatus);
router.get('/fetch-history', protect, getFetchHistory);
router.get('/fetch/latest', protect, getLatestJob);
router.get('/fetch/status', protect, getLiveFetchStatus);
router.get('/fetch/:jobId', protect, getJobStatus);

// Trigger Fetch
router.post('/fetch', protect, triggerFetch);
router.post('/fetch/source/:sourceName', protect, triggerFetchSource);

module.exports = router;
