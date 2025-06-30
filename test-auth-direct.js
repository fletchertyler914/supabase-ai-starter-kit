#!/usr/bin/env node

// Test script for Supabase Authentication - Direct to Auth Service
// Usage: node test-auth-direct.js

const http = require('http');
const fs = require('fs');

// Read environment variables
const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};
envContent.split('\n').forEach((line) => {
  const [key, value] = line.split('=');
  if (key && value) envVars[key.trim()] = value.trim();
});

const ANON_KEY = envVars.ANON_KEY;

console.log('🧪 Testing Supabase Auth Service Directly...\n');

// Test direct auth service connection
function testAuthService() {
  return new Promise((resolve, reject) => {
    // Test different possible auth endpoints
    const endpoints = [
      { host: 'localhost', port: 9999, path: '/health' }, // GoTrue direct
      { host: 'localhost', port: 54321, path: '/auth/v1/health' }, // Supabase local
    ];

    let successCount = 0;
    let results = [];

    endpoints.forEach((endpoint, index) => {
      const options = {
        hostname: endpoint.host,
        port: endpoint.port,
        path: endpoint.path,
        method: 'GET',
        headers: {
          apikey: ANON_KEY,
        },
      };

      const req = http.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          const result = {
            endpoint: `${endpoint.host}:${endpoint.port}${endpoint.path}`,
            status: res.statusCode,
            success: res.statusCode === 200,
            body: body,
          };
          results.push(result);

          if (res.statusCode === 200) {
            successCount++;
            console.log(`✅ ${result.endpoint} - Working!`);
          } else {
            console.log(`❌ ${result.endpoint} - Status: ${res.statusCode}`);
          }

          if (results.length === endpoints.length) {
            resolve({ results, successCount });
          }
        });
      });

      req.on('error', (err) => {
        const result = {
          endpoint: `${endpoint.host}:${endpoint.port}${endpoint.path}`,
          status: 'ERROR',
          success: false,
          error: err.message,
        };
        results.push(result);
        console.log(`❌ ${result.endpoint} - ${err.message}`);

        if (results.length === endpoints.length) {
          resolve({ results, successCount });
        }
      });

      req.setTimeout(3000, () => {
        req.destroy();
        const result = {
          endpoint: `${endpoint.host}:${endpoint.port}${endpoint.path}`,
          status: 'TIMEOUT',
          success: false,
          error: 'Timeout',
        };
        results.push(result);
        console.log(`❌ ${result.endpoint} - Timeout`);

        if (results.length === endpoints.length) {
          resolve({ results, successCount });
        }
      });

      req.end();
    });
  });
}

// Test signup using docker internal network
function testSignupDirect() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      email: 'test@example.com',
      password: 'testpassword123',
    });

    // Try to connect to auth container directly via docker compose
    const options = {
      hostname: 'localhost',
      port: 54321, // Supabase local development port
      path: '/auth/v1/signup',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: ANON_KEY,
        'Content-Length': data.length,
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        console.log(`\n📝 Direct Signup Response (${res.statusCode}):`);
        try {
          const parsed = JSON.parse(body);
          console.log(JSON.stringify(parsed, null, 2));
          resolve(parsed);
        } catch (e) {
          console.log('Raw response:', body);
          resolve({ error: 'Invalid JSON response', status: res.statusCode });
        }
      });
    });

    req.on('error', (err) => {
      console.log('❌ Direct signup failed:', err.message);
      reject(err);
    });

    req.setTimeout(5000, () => {
      console.log('❌ Direct signup timeout');
      req.destroy();
      reject(new Error('Timeout'));
    });

    req.write(data);
    req.end();
  });
}

// Run tests
async function runTests() {
  console.log('🔧 Environment check:');
  console.log(
    `- ANON_KEY: ${
      ANON_KEY ? ANON_KEY.substring(0, 20) + '...' : 'NOT FOUND'
    }\n`
  );

  try {
    // Test 1: Auth service connectivity
    console.log('🚀 Test 1: Auth Service Connectivity');
    const connectivityResults = await testAuthService();

    if (connectivityResults.successCount > 0) {
      // Test 2: Signup functionality
      console.log('\n🚀 Test 2: User Signup (Direct)');
      await testSignupDirect();
    } else {
      console.log('\n❌ No auth endpoints accessible - skipping signup test');
    }

    console.log('\n✅ Direct auth tests completed!');
  } catch (error) {
    console.log('\n❌ Direct tests failed:', error.message);
  }
}

runTests();
