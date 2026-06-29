## Data Sources

When reading from external systems, prefer purpose-built tools over generic HTTP:

- **MCP servers**: when an MCP server is available for a data source, use it rather than the HTTP API directly
- **GitHub**: access repositories, PRs, issues, and URLs via the `gh` CLI — not by fetching github.com URLs or calling the REST API manually. `gh` is authenticated and returns structured data.

### MCP auth failures — stop and surface immediately

When an MCP tool call returns a message indicating authentication is required — any of:
- "requires OAuth authentication"
- "needs-auth"
- "auth expired"
- "authentication failed"
- "MCP re-authentication required"

**Stop the current task immediately.** Do not silently skip the source, log it in a footnote, or continue as if the data were present. Instead:

1. Tell the user which server failed and what the error was
2. Provide the exact fix: run `/mcp-auth <server>` in the session, or `mcp({ action: "auth-start", server: "<server>" })` to get a browser URL
3. Wait — only continue after the user either fixes the auth or explicitly says to proceed without that data

If running as a worker or subagent, include the failure in your completion/DONE message. Do not bury it in a coverage table that the manager may skim.
