// Structural validation/output helper. Vendor response values never reach stderr.
import { readFileSync, writeFileSync, openSync, closeSync, unlinkSync, realpathSync, constants, statSync } from 'node:fs';
import { dirname, basename, resolve, isAbsolute, sep } from 'node:path';
import { createHash } from 'node:crypto';
const object = (v: unknown): v is Record<string, any> => !!v && typeof v === 'object' && !Array.isArray(v);
const requireThat = (v: unknown) => { if (!v) throw Error('invalid'); };
const strings = (v: unknown) => Array.isArray(v) && v.every(x=>typeof x==='string');
const json = (p:string) => JSON.parse(readFileSync(p,'utf8'));
try {
  const [operation, file, ...rest] = process.argv.slice(2);
  if (operation === 'save') {
    const output = process.env.STATSIG_OUTPUT ?? '';
    requireThat(isAbsolute(output));
    const parent = realpathSync(dirname(output));
    const repo = realpathSync(resolve(import.meta.dir,'../..'));
    requireThat(parent !== repo && !parent.startsWith(repo + sep));
    const contents=readFileSync(file), target=resolve(parent,basename(output));
    const fd = openSync(target, constants.O_CREAT|constants.O_EXCL|constants.O_WRONLY|constants.O_NOFOLLOW,0o600);
    try { writeFileSync(fd,contents); } catch { unlinkSync(target); throw Error('write failed'); } finally { closeSync(fd); }
  } else if (operation === 'project') {
    const data = json(file).data;
    requireThat(object(data) && typeof data.name==='string' && ['OPEN','CLOSED'].includes(data.visibility));
    requireThat(data.default_unit_type == null || typeof data.default_unit_type === 'string');
    writeFileSync(rest[0],JSON.stringify({project:{name:data.name,visibility:data.visibility,default_unit_type:data.default_unit_type??null},assessment:'CONFIGURATION-ONLY'},null,2)+'\n');
  } else if (operation === 'reviews') {
    const data = json(file).data;
    const required=['is_config_review_required','is_metric_review_required','is_metric_review_required_on_verified_only'];
    const optional=['is_whn_analysis_only_review_required','is_whn_source_review_required'];
    requireThat(object(data) && required.every(k=>typeof data[k]==='boolean'));
    requireThat(optional.every(k=>data[k]===undefined||typeof data[k]==='boolean'));
    const flags=Object.fromEntries([...required,...optional].filter(k=>data[k]!==undefined).map(k=>[k,data[k]]));
    writeFileSync(rest[0],JSON.stringify({flags,coverage:'Project flags only; inspect per-role bypass, designated reviewers and each environment separately.'},null,2)+'\n');
  } else if (operation === 'keys-page') {
    const page=Number(rest[0]), aggregateFile=rest[1], response=json(file);
    requireThat(Array.isArray(response.data)&&response.data.length<=100&&object(response.pagination));
    const p=response.pagination;
    requireThat(p.pageNumber===page&&p.itemsPerPage===100);
    requireThat(p.nextPage===null||typeof p.nextPage==='string');
    requireThat(p.totalItems===undefined||(Number.isInteger(p.totalItems)&&p.totalItems>=0));
    const aggregate=page===1?[]:json(aggregateFile);
    for(const key of response.data){
      requireThat(object(key)&&['SERVER','CLIENT','CONSOLE','SCIM','ORG'].includes(key.type));
      requireThat(['active','deactivated'].includes(key.status)&&typeof key.description==='string'&&strings(key.scopes));
      requireThat(key.key===null||typeof key.key==='string');
      for(const field of ['environments','secondaryTargetApps','secondaryTargetAppIDs'])requireThat(key[field]==null||strings(key[field]));
      for(const field of ['primaryTargetApp','targetAppID','lastUsed'])requireThat(key[field]==null||typeof key[field]==='string');
      const fingerprint=key.key===null?null:createHash('sha256').update(key.key).digest('hex');
      requireThat(!fingerprint||!aggregate.some((x:any)=>x.fingerprint===fingerprint));
      aggregate.push({fingerprint,type:key.type,status:key.status,description:key.description,scopes:key.scopes,
        environments:key.environments??null,primaryTargetApp:key.primaryTargetApp??null,targetAppID:key.targetAppID??null,
        secondaryTargetApps:key.secondaryTargetApps??null,secondaryTargetAppIDs:key.secondaryTargetAppIDs??null,lastUsed:key.lastUsed??null});
    }
    requireThat(aggregate.length<=10000);
    if(p.nextPage!==null){
      const next=new URL(p.nextPage,'https://statsigapi.net');
      requireThat(!next.username&&!next.password&&!next.hash&&next.origin==='https://statsigapi.net'&&next.pathname==='/console/v1/keys'&&next.searchParams.get('page')===String(page+1));
      requireThat([...next.searchParams.keys()].every(k=>['page','limit'].includes(k)));
      requireThat(next.searchParams.getAll('page').length===1&&next.searchParams.getAll('limit').length<=1);
      requireThat(!next.searchParams.has('limit')||next.searchParams.get('limit')==='100');
    }
    if(p.nextPage===null&&p.totalItems!==undefined)requireThat(p.totalItems===aggregate.length);
    writeFileSync(aggregateFile,JSON.stringify(aggregate));
    process.stdout.write(p.nextPage===null?'done':'next');
  } else if(operation==='keys-finish') {
    writeFileSync(rest[0],JSON.stringify({keys:json(file),coverage:'Completed observed pagination; reconcile personal/organization credentials and masked values in the console. Not a compliance verdict.'},null,2)+'\n');
  } else if(operation==='user') {
    requireThat(statSync(file).size<=65536);
    const input=json(file), allowed=['userID','email','ip','userAgent','country','locale','custom'];
    requireThat(object(input)&&Object.keys(input).every(k=>allowed.includes(k)));
    requireThat(typeof input.userID==='string'&&/^[A-Za-z0-9][A-Za-z0-9_.-]{0,199}$/.test(input.userID));
    const privateAttributes:Record<string,unknown>={};
    for(const [key,value]of Object.entries(input)){
      if(key==='userID')continue;
      if(key==='custom'){
        requireThat(object(value));
        for(const [k,v]of Object.entries(value)){
          requireThat(!allowed.includes(k)&&!['privateAttributes','__proto__','constructor','prototype'].includes(k)&&['string','number','boolean'].includes(typeof v));
          privateAttributes[k]=v;
        }
      }else{requireThat(typeof value==='string');privateAttributes[key]=value;}
    }
    writeFileSync(rest[0],JSON.stringify({userID:input.userID,privateAttributes},null,2)+'\n');
  } else if(operation==='status') {
    let value=readFileSync(file,'utf8').trim();
    try{value=JSON.parse(value);}catch{}
    requireThat(['PENDING','COMPLETE'].includes(value));
    writeFileSync(rest[0],JSON.stringify({status:value,coverage:'Existing request status only; this pack submits no deletion.'})+'\n');
  } else { throw Error('unsupported'); }
} catch {
  process.stderr.write('UNKNOWN: invalid input, response contract, pagination or private output; no complete evidence saved.\n');
  process.exit(2);
}
