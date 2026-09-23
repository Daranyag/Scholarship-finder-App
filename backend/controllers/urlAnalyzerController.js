const urlAnalyzerService = require('../services/urlAnalyzerService');

// Map to track requests for rate limiting (simple in-memory)
const rateLimitMap = new Map();

exports.analyzeUrl = async (req, res) => {
  const { url } = req.body;

  if (!url || typeof url !== 'string' || (!url.startsWith('http://') && !url.startsWith('https://'))) {
    return res.status(400).json({ success: false, message: 'Please enter a valid scholarship website URL.' });
  }

  // Rate Limiting (max 5 requests per 5 minutes per user/IP)
  const clientIdentifier = req.user ? req.user.id : (req.ip || 'unknown');
  const now = Date.now();
  const limitWindow = 5 * 60 * 1000;
  
  if (!rateLimitMap.has(clientIdentifier)) {
    rateLimitMap.set(clientIdentifier, []);
  }
  
  let userRequests = rateLimitMap.get(clientIdentifier);
  userRequests = userRequests.filter(time => now - time < limitWindow);
  
  if (userRequests.length >= 5) {
    return res.status(429).json({ success: false, message: 'The website is temporarily rate limiting requests.' });
  }
  
  userRequests.push(now);
  rateLimitMap.set(clientIdentifier, userRequests);

  try {
    const result = await urlAnalyzerService.analyzeUrl(url);

    if (!result.success) {
      if (result.error === 'UNSAFE_URL') {
         return res.status(403).json({ success: false, message: 'The website does not allow automated access.' });
      }
      if (result.error === 'TIMEOUT') {
         return res.status(408).json({ success: false, message: 'The website took too long to respond.' });
      }
      if (result.error === 'JS_RENDERED') {
         return res.status(400).json({ success: false, message: 'This webpage requires browser-rendered content and could not be fully analyzed.' });
      }
      if (result.error && result.error.startsWith('HTTP_404')) {
         return res.status(404).json({ success: false, message: 'The scholarship webpage was not found.' });
      }
      if (result.error && result.error.startsWith('HTTP_403')) {
         return res.status(403).json({ success: false, message: 'The website does not allow automated access.' });
      }
      if (result.error && result.error.startsWith('HTTP_429')) {
         return res.status(429).json({ success: false, message: 'The website is temporarily rate limiting requests.' });
      }

      return res.status(400).json({ success: false, message: 'Unable to access this website.' });
    }

    return res.json(result);
  } catch (error) {
    console.error('URL Analyzer Error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error during analysis.' });
  }
};
