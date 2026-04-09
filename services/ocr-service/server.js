const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
require('dotenv').config();

// ==========================================
// Configuration
// ==========================================

const PORT = process.env.PORT || 8089;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const NODE_ENV = process.env.NODE_ENV || 'dev';

// ==========================================
// Logging Configuration
// ==========================================

const logger = winston.createLogger({
    level: LOG_LEVEL,
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'ocr-service', environment: NODE_ENV },
    transports: [
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        })
    ]
});

// ==========================================
// Express App Setup
// ==========================================

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Request logging
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`, {
        method: req.method,
        path: req.path,
        query: req.query,
        ip: req.ip
    });
    next();
});

// ==========================================
// Health Check
// ==========================================

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'UP',
        service: 'ocr-service',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// ==========================================
// Mock OCR Endpoints
// ==========================================

/**
 * Extract text and data from documents
 * POST /api/ocr/extract
 */
app.post('/api/ocr/extract', (req, res) => {
    try {
        const { document_type, file_path, file_data } = req.body;

        if (!document_type) {
            return res.status(400).json({
                success: false,
                error: 'document_type is required'
            });
        }

        const requestId = uuidv4();
        logger.info('OCR Extraction Request', {
            requestId,
            documentType: document_type,
            filePathProvided: !!file_path,
            fileDataSize: file_data ? Buffer.byteLength(file_data, 'utf8') : 0
        });

        // Mock response based on document type
        const mockResponses = {
            'VEHICLE_LICENSE': {
                success: true,
                requestId,
                documentType: document_type,
                extractedFields: {
                    vehicleNumber: 'AB1234CD',
                    ownerName: 'John Doe',
                    registrationNumber: 'REG123456',
                    engineNumber: 'EN123456789',
                    chassisNumber: 'CH123456789',
                    modelYear: 2021,
                    fuelType: 'Diesel',
                    color: 'Black',
                    registrationDate: '2021-01-15',
                    expiryDate: '2026-01-15'
                },
                confidence: 0.95,
                processingTime: Math.random() * 2000 + 500
            },
            'DRIVER_LICENSE': {
                success: true,
                requestId,
                documentType: document_type,
                extractedFields: {
                    licenseNumber: 'DL123456789',
                    name: 'Jane Smith',
                    dateOfBirth: '1990-05-20',
                    gender: 'Female',
                    address: '123 Main Street, Seoul',
                    issueDate: '2019-06-01',
                    expiryDate: '2029-06-01',
                    restrictions: 'None',
                    licenseClass: 'B'
                },
                confidence: 0.93,
                processingTime: Math.random() * 2000 + 500
            },
            'BUSINESS_REGISTRATION': {
                success: true,
                requestId,
                documentType: document_type,
                extractedFields: {
                    businessNumber: '123-45-67890',
                    companyName: 'SKEP Corporation',
                    representative: 'Park Min-jun',
                    businessAddress: '456 Business Park, Seoul',
                    businessType: 'Technology Services',
                    businessCategory: 'Software Development',
                    registrationDate: '2015-03-10',
                    capitalAmount: '500,000,000'
                },
                confidence: 0.94,
                processingTime: Math.random() * 2000 + 500
            },
            'PASSPORT': {
                success: true,
                requestId,
                documentType: document_type,
                extractedFields: {
                    passportNumber: 'P123456789',
                    fullName: 'Kim Su-jin',
                    nationality: 'South Korea',
                    dateOfBirth: '1985-08-15',
                    gender: 'Female',
                    issueDate: '2017-04-01',
                    expiryDate: '2027-04-01',
                    issuingCountry: 'KOR'
                },
                confidence: 0.96,
                processingTime: Math.random() * 2000 + 500
            },
            'ID_CARD': {
                success: true,
                requestId,
                documentType: document_type,
                extractedFields: {
                    idNumber: '900515-1234567',
                    name: 'Lee Ji-woo',
                    dateOfBirth: '1990-05-15',
                    gender: 'Male',
                    address: '789 Apartment, Busan',
                    issueDate: '2018-05-15',
                    expiryDate: '2028-05-15'
                },
                confidence: 0.92,
                processingTime: Math.random() * 2000 + 500
            }
        };

        const response = mockResponses[document_type] || {
            success: true,
            requestId,
            documentType: document_type,
            extractedFields: {
                rawText: 'Sample extracted text from document',
                metadata: {
                    pages: 1,
                    language: 'ko'
                }
            },
            confidence: 0.85,
            processingTime: Math.random() * 2000 + 500
        };

        logger.info('OCR Extraction Completed', {
            requestId,
            success: true,
            confidence: response.confidence
        });

        res.status(200).json(response);

    } catch (error) {
        logger.error('OCR Extraction Error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: error.message
        });
    }
});

/**
 * Validate document image quality
 * POST /api/ocr/validate
 */
app.post('/api/ocr/validate', (req, res) => {
    try {
        const { file_data, document_type } = req.body;

        if (!file_data) {
            return res.status(400).json({
                success: false,
                error: 'file_data is required'
            });
        }

        const requestId = uuidv4();
        logger.info('Document Validation Request', {
            requestId,
            documentType: document_type
        });

        // Mock validation response
        const isValid = Math.random() > 0.1; // 90% pass rate

        const response = {
            success: true,
            requestId,
            isValid,
            quality: {
                brightness: Math.random() * 100,
                contrast: Math.random() * 100,
                sharpness: Math.random() * 100,
                glare: Math.random() * 50
            },
            recommendations: isValid ? [] : ['Image quality is too low', 'Please ensure adequate lighting']
        };

        logger.info('Document Validation Completed', {
            requestId,
            isValid,
            quality: response.quality
        });

        res.status(200).json(response);

    } catch (error) {
        logger.error('Document Validation Error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

/**
 * Get OCR service status
 * GET /api/ocr/status
 */
app.get('/api/ocr/status', (req, res) => {
    res.status(200).json({
        status: 'operational',
        service: 'ocr-service',
        version: '1.0.0',
        capabilities: [
            'VEHICLE_LICENSE',
            'DRIVER_LICENSE',
            'BUSINESS_REGISTRATION',
            'PASSPORT',
            'ID_CARD'
        ],
        supportedFormats: ['image/jpeg', 'image/png', 'application/pdf'],
        timestamp: new Date().toISOString()
    });
});

// ==========================================
// Error Handling
// ==========================================

// 404 Handler
app.use((req, res) => {
    logger.warn('Route not found', {
        method: req.method,
        path: req.path
    });
    res.status(404).json({
        success: false,
        error: 'Route not found',
        path: req.path
    });
});

// Global error handler
app.use((err, req, res, next) => {
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        method: req.method,
        path: req.path
    });
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// ==========================================
// Server Start
// ==========================================

const server = app.listen(PORT, () => {
    logger.info(`OCR Service started successfully`, {
        port: PORT,
        environment: NODE_ENV,
        logLevel: LOG_LEVEL
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, gracefully shutting down...');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, gracefully shutting down...');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

module.exports = app;
