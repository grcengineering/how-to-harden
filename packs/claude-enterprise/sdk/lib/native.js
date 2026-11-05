import Anthropic from '@anthropic-ai/sdk';
import {mkdtempSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
export function scopedClient(apiKey,fetch){
  if(typeof apiKey!=='string'||!apiKey||/\s/.test(apiKey))throw Error('Invalid scoped credential');
  return new Anthropic({apiKey,authToken:null,baseURL:'https://api.anthropic.com',maxRetries:0,timeout:30000,logLevel:'off',openTelemetry:false,...(fetch?{fetch}:{})});
}
export function privateEvidence(name,rows){
  const dir=mkdtempSync(join(tmpdir(),'hth-anthropic-sdk-'));
  const path=join(dir,name+'.json');writeFileSync(path,JSON.stringify(rows,null,2)+'\n',{mode:0o600,flag:'wx'});
  console.log('Private native inventory (review policy separately): '+path);
}
