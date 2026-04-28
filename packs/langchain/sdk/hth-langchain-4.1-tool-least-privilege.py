# HTH LangChain Control 4.1: Apply Tool-Level Least Privilege
# Profile: L1 | NIST: AC-6, CM-7
# https://howtoharden.com/guides/langchain/#41-tool-level-least-privilege

# HTH Guide Excerpt: begin sdk-tool-allowlist
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langchain_openai import ChatOpenAI


# Each tool is narrowly scoped — no generic "execute SQL" or "run shell"
@tool
def lookup_customer(customer_id: str) -> dict:
    """Read-only customer lookup. Validates ID format before query."""
    if not customer_id.isalnum() or len(customer_id) > 32:
        raise ValueError("Invalid customer_id")
    # Hits a read-only replica with a least-privileged DB role
    return read_only_db.fetch_one(
        "SELECT id, name, email, plan FROM customers WHERE id = %s",
        (customer_id,),
    )


@tool
def issue_refund(customer_id: str, amount_cents: int, reason: str) -> dict:
    """Refund up to $100. Larger refunds require human approval."""
    if amount_cents > 10_000:
        raise PermissionError("Refunds over $100 require human approval")
    # Calls a service account scoped to refunds only
    return billing_client.refund(customer_id, amount_cents, reason)


# Explicit allowlist of tools — agent has NO access to anything else
agent = create_react_agent(
    model=ChatOpenAI(model="gpt-4o-mini"),
    tools=[lookup_customer, issue_refund],
)
# HTH Guide Excerpt: end sdk-tool-allowlist

# HTH Guide Excerpt: begin sdk-deny-broad-tools
# AVOID broad tools that grant the model arbitrary capability:
# from langchain_community.tools import ShellTool, RequestsGetTool
# bad_agent = create_react_agent(model=llm, tools=[ShellTool(), RequestsGetTool()])
# Both can be turned into RCE / SSRF vectors via prompt injection (OWASP LLM01).
# HTH Guide Excerpt: end sdk-deny-broad-tools
