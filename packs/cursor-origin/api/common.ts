// Shared structural helper; no requests when imported. Bun 1.x, no dependencies.
// Only fixed first-party HTTPS hosts; no endpoint override or redirect forwarding.
export type Get = (url: URL, token: string) => Promise<Record<string, any>>;
export function required(name: string, env = process.env): string {
  const value = env[name];
  if (!value || /[\r\n\x00]/.test(value)) throw new Error(`PRECONDITION: set valid ${name}`);
  return value;
}
export const get: Get = async (url, token) => {
  if (url.protocol !== 'https:' || !['api.x.ai', 'management-api.x.ai', 'api.cursor.com'].includes(url.hostname) || url.port || url.username || url.password)
    throw new Error('UNKNOWN: refused noncanonical API target');
  let response: Response;
  try { response = await fetch(url, {method:'GET', headers:{Authorization:`Bearer ${token}`}, redirect:'error', signal:AbortSignal.timeout(30000)}); }
  catch { throw new Error('UNKNOWN: transport or redirect failure; response body suppressed'); }
  if (!response.ok) throw new Error(`UNKNOWN: HTTP ${response.status}; response body suppressed`);
  const body = await response.text();
  if (Buffer.byteLength(body) > 10_000_000) throw new Error('UNKNOWN: oversized response');
  let parsed: any;
  try { parsed = JSON.parse(body); } catch { throw new Error('UNKNOWN: malformed JSON; response body suppressed'); }
  if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object') throw new Error('UNKNOWN: expected JSON object');
  return parsed;
};
export function next(value: unknown): string {
  if (value === undefined || value === null || value === '') return '';
  if (typeof value !== 'string') throw new Error('UNKNOWN: malformed pagination token');
  return value;
}
export async function pages(base: URL, token: string, list: string, responseCursor: string, requestCursor: string, read: Get = get): Promise<any[]> {
  const result: any[] = [], seen = new Set<string>();
  let cursor = '';
  for (let page=0; page<500; page++) {
    const url=new URL(base);
    if (cursor) url.searchParams.set(requestCursor,cursor);
    const data=await read(url,token);
    if (!Array.isArray(data[list])) throw new Error('UNKNOWN: missing inventory array');
    result.push(...data[list]);
    cursor=next(data[responseCursor]);
    if (!cursor) return result;
    if (seen.has(cursor)) throw new Error('UNKNOWN: repeated pagination token');
    seen.add(cursor);
  }
  throw new Error('UNKNOWN: pagination cap exceeded');
}
export function main(fn:()=>Promise<unknown>) { fn().then(value=>console.log(JSON.stringify(value))).catch(error=>{const reason=error instanceof Error && /^(UNKNOWN|PRECONDITION):/.test(error.message)?error.message:'UNKNOWN: validation failure; details suppressed';console.log(JSON.stringify({status:'UNKNOWN',reason}));process.exitCode=3;}); }
