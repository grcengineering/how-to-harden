//! Standard library functions for the jaq evaluator.
//!
//! Registers native (Rust-implemented) functions and jq-defined functions
//! into a jaq ParseCtx so that audit check expressions can use standard
//! jq builtins like `select`, `length`, `test`, `all`, etc.

use jaq_interpret::{Error, Native, ParseCtx, Val};

/// Register all standard library functions into the given ParseCtx.
pub fn register_stdlib(ctx: &mut ParseCtx) {
    // Register native (Rust-implemented) functions
    ctx.insert_natives(native_functions());

    // Register jq-defined functions (parsed from jq syntax)
    let (defs, errs) = jaq_parse::parse(JQ_DEFS_BASIC, jaq_parse::defs());
    if !errs.is_empty() {
        tracing::warn!("jq stdlib parse errors: {}", errs.len());
    }
    if let Some(defs) = defs {
        ctx.insert_defs(defs);
    }
}

/// jq-syntax definitions for derived functions.
/// Definitions that use `;` in argument lists (like `limit(n; f)`)
/// must be registered separately since jaq_parse::defs() handles `;` args.
///
/// NOTE: Each definition block is parsed separately to isolate parse errors.
const JQ_DEFS_BASIC: &str = "\
def select(f): if f then . else empty end;\n\
def map(f): [.[] | f];\n\
def any: reduce .[] as $x (false; . or $x);\n\
def any(f): reduce .[] as $x (false; . or ($x | f));\n\
def all: reduce .[] as $x (true; . and $x);\n\
def all(f): reduce .[] as $x (true; . and ($x | f));\n\
def last(f): reduce f as $x (null; $x);\n\
def last: .[-1];\n\
def first: .[0];\n\
def recurse(f): def r: ., (f | r); r;\n\
def recurse: recurse(.[]?);\n\
def flatten: [.[] | if type == \"array\" then .[] else . end];\n\
def from_entries: map({(.key // .name): .value}) | add // {};\n\
def to_entries: [keys_unsorted[] as $k | {key: $k, value: .[$k]}];\n\
def with_entries(f): to_entries | map(f) | from_entries;\n\
def min_by(f): reduce .[] as $x (null; if . == null or ($x | f) < (. | f) then $x else . end);\n\
def max_by(f): reduce .[] as $x (null; if . == null or ($x | f) > (. | f) then $x else . end);\n\
def inside(x): . as $s | x | contains($s);\n\
def ltrimstr(x): if startswith(x) then .[x | length:] else . end;\n\
def rtrimstr(x): if endswith(x) then .[:length - (x | length)] else . end;\n\
def ascii_downcase: explode | map(if . >= 65 and . <= 90 then . + 32 else . end) | implode;\n\
def ascii_upcase: explode | map(if . >= 97 and . <= 122 then . - 32 else . end) | implode;\n\
def isnan: . != .;\n\
def isinfinite: . == (1/0) or . == (-1/0);\n\
def isfinite: isinfinite | not;\n\
def isnormal: (isinfinite or isnan or . == 0) | not;\n\
";

// NOTE: Multi-arg jq defs like `limit(n; f)` cannot be used because jaq-parse's
// `foreach` only supports 2-arg form `(init; body)`, not jq's 3-arg form
// `(init; update; extract)`. Functions like `gsub` are implemented as native
// functions instead.

/// Build the list of native function registrations.
fn native_functions() -> Vec<(String, usize, Native<Val>)> {
    vec![
        ("length".into(), 0, Native::new(native_length)),
        ("utf8bytelength".into(), 0, Native::new(native_length)),
        ("empty".into(), 0, Native::new(native_empty)),
        ("not".into(), 0, Native::new(native_not)),
        ("type".into(), 0, Native::new(native_type)),
        ("null".into(), 0, Native::new(native_null)),
        ("true".into(), 0, Native::new(native_true)),
        ("false".into(), 0, Native::new(native_false)),
        ("error".into(), 0, Native::new(native_error)),
        ("error".into(), 1, Native::new(native_error_msg)),
        ("has".into(), 1, Native::new(native_has)),
        ("contains".into(), 1, Native::new(native_contains)),
        ("keys".into(), 0, Native::new(native_keys)),
        ("keys_unsorted".into(), 0, Native::new(native_keys_unsorted)),
        ("values".into(), 0, Native::new(native_values)),
        ("sort".into(), 0, Native::new(native_sort)),
        ("reverse".into(), 0, Native::new(native_reverse)),
        ("add".into(), 0, Native::new(native_add)),
        ("min".into(), 0, Native::new(native_min)),
        ("max".into(), 0, Native::new(native_max)),
        ("test".into(), 1, Native::new(native_test1)),
        ("test".into(), 2, Native::new(native_test2)),
        ("match".into(), 1, Native::new(native_match1)),
        ("match".into(), 2, Native::new(native_match2)),
        ("capture".into(), 1, Native::new(native_capture1)),
        ("capture".into(), 2, Native::new(native_capture2)),
        ("split".into(), 1, Native::new(native_split)),
        ("join".into(), 1, Native::new(native_join)),
        ("gsub".into(), 2, Native::new(native_gsub)),
        ("sub".into(), 2, Native::new(native_sub)),
        ("startswith".into(), 1, Native::new(native_startswith)),
        ("endswith".into(), 1, Native::new(native_endswith)),
        ("tostring".into(), 0, Native::new(native_tostring)),
        ("tonumber".into(), 0, Native::new(native_tonumber)),
        ("ascii".into(), 0, Native::new(native_tostring)),
        ("explode".into(), 0, Native::new(native_explode)),
        ("implode".into(), 0, Native::new(native_implode)),
        ("now".into(), 0, Native::new(native_now)),
        ("fromdateiso8601".into(), 0, Native::new(native_fromdateiso8601)),
        ("todateiso8601".into(), 0, Native::new(native_todateiso8601)),
        ("strftime".into(), 1, Native::new(native_strftime)),
        ("floor".into(), 0, Native::new(native_floor)),
        ("ceil".into(), 0, Native::new(native_ceil)),
        ("round".into(), 0, Native::new(native_round)),
        ("fabs".into(), 0, Native::new(native_fabs)),
        ("log".into(), 0, Native::new(native_log)),
        ("log2".into(), 0, Native::new(native_log2)),
        ("sqrt".into(), 0, Native::new(native_sqrt)),
        ("pow".into(), 2, Native::new(native_pow)),
        ("infinite".into(), 0, Native::new(native_infinite)),
        ("nan".into(), 0, Native::new(native_nan)),
        ("input".into(), 0, Native::new(native_empty)),
        ("inputs".into(), 0, Native::new(native_empty)),
        ("path".into(), 1, Native::new(native_path)),
        ("getpath".into(), 1, Native::new(native_getpath)),
        ("env".into(), 0, Native::new(native_env)),
        ("builtins".into(), 0, Native::new(native_builtins)),
        ("tojson".into(), 0, Native::new(native_tojson)),
        ("fromjson".into(), 0, Native::new(native_fromjson)),
    ]
}

// ── Helper ──────────────────────────────────────────────────────────

type Cv<'a> = (jaq_interpret::Ctx<'a, Val>, Val);
type Out<'a> = Box<dyn Iterator<Item = Result<Val, Error>> + 'a>;

fn box_once<'a>(v: Result<Val, Error>) -> Out<'a> {
    Box::new(std::iter::once(v))
}

fn val_str(s: &str) -> Val {
    Val::from(s.to_string())
}

// ── Native function implementations ─────────────────────────────────

fn native_length<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    let v = cv.1;
    match &v {
        Val::Null => box_once(Ok(Val::Int(0))),
        Val::Bool(_) => box_once(Ok(Val::Int(if v.as_bool() { 1 } else { 0 }))),
        Val::Int(i) => box_once(Ok(Val::Int(i.unsigned_abs() as isize))),
        Val::Float(f) => box_once(Ok(Val::Float(f.abs()))),
        Val::Num(_) => box_once(Ok(v)),
        Val::Str(s) => box_once(Ok(Val::Int(s.chars().count() as isize))),
        Val::Arr(a) => box_once(Ok(Val::Int(a.len() as isize))),
        Val::Obj(o) => box_once(Ok(Val::Int(o.len() as isize))),
    }
}

fn native_empty<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    Box::new(std::iter::empty())
}

fn native_not<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    box_once(Ok(Val::Bool(!cv.1.as_bool())))
}

fn native_type<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    let type_name = match &cv.1 {
        Val::Null => "null",
        Val::Bool(_) => "boolean",
        Val::Int(_) | Val::Float(_) | Val::Num(_) => "number",
        Val::Str(_) => "string",
        Val::Arr(_) => "array",
        Val::Obj(_) => "object",
    };
    box_once(Ok(val_str(type_name)))
}

fn native_null<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    box_once(Ok(Val::Null))
}

fn native_true<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    box_once(Ok(Val::Bool(true)))
}

fn native_false<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    box_once(Ok(Val::Bool(false)))
}

fn native_error<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    box_once(Err(Error::Val(cv.1)))
}

fn native_error_msg<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let msg_filter = args.get(0);
    Box::new(msg_filter.run(cv).map(|v| match v {
        Ok(v) => Err(Error::Val(v)),
        Err(e) => Err(e),
    }))
}

fn native_has<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let key_filter = args.get(0);
    let val = cv.1.clone();
    Box::new(key_filter.run(cv).map(move |k| {
        let k = k?;
        Ok(Val::Bool(val.has(&k).unwrap_or(false)))
    }))
}

fn native_contains<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let other_filter = args.get(0);
    let val = cv.1.clone();
    Box::new(other_filter.run(cv).map(move |other| {
        let other = other?;
        Ok(Val::Bool(val.contains(&other)))
    }))
}

fn native_keys<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.keys_unsorted() {
        Ok(mut keys) => {
            keys.sort();
            box_once(Ok(Val::arr(keys)))
        }
        Err(e) => box_once(Err(e)),
    }
}

fn native_keys_unsorted<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.keys_unsorted() {
        Ok(keys) => box_once(Ok(Val::arr(keys))),
        Err(e) => box_once(Err(e)),
    }
}

fn native_values<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::ValT;
    let vals: Vec<_> = cv.1.values().collect();
    let result: Result<Vec<Val>, Error> = vals.into_iter().collect();
    match result {
        Ok(v) => box_once(Ok(Val::arr(v))),
        Err(e) => box_once(Err(e)),
    }
}

fn native_sort<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1 {
        Val::Arr(a) => {
            let mut v = (*a).clone();
            v.sort();
            box_once(Ok(Val::arr(v)))
        }
        other => box_once(Err(Error::Type(other, jaq_interpret::error::Type::Arr))),
    }
}

fn native_reverse<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1 {
        Val::Arr(a) => {
            let mut v = (*a).clone();
            v.reverse();
            box_once(Ok(Val::arr(v)))
        }
        Val::Str(s) => box_once(Ok(Val::from(s.chars().rev().collect::<String>()))),
        other => box_once(Err(Error::Type(other, jaq_interpret::error::Type::Arr))),
    }
}

fn native_add<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1 {
        Val::Arr(a) => {
            let mut result = Val::Null;
            for item in a.iter() {
                result = match result + item.clone() {
                    Ok(v) => v,
                    Err(e) => return box_once(Err(e)),
                };
            }
            box_once(Ok(result))
        }
        Val::Null => box_once(Ok(Val::Null)),
        other => box_once(Err(Error::Type(other, jaq_interpret::error::Type::Arr))),
    }
}

fn native_min<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1 {
        Val::Arr(a) if a.is_empty() => box_once(Ok(Val::Null)),
        Val::Arr(a) => box_once(Ok(a.iter().min().cloned().unwrap_or(Val::Null))),
        other => box_once(Err(Error::Type(other, jaq_interpret::error::Type::Arr))),
    }
}

fn native_max<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1 {
        Val::Arr(a) if a.is_empty() => box_once(Ok(Val::Null)),
        Val::Arr(a) => box_once(Ok(a.iter().max().cloned().unwrap_or(Val::Null))),
        other => box_once(Err(Error::Type(other, jaq_interpret::error::Type::Arr))),
    }
}

// ── Regex functions ─────────────────────────────────────────────────

fn build_regex(pattern: &str, flags: &str) -> Result<regex::Regex, Error> {
    let case_insensitive = flags.contains('i');
    let global = flags.contains('g');
    let multiline = flags.contains('m');
    let dotall = flags.contains('s');
    let extended = flags.contains('x');

    let mut builder = regex::RegexBuilder::new(pattern);
    builder.case_insensitive(case_insensitive);
    builder.multi_line(multiline);
    builder.dot_matches_new_line(dotall);
    builder.ignore_whitespace(extended);
    let _ = global; // global is handled by the caller

    builder
        .build()
        .map_err(|e| Error::str(format!("invalid regex: {e}")))
}

fn native_test1<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let re_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(re_filter.run(cv).map(move |re_val| {
        let re_val = re_val?;
        let pattern = match &re_val {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(re_val, jaq_interpret::error::Type::Str)),
        };
        let input_str = match &input {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(input.clone(), jaq_interpret::error::Type::Str)),
        };
        let re = build_regex(pattern, "")?;
        Ok(Val::Bool(re.is_match(input_str)))
    }))
}

fn native_test2<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let re_filter = args.get(0);
    let flags_filter = args.get(1);
    let input = cv.1.clone();
    let ctx = cv.0.clone();
    Box::new(re_filter.run(cv).flat_map(move |re_val| {
        let re_val = match re_val {
            Ok(v) => v,
            Err(e) => return box_once(Err(e)),
        };
        let pattern = match &re_val {
            Val::Str(s) => s.to_string(),
            _ => return box_once(Err(Error::Type(re_val, jaq_interpret::error::Type::Str))),
        };
        let input2 = input.clone();
        let input_for_flags = input.clone();
        Box::new(
            flags_filter
                .clone()
                .run((ctx.clone(), input_for_flags))
                .map(move |flags_val| {
                    let flags_val = flags_val?;
                    let flags = match &flags_val {
                        Val::Str(s) => &**s,
                        _ => return Err(Error::Type(flags_val, jaq_interpret::error::Type::Str)),
                    };
                    let input_str = match &input2 {
                        Val::Str(s) => &**s,
                        _ => {
                            return Err(Error::Type(
                                input2.clone(),
                                jaq_interpret::error::Type::Str,
                            ))
                        }
                    };
                    let re = build_regex(&pattern, flags)?;
                    Ok(Val::Bool(re.is_match(input_str)))
                }),
        ) as Out
    }))
}

fn regex_match_to_val(m: &regex::Match, captures: &regex::Captures) -> Val {
    use jaq_interpret::ValT;

    let mut cap_vals = Vec::new();
    for (i, cap) in captures.iter().enumerate() {
        if i == 0 {
            continue;
        }
        if let Some(c) = cap {
            if let Ok(cap_obj) = Val::from_map([
                (val_str("offset"), Val::Int(c.start() as isize)),
                (val_str("length"), Val::Int(c.len() as isize)),
                (val_str("string"), Val::from(c.as_str().to_string())),
                (val_str("name"), Val::Null),
            ]) {
                cap_vals.push(cap_obj);
            }
        }
    }

    Val::from_map([
        (val_str("offset"), Val::Int(m.start() as isize)),
        (val_str("length"), Val::Int(m.len() as isize)),
        (val_str("string"), Val::from(m.as_str().to_string())),
        (val_str("captures"), Val::arr(cap_vals)),
    ])
    .unwrap_or(Val::Null)
}

fn do_match(input_str: &str, pattern: &str, flags: &str) -> Result<Vec<Val>, Error> {
    let re = build_regex(pattern, flags)?;
    let global = flags.contains('g');

    let mut results = Vec::new();
    if global {
        for caps in re.captures_iter(input_str) {
            if let Some(m) = caps.get(0) {
                results.push(regex_match_to_val(&m, &caps));
            }
        }
    } else if let Some(caps) = re.captures(input_str) {
        if let Some(m) = caps.get(0) {
            results.push(regex_match_to_val(&m, &caps));
        }
    }
    Ok(results)
}

fn native_match1<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let re_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(re_filter.run(cv).flat_map(move |re_val| {
        let re_val = match re_val {
            Ok(v) => v,
            Err(e) => return box_once(Err(e)),
        };
        let pattern = match &re_val {
            Val::Str(s) => s.to_string(),
            _ => return box_once(Err(Error::Type(re_val, jaq_interpret::error::Type::Str))),
        };
        let input_str = match &input {
            Val::Str(s) => s.to_string(),
            _ => {
                return box_once(Err(Error::Type(
                    input.clone(),
                    jaq_interpret::error::Type::Str,
                )))
            }
        };
        match do_match(&input_str, &pattern, "") {
            Ok(vals) => Box::new(vals.into_iter().map(Ok)) as Out,
            Err(e) => box_once(Err(e)),
        }
    }))
}

fn native_match2<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let re_filter = args.get(0);
    let flags_filter = args.get(1);
    let input = cv.1.clone();
    let ctx = cv.0.clone();
    Box::new(re_filter.run(cv).flat_map(move |re_val| {
        let re_val = match re_val {
            Ok(v) => v,
            Err(e) => return box_once(Err(e)),
        };
        let pattern = match &re_val {
            Val::Str(s) => s.to_string(),
            _ => return box_once(Err(Error::Type(re_val, jaq_interpret::error::Type::Str))),
        };
        let input2 = input.clone();
        Box::new(
            flags_filter
                .clone()
                .run((ctx.clone(), input.clone()))
                .flat_map(move |flags_val| {
                    let flags_val = match flags_val {
                        Ok(v) => v,
                        Err(e) => return box_once(Err(e)),
                    };
                    let flags = match &flags_val {
                        Val::Str(s) => s.to_string(),
                        _ => {
                            return box_once(Err(Error::Type(
                                flags_val,
                                jaq_interpret::error::Type::Str,
                            )))
                        }
                    };
                    let input_str = match &input2 {
                        Val::Str(s) => s.to_string(),
                        _ => {
                            return box_once(Err(Error::Type(
                                input2.clone(),
                                jaq_interpret::error::Type::Str,
                            )))
                        }
                    };
                    match do_match(&input_str, &pattern, &flags) {
                        Ok(vals) => Box::new(vals.into_iter().map(Ok)) as Out,
                        Err(e) => box_once(Err(e)),
                    }
                }),
        ) as Out
    }))
}

fn native_capture1<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    native_match1(args, cv)
}

fn native_capture2<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    native_match2(args, cv)
}

// ── String functions ────────────────────────────────────────────────

fn native_split<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let sep_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(sep_filter.run(cv).map(move |sep_val| {
        let sep_val = sep_val?;
        let input_str = match &input {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(input.clone(), jaq_interpret::error::Type::Str)),
        };
        let sep = match &sep_val {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(sep_val, jaq_interpret::error::Type::Str)),
        };
        // Try as regex first, fall back to literal split
        if let Ok(re) = regex::Regex::new(sep) {
            let parts: Vec<Val> = re.split(input_str).map(|s| Val::from(s.to_string())).collect();
            Ok(Val::arr(parts))
        } else {
            let parts: Vec<Val> = input_str.split(sep).map(|s| Val::from(s.to_string())).collect();
            Ok(Val::arr(parts))
        }
    }))
}

fn native_join<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let sep_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(sep_filter.run(cv).map(move |sep_val| {
        let sep_val = sep_val?;
        let arr = match &input {
            Val::Arr(a) => a,
            _ => return Err(Error::Type(input.clone(), jaq_interpret::error::Type::Arr)),
        };
        let sep = match &sep_val {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(sep_val, jaq_interpret::error::Type::Str)),
        };
        let parts: Vec<String> = arr
            .iter()
            .map(|v| match v {
                Val::Str(s) => (**s).clone(),
                Val::Null => String::new(),
                other => format!("{other}"),
            })
            .collect();
        Ok(Val::from(parts.join(sep)))
    }))
}

fn native_gsub<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let re_filter = args.get(0);
    let repl_filter = args.get(1);
    let input = cv.1.clone();
    let ctx = cv.0.clone();
    Box::new(re_filter.run(cv).flat_map(move |re_val| {
        let re_val = match re_val {
            Ok(v) => v,
            Err(e) => return box_once(Err(e)),
        };
        let pattern = match &re_val {
            Val::Str(s) => s.to_string(),
            _ => return box_once(Err(Error::Type(re_val, jaq_interpret::error::Type::Str))),
        };
        let input2 = input.clone();
        Box::new(
            repl_filter
                .clone()
                .run((ctx.clone(), input.clone()))
                .map(move |repl_val| {
                    let repl_val = repl_val?;
                    let replacement = match &repl_val {
                        Val::Str(s) => &**s,
                        _ => return Err(Error::Type(repl_val, jaq_interpret::error::Type::Str)),
                    };
                    let input_str = match &input2 {
                        Val::Str(s) => &**s,
                        _ => {
                            return Err(Error::Type(
                                input2.clone(),
                                jaq_interpret::error::Type::Str,
                            ))
                        }
                    };
                    let re = build_regex(&pattern, "")?;
                    Ok(Val::from(re.replace_all(input_str, replacement).to_string()))
                }),
        ) as Out
    }))
}

fn native_sub<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let re_filter = args.get(0);
    let repl_filter = args.get(1);
    let input = cv.1.clone();
    let ctx = cv.0.clone();
    Box::new(re_filter.run(cv).flat_map(move |re_val| {
        let re_val = match re_val {
            Ok(v) => v,
            Err(e) => return box_once(Err(e)),
        };
        let pattern = match &re_val {
            Val::Str(s) => s.to_string(),
            _ => return box_once(Err(Error::Type(re_val, jaq_interpret::error::Type::Str))),
        };
        let input2 = input.clone();
        Box::new(
            repl_filter
                .clone()
                .run((ctx.clone(), input.clone()))
                .map(move |repl_val| {
                    let repl_val = repl_val?;
                    let replacement = match &repl_val {
                        Val::Str(s) => &**s,
                        _ => return Err(Error::Type(repl_val, jaq_interpret::error::Type::Str)),
                    };
                    let input_str = match &input2 {
                        Val::Str(s) => &**s,
                        _ => {
                            return Err(Error::Type(
                                input2.clone(),
                                jaq_interpret::error::Type::Str,
                            ))
                        }
                    };
                    let re = build_regex(&pattern, "")?;
                    Ok(Val::from(re.replace(input_str, replacement).to_string()))
                }),
        ) as Out
    }))
}

fn native_startswith<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let prefix_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(prefix_filter.run(cv).map(move |prefix_val| {
        let prefix_val = prefix_val?;
        let input_str = match &input {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(input.clone(), jaq_interpret::error::Type::Str)),
        };
        let prefix = match &prefix_val {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(prefix_val, jaq_interpret::error::Type::Str)),
        };
        Ok(Val::Bool(input_str.starts_with(prefix)))
    }))
}

fn native_endswith<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let suffix_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(suffix_filter.run(cv).map(move |suffix_val| {
        let suffix_val = suffix_val?;
        let input_str = match &input {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(input.clone(), jaq_interpret::error::Type::Str)),
        };
        let suffix = match &suffix_val {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(suffix_val, jaq_interpret::error::Type::Str)),
        };
        Ok(Val::Bool(input_str.ends_with(suffix)))
    }))
}

fn native_tostring<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Str(_) => box_once(Ok(cv.1)),
        other => box_once(Ok(Val::from(format!("{other}")))),
    }
}

fn native_tonumber<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Int(_) | Val::Float(_) | Val::Num(_) => box_once(Ok(cv.1)),
        Val::Str(s) => {
            if let Ok(i) = s.parse::<isize>() {
                box_once(Ok(Val::Int(i)))
            } else if let Ok(f) = s.parse::<f64>() {
                box_once(Ok(Val::Float(f)))
            } else {
                box_once(Err(Error::str(format!("cannot convert {s:?} to number"))))
            }
        }
        other => box_once(Err(Error::Type(other.clone(), jaq_interpret::error::Type::Num))),
    }
}

fn native_explode<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Str(s) => {
            let codepoints: Vec<Val> = s.chars().map(|c| Val::Int(c as isize)).collect();
            box_once(Ok(Val::arr(codepoints)))
        }
        other => box_once(Err(Error::Type(other.clone(), jaq_interpret::error::Type::Str))),
    }
}

fn native_implode<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Arr(a) => {
            let mut s = String::new();
            for v in a.iter() {
                match v {
                    Val::Int(i) => {
                        if let Some(c) = char::from_u32(*i as u32) {
                            s.push(c);
                        }
                    }
                    _ => return box_once(Err(Error::Type(v.clone(), jaq_interpret::error::Type::Int))),
                }
            }
            box_once(Ok(Val::from(s)))
        }
        other => box_once(Err(Error::Type(other.clone(), jaq_interpret::error::Type::Arr))),
    }
}

// ── Time functions ──────────────────────────────────────────────────

fn native_now<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    let now = chrono::Utc::now().timestamp();
    box_once(Ok(Val::Int(now as isize)))
}

fn native_fromdateiso8601<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Str(s) => {
            // Try RFC 3339 first, then ISO 8601 variations
            if let Ok(dt) = chrono::DateTime::parse_from_rfc3339(s) {
                box_once(Ok(Val::Int(dt.timestamp() as isize)))
            } else if let Ok(dt) = chrono::NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S") {
                box_once(Ok(Val::Int(
                    dt.and_utc().timestamp() as isize,
                )))
            } else if let Ok(dt) = chrono::NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%SZ") {
                box_once(Ok(Val::Int(
                    dt.and_utc().timestamp() as isize,
                )))
            } else if let Ok(dt) = chrono::NaiveDate::parse_from_str(s, "%Y-%m-%d") {
                box_once(Ok(Val::Int(
                    dt.and_hms_opt(0, 0, 0)
                        .unwrap()
                        .and_utc()
                        .timestamp() as isize,
                )))
            } else {
                box_once(Err(Error::str(format!(
                    "cannot parse date: {s}"
                ))))
            }
        }
        other => box_once(Err(Error::Type(other.clone(), jaq_interpret::error::Type::Str))),
    }
}

fn native_todateiso8601<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Int(ts) => {
            let dt = chrono::DateTime::from_timestamp(*ts as i64, 0)
                .unwrap_or_default();
            box_once(Ok(Val::from(dt.format("%Y-%m-%dT%H:%M:%SZ").to_string())))
        }
        Val::Float(ts) => {
            let dt = chrono::DateTime::from_timestamp(*ts as i64, 0)
                .unwrap_or_default();
            box_once(Ok(Val::from(dt.format("%Y-%m-%dT%H:%M:%SZ").to_string())))
        }
        other => box_once(Err(Error::Type(other.clone(), jaq_interpret::error::Type::Num))),
    }
}

fn native_strftime<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let fmt_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(fmt_filter.run(cv).map(move |fmt_val| {
        let fmt_val = fmt_val?;
        let fmt_str = match &fmt_val {
            Val::Str(s) => &**s,
            _ => return Err(Error::Type(fmt_val, jaq_interpret::error::Type::Str)),
        };
        let ts = match &input {
            Val::Int(i) => *i as i64,
            Val::Float(f) => *f as i64,
            _ => return Err(Error::Type(input.clone(), jaq_interpret::error::Type::Num)),
        };
        let dt = chrono::DateTime::from_timestamp(ts, 0).unwrap_or_default();
        Ok(Val::from(dt.format(fmt_str).to_string()))
    }))
}

// ── Math functions ──────────────────────────────────────────────────

fn native_floor<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.round(f64::floor) {
        Ok(v) => box_once(Ok(v)),
        Err(e) => box_once(Err(e)),
    }
}

fn native_ceil<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.round(f64::ceil) {
        Ok(v) => box_once(Ok(v)),
        Err(e) => box_once(Err(e)),
    }
}

fn native_round<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.round(f64::round) {
        Ok(v) => box_once(Ok(v)),
        Err(e) => box_once(Err(e)),
    }
}

fn native_fabs<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Int(i) => box_once(Ok(Val::Int(i.unsigned_abs() as isize))),
        Val::Float(f) => box_once(Ok(Val::Float(f.abs()))),
        other => box_once(Err(Error::Type(other.clone(), jaq_interpret::error::Type::Num))),
    }
}

fn native_log<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.as_float() {
        Ok(f) => box_once(Ok(Val::Float(f.ln()))),
        Err(e) => box_once(Err(e)),
    }
}

fn native_log2<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.as_float() {
        Ok(f) => box_once(Ok(Val::Float(f.log2()))),
        Err(e) => box_once(Err(e)),
    }
}

fn native_sqrt<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match cv.1.as_float() {
        Ok(f) => box_once(Ok(Val::Float(f.sqrt()))),
        Err(e) => box_once(Err(e)),
    }
}

fn native_pow<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let base_filter = args.get(0);
    let exp_filter = args.get(1);
    Box::new(base_filter.run(cv.clone()).flat_map(move |base| {
        let base = match base {
            Ok(v) => v,
            Err(e) => return box_once(Err(e)),
        };
        Box::new(exp_filter.clone().run(cv.clone()).map(move |exp| {
            let exp = exp?;
            let b = base.as_float().map_err(|_| Error::Type(base.clone(), jaq_interpret::error::Type::Num))?;
            let e = exp.as_float().map_err(|_| Error::Type(exp.clone(), jaq_interpret::error::Type::Num))?;
            Ok(Val::Float(b.powf(e)))
        })) as Out
    }))
}

fn native_infinite<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    box_once(Ok(Val::Float(f64::INFINITY)))
}

fn native_nan<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    box_once(Ok(Val::Float(f64::NAN)))
}

// ── Path functions ──────────────────────────────────────────────────

fn native_path<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    // Simplified path implementation - just return empty for now
    box_once(Ok(Val::arr(vec![])))
}

fn native_getpath<'a>(args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::FilterT;
    let path_filter = args.get(0);
    let input = cv.1.clone();
    Box::new(path_filter.run(cv).map(move |path_val| {
        let path_val = path_val?;
        let path = match &path_val {
            Val::Arr(a) => a,
            _ => return Err(Error::Type(path_val, jaq_interpret::error::Type::Arr)),
        };
        let mut current = input.clone();
        for key in path.iter() {
            use jaq_interpret::ValT;
            current = current.index(key)?;
        }
        Ok(current)
    }))
}

// ── Environment & Meta ──────────────────────────────────────────────

fn native_env<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    use jaq_interpret::ValT;
    let pairs: Vec<(Val, Val)> = std::env::vars()
        .map(|(k, v)| (Val::from(k), Val::from(v)))
        .collect();
    match Val::from_map(pairs) {
        Ok(obj) => box_once(Ok(obj)),
        Err(e) => box_once(Err(e)),
    }
}

fn native_builtins<'a>(_args: jaq_interpret::Args<'a, Val>, _cv: Cv<'a>) -> Out<'a> {
    let builtins = vec![
        "length", "empty", "not", "type", "null", "true", "false",
        "error", "has", "contains", "keys", "keys_unsorted", "values",
        "sort", "reverse", "add", "min", "max", "test", "match",
        "capture", "split", "join", "startswith", "endswith",
        "tostring", "tonumber", "explode", "implode", "now",
        "fromdateiso8601", "todateiso8601", "strftime",
        "floor", "ceil", "round", "fabs", "log", "log2", "sqrt", "pow",
        "infinite", "nan", "path", "getpath", "env", "builtins",
        "select", "map", "any", "all", "first", "last", "limit",
        "from_entries", "to_entries", "with_entries", "flatten",
        "recurse", "unique", "unique_by", "sort_by", "group_by",
        "min_by", "max_by", "tojson", "fromjson",
    ];
    let vals: Vec<Val> = builtins.into_iter().map(|s| Val::from(s.to_string())).collect();
    box_once(Ok(Val::arr(vals)))
}

fn native_tojson<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    let json: serde_json::Value = cv.1.into();
    match serde_json::to_string(&json) {
        Ok(s) => box_once(Ok(Val::from(s))),
        Err(e) => box_once(Err(Error::str(format!("tojson: {e}")))),
    }
}

fn native_fromjson<'a>(_args: jaq_interpret::Args<'a, Val>, cv: Cv<'a>) -> Out<'a> {
    match &cv.1 {
        Val::Str(s) => match serde_json::from_str::<serde_json::Value>(s) {
            Ok(v) => box_once(Ok(Val::from(v))),
            Err(e) => box_once(Err(Error::str(format!("fromjson: {e}")))),
        },
        other => box_once(Err(Error::Type(other.clone(), jaq_interpret::error::Type::Str))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn eval(expr: &str, input: &serde_json::Value) -> serde_json::Value {
        let (filter, errs) = jaq_parse::parse(expr, jaq_parse::main());
        assert!(errs.is_empty(), "Parse errors: {:?}", errs);
        let filter = filter.unwrap();

        let mut ctx = ParseCtx::new(Vec::new());
        register_stdlib(&mut ctx);
        let filter = ctx.compile(filter);
        if !ctx.errs.is_empty() {
            let msgs: Vec<String> = ctx.errs.iter()
                .map(|(err, span)| format!("span={span:?}, err={err}"))
                .collect();
            panic!("Compile errors:\n{}", msgs.join("\n"));
        }

        let inputs = jaq_interpret::RcIter::new(std::iter::empty());
        let val = Val::from(input.clone());
        use jaq_interpret::FilterT;
        let mut out = filter.run((jaq_interpret::Ctx::new([], &inputs), val));
        match out.next() {
            Some(Ok(v)) => v.into(),
            Some(Err(e)) => panic!("jq error: {e}"),
            None => json!(null),
        }
    }

    #[test]
    fn test_defs_parse_basic() {
        let (defs, errs) = jaq_parse::parse(JQ_DEFS_BASIC, jaq_parse::defs());
        if !errs.is_empty() {
            for err in &errs {
                println!("Basic parse error: {err}");
            }
            panic!("{} basic parse errors", errs.len());
        }
        let defs = defs.unwrap();
        println!("Parsed {} basic defs:", defs.len());
        for def in &defs {
            println!("  def {} (arity {})", def.lhs.name, def.lhs.args.len());
        }
        assert!(!defs.is_empty(), "Should have parsed at least one def");
    }

    #[test]
    fn test_gsub() {
        assert_eq!(
            eval(r#"gsub("o"; "0")"#, &json!("foobar")),
            json!("f00bar")
        );
    }

    #[test]
    fn test_select_simple() {
        // Test with the simplest possible select usage
        let mut ctx = ParseCtx::new(Vec::new());
        register_stdlib(&mut ctx);

        let src = "def myselect(f): if f then . else empty end; [1, 2, 3] | [.[] | myselect(. > 1)]";
        let (filter, errs) = jaq_parse::parse(src, jaq_parse::main());
        assert!(errs.is_empty(), "Parse errors: {:?}", errs);
        let _filter = ctx.compile(filter.unwrap());
        if !ctx.errs.is_empty() {
            let msgs: Vec<String> = ctx.errs.iter()
                .map(|(err, span)| format!("span={span:?}, err={err}"))
                .collect();
            panic!("Compile errors:\n{}", msgs.join("\n"));
        }
    }

    #[test]
    fn test_length_array() {
        assert_eq!(eval("length", &json!([1, 2, 3])), json!(3));
    }

    #[test]
    fn test_length_string() {
        assert_eq!(eval("length", &json!("hello")), json!(5));
    }

    #[test]
    fn test_length_object() {
        assert_eq!(eval("length", &json!({"a": 1, "b": 2})), json!(2));
    }

    #[test]
    fn test_length_null() {
        assert_eq!(eval("length", &json!(null)), json!(0));
    }

    #[test]
    fn test_select() {
        let input = json!([
            {"key": "webauthn", "status": "ACTIVE"},
            {"key": "totp", "status": "ACTIVE"}
        ]);
        let expr = r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#;
        assert_eq!(eval(expr, &input), json!(true));
    }

    #[test]
    fn test_select_no_match() {
        let input = json!([
            {"key": "webauthn", "status": "INACTIVE"}
        ]);
        let expr = r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#;
        assert_eq!(eval(expr, &input), json!(false));
    }

    #[test]
    fn test_all_zero_arity() {
        let input = json!([true, true, true]);
        assert_eq!(eval("all", &input), json!(true));

        let input2 = json!([true, false, true]);
        assert_eq!(eval("all", &input2), json!(false));
    }

    #[test]
    fn test_all_with_filter() {
        let input = json!([false, false, false]);
        assert_eq!(eval("all(. == false)", &input), json!(true));
    }

    #[test]
    fn test_has() {
        assert_eq!(eval(r#"has("id")"#, &json!({"id": 123})), json!(true));
        assert_eq!(eval(r#"has("missing")"#, &json!({"id": 123})), json!(false));
    }

    #[test]
    fn test_type() {
        assert_eq!(eval("type", &json!(null)), json!("null"));
        assert_eq!(eval("type", &json!(42)), json!("number"));
        assert_eq!(eval("type", &json!("hello")), json!("string"));
        assert_eq!(eval("type", &json!([1, 2])), json!("array"));
        assert_eq!(eval("type", &json!({"a": 1})), json!("object"));
    }

    #[test]
    fn test_not() {
        assert_eq!(eval("not", &json!(true)), json!(false));
        assert_eq!(eval("not", &json!(false)), json!(true));
        assert_eq!(eval("not", &json!(null)), json!(true));
    }

    #[test]
    fn test_test_regex() {
        let input = json!("admin-policy");
        assert_eq!(eval(r#"test("admin"; "i")"#, &input), json!(true));
        assert_eq!(eval(r#"test("ADMIN"; "i")"#, &input), json!(true));
        assert_eq!(eval(r#"test("ADMIN")"#, &input), json!(false));
    }

    #[test]
    fn test_now() {
        let result = eval("now", &json!(null));
        assert!(result.is_number());
        assert!(result.as_i64().unwrap() > 1700000000);
    }

    #[test]
    fn test_fromdateiso8601() {
        let result = eval("fromdateiso8601", &json!("2024-01-01T00:00:00Z"));
        assert_eq!(result, json!(1704067200));
    }

    #[test]
    fn test_keys() {
        let result = eval("keys", &json!({"b": 2, "a": 1, "c": 3}));
        assert_eq!(result, json!(["a", "b", "c"]));
    }

    #[test]
    fn test_map() {
        assert_eq!(eval("map(. + 1)", &json!([1, 2, 3])), json!([2, 3, 4]));
    }

    #[test]
    fn test_okta_mfa_check() {
        let input = json!([
            {"key": "webauthn", "status": "ACTIVE"},
            {"key": "totp", "status": "ACTIVE"}
        ]);
        let expr = r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#;
        assert_eq!(eval(expr, &input), json!(true));
    }

    #[test]
    fn test_okta_network_zone_check() {
        let input = json!([
            {"status": "ACTIVE", "system": false, "name": "Corporate"},
            {"status": "INACTIVE", "system": true, "name": "Default"}
        ]);
        let expr = r#"[.[] | select(.status == "ACTIVE" and .system == false)] | length > 0"#;
        assert_eq!(eval(expr, &input), json!(true));
    }

    #[test]
    fn test_okta_all_inactive_check() {
        let input = json!([
            {"status": "ACTIVE", "settings": {"recovery": {"factors": {"okta_sms": {"status": "INACTIVE"}}}}},
        ]);
        let expr = r#"[.[] | select(.status == "ACTIVE") | .settings.recovery.factors.okta_sms.status == "INACTIVE"] | all"#;
        assert_eq!(eval(expr, &input), json!(true));
    }

    #[test]
    fn test_okta_test_regex_check() {
        let input = json!([
            {"name": "Admin Policy", "conditions": {"network": {"connection": "ZONE"}}},
        ]);
        let expr = r#"[.[] | select(.name | test("admin"; "i")) | .conditions.network.connection] | . != ["ANYWHERE"]"#;
        assert_eq!(eval(expr, &input), json!(true));
    }
}
