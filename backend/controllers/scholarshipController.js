const Scholarship = require('../models/Scholarship');
const { matchScholarship } = require('../services/eligibilityMatcherService');

// Initial seed data to populate the DB if it's empty
const seedScholarships = [
    {
        title: 'Tamil Nadu Merit Scholarship',
        organization: 'State Government',
        description: 'A merit-based scholarship for outstanding students in Tamil Nadu pursuing higher education. Candidates must have scored above 90% in their previous academic year.',
        amount: '₹50,000',
        eligibility: {
            caste: ['All'],
            incomeMax: 500000,
            stream: ['All'],
            educationLevel: ['UG Degree', 'PG Degree'],
            gender: 'Any'
        },
        deadline: '30 October 2026',
        applyUrl: 'https://scholarships.gov.in/',
        sourceUrl: 'https://www.tn.gov.in/department',
        sourceName: 'TN Government Official Portal',
        documents: ['Aadhaar Card', 'Income Certificate', '12th Marksheet', 'College ID'],
        isActive: true,
        category: 'Merit-Based',
        iconName: 'star',
        colorName: 'amber'
    },
    {
        title: 'Post Matric Scholarship for Minorities',
        organization: 'Ministry of Minority Affairs',
        description: 'Scholarship awarded to meritorious students belonging to minority communities to pursue higher education.',
        amount: '₹20,000',
        eligibility: {
            caste: ['Minority'],
            incomeMax: 200000,
            stream: ['All'],
            educationLevel: ['11th', '12th', 'UG Degree'],
            gender: 'Any'
        },
        deadline: '15 November 2026',
        applyUrl: 'https://scholarships.gov.in/',
        sourceUrl: 'https://www.minorityaffairs.gov.in/',
        sourceName: 'Ministry of Minority Affairs',
        documents: ['Minority Certificate', 'Income Certificate', 'Aadhaar Card'],
        isActive: true,
        category: 'Minority',
        iconName: 'group',
        colorName: 'purple'
    },
    {
        title: 'CM Girl Child Protection Scheme',
        organization: 'Dept. of Social Welfare',
        description: 'Financial assistance provided to the girl child for education and empowerment, encouraging family planning.',
        amount: '₹25,000',
        eligibility: {
            caste: ['All'],
            incomeMax: 150000,
            stream: ['All'],
            educationLevel: ['All'],
            gender: 'Female'
        },
        deadline: '01 December 2026',
        applyUrl: 'https://tnsocialwelfare.tn.gov.in/',
        sourceUrl: 'https://tnsocialwelfare.tn.gov.in/',
        sourceName: 'TN Social Welfare Dept',
        documents: ['Birth Certificate', 'Income Certificate', 'Aadhaar Card'],
        isActive: true,
        category: 'Women',
        iconName: 'female',
        colorName: 'pink'
    },
    {
        title: 'Expired Vidyadhan Scholarship',
        organization: 'Sarojini Damodaran Foundation',
        description: 'This is an example of an expired scholarship.',
        amount: '₹10,000 / year',
        eligibility: {
            caste: ['All'],
            incomeMax: 200000,
            stream: ['All'],
            educationLevel: ['11th', '12th'],
            gender: 'Any'
        },
        deadline: '01 January 2024', // Past date
        applyUrl: 'https://www.vidyadhan.org/apply',
        sourceUrl: 'https://www.vidyadhan.org/',
        sourceName: 'Vidyadhan Official',
        documents: ['10th Marksheet', 'Income Certificate', 'Photograph'],
        isActive: false, // Closed
        category: 'Need-Based',
        iconName: 'favorite',
        colorName: 'red'
    }
];

// @desc    Get all scholarships
// @route   GET /api/scholarships
// @access  Public (or Private depending on design, using Public for now to match UI)
const getScholarships = async (req, res) => {
    try {
        // Simple seed mechanism for testing
        const count = await Scholarship.countDocuments();
        if (count === 0) {
            await Scholarship.insertMany(seedScholarships);
        }

        const scholarships = await Scholarship.find().sort('-createdAt');
        
        let lastUpdated = null;
        let dataStale = 'fresh'; // 'fresh' < 7 days, 'aging' 7-14, 'stale' > 14
        
        if (scholarships.length > 0) {
            // Find the most recently updated active scholarship
            const latestScholarship = await Scholarship.findOne({ isActive: true }).sort('-lastUpdated');
            if (latestScholarship && latestScholarship.lastUpdated) {
                lastUpdated = latestScholarship.lastUpdated;
                
                const daysSinceUpdate = (new Date() - new Date(lastUpdated)) / (1000 * 60 * 60 * 24);
                if (daysSinceUpdate > 14) {
                    dataStale = 'stale';
                } else if (daysSinceUpdate > 7) {
                    dataStale = 'aging';
                }
            }
        }
        
        res.status(200).json({
            success: true,
            count: scholarships.length,
            lastUpdated: lastUpdated,
            dataStale: dataStale,
            scholarships
        });
    } catch (error) {
        console.error('Error fetching scholarships:', error);
        res.status(500).json({ success: false, message: 'Server Error fetching scholarships' });
    }
};

// @desc    Get single scholarship
// @route   GET /api/scholarships/:id
// @access  Public
const getScholarshipById = async (req, res) => {
    try {
        const scholarship = await Scholarship.findById(req.params.id);

        if (!scholarship) {
            return res.status(404).json({ success: false, message: 'Scholarship not found' });
        }

        let dataStale = 'fresh';
        if (scholarship.lastUpdated) {
            const daysSinceUpdate = (new Date() - new Date(scholarship.lastUpdated)) / (1000 * 60 * 60 * 24);
            if (daysSinceUpdate > 14) {
                dataStale = 'stale';
            } else if (daysSinceUpdate > 7) {
                dataStale = 'aging';
            }
        }

        // Optional: Run match logic if user is authenticated (which they are via protect)
        let matchResult = null;
        if (req.user) {
             matchResult = matchScholarship(req.user, scholarship);
        }

        // Map it to exactly what the prompt expects
        res.status(200).json({
            success: true,
            dataStale,
            matchResult,
            scholarship: {
                id: scholarship._id,
                title: scholarship.title,
                organization: scholarship.organization,
                description: scholarship.description,
                amount: scholarship.amount,
                eligibility: scholarship.eligibility,
                deadline: scholarship.deadline,
                applyUrl: scholarship.applyUrl,
                sourceUrl: scholarship.sourceUrl,
                sourceName: scholarship.sourceName,
                documents: scholarship.documents,
                lastUpdated: scholarship.lastUpdated,
                isActive: scholarship.isActive,
                category: scholarship.category,
                iconName: scholarship.iconName,
                colorName: scholarship.colorName
            }
        });
    } catch (error) {
        console.error('Error fetching scholarship by ID:', error);
        
        // Handle invalid MongoDB IDs
        if (error.kind === 'ObjectId') {
             return res.status(404).json({ success: false, message: 'Scholarship not found' });
        }
        
        res.status(500).json({ success: false, message: 'Server Error fetching scholarship details' });
    }
};

// @desc    Get scholarships matching the authenticated user
// @route   GET /api/scholarships/matches
// @access  Private
const getMatches = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        // Get all active scholarships
        const scholarships = await Scholarship.find({ isActive: true });
        
        // Filter out expired scholarships if deadline logic is possible
        // (Assuming deadline is string, hard to auto-expire, relying on isActive for now)

        const matches = [];
        for (const sch of scholarships) {
            const result = matchScholarship(user, sch);
            if (result.matchStatus === 'eligible' || result.matchStatus === 'possibly_eligible' || result.matchStatus === 'needs_verification') {
                matches.push({
                    scholarship: sch,
                    matchResult: result
                });
            }
        }

        res.status(200).json({
            success: true,
            count: matches.length,
            matches
        });
    } catch (error) {
        console.error('Error fetching matches:', error);
        res.status(500).json({ success: false, message: 'Server Error calculating matches' });
    }
};

module.exports = {
    getScholarships,
    getScholarshipById,
    getMatches
};
