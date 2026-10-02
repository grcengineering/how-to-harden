# HTH Pack Contract: v1
#   control: langchain-3.3
#   guide:   https://howtoharden.com/guides/langchain/#33-disable-allow_dangerous_code-unless-explicitly-required
#   profile: L1
#   mode:    read-only
#   requires: langchain-sandbox + Deno (Pyodide excerpt); modal + langchain-modal + a Modal account (provider excerpt)
# =============================================================================
# HTH LangChain Control 3.3: Disable allow_dangerous_code Unless Explicitly Required
# (also rendered by control 3.4, Sandbox Untrusted Code Execution)
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 SI-10, SC-39
#
# Sources (signatures checked against the installed libraries, 2026-09-24):
#   langchain-sandbox 0.0.6 (github.com/langchain-ai/langchain-sandbox): SyncPyodideSandbox,
#     allow_* flags on the constructor; execute(code, timeout_seconds=, memory_limit_mb=);
#     CodeExecutionResult fields: result, stdout, stderr, status
#   langchain-modal 0.0.6 + modal 1.5.5: modal.Sandbox.create(app=, image=, cpu=, memory=,
#     timeout=, block_network=, cidr_allowlist=), wrapped by langchain_modal.ModalSandbox(sandbox=)
#
# TRAPS
#  1. PyodideSandbox.execute is async. A sync @tool must use SyncPyodideSandbox, or it
#     returns a coroutine instead of running anything.
#  2. The timeout is an execute() argument, not a constructor argument (TypeError).
#  3. langchain-sandbox 0.0.6 pins langchain-core 0.3.x, so it cannot share a virtualenv
#     with langchain-core 1.x. Run it in the sandbox-tool's own environment or service.

# HTH Guide Excerpt: begin sdk-avoid-python-repl
# UNSAFE: PythonREPLTool with allow_dangerous_code=True grants the model full process
# privileges. Python-level "restrictions" are bypassable via ctypes, importlib, and
# __subclasses__() chains.
# from langchain_experimental.tools import PythonREPLTool
# unsafe_tool = PythonREPLTool(allow_dangerous_code=True)  # DO NOT USE in prod

# SAFE: route untrusted Python through an infrastructure-isolated (WebAssembly/Deno) sandbox
from langchain_sandbox import SyncPyodideSandbox
from langchain_core.tools import tool

sandbox = SyncPyodideSandbox(
    allow_net=False,    # no network egress from agent code
    allow_read=False,   # no host filesystem reads
    allow_write=False,  # no host filesystem writes
    allow_run=False,    # no subprocess spawning
    allow_env=False,    # no host environment variables
    allow_ffi=False,    # no native FFI
)


@tool
def run_python(code: str) -> str:
    """Execute Python code in an isolated WebAssembly sandbox."""
    result = sandbox.execute(code, timeout_seconds=30, memory_limit_mb=256)
    return result.stdout if result.status == "success" else f"Error: {result.stderr}"
# HTH Guide Excerpt: end sdk-avoid-python-repl

# HTH Guide Excerpt: begin sdk-prefer-provider-sandbox
# For production, prefer a provider-managed sandbox. langchain-ai publishes Modal, Daytona
# and Runloop backends (langchain-modal / langchain-daytona / langchain-runloop). Limits and
# egress are set on the provider sandbox itself; the LangChain wrapper only adopts it.
import modal
from langchain_modal import ModalSandbox

app = modal.App.lookup("hth-agent-sandbox", create_if_missing=True)
modal_sb = modal.Sandbox.create(
    app=app,
    image=modal.Image.debian_slim(python_version="3.12"),
    cpu=1.0,
    memory=512,           # MiB
    timeout=60,           # seconds
    block_network=True,   # or cidr_allowlist=[...] for a narrow egress allowlist
)
prod_sandbox = ModalSandbox(sandbox=modal_sb)
# HTH Guide Excerpt: end sdk-prefer-provider-sandbox
