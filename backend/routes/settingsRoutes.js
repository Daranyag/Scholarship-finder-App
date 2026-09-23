const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
    getSettings,
    updateSettings,
    changePassword,
    exportData,
    deleteAccount
} = require('../controllers/settingsController');

router.route('/')
    .get(protect, getSettings)
    .put(protect, updateSettings);

router.route('/change-password')
    .post(protect, changePassword);

router.route('/export')
    .get(protect, exportData);

router.route('/account')
    .delete(protect, deleteAccount);

module.exports = router;
