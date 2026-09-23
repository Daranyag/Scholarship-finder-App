const axios = require('axios');
const cheerio = require('cheerio');
const url = require('url');
const dns = require('dns').promises;

// Simple SSRF protection
async function isSafeUrl(urlString) {
  try {
    const parsedUrl = new URL(urlString);
    if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
      return false;
    }
    
    // Check hostname
    const hostname = parsedUrl.hostname;
    
    // Block obvious local/internal hosts
    const blockedHosts = ['localhost', '127.0.0.1', '0.0.0.0', '169.254.169.254'];
    if (blockedHosts.includes(hostname) || hostname.endsWith('.local')) {
      return false;
    }

    // Resolve IP and check if it's a private IP block
    const lookupResult = await dns.lookup(hostname);
    const ip = lookupResult.address;
    
    const parts = ip.split('.').map(Number);
    if (parts.length === 4) {
      if (
        parts[0] === 10 || // 10.0.0.0/8
        (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) || // 172.16.0.0/12
        (parts[0] === 192 && parts[1] === 168) || // 192.168.0.0/16
        parts[0] === 127 || // 127.0.0.0/8
        (parts[0] === 169 && parts[1] === 254) // 169.254.0.0/16
      ) {
        return false;
      }
    }
    
    return true;
  } catch (error) {
    return false;
  }
}

function extractTextWithRegex($, regex) {
  let found = null;
  $('*').each((i, el) => {
    // Only search elements that contain direct text
    if ($(el).children().length === 0) {
      const text = $(el).text().trim();
      if (regex.test(text)) {
        found = text;
        return false; // Break loop
      }
    }
  });
  return found;
}

function extractNumber(text) {
  if (!text) return null;
  const match = text.replace(/,/g, '').match(/\d+/);
  return match ? parseInt(match[0], 10) : null;
}

exports.analyzeUrl = async (targetUrl) => {
  try {
    const isSafe = await isSafeUrl(targetUrl);
    if (!isSafe) {
      throw new Error('UNSAFE_URL');
    }

    const response = await axios.get(targetUrl, {
      timeout: 10000,
      maxContentLength: 5 * 1024 * 1024, // 5MB limit
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      }
    });

    const html = response.data;
    const $ = cheerio.load(html);
    
    // Fallbacks if body is empty or mainly scripts
    if ($('body').text().replace(/\s+/g, '').length < 100) {
      throw new Error('JS_RENDERED');
    }

    const title = $('title').text().trim() || extractTextWithRegex($, /scholarship/i) || 'Unknown Scholarship';
    
    // Amount extraction
    const amountText = extractTextWithRegex($, /(₹|Rs\.|INR)\s*\d+[,0-9]*/i);
    const amount = amountText ? amountText.match(/(₹|Rs\.|INR)\s*[\d,]+/i)[0] : null;

    // Income extraction
    const incomeText = extractTextWithRegex($, /income.*(not exceed|less than|up to|maximum).*\d+/i) || 
                       extractTextWithRegex($, /\d+\s*lakh/i);
    let income_max = null;
    if (incomeText) {
       if (incomeText.toLowerCase().includes('lakh')) {
          const match = incomeText.match(/(\d+(\.\d+)?)\s*lakh/i);
          if (match) income_max = parseFloat(match[1]) * 100000;
       } else {
          income_max = extractNumber(incomeText);
       }
    }

    // Gender
    const textBody = $('body').text().toLowerCase();
    let gender = "Any";
    if (/\b(female|women|girls)\b/.test(textBody) && !/\b(male|boys)\b/.test(textBody)) {
      gender = "Female";
    }

    // Deadline
    const deadlineText = extractTextWithRegex($, /(last date|deadline|closing date).*\d{1,2}.*20\d{2}/i);

    // Apply URL
    let applyUrl = null;
    $('a').each((i, el) => {
      const href = $(el).attr('href');
      const text = $(el).text().toLowerCase();
      if ((text.includes('apply') || text.includes('registration')) && href) {
        try {
          applyUrl = new URL(href, targetUrl).href;
          return false;
        } catch (e) {}
      }
    });

    return {
      success: true,
      sourceUrl: targetUrl,
      title,
      organization: 'Extracted from source',
      amount: amount || 'Not specified on the analyzed webpage.',
      eligibility: {
        caste: [],
        income_max: income_max,
        stream: [],
        level: [],
        gender: gender
      },
      deadline: deadlineText || 'Not specified on the analyzed webpage.',
      documents: [],
      description: 'Extracted information from official webpage. Please verify the original source.',
      applyUrl: applyUrl,
      source: new URL(targetUrl).hostname
    };
  } catch (error) {
    if (error.code === 'ECONNABORTED') {
      return { success: false, error: 'TIMEOUT' };
    }
    if (error.message === 'UNSAFE_URL') {
      return { success: false, error: 'UNSAFE_URL' };
    }
    if (error.message === 'JS_RENDERED') {
      return { success: false, error: 'JS_RENDERED' };
    }
    if (error.response) {
       return { success: false, error: `HTTP_${error.response.status}` };
    }
    return { success: false, error: 'FETCH_ERROR', message: error.message };
  }
};
