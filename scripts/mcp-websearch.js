#!/usr/bin/env node
/**
 * MCP Server for Web Search and URL Fetching (Keyless & Zero Config)
 * Provides real-time internet search and documentation fetching for OpenCode/Antigravity models.
 */

const readline = require("readline");

async function searchWeb(query, maxResults = 5) {
  try {
    const res = await fetch("https://api.tavily.com/search", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Tavily-Access-Mode": "keyless",
        "X-Client-Name": "opencode2",
        "User-Agent": "Mozilla/5.0 (compatible; OpenCode2/2.2.2)"
      },
      body: JSON.stringify({
        query: query,
        max_results: maxResults,
        search_depth: "basic"
      })
    });

    if (!res.ok) {
      throw new Error(`Search API returned status ${res.status}`);
    }

    const data = await res.json();
    if (!data.results || data.results.length === 0) {
      return "No results found.";
    }

    return data.results
      .map(
        (r, i) =>
          `[${i + 1}] ${r.title}\nURL: ${r.url}\n${r.content || ""}\n`
      )
      .join("\n---\n");
  } catch (err) {
    return `Web search failed: ${err.message}`;
  }
}

async function fetchUrl(url) {
  try {
    const res = await fetch(url, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
      }
    });

    if (!res.ok) {
      throw new Error(`Fetch returned status ${res.status}`);
    }

    const text = await res.text();
    // Simple HTML to readable text conversion
    const cleanText = text
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, "")
      .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, "")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim();

    return cleanText.slice(0, 8000);
  } catch (err) {
    return `Fetch failed: ${err.message}`;
  }
}

const TOOLS = [
  {
    name: "web_search",
    description:
      "Search the live web for the latest facts, news, documentation, versions, software releases, or real-time internet data. MUST be used when asked about current versions, recent events, or library updates.",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "The search query to look up on the web"
        },
        count: {
          type: "number",
          description: "Number of search results to return (1-10, default 5)",
          default: 5
        }
      },
      required: ["query"]
    }
  },
  {
    name: "fetch_url",
    description:
      "Fetch the raw text content of a web page or online documentation URL.",
    inputSchema: {
      type: "object",
      properties: {
        url: {
          type: "string",
          description: "The HTTP/HTTPS URL to fetch"
        }
      },
      required: ["url"]
    }
  }
];

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.on("line", async (line) => {
  if (!line.trim()) return;

  try {
    const req = JSON.parse(line);

    if (req.method === "initialize") {
      const resp = {
        jsonrpc: "2.0",
        id: req.id,
        result: {
          protocolVersion: "2024-11-05",
          capabilities: {
            tools: {}
          },
          serverInfo: {
            name: "web-search-mcp",
            version: "1.0.0"
          }
        }
      };
      process.stdout.write(JSON.stringify(resp) + "\n");
    } else if (req.method === "notifications/initialized") {
      // client ack
    } else if (req.method === "tools/list") {
      const resp = {
        jsonrpc: "2.0",
        id: req.id,
        result: {
          tools: TOOLS
        }
      };
      process.stdout.write(JSON.stringify(resp) + "\n");
    } else if (req.method === "tools/call") {
      const { name, arguments: args } = req.params || {};

      let resultText = "";
      if (name === "web_search") {
        resultText = await searchWeb(args?.query || "", args?.count || 5);
      } else if (name === "fetch_url") {
        resultText = await fetchUrl(args?.url || "");
      } else {
        resultText = `Unknown tool: ${name}`;
      }

      const resp = {
        jsonrpc: "2.0",
        id: req.id,
        result: {
          content: [
            {
              type: "text",
              text: resultText
            }
          ]
        }
      };
      process.stdout.write(JSON.stringify(resp) + "\n");
    } else {
      // Unknown method, respond with error or ignore notifications
      if (req.id !== undefined) {
        const resp = {
          jsonrpc: "2.0",
          id: req.id,
          error: {
            code: -32601,
            message: `Method not found: ${req.method}`
          }
        };
        process.stdout.write(JSON.stringify(resp) + "\n");
      }
    }
  } catch (e) {
    // ignore parse error
  }
});
