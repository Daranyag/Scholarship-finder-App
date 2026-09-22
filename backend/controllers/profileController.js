const User = require('../models/User');

// Calculate profile completion percentage
const calculateProfileCompletion = (user) => {
    const requiredFields = [
        'name',
        'dateOfBirth',
        'gender',
        'district',
        'caste',
        'annualIncome',
        'educationLevel',
        'stream',
        'institution',
        'yearOfStudy'
    ];

    let filledCount = 0;

    requiredFields.forEach(field => {
        if (user[field] !== undefined && user[field] !== null && user[field] !== '') {
            filledCount++;
        }
    });

    const completion = Math.round((filledCount / requiredFields.length) * 100);
    return {
        percentage: completion,
        isComplete: completion === 100
    };
};

// @desc    Get user profile
// @route   GET /api/profile
// @access  Private
const getProfile = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const completionStatus = calculateProfileCompletion(user);

        res.status(200).json({
            success: true,
            data: user,
            profileCompletion: completionStatus.percentage,
            profileComplete: completionStatus.isComplete
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update user profile
// @route   PUT /api/profile
// @access  Private
const updateProfile = async (req, res, next) => {
    try {
        const {
            name,
            phone,
            dateOfBirth,
            gender,
            district,
            caste,
            annualIncome,
            educationLevel,
            stream,
            institution,
            yearOfStudy
        } = req.body;

        // Validation for income
        if (annualIncome !== undefined && annualIncome !== null) {
            if (isNaN(annualIncome) || Number(annualIncome) < 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Annual income must be a valid non-negative number'
                });
            }
        }

        const profileFields = {};
        if (name) profileFields.name = name;
        if (phone !== undefined) profileFields.phone = phone;
        if (dateOfBirth) profileFields.dateOfBirth = dateOfBirth;
        if (gender) profileFields.gender = gender;
        if (district) profileFields.district = district;
        if (caste) profileFields.caste = caste;
        if (annualIncome !== undefined) profileFields.annualIncome = Number(annualIncome);
        if (educationLevel) profileFields.educationLevel = educationLevel;
        if (stream) profileFields.stream = stream;
        if (institution) profileFields.institution = institution;
        if (yearOfStudy) profileFields.yearOfStudy = yearOfStudy;

        let user = await User.findByIdAndUpdate(
            req.user.id,
            { $set: profileFields },
            { new: true, runValidators: true }
        ).select('-password');

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const completionStatus = calculateProfileCompletion(user);

        res.status(200).json({
            success: true,
            data: user,
            profileCompletion: completionStatus.percentage,
            profileComplete: completionStatus.isComplete
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getProfile,
    updateProfile,
    calculateProfileCompletion
};
