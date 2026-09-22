// 1. Load environment variables
require('dotenv').config();

// 2. Validate required configuration
const requiredEnvVars = ['PORT', 'MONGODB_URI', 'JWT_SECRET', 'NODE_ENV'];
const missingVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingVars.length > 0) {
    console.error(`[ERROR] Missing required environment variables: ${missingVars.join(', ')}`);
}

const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');

// Import Routes
const healthRoutes = require('./routes/healthRoutes');
const authRoutes = require('./routes/authRoutes');
const profileRoutes = require('./routes/profileRoutes');
const scholarshipRoutes = require('./routes/scholarshipRoutes');
const adminRoutes = require('./routes/adminRoutes');
const cron = require('node-cron');
const { runFetch } = require('./services/scholarshipFetcherService');

// Import Middleware
const notFoundMiddleware = require('./middleware/notFoundMiddleware');
const errorMiddleware = require('./middleware/errorMiddleware');

const app = express();

// 3. Connect to MongoDB
connectDB();

// Initialize automatic fetch cron job
const intervalDays = process.env.SCHOLARSHIP_FETCH_INTERVAL_DAYS || 7;
// Note: node-cron allows */X for day of month. Alternatively, if it's 7, '0 0 * * 0' is every Sunday.
// We'll use a dynamic expression: '0 0 */INTERVAL * *'
const cronExpression = `0 0 */${intervalDays} * *`;
cron.schedule(cronExpression, async () => {
    console.log(`[Scheduler] Running automatic scholarship fetch (Every ${intervalDays} days)...`);
    await runFetch();
});

// 4. Initialize Express (done above)

// 5. Register middleware
app.use(cors()); // Allow all origins for development
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 6. Register routes
app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/scholarships', scholarshipRoutes);
app.use('/api/admin/scholarships', adminRoutes);

// 7. Register 404 middleware
app.use(notFoundMiddleware);

// 8. Register error middleware
app.use(errorMiddleware);

// 9. Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT} in ${process.env.NODE_ENV} mode`);
});
