#!/bin/bash

# Helper script to extract API keys for Postman setup
# Usage: ./setup-keys.sh

echo "🔑 Supabase API Keys for Postman Setup"
echo "======================================"
echo ""

if [[ ! -f ../.env ]]; then
    if [[ -f "../.env.example" ]]; then
        echo "📄 .env file not found, copying from .env.example..."
        if cp ../.env.example ../.env 2>/dev/null; then
            echo "✅ Environment file created from .env.example"
            echo "⚠️  Please review and update the .env file with your actual values before proceeding"
        else
            echo "❌ Failed to copy .env.example to .env"
            exit 1
        fi
    else
        echo "❌ .env.example file not found! Cannot create .env file."
        echo "   Please create a .env file with the required environment variables."
        exit 1
    fi
fi

if [[ ! -f ../.env ]]; then
    echo "❌ .env file not found!"
    exit 1
fi

ANON_KEY=$(grep ANON_KEY ../.env | cut -d'=' -f2)
SERVICE_KEY=$(grep SERVICE_ROLE_KEY ../.env | cut -d'=' -f2)

if [[ -z "$ANON_KEY" ]]; then
    echo "❌ ANON_KEY not found in .env file"
    exit 1
fi

if [[ -z "$SERVICE_KEY" ]]; then
    echo "❌ SERVICE_ROLE_KEY not found in .env file"
    exit 1
fi

echo "📋 Copy these keys to your Postman environment:"
echo ""
echo "🔸 anon_key:"
echo "$ANON_KEY"
echo ""
echo "🔸 service_role_key:"
echo "$SERVICE_KEY"
echo ""
echo "📍 Instructions:"
echo "1. Open Postman"
echo "2. Select 'Supabase AI Starter Kit - Local Development' environment"
echo "3. Update the environment variables with the keys above"
echo "4. Replace YOUR_SUPABASE_ANON_KEY_HERE with the anon_key"
echo "5. Replace YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE with the service_role_key"
echo ""
echo "🚀 Then run your first test: 'Kong Health Check' in the collection" 
