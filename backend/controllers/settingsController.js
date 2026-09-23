const User = require('../models/User');
const ScholarshipApplication = require('../models/ScholarshipApplication');
const bcrypt = require('bcryptjs');

// @desc    Get User Settings
// @route   GET /api/settings
// @access  Private
const getSettings = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('languagePreference notificationPreferences');
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });
        
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Update Settings
// @route   PUT /api/settings
// @access  Private
const updateSettings = async (req, res) => {
    try {
        const { languagePreference, notificationPreferences } = req.body;
        
        const updateData = {};
        if (languagePreference !== undefined) updateData.languagePreference = languagePreference;
        if (notificationPreferences !== undefined) updateData.notificationPreferences = notificationPreferences;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            { $set: updateData },
            { new: true, runValidators: true }
        ).select('languagePreference notificationPreferences');
        
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Change Password
// @route   POST /api/settings/change-password
// @access  Private
const changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        const user = await User.findById(req.user.id).select('+password');
        
        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) {
            return res.status(400).json({ success: false, message: 'Incorrect current password' });
        }

        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(newPassword, salt);
        await user.save();

        res.status(200).json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Export User Data
// @route   GET /api/settings/export
// @access  Private
const exportData = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).lean();
        const applications = await ScholarshipApplication.find({ user: req.user.id }).lean();
        
        // Remove highly sensitive fields before export
        delete user.password;
        
        const exportBlob = {
            profile: user,
            applications: applications,
            exportedAt: new Date()
        };
        
        res.status(200).json({ success: true, data: exportBlob });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Delete Account
// @route   DELETE /api/settings/account
// @access  Private
const deleteAccount = async (req, res) => {
    try {
        // Delete all associated applications
        await ScholarshipApplication.deleteMany({ user: req.user.id });
        
        // Delete the user
        await User.findByIdAndDelete(req.user.id);
        
        res.status(200).json({ success: true, message: 'Account deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

module.exports = {
    getSettings,
    updateSettings,
    changePassword,
    exportData,
    deleteAccount
};
