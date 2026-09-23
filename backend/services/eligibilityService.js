const pdf = require('pdf-parse');
const Tesseract = require('tesseract.js');
const axios = require('axios');
const cheerio = require('cheerio');
const https = require('https');

// Helper: Text to Criteria Extractor
const extractCriteria = (text) => {
    const textLower = text.toLowerCase();
    const criteria = {
        title: 'Unknown Scholarship',
        caste: [],
        incomeMax: null,
        educationLevel: [],
        stream: [],
        deadline: null,
        documents: []
    };

    if (textLower.includes('bc') || textLower.includes('backward class')) criteria.caste.push('BC');
    if (textLower.includes('mbc') || textLower.includes('most backward')) criteria.caste.push('MBC');
    if (textLower.includes('sc') || textLower.includes('scheduled caste')) criteria.caste.push('SC');
    if (textLower.includes('st') || textLower.includes('scheduled tribe')) criteria.caste.push('ST');
    if (textLower.includes('minority')) criteria.caste.push('Minority');

    const incomeMatch = textLower.match(/income.*?(rs\.?|rupees|₹)\s*([\d,]+(\.\d{1,2})?)\s*(lakh|lakhs)?/i);
    if (incomeMatch) {
        let amtStr = incomeMatch[2].replace(/,/g, '');
        let amt = parseFloat(amtStr);
        if (incomeMatch[4]) amt = amt * 100000;
        criteria.incomeMax = amt;
    }

    if (textLower.match(/\b(b\.?e|b\.?tech|engineering)\b/i)) criteria.stream.push('Engineering');
    if (textLower.match(/\b(mbbs|bds|medical)\b/i)) criteria.stream.push('Medical');
    
    if (textLower.match(/\b(ug|under\s?graduate|degree|bachelor)\b/i)) criteria.educationLevel.push('UG Degree');
    if (textLower.match(/\b(pg|post\s?graduate|master)\b/i)) criteria.educationLevel.push('PG Degree');

    const dateMatch = textLower.match(/(last date|deadline|closing date).*?(\d{1,2}(st|nd|rd|th)?[\s\-\/](jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s\-\/]\d{2,4}|\d{1,2}[\-\/]\d{1,2}[\-\/]\d{2,4})/i);
    if (dateMatch) {
        criteria.deadline = dateMatch[2];
    }

    const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 5);
    if (lines.length > 0) {
        criteria.title = lines[0].substring(0, 50) + (lines[0].length > 50 ? '...' : '');
    }

    return criteria;
};

const analyzeSource = async (sourceType, url, fileBuffer) => {
    let extractedText = '';
    let sourceName = 'Unknown';
    
    if (sourceType === 'url') {
        if (!url) throw Object.assign(new Error('URL is required'), { statusCode: 400 });
        sourceName = url;
        const agent = new https.Agent({ rejectUnauthorized: false });
        const response = await axios.get(url, { timeout: 10000, httpsAgent: agent, maxRedirects: 2 });
        const $ = cheerio.load(response.data);
        extractedText = $('body').text();
    } 
    else if (sourceType === 'pdf') {
        if (!fileBuffer) throw Object.assign(new Error('PDF file is required'), { statusCode: 400 });
        sourceName = 'Uploaded PDF Document';
        const data = await pdf(fileBuffer);
        extractedText = data.text;
    } 
    else if (sourceType === 'image') {
        if (!fileBuffer) throw Object.assign(new Error('Image file is required'), { statusCode: 400 });
        sourceName = 'Uploaded Image';
        const worker = await Tesseract.createWorker('eng');
        const ret = await worker.recognize(fileBuffer);
        extractedText = ret.data.text;
        await worker.terminate();
    } else {
        throw Object.assign(new Error('Invalid source type'), { statusCode: 400 });
    }

    if (!extractedText || extractedText.trim().length < 20) {
        throw Object.assign(new Error('Unable to determine eligibility from the available information. The document could not be read clearly.'), { statusCode: 400 });
    }

    const criteria = extractCriteria(extractedText);
    
    return {
        status: 'success',
        sourceType,
        extractedData: {
            title: criteria.title,
            sourceName: sourceName,
            eligibility: {
                caste: criteria.caste,
                incomeMax: criteria.incomeMax,
                stream: criteria.stream,
                educationLevel: criteria.educationLevel
            },
            deadline: criteria.deadline
        }
    };
};

module.exports = {
    analyzeSource,
    extractCriteria
};
