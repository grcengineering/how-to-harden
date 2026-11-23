#!/usr/bin/env python3
"""Offline safety assertions, not a reproduction of Inspect's policy evaluator."""
from pathlib import Path
import unittest
import yaml

PATH = Path(__file__).resolve().parents[1] / 'packs/inspect/config/hth-inspect-4.01-human-review-approval-baseline.yml'

class ApprovalBaseline(unittest.TestCase):
    def setUp(self):
        self.policy = yaml.safe_load(PATH.read_text())

    def test_native_keys(self):
        self.assertEqual(set(self.policy), {'default', 'rules'})
        self.assertEqual(set(self.policy['default']), {'action', 'rationale'})
        for rule in self.policy['rules']:
            self.assertEqual(set(rule), {'paths', 'action', 'rationale'})
            self.assertTrue(all(isinstance(x, str) and x for x in rule['paths']))

    def test_no_automatic_approval_or_classifier(self):
        self.assertEqual(self.policy['default']['action'], 'deny')
        for rule in self.policy['rules']:
            self.assertEqual(rule['action'], 'deny')
            self.assertNotIn('targets', rule)

    def test_policy_and_instruction_paths_protected(self):
        paths = {p for r in self.policy['rules'] for p in r['paths']}
        self.assertTrue({'.inspect/**', '.github/**', 'AGENTS.md', 'CLAUDE.md'} <= paths)

if __name__ == '__main__':
    unittest.main()
