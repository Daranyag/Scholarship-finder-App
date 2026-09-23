const express = require('express');
const router = express.Router();
const {
    getOverview,
    getSources,
    getFetchHistory,
    getRecentChanges,
    refreshData
} = require('../controllers/dataMonitorController');
const { protect } = require('../middleware/authMiddleware');

router.get('/overview', protect, getOverview);
router.get('/sources', protect, getSources);
router.get('/fetch-history', protect, getFetchHistory);
router.get('/changes', protect, getRecentChanges);
router.post('/refresh', protect, refreshData);

module.exports = router;
