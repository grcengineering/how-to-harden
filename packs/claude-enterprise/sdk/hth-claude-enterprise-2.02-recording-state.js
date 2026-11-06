// HTH Control claude-enterprise 2.2: Native recording-state read
// Profile: L2 | Existing authorized ANTHROPIC_ADMIN_KEY; exact minimum Enterprise scope unverified
// https://howtoharden.com/guides/claude-enterprise/#22-enable-the-compliance-api-with-least-privilege-keys
// Source: https://platform.claude.com/docs/en/api/http/organization/compliance_settings/retrieve
import {scopedClient,privateEvidence} from './lib/native.js';
import {pathToFileURL} from 'node:url';
// HTH Guide Excerpt: begin native-sdk-recording-state
export async function recordingState(key,transport){
  const data=await scopedClient(key,transport).organization.complianceSettings.retrieve();
  if(data?.type!=='compliance_settings'||!['enabled','disabled'].includes(data?.state?.type))throw Error('Unknown recording state');
  return data; // Parent-inherited singleton; not an effective-settings list or native posture score.
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
  try{const data=await recordingState(process.env.ANTHROPIC_ADMIN_KEY);privateEvidence('recording-state',data);if(data.state.type!=='enabled')process.exitCode=1;}
  catch{console.error('Incomplete recording-state evidence; no success file.');process.exitCode=2;}
}
// HTH Guide Excerpt: end native-sdk-recording-state
