# HTH LangChain Control 3.3: Disable allow_dangerous_code Unless Explicitly Required
# Profile: L1 | NIST: SI-10, SC-39
# https://howtoharden.com/guides/langchain/#33-disable-allow-dangerous-code

# HTH Guide Excerpt: begin sdk-avoid-python-repl
# UNSAFE — PythonREPLTool with allow_dangerous_code=True grants the model
# full process privileges. Python-level "restrictions" are bypassable via
# ctypes, importlib, and __subclasses__() chains.
# from langchain_experimental.tools import PythonREPLTool
# unsafe_tool = PythonREPLTool(allow_dangerous_code=True)  # DO NOT USE in prod

# SAFE — route untrusted Python through an infrastructure-isolated sandbox
from langchain_sandbox import PyodideSandbox
from langchain_core.tools import tool

sandbox = PyodideSandbox(
    allow_net=False,         # No network egress from agent code
    allow_read=False,        # No host filesystem reads
    allow_write=False,       # No host filesystem writes
    allow_run=False,         # No subprocess spawning
    timeout_seconds=30,      # Hard timeout
)

@tool
def run_python(code: str) -> str:
    """Execute Python code in an isolated WebAssembly sandbox."""
    result = sandbox.execute(code)
    return result.stdout if result.success else f"Error: {result.error}"
# HTH Guide Excerpt: end sdk-avoid-python-repl

# HTH Guide Excerpt: begin sdk-prefer-provider-sandbox
# For production, prefer provider-managed sandboxes (Modal, Daytona, Runloop)
# rather than in-process Python sandboxing — see langchain-ai/deepagents.
from deepagents.sandbox import ModalSandbox

prod_sandbox = ModalSandbox(
    image="python:3.12-slim",
    cpu_limit=1.0,
    memory_limit_mb=512,
    network_egress_allowlist=["api.openai.com", "api.anthropic.com"],
    max_execution_seconds=60,
)
# HTH Guide Excerpt: end sdk-prefer-provider-sandbox
