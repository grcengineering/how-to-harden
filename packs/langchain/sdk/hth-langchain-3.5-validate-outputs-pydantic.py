# HTH Pack Contract: v1
#   control: langchain-3.5
#   guide:   https://howtoharden.com/guides/langchain/#35-enforce-pydantic-output-validation
#   profile: L1
#   mode:    read-only
#   requires: langchain-core, langchain-classic (RetryWithErrorOutputParser), langchain-openai + OPENAI_API_KEY (or any chat model)
# =============================================================================
# HTH LangChain Control 3.5: Enforce Pydantic Output Validation
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 SI-10
#
# Checked against langchain 1.4.2, langchain-core 1.6.5, langchain-classic 1.0.8 (2026-09-24).
#
# TRAPS
#  1. On langchain 1.x the retry parsers moved: `from langchain.output_parsers import ...`
#     raises ModuleNotFoundError; they live in langchain_classic.output_parsers.
#  2. RetryWithErrorOutputParser cannot sit at the end of a `prompt | llm | parser` chain:
#     its parse() raises NotImplementedError on every call. It needs the original prompt,
#     so call parse_with_prompt() with both the completion and the prompt value.

# HTH Guide Excerpt: begin sdk-pydantic-output-parser
from typing import Literal
from pydantic import BaseModel, Field, field_validator
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI


class TicketTriageDecision(BaseModel):
    """Strict schema enforced on every LLM response."""
    severity: Literal["low", "medium", "high", "critical"]
    category: Literal["bug", "feature_request", "billing", "abuse"]
    summary: str = Field(min_length=5, max_length=200)
    requires_human: bool

    @field_validator("summary")
    @classmethod
    def reject_html(cls, v: str) -> str:
        if "<" in v or ">" in v:
            raise ValueError("Summary must not contain HTML")
        return v


parser = PydanticOutputParser(pydantic_object=TicketTriageDecision)

prompt = ChatPromptTemplate.from_messages([
    ("system", "Triage the support ticket. {format_instructions}"),
    ("user", "{ticket}"),
]).partial(format_instructions=parser.get_format_instructions())

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
chain = prompt | llm | parser

# Returns a fully validated TicketTriageDecision; raises on schema violation.
decision = chain.invoke({"ticket": "Login button does nothing on mobile"})
# HTH Guide Excerpt: end sdk-pydantic-output-parser

# HTH Guide Excerpt: begin sdk-retry-on-validation-failure
from langchain_classic.output_parsers import RetryWithErrorOutputParser
from langchain_core.runnables import RunnableLambda, RunnableParallel

# On a parse failure, send the error and the original prompt back to the LLM to self-correct
retry_parser = RetryWithErrorOutputParser.from_llm(parser=parser, llm=llm, max_retries=2)
robust_chain = RunnableParallel(completion=prompt | llm, prompt_value=prompt) | RunnableLambda(
    lambda x: retry_parser.parse_with_prompt(x["completion"].content, x["prompt_value"])
)

decision = robust_chain.invoke({"ticket": "Login button does nothing on mobile"})
# HTH Guide Excerpt: end sdk-retry-on-validation-failure
