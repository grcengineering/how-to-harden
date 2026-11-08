"""Local JSON validation/projection helper, not a Ramp SDK. Standard library only."""
import datetime
import json
import re
import sys
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError('Duplicate JSON key')
        result[key] = value
    return result


def reject_constant(value):
    raise ValueError('Non-finite JSON number')


def validate(value, schema):
    if value is None and schema.get('nullable'):
        return None
    typ = schema.get('type')
    kinds = {'object': dict, 'array': list, 'string': str, 'boolean': bool, 'integer': int, 'number': (int, float)}
    if typ in kinds and (not isinstance(value, kinds[typ]) or typ in ('integer', 'number') and isinstance(value, bool)):
        raise ValueError('Wrong field type')
    if typ == 'object':
        if not all(k in value for k in schema.get('required', [])):
            raise ValueError('Missing field')
        return {k: validate(value[k], v) for k, v in schema['properties'].items() if k in value}
    if typ == 'array':
        return [validate(v, schema['items']) for v in value]
    return value


def main():
    mode, *args = sys.argv[1:]
    if mode == 'dates':
        start, end = args
        for v in args:
            if not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', v):
                raise ValueError('UTC timestamps required')
        if datetime.datetime.fromisoformat(start.replace('Z', '+00:00')) >= datetime.datetime.fromisoformat(end.replace('Z', '+00:00')):
            raise ValueError('Invalid interval')
        print('?' + urlencode({'from_date': start, 'to_date': end, 'page_size': 100}))
    elif mode == 'page':
        kind, path, query, paged, folder = args
        tmp = Path(folder)
        response = json.loads((tmp / 'page').read_text(), object_pairs_hook=unique_object, parse_constant=reject_constant)
        if paged == 'yes':
            rows = response['data']
            next_url = response['page']['next']
            if next_url is not None:
                if not isinstance(next_url, str) or not next_url or not next_url.isascii() or any(ord(c) <= 32 or ord(c) == 127 for c in next_url):
                    raise ValueError('Invalid next URL')
                parsed = urlsplit(next_url)
                if parsed.scheme != 'https' or parsed.netloc != 'api.ramp.com' or parsed.path != path or parsed.fragment:
                    raise ValueError('Unsafe next URL')
                pairs = parse_qsl(parsed.query, strict_parsing=True)
                params = dict(pairs)
                expected = dict(parse_qsl(query.lstrip('?')))
                if len(params) != len(pairs) or set(params) != set(expected) | {'start'} or not params['start']:
                    raise ValueError('Unexpected pagination parameters')
                if any(params[k] != v for k, v in expected.items()):
                    raise ValueError('Changed query filters')
        else:
            rows = response if kind == 'webhooks' else response['connections' if kind == 'accounting' else 'data']
            next_url = None
        if not isinstance(rows, list):
            raise ValueError('Expected array')
        schema = json.loads(Path(__file__).with_name('response-shapes.json').read_text())[kind]
        projected = [validate(row, schema) for row in rows]
        with (tmp / (kind + '.ndjson')).open('a') as f:
            for row in projected:
                f.write(json.dumps(row, separators=(',', ':')) + '\n')
        (tmp / 'next').write_text(next_url or '')
    elif mode == 'report':
        folder, *kinds = args
        result = {kind: [json.loads(line) for line in (Path(folder) / (kind + '.ndjson')).read_text().splitlines()] for kind in kinds}
        # Audit output is NDJSON with original documented field names, directly ingestible.
        if kinds == ['audit']:
            payload = ''.join(json.dumps(row) + '\n' for row in result['audit'])
        else:
            payload = json.dumps(result, indent=2) + '\n'
        sys.stdout.write(payload)
    else:
        raise ValueError('Unknown mode')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError):
        print('Ramp response validation failed.', file=sys.stderr)
        sys.exit(1)
