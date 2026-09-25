# HTH Pack Contract: v1
#   control: langchain-5.2
#   guide:   https://howtoharden.com/guides/langchain/#52-configure-tracing-sampling
#   profile: L1
#   mode:    read-only
#   requires: langsmith SDK (>= 0.8.18 per control 3.2), LANGSMITH_API_KEY at run time
# =============================================================================
# HTH LangChain Control 5.2: Configure Tracing Sampling — per-operation sampling
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 SI-12 | SOC 2 CC6.7
#
# Source: https://docs.langchain.com/langsmith/sample-traces ("Set different sampling
# rates per client"). Checked against langsmith 0.14.0: Client(tracing_sampling_rate=)
# overrides the environment variable, and tracing_context(client=) routes a block of
# traced calls through that client. Tags such as tags=["sampled"] do NOT sample anything.

# HTH Guide Excerpt: begin sdk-per-client-sampling
import langsmith
from langsmith import Client, tracing_context

# Low-risk, high-volume path: keep 10% of traces
sampled_client = Client(tracing_sampling_rate=0.1)
# Path that handles sensitive payloads: send nothing
no_trace_client = Client(tracing_sampling_rate=0.0)


@langsmith.traceable
def answer_faq(question: str) -> str:
    return f"FAQ answer for: {question}"


@langsmith.traceable
def handle_account_change(request: str) -> str:
    return "account updated"


with tracing_context(enabled=True, client=sampled_client):
    answer_faq("How do I reset my password?")

with tracing_context(enabled=True, client=no_trace_client):
    handle_account_change("change billing email")
# HTH Guide Excerpt: end sdk-per-client-sampling
