#!/usr/bin/env python3
"""Offline contract tests. No Inspect/AWS credentials or network requests."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / 'packs/inspect/config'
TRUST = CONFIG / 'hth-inspect-3.03-exact-workload-trust.sh'
REVIEW = CONFIG / 'hth-inspect-4.02-review-verification-config.sh'


def run(pack, *args):
    return subprocess.run(['bash', str(pack), *args], text=True, capture_output=True)


class TrustTests(unittest.TestCase):
    def args(self, issuer='https://example.inspect.com/api/oidc', subject='org:org-id:repository:github:owner/repo:lifecycle:runtime', account='123456789012'):
        return ['--issuer', issuer, '--subject', subject, '--account-id', account]

    def test_exact_runtime_condition(self):
        r = run(TRUST, *self.args())
        self.assertEqual(r.returncode, 0, r.stderr)
        s = json.loads(r.stdout)['Statement'][0]
        self.assertEqual(s['Action'], 'sts:AssumeRoleWithWebIdentity')
        self.assertEqual(s['Principal']['Federated'], 'arn:aws:iam::123456789012:oidc-provider/example.inspect.com/api/oidc')
        self.assertEqual(s['Condition'], {'StringEquals': {
            'example.inspect.com/api/oidc:aud': 'sts.amazonaws.com',
            'example.inspect.com/api/oidc:sub': 'org:org-id:repository:github:owner/repo:lifecycle:runtime'}})

    def test_build_lifecycle_and_encoded_values(self):
        r = run(TRUST, *self.args(subject='org:org%3Aid:repository:github:owner/repo:lifecycle:build'))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('org%3Aid', r.stdout)

    def test_rejects_wildcards(self):
        for value in ['org:*:repository:github:owner/repo:lifecycle:runtime', 'org:id:repository:github:owner/*:lifecycle:runtime', 'org:id:repository:github:owner/repo:lifecycle:*']:
            with self.subTest(value=value):
                r = run(TRUST, *self.args(subject=value))
                self.assertNotEqual(r.returncode, 0)
                self.assertEqual(r.stdout, '')

    def test_rejects_wrong_issuer(self):
        for value in ['http://example.inspect.com/api/oidc', 'https://example.inspect.com.evil.test/api/oidc', 'https://u:p@example.inspect.com/api/oidc', 'https://example.inspect.com:443/api/oidc', 'https://example.inspect.com/api/oidc?x=y', 'https://example.inspect.com/api/oidc#x']:
            with self.subTest(value=value):
                self.assertNotEqual(run(TRUST, *self.args(issuer=value)).returncode, 0)

    def test_rejects_malformed_subject(self):
        for value in ['org:id:repository:github:owner/repo:lifecycle:preview', 'org:id:repository:github:owner/repo:lifecycle:runtime\n', 'org:id:repository:github:owner/repo%ZZ:lifecycle:runtime']:
            self.assertNotEqual(run(TRUST, *self.args(subject=value)).returncode, 0)

    def test_rejects_bad_account(self):
        self.assertNotEqual(run(TRUST, *self.args(account='123')).returncode, 0)


class ReviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        for path in ['.claude/skills/security/SKILL.md', '.agents/skills/verify-web/SKILL.md']:
            p = self.root / path
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('Test fixture only\n')

    def tearDown(self):
        self.temp.cleanup()

    def test_review_native_schema(self):
        r = run(REVIEW, 'review', '--repo', str(self.root), '--skill', 'security')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(json.loads(r.stdout), {'version': 1, 'rules': [{'id': 'hth-security', 'skill': 'security'}]})
        self.assertFalse((self.root / '.inspect').exists())

    def test_verification_native_schema(self):
        r = run(REVIEW, 'verification', '--repo', str(self.root), '--skill', '.agents/skills/verify-web/SKILL.md')
        self.assertEqual(r.returncode, 0, r.stderr)
        config = json.loads(r.stdout)
        self.assertEqual(config['skill'], '.agents/skills/verify-web/SKILL.md')
        self.assertEqual(config['model'], 'auto')
        self.assertNotIn('paths', config)
        self.assertFalse((self.root / '.inspect').exists())

    def test_missing_skill_fails_closed(self):
        r = run(REVIEW, 'review', '--repo', str(self.root), '--skill', 'missing')
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(r.stdout, '')

    def test_namespace_rejected(self):
        self.assertNotEqual(run(REVIEW, 'review', '--repo', str(self.root), '--skill', 'plugin:security').returncode, 0)

    def test_traversal_and_absolute_rejected(self):
        for path in ['../SKILL.md', '/tmp/SKILL.md']:
            self.assertNotEqual(run(REVIEW, 'verification', '--repo', str(self.root), '--skill', path).returncode, 0)

    def test_symlink_escape_rejected(self):
        with tempfile.TemporaryDirectory() as external:
            outside = Path(external) / 'SKILL.md'
            outside.write_text('Outside fixture\n')
            (self.root / 'SKILL.md').symlink_to(outside)
            self.assertNotEqual(run(REVIEW, 'verification', '--repo', str(self.root), '--skill', 'SKILL.md').returncode, 0)


if __name__ == '__main__':
    unittest.main()
