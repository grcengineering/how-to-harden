# HTH LangChain Control 5.1: Redact Sensitive Data from LangSmith Traces
# Profile: L1 | NIST: SC-28, SI-12
# https://howtoharden.com/guides/langchain/#51-redact-sensitive-data-from-traces

# HTH Guide Excerpt: begin sdk-trace-redaction
import re
from langsmith import traceable
from langsmith.run_helpers import trace

PII_PATTERNS = [
    (re.compile(r"\b\d{3}-\d{2}-\d{4}\b"), "[REDACTED_SSN]"),
    (re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"), "[REDACTED_EMAIL]"),
    (re.compile(r"\b(?:\d[ -]*?){13,16}\b"), "[REDACTED_CC]"),
    (re.compile(r"\bAKIA[0-9A-Z]{16}\b"), "[REDACTED_AWS_KEY]"),
    (re.compile(r"\bsk-[A-Za-z0-9]{32,}\b"), "[REDACTED_API_KEY]"),
]


def redact(value):
    if isinstance(value, str):
        for pattern, replacement in PII_PATTERNS:
            value = pattern.sub(replacement, value)
        return value
    if isinstance(value, dict):
        return {k: redact(v) for k, v in value.items()}
    if isinstance(value, list):
        return [redact(v) for v in value]
    return value


# Apply redaction to inputs/outputs before they leave the process
@traceable(
    name="customer_support_agent",
    process_inputs=redact,
    process_outputs=redact,
)
def support_agent(user_message: str) -> str:
    return run_agent(user_message)
# HTH Guide Excerpt: end sdk-trace-redaction

# HTH Guide Excerpt: begin sdk-disable-tracing-conditionally
import os

# Hard-disable tracing for explicit production data residency requirements
if os.getenv("ENV") == "prod-eu" and not os.getenv("LANGSMITH_RESIDENCY_EU_OK"):
    os.environ["LANGCHAIN_TRACING_V2"] = "false"
    os.environ["LANGSMITH_TRACING"] = "false"
# HTH Guide Excerpt: end sdk-disable-tracing-conditionally
