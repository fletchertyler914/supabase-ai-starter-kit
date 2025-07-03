#!/usr/bin/env node

// Test script for Supabase Authentication
// Usage: node test-auth.js

const https = require('https');
const http = require('http');

// Read environment variables
const fs = require('fs');

// Check for .env file and copy from .env.example if it doesn't exist
if (!fs.existsSync('.env')) {
  if (fs.existsSync('.env.example')) {
    console.log('📄 .env file not found, copying from .env.example...');
    try {
      fs.copyFileSync('.env.example', '.env');
      console.log('✅ Environment file created from .env.example');
      console.log(
        '⚠️  Please review and update the .env file with your actual values before proceeding\n'
      );
    } catch (error) {
      console.error('❌ Failed to copy .env.example to .env:', error.message);
      process.exit(1);
    }
  } else {
    console.error('❌ .env.example file not found! Cannot create .env file.');
    console.error(
      '   Please create a .env file with the required environment variables.'
    );
    process.exit(1);
  }
}

const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};
envContent.split('\n').forEach((line) => {
  const [key, value] = line.split('=');
  if (key && value) envVars[key.trim()] = value.trim();
});

const ANON_KEY = envVars.ANON_KEY;
const BASE_URL = 'http://localhost:8000'; // Kong proxy
const AUTH_URL = `${BASE_URL}/auth/v1`;

console.log('🧪 Testing Supabase Authentication...\n');

// Test signup
function testSignup() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      email: 'test@example.com',
      password: 'testpassword123',
    });

    const options = {
      hostname: 'localhost',
      port: 8000,
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
        console.log(`📝 Signup Response (${res.statusCode}):`);
        try {
          const parsed = JSON.parse(body);
          console.log(JSON.stringify(parsed, null, 2));
          resolve(parsed);
        } catch (e) {
          console.log('Raw response:', body);
          resolve({ error: 'Invalid JSON response' });
        }
      });
    });

    req.on('error', (err) => {
      console.log('❌ Signup failed:', err.message);
      reject(err);
    });

    req.setTimeout(5000, () => {
      console.log('❌ Signup timeout');
      req.destroy();
      reject(new Error('Timeout'));
    });

    req.write(data);
    req.end();
  });
}

// Test signin
function testSignin() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      email: 'test@example.com',
      password: 'testpassword123',
    });

    const options = {
      hostname: 'localhost',
      port: 8000,
      path: '/auth/v1/token?grant_type=password',
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
        console.log(`\n🔑 Signin Response (${res.statusCode}):`);
        try {
          const parsed = JSON.parse(body);
          console.log(JSON.stringify(parsed, null, 2));
          resolve(parsed);
        } catch (e) {
          console.log('Raw response:', body);
          resolve({ error: 'Invalid JSON response' });
        }
      });
    });

    req.on('error', (err) => {
      console.log('❌ Signin failed:', err.message);
      reject(err);
    });

    req.setTimeout(5000, () => {
      console.log('❌ Signin timeout');
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
    `- ANON_KEY: ${ANON_KEY ? ANON_KEY.substring(0, 20) + '...' : 'NOT FOUND'}`
  );
  console.log(`- AUTH_URL: ${AUTH_URL}\n`);

  try {
    // Test 1: Signup
    console.log('🚀 Test 1: User Signup');
    await testSignup();

    // Wait a moment
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Test 2: Signin
    console.log('🚀 Test 2: User Signin');
    await testSignin();

    console.log('\n✅ Auth tests completed!');
  } catch (error) {
    console.log('\n❌ Tests failed:', error.message);
  }
}

runTests();
