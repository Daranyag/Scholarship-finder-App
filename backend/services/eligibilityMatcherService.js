const matchScholarship = (user, scholarship, answers = {}) => {
    const sElig = scholarship.eligibility || {};
    const results = [];

    // Helper to lower case arrays for comparison
    const sCaste = (sElig.caste || []).map(c => c.toLowerCase());
    const sStream = (sElig.stream || []).map(s => s.toLowerCase());
    const sLevel = (sElig.educationLevel || []).map(l => l.toLowerCase());
    const sGender = (sElig.gender || 'Any').toLowerCase();
    const sIncomeMax = sElig.incomeMax;

    // 1. Caste Matching
    if (sCaste.length > 0 && !sCaste.includes('all') && !sCaste.includes('any')) {
        const userCaste = user.caste ? user.caste.toLowerCase() : null;
        if (!userCaste) {
            results.push({
                type: 'caste',
                label: 'Community Requirement',
                userValue: 'Missing',
                requiredValue: sElig.caste.join(', '),
                status: 'UNKNOWN',
                reason: 'Your category is missing from your profile.',
            });
        } else if (sCaste.includes(userCaste) || (sCaste.includes('minority') && userCaste === 'minority')) {
            results.push({
                type: 'caste',
                label: 'Community Requirement',
                userValue: user.caste,
                requiredValue: sElig.caste.join(', '),
                status: 'MATCHED',
                reason: 'Your category matches the scholarship requirement.',
            });
        } else {
            results.push({
                type: 'caste',
                label: 'Community Requirement',
                userValue: user.caste,
                requiredValue: sElig.caste.join(', '),
                status: 'NOT_MATCHED',
                reason: 'This scholarship is restricted to categories other than your reported category.',
            });
        }
    }

    // 2. Income Matching
    if (sIncomeMax !== undefined && sIncomeMax !== null) {
        if (user.annualIncome === undefined || user.annualIncome === null) {
            results.push({
                type: 'income',
                label: 'Income Limit',
                userValue: 'Missing',
                requiredValue: `₹${sIncomeMax}`,
                status: 'UNKNOWN',
                reason: 'Your annual family income is missing from your profile.',
            });
        } else if (user.annualIncome <= sIncomeMax) {
            results.push({
                type: 'income',
                label: 'Income Limit',
                userValue: `₹${user.annualIncome}`,
                requiredValue: `₹${sIncomeMax}`,
                status: 'MATCHED',
                reason: 'Your annual family income is within the listed limit.',
            });
        } else {
            results.push({
                type: 'income',
                label: 'Income Limit',
                userValue: `₹${user.annualIncome}`,
                requiredValue: `₹${sIncomeMax}`,
                status: 'NOT_MATCHED',
                reason: 'Your reported annual family income exceeds the income limit listed for this scholarship.',
            });
        }
    }

    // 3. Stream Matching
    if (sStream.length > 0 && !sStream.includes('all') && !sStream.includes('any')) {
        const userStream = user.stream ? user.stream.toLowerCase() : null;
        if (!userStream) {
            results.push({
                type: 'stream',
                label: 'Course / Stream',
                userValue: 'Missing',
                requiredValue: sElig.stream.join(', '),
                status: 'UNKNOWN',
                reason: 'Your stream is missing from your profile.',
            });
        } else if (sStream.includes(userStream)) {
            results.push({
                type: 'stream',
                label: 'Course / Stream',
                userValue: user.stream,
                requiredValue: sElig.stream.join(', '),
                status: 'MATCHED',
                reason: 'Your stream matches the scholarship requirement.',
            });
        } else {
            results.push({
                type: 'stream',
                label: 'Course / Stream',
                userValue: user.stream,
                requiredValue: sElig.stream.join(', '),
                status: 'NOT_MATCHED',
                reason: 'The scholarship requires an eligible course.',
            });
        }
    }

    // 4. Education Level Matching
    if (sLevel.length > 0 && !sLevel.includes('all') && !sLevel.includes('any')) {
        const userLevel = user.educationLevel ? user.educationLevel.toLowerCase() : null;
        if (!userLevel) {
            results.push({
                type: 'educationLevel',
                label: 'Education Level',
                userValue: 'Missing',
                requiredValue: sElig.educationLevel.join(', '),
                status: 'UNKNOWN',
                reason: 'Your education level is missing from your profile.',
            });
        } else if (sLevel.includes(userLevel)) {
            results.push({
                type: 'educationLevel',
                label: 'Education Level',
                userValue: user.educationLevel,
                requiredValue: sElig.educationLevel.join(', '),
                status: 'MATCHED',
                reason: 'Your education level matches.',
            });
        } else {
            results.push({
                type: 'educationLevel',
                label: 'Education Level',
                userValue: user.educationLevel,
                requiredValue: sElig.educationLevel.join(', '),
                status: 'NOT_MATCHED',
                reason: 'Your education level does not match.',
            });
        }
    }

    // 5. Gender Matching
    if (sGender !== 'any' && sGender !== 'all' && sGender !== '') {
        const userGender = user.gender ? user.gender.toLowerCase() : null;
        if (!userGender) {
            results.push({
                type: 'gender',
                label: 'Gender',
                userValue: 'Missing',
                requiredValue: scholarship.eligibility.gender,
                status: 'UNKNOWN',
                reason: 'Your gender is missing from your profile.',
            });
        } else if (userGender === sGender) {
            results.push({
                type: 'gender',
                label: 'Gender',
                userValue: user.gender,
                requiredValue: scholarship.eligibility.gender,
                status: 'MATCHED',
                reason: 'Your gender matches.',
            });
        } else {
            results.push({
                type: 'gender',
                label: 'Gender',
                userValue: user.gender,
                requiredValue: scholarship.eligibility.gender,
                status: 'NOT_MATCHED',
                reason: 'This scholarship is restricted by gender.',
            });
        }
    }

    // 6. Additional Requirements (from Module 10A)
    if (scholarship.additionalRequirements && scholarship.additionalRequirements.length > 0) {
        for (let i = 0; i < scholarship.additionalRequirements.length; i++) {
            const req = scholarship.additionalRequirements[i];
            const qId = req._id ? req._id.toString() : i.toString();
            const answer = answers[qId];

            if (answer === undefined || answer === null || answer === '') {
                results.push({
                    type: 'additional',
                    label: req.question,
                    userValue: 'Missing',
                    requiredValue: req.requiredValue?.toString(),
                    status: 'UNKNOWN',
                    reason: 'Required information is missing.',
                    sourceText: req.sourceText
                });
            } else {
                let isMatch = false;
                if (req.type === 'yes_no') {
                    isMatch = (answer.toString() === req.requiredValue.toString());
                } else {
                    isMatch = (answer.toString().toLowerCase() === req.requiredValue.toString().toLowerCase());
                }

                if (isMatch) {
                    results.push({
                        type: 'additional',
                        label: req.question,
                        userValue: answer.toString() === 'true' ? 'Yes' : (answer.toString() === 'false' ? 'No' : answer.toString()),
                        requiredValue: req.requiredValue?.toString() === 'true' ? 'Yes' : (req.requiredValue?.toString() === 'false' ? 'No' : req.requiredValue?.toString()),
                        status: 'MATCHED',
                        reason: 'Matches requirement.',
                        sourceText: req.sourceText
                    });
                } else {
                    results.push({
                        type: 'additional',
                        label: req.question,
                        userValue: answer.toString() === 'true' ? 'Yes' : (answer.toString() === 'false' ? 'No' : answer.toString()),
                        requiredValue: req.requiredValue?.toString() === 'true' ? 'Yes' : (req.requiredValue?.toString() === 'false' ? 'No' : req.requiredValue?.toString()),
                        status: 'NOT_MATCHED',
                        reason: 'Did not meet requirement.',
                        sourceText: req.sourceText
                    });
                }
            }
        }
    }

    // 7. Calculate overall status based on strict rules
    let finalStatus = 'LIKELY_ELIGIBLE';
    
    const hasFail = results.some(r => r.status === 'NOT_MATCHED');
    const hasUnknown = results.some(r => r.status === 'UNKNOWN');
    const hasVerification = results.some(r => r.status === 'REQUIRES_VERIFICATION' || r.status === 'CONFLICT');

    if (hasFail) {
        finalStatus = 'DOES_NOT_MEET_LISTED_REQUIREMENTS';
    } else if (hasUnknown) {
        finalStatus = 'NOT_ENOUGH_INFORMATION';
    } else if (hasVerification) {
        finalStatus = 'NEEDS_VERIFICATION';
    }

    // 8. Required Documents Mapping (Dummy mapping based on found criteria for now)
    const requiredDocuments = [];
    if (sCaste.length > 0 && !sCaste.includes('all') && !sCaste.includes('any')) {
        requiredDocuments.push({ name: 'Community Certificate', status: 'Verification Pending' });
    }
    if (sIncomeMax !== undefined && sIncomeMax !== null) {
        requiredDocuments.push({ name: 'Income Certificate', status: 'Verification Pending' });
    }

    // 9. Format final output
    return {
        status: finalStatus,
        summary: _generateSummary(finalStatus),
        matchedRequirements: results.filter(r => r.status === 'MATCHED'),
        failedRequirements: results.filter(r => r.status === 'NOT_MATCHED'),
        missingRequirements: results.filter(r => r.status === 'UNKNOWN'),
        verificationRequired: results.filter(r => r.status === 'REQUIRES_VERIFICATION' || r.status === 'CONFLICT'),
        conflicts: results.filter(r => r.status === 'CONFLICT'),
        requiredDocuments: requiredDocuments,
        sources: scholarship.sourceUrl ? [{ url: scholarship.sourceUrl, name: scholarship.sourceName }] : []
    };
};

function _generateSummary(status) {
    switch (status) {
        case 'LIKELY_ELIGIBLE':
            return 'All currently known requirements are matched. Verification may still be required.';
        case 'DOES_NOT_MEET_LISTED_REQUIREMENTS':
            return 'Because one or more mandatory requirements are not met, the scholarship does not currently match the information provided.';
        case 'NOT_ENOUGH_INFORMATION':
            return 'Eligibility Cannot Be Determined Yet. Some mandatory information is missing.';
        case 'NEEDS_VERIFICATION':
            return 'Your provided information matches the currently known requirements, but some information/documents require verification.';
        default:
            return '';
    }
}

module.exports = {
    matchScholarship
};
