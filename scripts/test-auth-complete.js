#!/usr/bin/env node

// Complete Supabase Authentication Test
// Tests: admin user provision, login, protected API access
// Usage: node test-auth-complete.js

const http = require('http');
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

// Read environment variables
const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};
envContent.split('\n').forEach((line) => {
  const [key, value] = line.split('=');
  if (key && value) envVars[key.trim()] = value.trim();
});

const ANON_KEY = envVars.ANON_KEY;
const SERVICE_ROLE_KEY = envVars.SERVICE_ROLE_KEY;
const BASE_URL = 'http://localhost:8000';
const TEST_EMAIL = `auth-test-${Date.now()}@example.com`;
const TEST_PASSWORD = 'testpassword123';

console.log('🧪 Complete Supabase Authentication Test\n');

function httpJsonRequest({ method, path, headers = {}, body }) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : '';
    const defaultHeaders = {
      'Content-Type': 'application/json',
      ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
    };

    const options = {
      hostname: 'localhost',
      port: 8000,
      path,
      method,
      headers: { ...defaultHeaders, ...headers },
    };

    const req = http.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => (responseData += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, data: responseData });
        }
      });
    });

    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function ensureConfirmedUser(email, password) {
  return httpJsonRequest({
    method: 'POST',
    path: '/auth/v1/admin/users',
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
    },
    body: {
      email,
      password,
      email_confirm: true,
      user_metadata: { source: 'test-auth-complete' },
    },
  });
}

// Test login with confirmed user
async function testLogin(email, password) {
  return httpJsonRequest({
    method: 'POST',
    path: '/auth/v1/token?grant_type=password',
    headers: { apikey: ANON_KEY },
    body: { email, password },
  });
}

// Test protected API endpoint with JWT
async function testProtectedEndpoint(accessToken) {
  return httpJsonRequest({
    method: 'GET',
    path: '/rest/v1/',
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${accessToken}`,
    },
  });
}

// Test user info endpoint
async function testUserInfo(accessToken) {
  return httpJsonRequest({
    method: 'GET',
    path: '/auth/v1/user',
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${accessToken}`,
    },
  });
}

// Run the complete test suite
async function runCompleteTest() {
  if (!ANON_KEY || !SERVICE_ROLE_KEY) {
    console.error('❌ Missing ANON_KEY or SERVICE_ROLE_KEY in .env');
    process.exit(1);
  }

  try {
    console.log(`👤 Provisioning confirmed test user (${TEST_EMAIL})...`);
    const createUserResult = await ensureConfirmedUser(TEST_EMAIL, TEST_PASSWORD);
    if (![200, 201, 422].includes(createUserResult.status)) {
      console.log(`   Status: ${createUserResult.status}`);
      console.log(`   ❌ User provision failed: ${JSON.stringify(createUserResult.data)}`);
      process.exit(1);
    }
    console.log(`   ✅ User provision response status: ${createUserResult.status}`);

    console.log('\n🔐 Testing Login...');
    const loginResult = await testLogin(TEST_EMAIL, TEST_PASSWORD);
    if (loginResult.status !== 200 || !loginResult.data.access_token) {
      console.log(`   Status: ${loginResult.status}`);
      console.log(`   ❌ Login failed: ${JSON.stringify(loginResult.data)}`);
      process.exit(1);
    }
    console.log('   ✅ Login successful!');
    const accessToken = loginResult.data.access_token;
    console.log(`   🔑 Access Token: ${accessToken.substring(0, 30)}...`);

    console.log('\n👤 Testing User Info...');
    const userResult = await testUserInfo(accessToken);
    if (userResult.status !== 200) {
      console.log(`   Status: ${userResult.status}`);
      console.log(`   ❌ Failed to get user info: ${JSON.stringify(userResult.data)}`);
      process.exit(1);
    }
    console.log('   ✅ User info retrieved!');
    console.log(`   📧 Email: ${userResult.data.email}`);
    console.log(`   🆔 ID: ${userResult.data.id}`);
    console.log(
      `   ✉️  Email Confirmed: ${
        userResult.data.email_confirmed_at ? '✅' : '❌'
      }`
    );

    console.log('\n🛡️  Testing Protected API Endpoint...');
    const apiResult = await testProtectedEndpoint(accessToken);
    if (apiResult.status !== 200) {
      console.log(`   Status: ${apiResult.status}`);
      console.log(`   ❌ Protected API access failed: ${JSON.stringify(apiResult.data)}`);
      process.exit(1);
    }
    console.log('   ✅ Protected API access successful!');

    console.log('\n🎉 Complete auth test passed.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    process.exit(1);
  }
}

// Run the test
runCompleteTest();
