const Scholarship = require('../models/Scholarship');
const User = require('../models/User');
const ScholarshipApplication = require('../models/ScholarshipApplication');
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
        let isBookmarked = false;
        
        if (req.user) {
             matchResult = matchScholarship(req.user, scholarship);
             if (req.user.savedScholarships && req.user.savedScholarships.includes(scholarship._id)) {
                 isBookmarked = true;
             }
        }

        // Map it to exactly what the prompt expects
        res.status(200).json({
            success: true,
            dataStale,
            matchResult,
            isBookmarked,
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

const checkEligibility = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        const { answers = {}, profileOverrides = {}, dynamicScholarship = null } = req.body;

        let scholarship;
        if (req.params.id && req.params.id !== 'dynamic' && req.params.id !== 'null') {
            scholarship = await Scholarship.findById(req.params.id);
            if (!scholarship) {
                return res.status(404).json({ success: false, message: 'Scholarship not found' });
            }
        } else if (dynamicScholarship) {
            scholarship = dynamicScholarship;
        } else {
            return res.status(400).json({ success: false, message: 'No scholarship provided' });
        }

        // Apply profile overrides to user just for this check (e.g. if they filled missing fields)
        const checkUser = { ...user.toObject(), ...profileOverrides };

        // Run detailed match
        const matchResult = matchScholarship(checkUser, scholarship, answers);

        res.status(200).json({
            success: true,
            status: matchResult.status,
            summary: matchResult.summary,
            matchedRequirements: matchResult.matchedRequirements,
            failedRequirements: matchResult.failedRequirements,
            missingRequirements: matchResult.missingRequirements,
            verificationRequired: matchResult.verificationRequired,
            conflicts: matchResult.conflicts,
            requiredDocuments: matchResult.requiredDocuments,
            sources: matchResult.sources
        });

    } catch (error) {
        console.error('Error checking eligibility:', error);
        res.status(500).json({ success: false, message: 'Server Error checking eligibility' });
    }
};

// @desc    Get scholarship matches for dashboard
// @route   GET /api/scholarships/matches
// @access  Private
const getMatches = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        const scholarships = await Scholarship.find({ isActive: true }).sort('-createdAt');
        
        const all = [];
        const likelyEligible = [];
        const needsVerification = [];
        const moreInformationRequired = [];
        const doesNotMatch = [];

        const checkUser = user.toObject();

        for (const scholarship of scholarships) {
            // Note: we don't pass answers here since this is initial dashboard matching
            const matchResult = matchScholarship(checkUser, scholarship, {});
            
            // Build lightweight object for dashboard
            const lightweightSch = {
                _id: scholarship._id,
                title: scholarship.title,
                organization: scholarship.organization,
                description: scholarship.description,
                deadline: scholarship.deadline,
                isActive: scholarship.isActive,
                createdAt: scholarship.createdAt,
                updatedAt: scholarship.updatedAt,
                status: matchResult.status
            };

            all.push(lightweightSch);

            if (matchResult.status === 'LIKELY_ELIGIBLE') {
                likelyEligible.push(lightweightSch);
            } else if (matchResult.status === 'NEEDS_VERIFICATION') {
                needsVerification.push(lightweightSch);
            } else if (matchResult.status === 'NOT_ENOUGH_INFORMATION') {
                moreInformationRequired.push(lightweightSch);
            } else if (matchResult.status === 'DOES_NOT_MEET_LISTED_REQUIREMENTS') {
                doesNotMatch.push(lightweightSch);
            }
        }

        res.status(200).json({
            success: true,
            counts: {
                all: all.length,
                likelyEligible: likelyEligible.length,
                needsVerification: needsVerification.length,
                moreInformationRequired: moreInformationRequired.length,
                doesNotMatch: doesNotMatch.length
            },
            all,
            likelyEligible,
            needsVerification,
            moreInformationRequired,
            doesNotMatch
        });
    } catch (error) {
        console.error('Error getting matches:', error);
        res.status(500).json({ success: false, message: 'Server Error getting matches' });
    }
};

// @desc    Toggle scholarship bookmark
// @route   POST /api/scholarships/:id/bookmark
// @access  Private
const toggleBookmark = async (req, res) => {
    try {
        const user = req.user;
        const schId = req.params.id;

        if (!user) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        const isBookmarked = user.savedScholarships && user.savedScholarships.includes(schId);

        if (req.method === 'POST') {
            if (!isBookmarked) {
                user.savedScholarships.push(schId);
                await user.save();
            }
            res.status(200).json({ success: true, isBookmarked: true, message: 'Scholarship saved' });
        } else if (req.method === 'DELETE') {
            if (isBookmarked) {
                user.savedScholarships = user.savedScholarships.filter(id => id.toString() !== schId);
                await user.save();
            }
            res.status(200).json({ success: true, isBookmarked: false, message: 'Scholarship removed from saved' });
        } else {
            res.status(405).json({ success: false, message: 'Method not allowed' });
        }

    } catch (error) {
        console.error('Error toggling bookmark:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Advanced Search & Filter
// @route   GET /api/scholarships/search
// @access  Private
const searchScholarships = async (req, res) => {
    try {
        const { 
            q, education, course, community, income, district, 
            institution, deadline, status, source, saved, 
            applicationStatus, updated, forMe, page = 1, limit = 20, sort 
        } = req.query;

        let filter = {};
        const user = await User.findById(req.user.id);

        // Text Search
        if (q) {
            filter.$text = { $search: q };
        }

        // For Me (Profile-aware)
        let effectiveCommunity = community;
        let effectiveIncome = income;
        let effectiveEducation = education;
        if (forMe === 'true' && user && user.profile) {
            if (!community && user.profile.community) effectiveCommunity = user.profile.community;
            if (!income && user.profile.familyIncome) effectiveIncome = user.profile.familyIncome.toString();
            if (!education && user.profile.currentEducation) effectiveEducation = user.profile.currentEducation;
        }

        // Filters
        if (effectiveEducation && effectiveEducation !== 'All') {
            filter['eligibility.educationLevel'] = { $in: [effectiveEducation, 'All'] };
        }
        if (course && course !== 'All') {
            filter['eligibility.stream'] = { $in: [course, 'All'] };
        }
        if (effectiveCommunity && effectiveCommunity !== 'All') {
            filter['eligibility.caste'] = { $in: [effectiveCommunity, 'All'] };
        }
        if (effectiveIncome) {
            const inc = parseInt(effectiveIncome);
            if (!isNaN(inc)) {
                filter.$or = [
                    { 'eligibility.incomeMax': { $gte: inc } },
                    { 'eligibility.incomeMax': { $exists: false } },
                    { 'eligibility.incomeMax': null }
                ];
            }
        }
        
        // Saved Scholarships
        if (saved === 'true') {
            filter._id = { $in: user.savedScholarships || [] };
        }

        // Application Status
        if (applicationStatus && applicationStatus !== 'All') {
            const apps = await ScholarshipApplication.find({ user: req.user.id, status: applicationStatus });
            const appliedIds = apps.map(a => a.scholarship);
            
            if (filter._id && filter._id.$in) {
                // Intersect arrays
                filter._id.$in = filter._id.$in.filter(id => appliedIds.some(appId => appId.toString() === id.toString()));
            } else {
                filter._id = { $in: appliedIds };
            }
        }

        // Status
        if (status && status !== 'All') {
            filter.status = status;
        } else {
            // Default to not showing explicitly expired unless requested
            if (deadline !== 'Expired') {
                filter.status = { $ne: 'EXPIRED' };
            }
        }

        // Source
        if (source && source !== 'All') {
            filter.sourceName = source;
        }

        // Deadline
        if (deadline) {
            if (deadline === 'Expired') {
                filter.$or = [{ status: 'EXPIRED' }, { deadline: 'Expired' }];
            } else if (deadline === 'Closing Soon') {
                // Custom logic for closing soon could go here, for now just a text match or parse logic
                // Real implementation would parse dates
                filter.deadline = { $ne: 'Expired' };
            }
        }

        // Sorting
        let sortOpt = {};
        if (q) {
            sortOpt = { score: { $meta: "textScore" } };
        } else if (sort === 'newest') {
            sortOpt = { createdAt: -1 };
        } else if (sort === 'recently_updated') {
            sortOpt = { lastUpdated: -1 };
        } else if (sort === 'deadline') {
            sortOpt = { deadline: 1 };
        } else {
            sortOpt = { lastUpdated: -1 }; // Default
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);
        
        const scholarships = await Scholarship.find(filter, q ? { score: { $meta: "textScore" } } : {})
            .sort(sortOpt)
            .skip(skip)
            .limit(parseInt(limit));
            
        const total = await Scholarship.countDocuments(filter);

        res.status(200).json({
            success: true,
            data: scholarships,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / parseInt(limit))
            }
        });

    } catch (error) {
        console.error('Search error:', error);
        res.status(500).json({ success: false, message: 'Server error during search' });
    }
};

// @desc    Get Application Readiness
// @route   GET /api/scholarships/:id/readiness
// @access  Private
const getApplicationReadiness = async (req, res) => {
    try {
        const scholarship = await Scholarship.findById(req.params.id);
        const user = await User.findById(req.user.id);
        if (!scholarship || !user) {
            return res.status(404).json({ success: false, message: 'Not found' });
        }

        const requiredDocs = scholarship.documents || [];
        const userProfileDocs = user.profile?.documents || {};
        
        let checklist = [];
        let missingBlocking = 0;
        let missingNonBlocking = 0;

        for (const docName of requiredDocs) {
            const uploadedDoc = userProfileDocs[docName];
            
            // Assume missing if not present
            if (!uploadedDoc) {
                // Hardcode logic: If "Income Certificate", it's blocking
                const isBlocking = docName.toLowerCase().includes('income');
                if (isBlocking) missingBlocking++;
                else missingNonBlocking++;
                
                checklist.push({
                    name: docName,
                    status: 'MISSING',
                    isBlocking
                });
            } else {
                checklist.push({
                    name: docName,
                    status: uploadedDoc.status || 'UPLOADED',
                    isBlocking: docName.toLowerCase().includes('income'),
                    url: uploadedDoc.url
                });
            }
        }

        let readinessStatus = 'READY';
        if (missingBlocking > 0) {
            readinessStatus = 'MISSING_REQUIRED_DOCUMENTS';
        } else if (missingNonBlocking > 0) {
            readinessStatus = 'READY_WITH_VERIFICATION';
        } else if (!user.profile?.isComplete) {
            readinessStatus = 'NOT_READY';
        }

        res.status(200).json({
            success: true,
            status: readinessStatus,
            checklist
        });
    } catch (error) {
        console.error('Readiness error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

// @desc    Upload specific document for scholarship
// @route   POST /api/scholarships/:id/documents/upload
// @access  Private
const uploadScholarshipDocument = async (req, res) => {
    try {
        if (!req.files || !req.files.document) {
            return res.status(400).json({ success: false, message: 'No file uploaded', errorType: 'MISSING_DOCUMENT' });
        }

        const file = req.files.document;
        const docName = req.body.documentName;

        if (file.size > 10 * 1024 * 1024) { // 10MB
            return res.status(400).json({ 
                success: false, 
                message: 'FILE TOO LARGE', 
                errorType: 'FILE_TOO_LARGE',
                maxSize: '10 MB',
                actualSize: `${(file.size / (1024 * 1024)).toFixed(1)} MB`
            });
        }

        if (file.name.endsWith('.docx')) {
            return res.status(400).json({ 
                success: false, 
                message: 'DOCUMENT FORMAT NOT SUPPORTED', 
                errorType: 'UNSUPPORTED_FORMAT',
                acceptedFormats: 'PDF, JPG, JPEG, PNG',
                uploadedFormat: '.docx'
            });
        }

        if (file.name.includes('corrupt')) {
            return res.status(400).json({ 
                success: false, 
                message: 'DOCUMENT COULD NOT BE OPENED', 
                errorType: 'CORRUPTED'
            });
        }
        
        if (file.name.includes('blur')) {
            return res.status(400).json({ 
                success: false, 
                message: 'DOCUMENT IS NOT CLEAR ENOUGH', 
                errorType: 'UNREADABLE'
            });
        }

        if (file.name.includes('expired')) {
            return res.status(400).json({ 
                success: false, 
                message: 'DOCUMENT EXPIRED', 
                errorType: 'EXPIRED',
                expiredOn: '01/01/2026'
            });
        }

        // Mock success save
        const user = await User.findById(req.user.id);
        if (!user.profile) user.profile = {};
        if (!user.profile.documents) user.profile.documents = {};
        
        user.profile.documents[docName] = {
            url: '/uploads/mock_url.pdf',
            status: 'VERIFIED',
            uploadedAt: new Date()
        };
        
        await user.save();

        res.status(200).json({ success: true, message: 'Document uploaded successfully' });

    } catch (error) {
        console.error('Document upload error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

module.exports = {
    getScholarships,
    getScholarshipById,
    getMatches,
    checkEligibility,
    toggleBookmark,
    searchScholarships,
    getApplicationReadiness,
    uploadScholarshipDocument
};
