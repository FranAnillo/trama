"""Exercise Trama in an isolated Chrome profile, locally or at --url."""
import argparse, base64, functools, http.server, json, os, shutil, socket, subprocess, tempfile, threading, time, urllib.request
from pathlib import Path
import websocket

class Browser:
    def __init__(self, address):
        self.ws=websocket.create_connection(address, origin='http://localhost',timeout=30); self.seq=0; self.errors=[]
    def call(self,method,params=None):
        self.seq+=1; current=self.seq
        self.ws.send(json.dumps({'id':current,'method':method,'params':params or {}}))
        while True:
            result=json.loads(self.ws.recv())
            if result.get('method') in ['Runtime.exceptionThrown','Network.loadingFailed']:self.errors.append(result)
            if result.get('id')==current:
                if 'error' in result: raise RuntimeError(result['error'])
                return result.get('result',{})
    def js(self,expression):
        r=self.call('Runtime.evaluate',{'expression':expression,'returnByValue':True,'awaitPromise':True})
        if r.get('exceptionDetails'):raise RuntimeError(r['exceptionDetails'])
        return r.get('result',{}).get('value')
    def nodes(self):return self.call('Accessibility.getFullAXTree')['nodes']
    def wait(self,label):
        for _ in range(160):
            self.js("document.querySelector('flt-semantics-placeholder')?.click()")
            if any(label in n.get('name',{}).get('value','') for n in self.nodes()):return
            time.sleep(.25)
        raise AssertionError('No apareció: '+label)
    def tap(self,label,contains=False):
        self.wait(label)
        nodes=[n for n in self.nodes() if n.get('backendDOMNodeId') and (n.get('name',{}).get('value')==label or contains and label in n.get('name',{}).get('value',''))]
        nodes.sort(key=lambda n:n.get('role',{}).get('value')!='button')
        assert nodes, label
        obj=self.call('DOM.resolveNode',{'backendNodeId':nodes[0]['backendDOMNodeId']})['object']['objectId']
        self.call('Runtime.callFunctionOn',{'objectId':obj,'functionDeclaration':"function(){this.closest('flt-semantics').click()}"})
        time.sleep(.4)
    def offline(self,value):self.call('Network.emulateNetworkConditions',{'offline':value,'latency':0,'downloadThroughput':-1,'uploadThroughput':-1})

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--url');parser.add_argument('--base-path',default='/');args=parser.parse_args()
    root=Path(__file__).resolve().parent.parent
    chrome=os.environ.get('CHROME_BIN') or shutil.which('google-chrome') or shutil.which('chromium') or '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    server=None;process=None
    with tempfile.TemporaryDirectory(prefix='trama-browser-') as temp:
        temp=Path(temp)
        try:
            url=args.url
            if not url:
                site=temp/'site';site.mkdir()
                parts=args.base_path.strip('/')
                if parts:
                    mount=site/parts;mount.parent.mkdir(parents=True,exist_ok=True);mount.symlink_to(root/'build/web',target_is_directory=True)
                else:site=root/'build/web'
                class Quiet(http.server.SimpleHTTPRequestHandler):
                    def log_message(self,*args):pass
                    def do_GET(self):
                        if self.path.endswith('/index.html'):
                            self.send_response(307);self.send_header('Location','./');self.end_headers();return
                        super().do_GET()
                server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=str(site)))
                threading.Thread(target=server.serve_forever,daemon=True).start()
                url=f'http://127.0.0.1:{server.server_port}{args.base_path}'
            with socket.socket() as s:s.bind(('127.0.0.1',0));port=s.getsockname()[1]
            process=subprocess.Popen([chrome,'--headless=new','--no-sandbox',f'--remote-debugging-port={port}','--remote-allow-origins=http://localhost',f'--user-data-dir={temp}/profile','--no-first-run','--no-default-browser-check','--lang=es-ES','about:blank'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            for _ in range(100):
                try:
                    tabs=json.load(urllib.request.urlopen(f'http://127.0.0.1:{port}/json',timeout=2));break
                except Exception:time.sleep(.2)
            else:raise RuntimeError('Chrome no arrancó')
            b=Browser(tabs[0]['webSocketDebuggerUrl'])
            b.call('Network.enable');b.call('Page.enable');b.call('Network.setCacheDisabled',{'cacheDisabled':True})
            b.call('Emulation.setDeviceMetricsOverride',{'width':1100,'height':1000,'deviceScaleFactor':1,'mobile':False})
            b.call('Page.navigate',{'url':url})
            b.wait('Elegir mis materias')
            b.tap('Cuenta y sincronización');b.wait('Tu progreso se guarda en este dispositivo');b.tap('Atrás')
            b.tap('Elegir mis materias');b.tap('Fundamentos de Programación');b.tap('Guardar');b.tap('Ver las 4 lecciones')
            b.tap('2. Sumar lo que pasa el filtro',contains=True);b.tap('Descargar y abrir');b.tap('Empezar práctica')
            b.tap('total += x');b.tap('Comprobar')
            for _ in range(80):
                if b.js('!!navigator.serviceWorker.controller'):break
                time.sleep(.25)
            assert b.js('!!navigator.serviceWorker.controller'), 'Offline worker not active'
            cached=b.js("(async()=>{let a=[];for(let k of await caches.keys())for(let r of await (await caches.open(k)).keys())if(r.url.includes('/content/'))a.push(r.url);return a})()")
            assert cached==[], 'Selective content was cached automatically'
            print('CACHE:',b.js("(async()=>{let a=[];for(let k of await caches.keys()){let c=await caches.open(k);for(let r of await c.keys())if(r.url.endsWith('index.html')){let v=await c.match(r);a.push({key:r.url,url:v.url,redirected:v.redirected,type:v.type,status:v.status})}}return a})()"),flush=True)
            b.offline(True);b.call('Page.reload');b.wait('Continuar donde lo dejaste');b.tap('Continuar donde lo dejaste');b.wait('PRÁCTICA · 2 DE 3')
            print('PASS: descarga selectiva, recarga offline y reanudación.',flush=True)
            b.tap('Atrás');b.tap('Unidades sin conexión');b.tap('Quitar unidad');b.tap('Atrás');b.tap('Continuar donde lo dejaste');b.tap('Descargar y abrir');b.wait('No se pudo')
            b.offline(False);b.tap('Continuar donde lo dejaste');b.tap('Descargar y abrir');b.wait('PRÁCTICA · 2 DE 3')
            b.tap('8');b.tap('Comprobar');b.tap('Continuar');b.tap('0');b.tap('Comprobar');b.tap('Ver resultados');b.wait('3 de 3 respuestas correctas.')
            b.tap('Volver al cuaderno');b.tap('Mi progreso');b.wait('10 XP')
            b.call('Page.reload');b.wait('Mi progreso');b.tap('Mi progreso');b.wait('10 XP')
            print('PASS: borrado sin pérdida, reconexión, sesión completa y XP persistentes.',flush=True)
            b.ws.close()
        except Exception:
            if 'b' in locals():
                diagnostics=root/'work/logs';diagnostics.mkdir(parents=True,exist_ok=True)
                try:
                    (diagnostics/'browser-failure.png').write_bytes(base64.b64decode(b.call('Page.captureScreenshot',{'format':'png'})['data']))
                    print('PAGE:',b.js('JSON.stringify({url:location.href,title:document.title,text:document.body.innerText.slice(0,1200)})'),flush=True)
                    print('NETWORK:',json.dumps(b.errors[-10:]),flush=True)
                except Exception:pass
            raise
        finally:
            if process:
                process.terminate()
                try:process.wait(timeout=10)
                except subprocess.TimeoutExpired:process.kill();process.wait()
            if server:server.shutdown();server.server_close()
if __name__=='__main__':main()
