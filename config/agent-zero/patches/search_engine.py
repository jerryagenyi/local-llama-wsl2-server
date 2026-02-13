# Patched copy of agent-zero python/tools/search_engine.py
# Fixes KeyError: 'results' when SearXNG returns a response without a "results" key
# (e.g. service down, error response, or unexpected JSON). Mount over container file
# via docker-compose volume: ./config/agent-zero/patches/search_engine.py:/a0/python/tools/search_engine.py:ro

import os
import asyncio
from python.helpers import dotenv, memory, perplexity_search, duckduckgo_search
from python.helpers.tool import Tool, Response
from python.helpers.print_style import PrintStyle
from python.helpers.errors import handle_error
from python.helpers.searxng import search as searxng

SEARCH_ENGINE_RESULTS = 10


class SearchEngine(Tool):
    async def execute(self, query="", **kwargs):
        searxng_result = await self.searxng_search(query)
        await self.agent.handle_intervention(
            searxng_result
        )  # wait for intervention and handle it, if paused
        return Response(message=searxng_result, break_loop=False)

    async def searxng_search(self, question):
        results = await searxng(question)
        return self.format_result_searxng(results, "Search Engine")

    def format_result_searxng(self, result, source):
        if isinstance(result, Exception):
            handle_error(result)
            return f"{source} search failed: {str(result)}"
        if not isinstance(result, dict):
            return f"{source} search failed: unexpected response type."
        if "results" not in result:
            err = result.get("error") or result.get("message") or "No results key in response (SearXNG may be down or misconfigured)."
            return f"{source} search failed: {err}"
        outputs = []
        for item in result["results"]:
            if not isinstance(item, dict):
                continue
            title = item.get("title", "")
            url = item.get("url", "")
            content = item.get("content", "")
            outputs.append(f"{title}\n{url}\n{content}")
        return "\n\n".join(outputs[:SEARCH_ENGINE_RESULTS]).strip()
