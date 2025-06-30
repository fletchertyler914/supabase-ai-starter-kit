#!/usr/bin/env node

// Complete Supabase Authentication Test
// Tests: signup, login, protected API access
// Usage: node test-auth-complete.js

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
const BASE_URL = 'http://localhost:8000';

console.log('🧪 Complete Supabase Authentication Test\n');

// Test login with confirmed user
function testLogin() {
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
        'Content-Length': data.length,
        apikey: ANON_KEY,
      },
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
    req.write(data);
    req.end();
  });
}

// Test protected API endpoint with JWT
function testProtectedEndpoint(accessToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 8000,
      path: '/rest/v1/profiles',
      method: 'GET',
      headers: {
        apikey: ANON_KEY,
        Authorization: `Bearer ${accessToken}`,
      },
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
    req.end();
  });
}

// Test user info endpoint
function testUserInfo(accessToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 8000,
      path: '/auth/v1/user',
      method: 'GET',
      headers: {
        apikey: ANON_KEY,
        Authorization: `Bearer ${accessToken}`,
      },
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
    req.end();
  });
}

// Run the complete test suite
async function runCompleteTest() {
  try {
    console.log('🔐 Testing Login...');
    const loginResult = await testLogin();
    console.log(`   Status: ${loginResult.status}`);

    if (loginResult.status === 200 && loginResult.data.access_token) {
      console.log('   ✅ Login successful!');
      const accessToken = loginResult.data.access_token;
      console.log(`   🔑 Access Token: ${accessToken.substring(0, 30)}...`);

      console.log('\n👤 Testing User Info...');
      const userResult = await testUserInfo(accessToken);
      console.log(`   Status: ${userResult.status}`);
      if (userResult.status === 200) {
        console.log('   ✅ User info retrieved!');
        console.log(`   📧 Email: ${userResult.data.email}`);
        console.log(`   🆔 ID: ${userResult.data.id}`);
        console.log(
          `   ✉️  Email Confirmed: ${
            userResult.data.email_confirmed_at ? '✅' : '❌'
          }`
        );
      } else {
        console.log(
          `   ❌ Failed to get user info: ${JSON.stringify(userResult.data)}`
        );
      }

      console.log('\n🛡️  Testing Protected API Endpoint...');
      const apiResult = await testProtectedEndpoint(accessToken);
      console.log(`   Status: ${apiResult.status}`);
      if (apiResult.status === 200) {
        console.log('   ✅ Protected API access successful!');
        console.log(
          `   📊 Response: ${JSON.stringify(apiResult.data).substring(
            0,
            100
          )}...`
        );
      } else {
        console.log(`   ℹ️  API Response: ${JSON.stringify(apiResult.data)}`);
      }
    } else {
      console.log(`   ❌ Login failed: ${JSON.stringify(loginResult.data)}`);
      if (
        loginResult.status === 400 &&
        loginResult.data.msg === 'Email not confirmed'
      ) {
        console.log('\n📧 Please confirm your email first!');
        console.log('   1. Go to http://localhost:9000');
        console.log('   2. Click on the email from test@example.com');
        console.log('   3. Click the confirmation link');
        console.log('   4. Run this test again');
      }
    }
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
runCompleteTest();
