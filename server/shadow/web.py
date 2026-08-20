"""内嵌的调试页。一个字符串，不引任何外部资源。

刻意做得很朴素：它的用途是"服务起来了没、模型装好了没、随手贴段文本配个 wav
看看分对不对"，真正的界面在手机上。CDN 一律不引——这台机器很可能没外网。
"""

INDEX = """<!doctype html>
<html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>repeat-shadow 跟读打分</title>
<style>
 body{font:14px/1.6 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif;
      margin:0;padding:24px;background:#f6f7f9;color:#222}
 .wrap{max-width:860px;margin:0 auto}
 h1{font-size:20px;margin:0 0 4px} .sub{color:#888;margin-bottom:20px}
 .card{background:#fff;border-radius:10px;padding:16px 18px;margin-bottom:14px;
       box-shadow:0 1px 3px rgba(0,0,0,.08)}
 .row{display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin:8px 0}
 label{min-width:76px;color:#666}
 input[type=text]{flex:1;min-width:220px;padding:7px 9px;border:1px solid #ddd;border-radius:6px;font:inherit}
 button{padding:7px 14px;border:0;border-radius:6px;background:#3b6ef5;color:#fff;font:inherit;cursor:pointer}
 button.g{background:#eee;color:#333}
 pre{background:#1e1e1e;color:#d8d8d8;padding:12px;border-radius:8px;overflow:auto;
     max-height:420px;font-size:12px;white-space:pre-wrap;word-break:break-all}
 .w{display:inline-block;padding:3px 7px;margin:2px;border-radius:5px;font-size:16px}
 .good{background:#d8f3dc;color:#1b4332} .fair{background:#ffeeba;color:#7a5901}
 .bad{background:#ffd6d6;color:#7a1616} .miss{text-decoration:line-through;opacity:.6}
 .pill{display:inline-block;padding:2px 8px;border-radius:99px;background:#eef;color:#335;font-size:12px;margin-right:6px}
 .err{color:#c00}
</style></head><body><div class="wrap">
<h1>repeat-shadow</h1>
<div class="sub">跟读打分调试页。正式界面在手机上。</div>

<div class="card"><div class="row"><b>服务状态</b>
 <button class="g" onclick="health()">刷新</button></div>
 <div id="h">...</div></div>

<div class="card"><b>打分</b>
 <div class="row"><label>参考文本</label>
  <input type="text" id="t" value="the sky is beautiful today"></div>
 <div class="row"><label>录音 wav</label>
  <input type="file" id="f" accept=".wav"></div>
 <div class="row"><label></label><button onclick="go()">打分</button>
  <span id="s"></span></div>
 <div id="words" style="margin-top:10px"></div>
 <pre id="out">选个 16k 单声道 PCM16 的 wav，点打分。</pre></div>

<script>
async function health(){
  const e=document.getElementById('h');
  try{
    const r=await fetch('/v1/health'); const j=await r.json();
    e.innerHTML='<span class="pill">模型 '+(j.modelInstalled?'已装':'未装')+'</span>'
      +'<span class="pill">'+(j.modelLoaded?'已加载':'未加载')+'</span>'
      +'<span class="pill">device '+(j.device||'-')+'</span>'
      +'<span class="pill">帧长 '+(j.frameMs||'-')+'ms</span>'
      +'<span class="pill">espeak '+(j.g2p&&j.g2p.ok?j.g2p.espeak:'不可用')+'</span>'
      +'<span class="pill">'+(j.g2p?j.g2p.lang:'')+'</span>'
      +(j.g2p&&j.g2p.error?'<div class="err">'+j.g2p.error+'</div>':'')
      +(j.missing&&j.missing.length?'<div class="err">缺文件：'+j.missing.join(', ')+'</div>':'');
  }catch(x){ e.innerHTML='<span class="err">连不上：'+x+'</span>'; }
}
async function go(){
  const f=document.getElementById('f').files[0];
  const out=document.getElementById('out'), sp=document.getElementById('s');
  const wd=document.getElementById('words');
  wd.innerHTML='';
  if(!f){ out.textContent='先选个 wav'; return; }
  sp.textContent='打分中...'; out.textContent='';
  const fd=new FormData();
  fd.append('audio',f); fd.append('text',document.getElementById('t').value);
  const t0=Date.now();
  try{
    const r=await fetch('/v1/score',{method:'POST',body:fd});
    const j=await r.json();
    sp.textContent=(Date.now()-t0)+'ms';
    if(j.error){ out.innerHTML='<span class="err">'+j.error+'</span>'; return; }
    wd.innerHTML='<div><b>'+j.overall+'</b> 分 &nbsp; 准确 '+j.accuracy
      +' / 完整 '+j.completeness+' / 流利 '+j.fluency
      +(j.mismatch?' &nbsp;<span class="err">读的不是这句</span>':'')+'</div><div>'
      +j.words.map(w=>'<span class="w '+w.level+(w.missed?' miss':'')+'" title="'
        +w.phones.map(p=>p.p+':'+p.score).join(' ')+'">'+w.w+' <sub>'+w.score+'</sub></span>').join('')
      +'</div>';
    out.textContent=JSON.stringify(j,null,1);
  }catch(x){ sp.textContent=''; out.innerHTML='<span class="err">'+x+'</span>'; }
}
health();
</script></div></body></html>
"""
