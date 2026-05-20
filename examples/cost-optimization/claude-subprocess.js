/**
 * claude-subprocess.js — Optimized Claude Code CLI subprocess wrapper
 *
 * Demonstrates the --setting-sources "" --tools "" optimization that achieves
 * 99.5% cost reduction when invoking Claude Code CLI as a subprocess.
 *
 * Benchmark (Claude Code CLI 2.1.92, 2026-04-26):
 *   Default invocation:              $0.21/call  (166K tokens, cache creation)
 *   --setting-sources "" only:       $0.025/call (20K tokens)
 *   --setting-sources "" --tools "": $0.001/call (1.1K tokens, 1.3s)
 *
 * Why the default is expensive:
 *   Claude Code CLI loads ~/.claude/CLAUDE.md, all hooks config, MCP server
 *   definitions, and memory files into the system prompt on every invocation.
 *   For scripted/automated calls, this overhead is pure waste.
 *
 * Real-world impact (100+ calls/day):
 *   Default:   ~$630/month
 *   Optimized: ~$3/month
 */

'use strict';

const { execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);

/**
 * Invoke Claude Code CLI as an optimized subprocess.
 *
 * @param {string} prompt              - The prompt to send
 * @param {object} options
 * @param {string} options.model       - Model alias: 'haiku' | 'sonnet' | 'opus' (default: 'haiku')
 * @param {string} options.systemPrompt - Minimal task-specific system prompt
 * @param {object} options.jsonSchema  - Optional JSON Schema for structured output
 * @param {number} options.maxBudgetUsd - Cost cap per call (default: 0.50)
 * @param {number} options.timeoutMs   - Timeout in milliseconds (default: 30000)
 * @returns {Promise<{result: string, structuredOutput?: object, costUsd?: number}>}
 */
async function claudeSubprocess(prompt, options = {}) {
  const {
    model = 'haiku',
    systemPrompt = 'You are a helpful assistant. Be concise.',
    jsonSchema = null,
    maxBudgetUsd = 0.50,
    timeoutMs = 30000,
  } = options;

  const args = [
    // Core: non-interactive print mode
    '-p', prompt,
    '--output-format', 'json',
    '--model', model,

    // KEY OPTIMIZATION: strip all settings and tools loading
    // Without these, Claude Code loads ~166K tokens of config on every call
    '--setting-sources', '',   // disables: CLAUDE.md, hooks config, memory files
    '--tools', '',             // disables: all built-in tools (Bash, Read, Edit, etc.)

    // Task-specific minimal system prompt (replaces the stripped global config)
    '--system-prompt', systemPrompt,

    // Safety
    '--max-budget-usd', String(maxBudgetUsd),
    '--no-session-persistence',
  ];

  // Optional: structured JSON output via JSON Schema
  if (jsonSchema) {
    args.push('--json-schema', JSON.stringify(jsonSchema));
  }

  const { stdout } = await execFileAsync('claude', args, {
    timeout: timeoutMs,
    maxBuffer: 10 * 1024 * 1024, // 10MB
  });

  const parsed = JSON.parse(stdout);

  // Claude Code CLI returns is_error: true for auth failures, budget exceeded, etc.
  if (parsed.is_error) {
    throw new Error(`Claude subprocess error: ${parsed.result}`);
  }

  return {
    result: parsed.result,
    structuredOutput: parsed.structured_output ?? null,
    costUsd: parsed.cost_usd ?? null,
  };
}

// ---------------------------------------------------------------------------
// Usage examples
// ---------------------------------------------------------------------------

async function main() {
  console.log('=== Example 1: Simple text response ===');
  const text = await claudeSubprocess(
    'Summarize the key benefit of the --setting-sources "" flag in one sentence.',
    { model: 'haiku' }
  );
  console.log('Result:', text.result);
  console.log('Cost:  ', text.costUsd ? `$${text.costUsd.toFixed(4)}` : 'N/A');

  console.log('\n=== Example 2: Structured JSON output ===');
  const structured = await claudeSubprocess(
    'Extract: {"language": "JavaScript", "purpose": "subprocess optimization"}',
    {
      model: 'haiku',
      systemPrompt: 'Extract structured data from the input. Return only valid JSON.',
      jsonSchema: {
        type: 'object',
        properties: {
          language: { type: 'string' },
          purpose:  { type: 'string' },
        },
        required: ['language', 'purpose'],
      },
    }
  );
  console.log('Structured output:', structured.structuredOutput);
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { claudeSubprocess };
