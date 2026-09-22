/**
 * Helper service to normalize extracted raw data into our Mongoose schema format.
 */

// Helper to parse income limits from text
// E.g., "Parental annual income should not exceed Rs.2.50 lakh." -> 250000
const parseIncomeLimit = (text) => {
    if (!text) return null;
    const lower = text.toLowerCase();
    
    // Look for patterns like "Rs.2.50 lakh" or "Rs.2,50,000"
    if (lower.includes('2.50 lakh') || lower.includes('2.5 lakh') || lower.includes('2,50,000')) {
        return 250000;
    }
    if (lower.includes('2.00 lakh') || lower.includes('2 lakh') || lower.includes('2,00,000')) {
        return 200000;
    }
    if (lower.includes('1.00 lakh') || lower.includes('1 lakh') || lower.includes('1,00,000')) {
        return 100000;
    }
    return null;
};

// Helper to deduce caste/community eligibility
// E.g., "Most Backward Classes and Denotified Communities" -> ["MBC", "DNC"]
const parseCaste = (text) => {
    if (!text) return ['Any'];
    const lower = text.toLowerCase();
    const castes = [];
    
    if (lower.includes('bc') || lower.includes('backward class') && !lower.includes('most')) {
        castes.push('BC');
    }
    if (lower.includes('mbc') || lower.includes('most backward class')) {
        castes.push('MBC');
    }
    if (lower.includes('dnc') || lower.includes('denotified')) {
        castes.push('DNC');
    }
    if (lower.includes('sc') || lower.includes('scheduled caste')) {
        castes.push('SC');
    }
    if (lower.includes('st') || lower.includes('scheduled tribe')) {
        castes.push('ST');
    }
    
    return castes.length > 0 ? castes : ['Any'];
};

// Helper to deduce education level
// E.g., "studying in 11th and 12th standards" -> ["11th", "12th"]
const parseEducationLevel = (text) => {
    if (!text) return ['Any'];
    const lower = text.toLowerCase();
    const levels = [];
    
    if (lower.includes('10th') || lower.includes('x standard')) levels.push('10th');
    if (lower.includes('11th') || lower.includes('xi standard') || lower.includes('+1')) levels.push('11th');
    if (lower.includes('12th') || lower.includes('xii standard') || lower.includes('+2') || lower.includes('plus two')) levels.push('12th');
    if (lower.includes('ug') || lower.includes('under graduate') || lower.includes('degree')) levels.push('UG');
    if (lower.includes('pg') || lower.includes('post graduate')) levels.push('PG');
    if (lower.includes('diploma') || lower.includes('polytechnic')) levels.push('Diploma');
    if (lower.includes('professional')) levels.push('Professional');
    if (lower.includes('ph.d') || lower.includes('phd')) levels.push('Ph.D');
    if (lower.includes('iti')) levels.push('ITI');
    
    return levels.length > 0 ? levels : ['Any'];
};

const parseGender = (text) => {
    if (!text) return 'Any';
    const lower = text.toLowerCase();
    if (lower.includes('girl') || lower.includes('women') || lower.includes('female')) {
        return 'Female';
    }
    if (lower.includes('boy') || lower.includes('male')) {
        return 'Male';
    }
    return 'Any';
};

const normalizeRecord = (rawRecord) => {
    return {
        title: rawRecord.title,
        organization: rawRecord.organization,
        description: rawRecord.description,
        amount: rawRecord.amount || 'Amount not specified',
        eligibility: {
            caste: parseCaste(rawRecord.eligibilityText),
            incomeMax: parseIncomeLimit(rawRecord.eligibilityText),
            stream: ['Any'], // Not enough info in this source usually
            educationLevel: parseEducationLevel(rawRecord.eligibilityText),
            gender: parseGender(rawRecord.eligibilityText)
        },
        deadline: rawRecord.deadline || 'Not specified',
        applyUrl: rawRecord.applyUrl || '',
        sourceUrl: rawRecord.sourceUrl,
        sourceName: rawRecord.sourceName,
        documents: [], // Source doesn't list exact docs easily
        lastUpdated: new Date(),
        isActive: true,
        category: 'All', // We can improve categorization later
        iconName: 'star',
        colorName: 'amber'
    };
};

module.exports = {
    parseIncomeLimit,
    parseCaste,
    parseEducationLevel,
    parseGender,
    normalizeRecord
};
