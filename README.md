# withings-mcp

A personal [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server for accessing selected Withings health data from local AI tools.

This repository is for my own hosted MCP server. It is intentionally scoped for personal, read-only use against the Withings API.

## Status

Work in progress. The initial repository is published so the server implementation can be developed and deployed from here.

## Goals

- Authenticate with the Withings API using OAuth 2.0.
- Expose useful read-only MCP tools/resources for personal health data.
- Keep credentials and tokens out of source control.
- Prefer a simple deployment story suitable for personal hosting.

## Planned configuration

Create a Withings developer application and configure the server with environment variables similar to:

```sh
WITHINGS_CLIENT_ID=...
WITHINGS_CLIENT_SECRET=...
WITHINGS_REDIRECT_URI=...
WITHINGS_TOKEN_PATH=./data/withings-token.json
```

OAuth tokens, `.env` files, and local data should remain private and must not be committed.

## Planned MCP client setup

Once the server executable exists, configure an MCP client with an entry like:

```json
{
  "mcpServers": {
    "withings": {
      "command": "withings-mcp",
      "env": {
        "WITHINGS_CLIENT_ID": "...",
        "WITHINGS_CLIENT_SECRET": "...",
        "WITHINGS_REDIRECT_URI": "..."
      }
    }
  }
}
```

## License

No license has been selected yet.
