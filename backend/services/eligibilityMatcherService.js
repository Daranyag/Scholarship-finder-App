/**
 * Compare an authenticated user's profile against a scholarship's eligibility criteria.
 * @param {Object} user 
 * @param {Object} scholarship 
 * @returns {Object} { matchStatus, matchedCriteria, unverifiedCriteria, reasons }
 */
const matchScholarship = (user, scholarship) => {
    const sElig = scholarship.eligibility || {};
    
    let matchStatus = 'eligible';
    const matchedCriteria = [];
    const unverifiedCriteria = [];
    const reasons = [];
    
    // Helper to lower case arrays for comparison
    const sCaste = (sElig.caste || []).map(c => c.toLowerCase());
    const sStream = (sElig.stream || []).map(s => s.toLowerCase());
    const sLevel = (sElig.educationLevel || []).map(l => l.toLowerCase());
    const sGender = (sElig.gender || 'Any').toLowerCase();
    const sIncomeMax = sElig.incomeMax;

    // 1. Caste Matching
    if (sCaste.length > 0 && !sCaste.includes('all') && !sCaste.includes('any')) {
        if (!user.caste) {
            matchStatus = 'needs_verification';
            unverifiedCriteria.push('caste');
            reasons.push("Your category is missing from your profile.");
        } else if (sCaste.includes(user.caste.toLowerCase()) || sCaste.includes('minority') /* Simplify logic */) {
            matchedCriteria.push('caste');
            reasons.push("Your category matches the scholarship requirement.");
        } else {
            return {
                matchStatus: 'not_eligible',
                matchedCriteria,
                unverifiedCriteria,
                reasons: ["This scholarship is restricted to categories other than your reported category."]
            };
        }
    } else {
        matchedCriteria.push('caste');
    }

    // 2. Income Matching
    if (sIncomeMax !== undefined && sIncomeMax !== null) {
        if (user.annualIncome === undefined || user.annualIncome === null) {
            matchStatus = 'needs_verification';
            unverifiedCriteria.push('income');
            reasons.push("Your annual family income is missing from your profile.");
        } else if (user.annualIncome <= sIncomeMax) {
            matchedCriteria.push('income');
            reasons.push("Your annual income is within the listed limit.");
        } else {
            return {
                matchStatus: 'not_eligible',
                matchedCriteria,
                unverifiedCriteria,
                reasons: ["The listed income limit is below your reported family income."]
            };
        }
    } else {
        unverifiedCriteria.push('income');
    }

    // 3. Stream Matching
    if (sStream.length > 0 && !sStream.includes('all') && !sStream.includes('any')) {
        if (!user.stream) {
            matchStatus = 'needs_verification';
            unverifiedCriteria.push('stream');
            reasons.push("Your stream is missing from your profile.");
        } else if (sStream.includes(user.stream.toLowerCase())) {
            matchedCriteria.push('stream');
            reasons.push("Your stream matches the scholarship requirement.");
        } else {
            return {
                matchStatus: 'not_eligible',
                matchedCriteria,
                unverifiedCriteria,
                reasons: ["Your stream does not match the scholarship requirement."]
            };
        }
    } else {
        matchedCriteria.push('stream');
    }

    // 4. Education Level Matching
    if (sLevel.length > 0 && !sLevel.includes('all') && !sLevel.includes('any')) {
        if (!user.educationLevel) {
            matchStatus = 'needs_verification';
            unverifiedCriteria.push('level');
            reasons.push("Your education level is missing from your profile.");
        } else if (sLevel.includes(user.educationLevel.toLowerCase())) {
            matchedCriteria.push('level');
            reasons.push("Your education level matches.");
        } else {
            return {
                matchStatus: 'not_eligible',
                matchedCriteria,
                unverifiedCriteria,
                reasons: ["Your education level does not match."]
            };
        }
    } else {
        matchedCriteria.push('level');
    }

    // 5. Gender Matching
    if (sGender !== 'any' && sGender !== 'all' && sGender !== '') {
        if (!user.gender) {
            matchStatus = 'needs_verification';
            unverifiedCriteria.push('gender');
            reasons.push("Your gender is missing from your profile.");
        } else if (user.gender.toLowerCase() === sGender) {
            matchedCriteria.push('gender');
            reasons.push("Your gender matches.");
        } else {
            return {
                matchStatus: 'not_eligible',
                matchedCriteria,
                unverifiedCriteria,
                reasons: ["This scholarship is restricted by gender."]
            };
        }
    } else {
        matchedCriteria.push('gender');
    }

    if (matchStatus === 'eligible' && unverifiedCriteria.length > 0) {
        matchStatus = 'possibly_eligible';
    }

    return {
        scholarshipId: scholarship._id,
        matchStatus,
        matchedCriteria,
        unverifiedCriteria,
        reasons
    };
};

module.exports = {
    matchScholarship
};
