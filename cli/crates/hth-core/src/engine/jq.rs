use crate::error::{HthError, HthResult};

/// Evaluates jq expressions against JSON values using jaq (pure Rust jq).
pub struct JqEvaluator;

impl JqEvaluator {
    pub fn new() -> Self {
        Self
    }

    /// Evaluate a jq expression against a JSON value.
    /// Returns the first output value. Control audit checks expect a boolean.
    pub fn evaluate(
        &self,
        expression: &str,
        input: &serde_json::Value,
    ) -> HthResult<serde_json::Value> {
        // Parse the expression
        let (filter, errs) = jaq_parse::parse(expression, jaq_parse::main());
        if !errs.is_empty() {
            let err_msgs: Vec<String> = errs.iter().map(|e| format!("{e}")).collect();
            return Err(HthError::JqParse {
                expression: expression.to_string(),
                message: err_msgs.join("; "),
            });
        }

        let filter = filter.ok_or_else(|| HthError::JqParse {
            expression: expression.to_string(),
            message: "Failed to parse expression".to_string(),
        })?;

        // Build definitions (core + standard library)
        let mut defs = jaq_interpret::ParseCtx::new(Vec::new());
        super::jq_stdlib::register_stdlib(&mut defs);

        let filter = defs.compile(filter);

        let inputs = jaq_interpret::RcIter::new(std::iter::empty());
        let val = jaq_interpret::Val::from(input.clone());

        let mut results =
            jaq_interpret::FilterT::run(&filter, (jaq_interpret::Ctx::new([], &inputs), val));

        match results.next() {
            Some(Ok(val)) => {
                let json_val: serde_json::Value = val.into();
                Ok(json_val)
            }
            Some(Err(e)) => Err(HthError::JqEvaluation {
                expression: expression.to_string(),
                message: format!("{e:?}"),
            }),
            None => Err(HthError::JqEvaluation {
                expression: expression.to_string(),
                message: "No output produced".to_string(),
            }),
        }
    }

    /// Evaluate a jq expression and return whether it matches the expected boolean.
    pub fn check(
        &self,
        expression: &str,
        input: &serde_json::Value,
        expected: bool,
    ) -> HthResult<bool> {
        let result = self.evaluate(expression, input)?;
        match result {
            serde_json::Value::Bool(b) => Ok(b == expected),
            _ => {
                // Try to coerce: non-null/non-false = true
                let truthy = !result.is_null() && result != serde_json::Value::Bool(false);
                Ok(truthy == expected)
            }
        }
    }
}

impl Default for JqEvaluator {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_simple_boolean() {
        let jq = JqEvaluator::new();
        let input = json!({"status": "ACTIVE"});
        let result = jq.evaluate(".status == \"ACTIVE\"", &input).unwrap();
        assert_eq!(result, json!(true));
    }

    #[test]
    fn test_array_select_length() {
        let jq = JqEvaluator::new();
        let input = json!([
            {"key": "webauthn", "status": "ACTIVE"},
            {"key": "totp", "status": "ACTIVE"}
        ]);
        let expr = r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#;
        let result = jq.evaluate(expr, &input).unwrap();
        assert_eq!(result, json!(true));
    }

    #[test]
    fn test_check_pass() {
        let jq = JqEvaluator::new();
        let input = json!([{"key": "webauthn", "status": "ACTIVE"}]);
        let expr = r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#;
        assert!(jq.check(expr, &input, true).unwrap());
    }

    #[test]
    fn test_check_fail() {
        let jq = JqEvaluator::new();
        let input = json!([{"key": "webauthn", "status": "INACTIVE"}]);
        let expr = r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#;
        assert!(!jq.check(expr, &input, true).unwrap());
    }
}
