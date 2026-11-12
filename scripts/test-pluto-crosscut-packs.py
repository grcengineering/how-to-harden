#!/usr/bin/env python3
"""Offline command-contract tests; no tenant, network, or actual credentials."""
import os, pathlib, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Packs(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.d=pathlib.Path(self.tmp.name)
  self.env=dict(os.environ,PATH=str(self.d)+':'+os.environ['PATH'],HTH_PROFILE_LEVEL='2',ARTIFACT=str(self.d/'artifact'),GITHUB_REPOSITORY='acme/release',EXPECTED_SIGNER_WORKFLOW='acme/build/.github/workflows/release.yml',EXPECTED_SOURCE_REF='refs/tags/v1',EXPECTED_SOURCE_SHA='a'*40,ARGS=str(self.d/'args'))
  (self.d/'artifact').write_bytes(b'fixture')
  for tool in ('gh','circleci'):
   p=self.d/tool;p.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$ARGS"\nexit "${MOCK_RC:-0}"\n');p.chmod(0o700)
 def tearDown(self):self.tmp.cleanup()
 def runpack(self,path,**env):return subprocess.run(['bash',str(ROOT/path)],env=dict(self.env,**env),capture_output=True,text=True)
 def test_attestation_identity(self):
  r=self.runpack('packs/github/cli/hth-github-3.20-verify-attestations.sh');self.assertEqual(r.returncode,0,r.stderr)
  args=(self.d/'args').read_text();self.assertIn('--signer-workflow\nacme/build/',args);self.assertIn('--source-ref\nrefs/tags/v1',args);self.assertIn('--source-digest\n'+'a'*40,args)
 def test_artifact_ends_after_delimiter(self):
  r=self.runpack('packs/github/cli/hth-github-3.20-verify-attestations.sh');self.assertEqual(r.returncode,0)
  args=(self.d/'args').read_text().splitlines();self.assertEqual(args[-2:],["--",self.env['ARTIFACT']])
 def test_verification_failure_propagates(self):self.assertEqual(self.runpack('packs/github/cli/hth-github-3.20-verify-attestations.sh',MOCK_RC='7').returncode,7)
 def test_tagged_oci_rejected(self):self.assertEqual(self.runpack('packs/github/cli/hth-github-3.20-verify-attestations.sh',ARTIFACT='oci://ghcr.io/acme/release:latest').returncode,2)
 def test_bad_source_rejected(self):self.assertEqual(self.runpack('packs/github/cli/hth-github-3.20-verify-attestations.sh',EXPECTED_SOURCE_SHA='HEAD').returncode,2)
 def test_profile_rejected(self):self.assertEqual(self.runpack('packs/github/cli/hth-github-3.20-verify-attestations.sh',HTH_PROFILE_LEVEL='1').returncode,2)
 def test_codeowners_emits_only(self):
  sentinel=ROOT/'.github/CODEOWNERS';before=sentinel.read_bytes() if sentinel.exists() else None
  r=self.runpack('packs/github/config/hth-github-3.30-codeowners-cicd-approval.sh',SECURITY_OWNER='@acme/security');self.assertEqual(r.returncode,0,r.stderr)
  for path in ('/.github/CODEOWNERS','**/.claude/','**/.mcp.json','**/AGENTS.md'):self.assertIn(path,r.stdout)
  self.assertEqual(before,sentinel.read_bytes() if sentinel.exists() else None)
 def test_codeowners_rejects_injection(self):self.assertEqual(self.runpack('packs/github/config/hth-github-3.30-codeowners-cicd-approval.sh',SECURITY_OWNER='@a\n* @bad').returncode,2)
 def test_circleci_only_help(self):
  r=self.runpack('packs/circleci/cli/hth-circleci-1.04-inventory-mcp-command-surface.sh');self.assertEqual(r.returncode,0);self.assertEqual((self.d/'args').read_text(),'help\nreference\n')
if __name__=='__main__':unittest.main()
