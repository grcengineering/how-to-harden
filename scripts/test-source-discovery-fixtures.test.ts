// Fixture/link integrity only. Model decisions are evaluated independently using cases.md.
import {describe,expect,test} from 'bun:test';
import {readFileSync,existsSync,realpathSync} from 'node:fs';
import {resolve,dirname,sep} from 'node:path';
const root=resolve(import.meta.dir,'..');
const base=resolve(root,'.claude/skills/_shared/evals/trust-center-discovery/fixture');
type Capture={file:string,status:number,contentType:string};
const read=(file:string)=>readFileSync(resolve(base,file),'utf8');
const routes=JSON.parse(read('routes.json')) as Record<string,Capture>;
const partial=JSON.parse(read('partial-routes.json')) as Record<string,Capture>;
const portal=read(routes['https://trust.lumen.invalid/'].file);
const advertised=JSON.parse(portal.match(/<script[^>]*type="application\/json"[^>]*>([\s\S]*?)<\/script>/)![1]);
function walkCatalog(captures:Record<string,Capture>){
  const pages:string[]=[],items:any[]=[];let url:string|null=advertised.publicCatalog;
  while(url){
    if(pages.includes(url))throw Error('Fixture cursor cycle');
    const capture=captures[url];if(!capture)throw Error('Fixture route missing');
    if(capture.status!==200)return {pages,items,complete:false,failed:url};
    if(capture.contentType!=='application/json')throw Error('Catalog is not JSON');
    const page=JSON.parse(read(capture.file));
    if(!Array.isArray(page.resources?.categories)||!Object.hasOwn(page,'next'))throw Error('Malformed fixture catalog');
    pages.push(url);items.push(...page.resources.categories.flatMap((c:any)=>c.items));url=page.next;
  }
  return {pages,items,complete:true,failed:null};
}
describe('frozen Trust Center capture graph',()=>{
  test('all fixture sources are reserved .invalid URLs and existing local captures',()=>{
    for(const captures of [routes,partial])for(const [url,c]of Object.entries(captures)){
      expect(new URL(url).hostname.endsWith('.invalid')).toBe(true);
      const path=resolve(base,c.file);expect(path.startsWith(base+sep)).toBe(true);expect(existsSync(path)).toBe(true);
      expect(realpathSync(path).startsWith(realpathSync(base)+sep)).toBe(true);
    }
  });
  test('advertised complete catalog spans categories and a second page with resolvable document links',()=>{
    const result=walkCatalog(routes);expect(result.complete).toBe(true);expect(result.pages).toHaveLength(2);
    expect(result.items).toHaveLength(7);expect(new Set(result.items.map(r=>r.id)).size).toBe(result.items.length);
    expect(result.items.map(r=>r.id).sort()).toEqual(['101','201','301','302','401','501','601']);
    for(const row of result.items){expect(routes[row.url]).toBeDefined();expect(routes[row.downloadUrl]).toBeDefined();}
  });
  test('partial resolver preserves failed paging and cannot silently reuse the full second-page body',()=>{
    const result=walkCatalog(partial);expect(result.complete).toBe(false);expect(result.pages).toHaveLength(1);
    expect(result.failed).toBe('https://trust.lumen.invalid/json?page=2');expect(result.items.some(r=>r.id==='301')).toBe(false);
    expect(partial[result.failed!].status).toBe(503);expect(partial[result.failed!].file).not.toBe(routes[result.failed!].file);
  });
  test('the restricted and HTTP-200 sign-in adversarial captures remain intact',()=>{
    const {items}=walkCatalog(routes);const locked=items.find(r=>r.id==='401'),falsePdf=items.find(r=>r.id==='501');
    expect(locked.isPublic).toBe(false);expect(locked.hasAccess).toBe(false);expect(routes[locked.downloadUrl].status).toBe(401);
    expect(falsePdf.isPublic).toBe(true);expect(routes[falsePdf.downloadUrl].status).toBe(200);
    expect(routes[falsePdf.downloadUrl].contentType).toBe('text/html');expect(read(routes[falsePdf.downloadUrl].file)).toContain('<title>Sign in</title>');
  });
  test('asset and certification JSON are distinct from the document catalog',()=>{
    const assets=JSON.parse(read(routes[advertised.assetManifest].file));const overview=JSON.parse(read('documents/601.json'));
    expect(assets.resources).toBeUndefined();expect(assets.assets).toHaveLength(1);
    expect(overview.customerConfigurationRequirements).toEqual([]);expect(overview.assessment.displayControlCount).toBe(16);
    expect(overview.resources).toBeUndefined();
  });
});

test('shared instructions and behavioral cases have valid local Markdown references',()=>{
  const paths=['AGENTS.md','SOURCES.md',
    '.claude/skills/_shared/source-discovery.md','.claude/skills/_shared/trust-center-discovery.md',
    '.claude/skills/_shared/evals/trust-center-discovery/cases.md',
    ...['create-hth-guide','update-hth-guide','create-code-pack','verify-hth','validate-hth-guide'].map(s=>`.claude/skills/${s}/SKILL.md`)];
  for(const file of paths){
    const body=readFileSync(resolve(root,file),'utf8');
    for(const match of body.matchAll(/\]\(([^)\s]+\.md(?:#[^)\s]*)?)\)/g)){
      const target=match[1].split('#')[0];if(/^[a-z]+:/i.test(target)||target.startsWith('/'))continue;
      expect(existsSync(resolve(root,dirname(file),target)),`${file} -> ${target}`).toBe(true);
    }
  }
});
