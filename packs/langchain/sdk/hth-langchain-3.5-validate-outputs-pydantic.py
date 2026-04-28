# HTH LangChain Control 3.5: Enforce Pydantic Output Validation on All LLM Outputs
# Profile: L1 | NIST: SI-10
# https://howtoharden.com/guides/langchain/#35-validate-outputs-pydantic

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
from langchain.output_parsers import RetryWithErrorOutputParser

# Wrap with retry — on parse failure, send the error back to the LLM to self-correct
retry_parser = RetryWithErrorOutputParser.from_llm(parser=parser, llm=llm, max_retries=2)
robust_chain = prompt | llm | retry_parser
# HTH Guide Excerpt: end sdk-retry-on-validation-failure
