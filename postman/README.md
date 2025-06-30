# Postman API Testing Setup

This directory contains Postman collections and environments for testing your Supabase AI Starter Kit APIs.

## 🚀 Quick Setup

### 1. Import Collection & Environment

1. Open Postman
2. Import `Supabase-AI-Starter-Kit.postman_collection.json`
3. Import `Supabase-AI-Starter-Kit.postman_environment.json`
4. Select the "Supabase AI Starter Kit - Local Development" environment

### 2. Configure API Keys (IMPORTANT!)

**Security Note:** Never commit actual API keys to version control!

1. Get your API keys from the `.env` file:

   ```bash
   grep -E "SUPABASE_ANON_KEY|SUPABASE_SERVICE_ROLE_KEY" .env
   ```

2. In Postman, update the environment variables:
   - `anon_key`: Replace `YOUR_SUPABASE_ANON_KEY_HERE` with your actual anon key
   - `service_role_key`: Replace `YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE` with your actual service role key

### 3. Test Your Setup

Run the requests in this order:

1. **Health Checks** → Test all services are running
2. **Authentication** → Create test user and login
3. **Database Operations** → Test CRUD operations
4. **Edge Functions** → Test serverless functions

## 📁 Collection Structure

### 🏥 Health & Status

- **Kong Health Check** - Verify API gateway is running
- **Supabase Health** - Check all Supabase services
- **n8n Health** - Verify n8n is accessible
- **Ollama Health** - Check local LLM service

### 🔐 Authentication

- **Sign Up** - Create new user account
- **Sign In** - Authenticate and get JWT token
- **Get User** - Retrieve current user profile
- **Refresh Token** - Renew authentication token

### 🗄️ Database Operations

- **List Profiles** - Get all user profiles
- **Create Profile** - Add new user profile
- **Update Profile** - Modify existing profile
- **Delete Profile** - Remove user profile

### ⚡ Edge Functions

- **Hello Function** - Test basic edge function
- **Main Function** - Test advanced edge function

### 🤖 n8n Integration (Coming Soon)

- **List Workflows** - Get available n8n workflows
- **Trigger Webhook** - Execute workflow via webhook
- **NodeBot Chat** - Test AI chatbot workflow
- **Ollama Chat** - Test local LLM integration

## 🔧 Environment Variables

| Variable           | Description                     | Example                 |
| ------------------ | ------------------------------- | ----------------------- |
| `base_url`         | Kong API Gateway URL            | `http://localhost:8000` |
| `anon_key`         | Supabase anonymous key          | `eyJhbGci...`           |
| `service_role_key` | Supabase service role key       | `eyJhbGci...`           |
| `user_jwt`         | User JWT token (auto-populated) | `eyJhbGci...`           |
| `test_email`       | Test user email                 | `test@example.com`      |
| `test_password`    | Test user password              | `testpassword123`       |

## 🛡️ Security Best Practices

1. **Never commit API keys** - Always use placeholder values in committed files
2. **Use environment-specific keys** - Different keys for dev/staging/prod
3. **Rotate keys regularly** - Generate new keys periodically
4. **Limit key permissions** - Use anon keys for client-side, service role for backend only
5. **Monitor key usage** - Track API usage in Supabase dashboard

## 🐛 Troubleshooting

### Common Issues

**"Unauthorized" errors:**

- Check if your API keys are correctly set in environment variables
- Verify the keys are not expired
- Ensure you're using the right key for the operation (anon vs service_role)

**Connection errors:**

- Verify Docker services are running: `docker compose ps`
- Check if Kong is accessible: `curl http://localhost:8000/health`
- Ensure environment variables match your setup

**Authentication failures:**

- Verify email/password auth is enabled in Supabase dashboard
- Check if test user exists or needs to be created
- Confirm JWT token is valid and not expired

## 📊 Testing Workflow

1. **Start with Health Checks** - Ensure all services are operational
2. **Test Authentication** - Create user, login, get profile
3. **Verify Database Access** - CRUD operations with proper auth
4. **Test Edge Functions** - Serverless function execution
5. **Future: n8n Integration** - Webhook and workflow testing

## 🚀 Next Steps

As you implement the Kong-n8n integration, new endpoints will be added to:

- Secure n8n API behind Kong with Supabase auth
- Test workflow execution with proper authentication
- Validate webhook security and access controls
