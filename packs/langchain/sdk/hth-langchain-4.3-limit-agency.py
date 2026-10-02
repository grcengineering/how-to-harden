# HTH Pack Contract: v1
#   control: langchain-4.3
#   guide:   https://howtoharden.com/guides/langchain/#43-limit-excessive-agency
#   profile: L2
#   mode:    read-only
#   requires: langchain >= 1.0 (langchain.agents middleware), langgraph (checkpointer), a chat model
# =============================================================================
# HTH LangChain Control 4.3: Limit Excessive Agency
# Profile Level: L2 (Walk)
# Frameworks: OWASP LLM Top 10 LLM06:2025 | NIST 800-53 AC-6
#
# Checked against langchain 1.4.2 (langchain.agents.create_agent and
# langchain.agents.middleware.ToolCallLimitMiddleware / HumanInTheLoopMiddleware) and
# langgraph 1.2.12 (InMemorySaver), 2026-09-24.
#
# Two mechanisms, both first-party: a hard ceiling on tool calls per run, and a human
# approval interrupt before any high-impact tool executes. The interrupt needs a
# checkpointer, because the paused run has to be resumable after the human decides.
# Use a durable checkpointer (Postgres/SQLite, patched per control 3.6) in production;
# InMemorySaver loses paused runs on restart.

# HTH Guide Excerpt: begin sdk-limit-agency-middleware
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware, ToolCallLimitMiddleware
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.checkpoint.memory import InMemorySaver


@tool
def lookup_customer(customer_id: str) -> str:
    """Read-only customer lookup."""
    if not customer_id.isalnum() or len(customer_id) > 32:
        raise ValueError("Invalid customer_id")
    return f"customer {customer_id}"


@tool
def issue_refund(customer_id: str, amount_cents: int, reason: str) -> str:
    """Issue a refund. High impact: always paused for human approval."""
    return f"refunded {amount_cents} cents to {customer_id}"


agent = create_agent(
    model=ChatOpenAI(model="gpt-4o-mini"),
    tools=[lookup_customer, issue_refund],
    middleware=[
        ToolCallLimitMiddleware(run_limit=5),                     # hard ceiling per invocation
        HumanInTheLoopMiddleware(interrupt_on={"issue_refund": True}),  # pause before refunds
    ],
    checkpointer=InMemorySaver(),   # required to pause and resume; use a durable store in prod
)
# HTH Guide Excerpt: end sdk-limit-agency-middleware
