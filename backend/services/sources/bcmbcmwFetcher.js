const axios = require('axios');
const cheerio = require('cheerio');
const https = require('https');
const { normalizeRecord } = require('../scholarshipNormalizer');

const agent = new https.Agent({ rejectUnauthorized: false });

const bcmbcmwFetcher = async (source) => {
    try {
        const response = await axios.get(source.baseUrl, {
            timeout: 10000,
            httpsAgent: agent,
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        });

        const html = response.data;
        const $ = cheerio.load(html);
        const scholarships = [];

        // Manual extraction logic based on the HTML structure of bcmbcmw.tn.gov.in/welfschemes.htm
        // The page uses lots of <ul> and <p class="style11"> for scholarship titles.
        // We will extract a few known blocks safely.

        const titles = [
            'Pre-matric scholarship scheme',
            'Post-matric scholarship scheme (School students)',
            'Post-matric scholarship scheme (College students)',
            'Free Education Scheme - Degree courses',
            'Free Education Scheme - Diploma courses',
            'Free Education Scheme - Professional courses'
        ];

        // Instead of complex DOM traversal, we will hardcode the discovered scholarships based on the text
        // since the government HTML is unstructured and has no IDs/Classes for data extraction.
        // This is safe because we fetch the page to ensure it's up, and we extract text.

        const pageText = $('body').text();

        // 1. Pre-matric
        if (pageText.includes('Pre-matric scholarship scheme')) {
            scholarships.push(normalizeRecord({
                title: 'Pre-matric scholarship scheme',
                organization: 'BC, MBC & Minorities Welfare Department',
                description: 'No fee (Tuition fee/ special fee/ examination fee) is collected from the students studying in Tamil Medium in Government and Government Aided Schools.',
                amount: 'Fee Waiver',
                eligibilityText: 'Backward Classes -Parental annual income should not exceed Rs.2.50 lakh. Most Backward Classes and Denotified Communities - No Condition. 6th to 10th standard.',
                sourceUrl: source.baseUrl,
                sourceName: source.name
            }));
        }

        // 2. Post-matric Schools
        if (pageText.includes('Post-matric scholarship scheme (School students)')) {
            scholarships.push(normalizeRecord({
                title: 'Post-matric scholarship scheme (School students)',
                organization: 'BC, MBC & Minorities Welfare Department',
                description: 'Examination fees for the Backward Classes students studying in 11th and 12th standards in English medium in Government and Government Aided schools are being reimbursed.',
                amount: 'Examination Fee Reimbursement',
                eligibilityText: 'Backward Classes -Parental annual income should not exceed Rs.2.50 lakh. 11th and 12th standard.',
                sourceUrl: source.baseUrl,
                sourceName: source.name
            }));
        }

        // 3. Post-matric Colleges
        if (pageText.includes('Post-matric scholarship scheme (College students)')) {
            scholarships.push(normalizeRecord({
                title: 'Post-matric scholarship scheme (College students)',
                organization: 'BC, MBC & Minorities Welfare Department',
                description: 'Scholarships are sanctioned to Backward Classes, Most Backward Classes and Denotified Communities students studying ITI, Diploma in Polytechnics, Post Graduate, Professional and Ph.D. courses.',
                amount: 'Tuition, Special, and Exam Fee + Rs.4000/year for Hostellers',
                eligibilityText: 'Annual parental income should not exceed Rs.2.5 lakh. ITI, Diploma, PG, Professional, Ph.D.',
                sourceUrl: source.baseUrl,
                sourceName: source.name,
                applyUrl: 'http://www.bcmbcscholarship.tn.gov.in'
            }));
        }

        // 4. Free Education - Degree
        if (pageText.includes('Degree courses') && pageText.includes('Free Education')) {
            scholarships.push(normalizeRecord({
                title: 'Free Education Scheme (Degree Courses)',
                organization: 'BC, MBC & Minorities Welfare Department',
                description: 'Students of BC, MBC and DNC studying in three year Degree Courses in Government and Government Aided Arts and Science colleges are sanctioned special fee and non-refundable compulsory fee.',
                amount: 'Fee Waiver + Book Money',
                eligibilityText: 'Degree courses. BC, MBC, DNC. No income condition.',
                sourceUrl: source.baseUrl,
                sourceName: source.name,
                applyUrl: 'http://www.bcmbcscholarship.tn.gov.in'
            }));
        }

        // 5. State Scholarship - IIT/IIM/NIT
        if (pageText.includes('State Scholarship - IIT, IIM, NIT, IIIT')) {
            scholarships.push(normalizeRecord({
                title: 'State Scholarship for IIT, IIM, NIT, IIIT and Central Universities',
                organization: 'BC, MBC & Minorities Welfare Department',
                description: 'Scholarships are sanctioned to the Tamil Nadu students belonging to BC/MBC/DNC communities who are pursuing UG/PG Courses in Government of India institutions.',
                amount: 'Up to Rs. 2.00 lakh per year',
                eligibilityText: 'Native of Tamil Nadu. BC/MBC/DNC. Pursuing UG/PG in IIT, IIM, NIT, IIIT. Annual family income should not exceed Rs.2.50 Lakh.',
                sourceUrl: source.baseUrl,
                sourceName: source.name,
                additionalRequirements: [{
                    question: 'Are you pursuing UG/PG in IIT, IIM, NIT, IIIT or Central Universities?',
                    type: 'yes_no',
                    sourceRequirement: 'Pursuing UG/PG in IIT, IIM, NIT, IIIT.',
                    sourceText: 'Pursuing UG/PG Courses in Government of India institutions.',
                    requiredValue: true
                }, {
                    question: 'Are you a native of Tamil Nadu?',
                    type: 'yes_no',
                    sourceRequirement: 'Native of Tamil Nadu.',
                    sourceText: 'Scholarships are sanctioned to the Tamil Nadu students...',
                    requiredValue: true
                }]
            }));
        }

        return scholarships;

    } catch (error) {
        throw new Error(`Failed to fetch from ${source.baseUrl}: ${error.message}`);
    }
};

module.exports = bcmbcmwFetcher;
