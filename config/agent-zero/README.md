# Agent Zero MCP Configuration

This directory contains the MCP (Model Context Protocol) server configuration for Agent Zero.

## Setup

1. Copy the example file:
   ```bash
   cp agentzero-mcp-config.json.example agentzero-mcp-config.json
   ```

2. Set environment variables in your `.env` file or Docker Compose:
   ```bash
   GITHUB_PERSONAL_ACCESS_TOKEN=your_github_token_here
   BRAVE_API_KEY=your_brave_api_key_here
   SERPAPI_TOKEN=your_serpapi_token_here
   ```

3. Replace placeholders in `agentzero-mcp-config.json` with actual values, or ensure the environment variables are available when Agent Zero starts.

## Security

⚠️ **Never commit `agentzero-mcp-config.json` with actual secrets!**

- Use environment variables for sensitive values
- The `.example` file is safe to commit
- Add `agentzero-mcp-config.json` to `.gitignore` if it contains secrets

## MCP Servers

- **SequentialThinking**: Task breakdown and planning
- **Context7**: Documentation and context packaging
- **GitHubMcp**: GitHub repository interaction
- **PlaywrightBrowser**: Browser automation
- **BraveSearch**: Search API integration
- **SerpAPI**: Search engine results
