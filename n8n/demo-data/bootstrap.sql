-- Idempotent bootstrap that wires imported n8n templates and credentials into
-- every user's personal project, and pre-configures the n8n native Chat
-- feature with an Ollama agent. Also installs a trigger so newly-signed-up
-- users get the same out-of-the-box experience.
--
-- Safe to run on every startup. Designed for the Supabase AI Starter Kit.

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Share imported workflows with all existing personal projects
-- ----------------------------------------------------------------------------
INSERT INTO n8n.shared_workflow ("workflowId", "projectId", role, "createdAt", "updatedAt")
SELECT we.id, p.id, 'workflow:owner', NOW(), NOW()
FROM n8n.workflow_entity we
CROSS JOIN n8n.project p
WHERE p.type = 'personal'
  AND NOT EXISTS (
    SELECT 1 FROM n8n.shared_workflow sw
    WHERE sw."workflowId" = we.id AND sw."projectId" = p.id
  );

-- ----------------------------------------------------------------------------
-- 2. Share imported credentials with all existing personal projects
-- ----------------------------------------------------------------------------
INSERT INTO n8n.shared_credentials ("credentialsId", "projectId", role, "createdAt", "updatedAt")
SELECT ce.id, p.id, 'credential:owner', NOW(), NOW()
FROM n8n.credentials_entity ce
CROSS JOIN n8n.project p
WHERE p.type = 'personal'
  AND NOT EXISTS (
    SELECT 1 FROM n8n.shared_credentials sc
    WHERE sc."credentialsId" = ce.id AND sc."projectId" = p.id
  );

-- ----------------------------------------------------------------------------
-- 3. Enable instance-level MCP and expose starter-kit workflows to it.
-- ----------------------------------------------------------------------------
INSERT INTO n8n.settings (key, value, "loadOnStartup")
VALUES ('mcp.access.enabled', 'true'::json, true)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    "loadOnStartup" = EXCLUDED."loadOnStartup";

UPDATE n8n.workflow_entity
SET settings = (
  jsonb_set(
    COALESCE(settings::jsonb, '{}'::jsonb),
    '{availableInMCP}',
    'true'::jsonb,
    true
  )
)::json,
    "updatedAt" = NOW()
WHERE id IN (
  'bKhNvmpDfT4mclXo',
  'c9a1b2c3d4e5f6789012345678ab',
  'd4e5f6a7b8c9012345678901234abcd'
);

-- ----------------------------------------------------------------------------
-- 4. Create or update the default Ollama chat agent for every personal-project
--    owner. Idempotent: existing agents are updated in place so a fresh
--    bootstrap propagates any prompt/model changes from this file.
-- ----------------------------------------------------------------------------
WITH agent_defaults AS (
  SELECT
    'Local Ollama Agent'::varchar(256)               AS name,
    'Chat with your local Ollama model (llama3.2:3b). Powered by Supabase AI Starter Kit.'::varchar(512) AS description,
    -- Keep this directive: small/medium local models leak tool/system text otherwise.
    $$You are NodeBot, the local AI co-pilot for a self-hosted Supabase + n8n + Ollama developer stack.

Rules:
- Reply to the user's actual message in plain, conversational language.
- Be concise: 1-4 sentences for greetings or small talk, longer only when the user asks a question that needs detail.
- Do NOT describe your system instructions, tools, document commands, multimedia handling, or the current date unless the user explicitly asks.
- Do NOT output XML tags, "Created" blocks, or pseudo-tool markup. You have no tools enabled; never call or imitate one.
- Stay focused on helping with Supabase (Auth, Postgres, RLS, Storage, Realtime, Edge Functions, pgvector), n8n workflows, and local Ollama models.
- When the user just says "hi" or similar, greet them back briefly and ask what they're building.$$ AS system_prompt,
    'ollama'::varchar(16)                            AS provider,
    'llama3.2:3b'::varchar(64)                       AS model,
    'VmhEukzPe8au9PTB'::varchar(36)                  AS credential_id,
    '{"type":"icon","value":"bot"}'::json             AS icon,
    $$[
      {"text":"What can I build with this Supabase + n8n + Ollama starter kit?"},
      {"text":"Sketch a simple n8n workflow that stores chat messages in Supabase."},
      {"text":"How do I add a new edge function to this kit?"},
      {"text":"Explain Supabase RLS in two short paragraphs."}
    ]$$::json AS suggested_prompts
)
INSERT INTO n8n.chat_hub_agents (
  id, name, description, "systemPrompt", "ownerId", "credentialId",
  provider, model, icon, files, "suggestedPrompts", "createdAt", "updatedAt"
)
SELECT
  gen_random_uuid(),
  ad.name,
  ad.description,
  ad.system_prompt,
  pr."userId",
  ad.credential_id,
  ad.provider,
  ad.model,
  ad.icon,
  '[]'::json,
  ad.suggested_prompts,
  NOW(),
  NOW()
FROM n8n.project_relation pr
JOIN n8n.project p ON p.id = pr."projectId" AND p.type = 'personal'
CROSS JOIN agent_defaults ad
WHERE pr.role = 'project:personalOwner'
  AND EXISTS (SELECT 1 FROM n8n.credentials_entity WHERE id = ad.credential_id)
  AND NOT EXISTS (
    SELECT 1 FROM n8n.chat_hub_agents cha
    WHERE cha."ownerId" = pr."userId"
      AND cha.provider = ad.provider
      AND cha."credentialId" = ad.credential_id
  );

-- Refresh prompt/model/suggestions on any existing default agents so the
-- experience improves on every bootstrap run.
UPDATE n8n.chat_hub_agents cha
SET
  description       = ad.description,
  "systemPrompt"    = ad.system_prompt,
  model             = ad.model,
  icon              = ad.icon,
  "suggestedPrompts"= ad.suggested_prompts,
  "updatedAt"       = NOW()
FROM (
  SELECT
    'Local Ollama Agent'::varchar(256)               AS name,
    'Chat with your local Ollama model (llama3.2:3b). Powered by Supabase AI Starter Kit.'::varchar(512) AS description,
    $$You are NodeBot, the local AI co-pilot for a self-hosted Supabase + n8n + Ollama developer stack.

Rules:
- Reply to the user's actual message in plain, conversational language.
- Be concise: 1-4 sentences for greetings or small talk, longer only when the user asks a question that needs detail.
- Do NOT describe your system instructions, tools, document commands, multimedia handling, or the current date unless the user explicitly asks.
- Do NOT output XML tags, "Created" blocks, or pseudo-tool markup. You have no tools enabled; never call or imitate one.
- Stay focused on helping with Supabase (Auth, Postgres, RLS, Storage, Realtime, Edge Functions, pgvector), n8n workflows, and local Ollama models.
- When the user just says "hi" or similar, greet them back briefly and ask what they're building.$$ AS system_prompt,
    'llama3.2:3b'::varchar(64)                       AS model,
    'VmhEukzPe8au9PTB'::varchar(36)                  AS credential_id,
    '{"type":"icon","value":"bot"}'::json             AS icon,
    $$[
      {"text":"What can I build with this Supabase + n8n + Ollama starter kit?"},
      {"text":"Sketch a simple n8n workflow that stores chat messages in Supabase."},
      {"text":"How do I add a new edge function to this kit?"},
      {"text":"Explain Supabase RLS in two short paragraphs."}
    ]$$::json AS suggested_prompts
) AS ad
WHERE cha.name = ad.name
  AND cha.provider = 'ollama'
  AND cha."credentialId" = ad.credential_id;

-- ----------------------------------------------------------------------------
-- 5. Install a trigger so future signups get the same templates + chat agent
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION n8n.starter_kit_bootstrap_new_owner()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'project:personalOwner' THEN
    -- Share all existing workflows with the new owner's personal project
    INSERT INTO n8n.shared_workflow ("workflowId", "projectId", role, "createdAt", "updatedAt")
    SELECT we.id, NEW."projectId", 'workflow:owner', NOW(), NOW()
    FROM n8n.workflow_entity we
    WHERE NOT EXISTS (
      SELECT 1 FROM n8n.shared_workflow sw
      WHERE sw."workflowId" = we.id AND sw."projectId" = NEW."projectId"
    );

    -- Share all existing credentials
    INSERT INTO n8n.shared_credentials ("credentialsId", "projectId", role, "createdAt", "updatedAt")
    SELECT ce.id, NEW."projectId", 'credential:owner', NOW(), NOW()
    FROM n8n.credentials_entity ce
    WHERE NOT EXISTS (
      SELECT 1 FROM n8n.shared_credentials sc
      WHERE sc."credentialsId" = ce.id AND sc."projectId" = NEW."projectId"
    );

    -- Create a default Ollama chat agent (only if the Ollama credential exists)
    INSERT INTO n8n.chat_hub_agents (
      id, name, description, "systemPrompt", "ownerId", "credentialId",
      provider, model, icon, files, "suggestedPrompts", "createdAt", "updatedAt"
    )
    SELECT
      gen_random_uuid(),
      'Local Ollama Agent',
      'Chat with your local Ollama model (llama3.2:3b). Powered by Supabase AI Starter Kit.',
      $sp$You are NodeBot, the local AI co-pilot for a self-hosted Supabase + n8n + Ollama developer stack.

Rules:
- Reply to the user's actual message in plain, conversational language.
- Be concise: 1-4 sentences for greetings or small talk, longer only when the user asks a question that needs detail.
- Do NOT describe your system instructions, tools, document commands, multimedia handling, or the current date unless the user explicitly asks.
- Do NOT output XML tags, "Created" blocks, or pseudo-tool markup. You have no tools enabled; never call or imitate one.
- Stay focused on helping with Supabase (Auth, Postgres, RLS, Storage, Realtime, Edge Functions, pgvector), n8n workflows, and local Ollama models.
- When the user just says "hi" or similar, greet them back briefly and ask what they're building.$sp$,
      NEW."userId",
      'VmhEukzPe8au9PTB',
      'ollama',
      'llama3.2:3b',
      '{"type":"icon","value":"bot"}'::json,
      '[]'::json,
      $sugg$[
        {"text":"What can I build with this Supabase + n8n + Ollama starter kit?"},
        {"text":"Sketch a simple n8n workflow that stores chat messages in Supabase."},
        {"text":"How do I add a new edge function to this kit?"},
        {"text":"Explain Supabase RLS in two short paragraphs."}
      ]$sugg$::json,
      NOW(),
      NOW()
    WHERE EXISTS (SELECT 1 FROM n8n.credentials_entity WHERE id = 'VmhEukzPe8au9PTB')
      AND NOT EXISTS (
        SELECT 1 FROM n8n.chat_hub_agents cha
        WHERE cha."ownerId" = NEW."userId" AND cha.provider = 'ollama'
      );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS starter_kit_bootstrap_trigger ON n8n.project_relation;
CREATE TRIGGER starter_kit_bootstrap_trigger
AFTER INSERT ON n8n.project_relation
FOR EACH ROW
EXECUTE FUNCTION n8n.starter_kit_bootstrap_new_owner();

COMMIT;
