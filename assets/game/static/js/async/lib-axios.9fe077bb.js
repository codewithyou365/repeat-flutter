"use strict";(self.webpackChunktyping=self.webpackChunktyping||[]).push([["72"],{701:function(e,t,r){let n,o,i,s,a;r.d(t,{Z:()=>tc});var l,u={};function c(e,t){return function(){return e.apply(t,arguments)}}r.r(u),r.d(u,{hasBrowserEnv:()=>ep,hasStandardBrowserEnv:()=>em,hasStandardBrowserWebWorkerEnv:()=>ey,navigator:()=>eh,origin:()=>eb});let{toString:f}=Object.prototype,{getPrototypeOf:d}=Object;let p=(n=Object.create(null),e=>{let t=f.call(e);return n[t]||(n[t]=t.slice(8,-1).toLowerCase())}),h=e=>(e=e.toLowerCase(),t=>p(t)===e),m=e=>t=>typeof t===e,{isArray:y}=Array,b=m("undefined"),g=h("ArrayBuffer"),w=m("string"),E=m("function"),R=m("number"),O=e=>null!==e&&"object"==typeof e,S=e=>{if("object"!==p(e))return!1;let t=d(e);return(null===t||t===Object.prototype||null===Object.getPrototypeOf(t))&&!(Symbol.toStringTag in e)&&!(Symbol.iterator in e)},T=h("Date"),A=h("File"),v=h("Blob"),x=h("FileList"),C=h("URLSearchParams"),[j,N,P,_]=["ReadableStream","Request","Response","Headers"].map(h);function L(e,t,{allOwnKeys:r=!1}={}){let n,o;if(null!=e)if("object"!=typeof e&&(e=[e]),y(e))for(n=0,o=e.length;n<o;n++)t.call(null,e[n],n,e);else{let o;let i=r?Object.getOwnPropertyNames(e):Object.keys(e),s=i.length;for(n=0;n<s;n++)o=i[n],t.call(null,e[o],o,e)}}function U(e,t){let r;t=t.toLowerCase();let n=Object.keys(e),o=n.length;for(;o-- >0;)if(t===(r=n[o]).toLowerCase())return r;return null}let F="undefined"!=typeof globalThis?globalThis:"undefined"!=typeof self?self:"undefined"!=typeof window?window:global,B=e=>!b(e)&&e!==F;let k=(o="undefined"!=typeof Uint8Array&&d(Uint8Array),e=>o&&e instanceof o),D=h("HTMLFormElement"),q=(({hasOwnProperty:e})=>(t,r)=>e.call(t,r))(Object.prototype),I=h("RegExp"),M=(e,t)=>{let r=Object.getOwnPropertyDescriptors(e),n={};L(r,(r,o)=>{let i;!1!==(i=t(r,o,e))&&(n[o]=i||r)}),Object.defineProperties(e,n)},z="abcdefghijklmnopqrstuvwxyz",H="0123456789",J={DIGIT:H,ALPHA:z,ALPHA_DIGIT:z+z.toUpperCase()+H},W=h("AsyncFunction"),K=((e,t)=>{var r,n;if(e)return setImmediate;return t?(r=`axios@${Math.random()}`,n=[],F.addEventListener("message",({source:e,data:t})=>{e===F&&t===r&&n.length&&n.shift()()},!1),e=>{n.push(e),F.postMessage(r,"*")}):e=>setTimeout(e)})("function"==typeof setImmediate,E(F.postMessage)),V="undefined"!=typeof queueMicrotask?queueMicrotask.bind(F):"undefined"!=typeof process&&process.nextTick||K,$={isArray:y,isArrayBuffer:g,isBuffer:function(e){return null!==e&&!b(e)&&null!==e.constructor&&!b(e.constructor)&&E(e.constructor.isBuffer)&&e.constructor.isBuffer(e)},isFormData:e=>{let t;return e&&("function"==typeof FormData&&e instanceof FormData||E(e.append)&&("formdata"===(t=p(e))||"object"===t&&E(e.toString)&&"[object FormData]"===e.toString()))},isArrayBufferView:function(e){let t;return t="undefined"!=typeof ArrayBuffer&&ArrayBuffer.isView?ArrayBuffer.isView(e):e&&e.buffer&&g(e.buffer)},isString:w,isNumber:R,isBoolean:e=>!0===e||!1===e,isObject:O,isPlainObject:S,isReadableStream:j,isRequest:N,isResponse:P,isHeaders:_,isUndefined:b,isDate:T,isFile:A,isBlob:v,isRegExp:I,isFunction:E,isStream:e=>O(e)&&E(e.pipe),isURLSearchParams:C,isTypedArray:k,isFileList:x,forEach:L,merge:function e(){let{caseless:t}=B(this)&&this||{},r={},n=(n,o)=>{let i=t&&U(r,o)||o;S(r[i])&&S(n)?r[i]=e(r[i],n):S(n)?r[i]=e({},n):y(n)?r[i]=n.slice():r[i]=n};for(let e=0,t=arguments.length;e<t;e++)arguments[e]&&L(arguments[e],n);return r},extend:(e,t,r,{allOwnKeys:n}={})=>(L(t,(t,n)=>{r&&E(t)?e[n]=c(t,r):e[n]=t},{allOwnKeys:n}),e),trim:e=>e.trim?e.trim():e.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,""),stripBOM:e=>(65279===e.charCodeAt(0)&&(e=e.slice(1)),e),inherits:(e,t,r,n)=>{e.prototype=Object.create(t.prototype,n),e.prototype.constructor=e,Object.defineProperty(e,"super",{value:t.prototype}),r&&Object.assign(e.prototype,r)},toFlatObject:(e,t,r,n)=>{let o,i,s;let a={};if(t=t||{},null==e)return t;do{for(i=(o=Object.getOwnPropertyNames(e)).length;i-- >0;)s=o[i],(!n||n(s,e,t))&&!a[s]&&(t[s]=e[s],a[s]=!0);e=!1!==r&&d(e)}while(e&&(!r||r(e,t))&&e!==Object.prototype);return t},kindOf:p,kindOfTest:h,endsWith:(e,t,r)=>{e=String(e),(void 0===r||r>e.length)&&(r=e.length),r-=t.length;let n=e.indexOf(t,r);return -1!==n&&n===r},toArray:e=>{if(!e)return null;if(y(e))return e;let t=e.length;if(!R(t))return null;let r=Array(t);for(;t-- >0;)r[t]=e[t];return r},forEachEntry:(e,t)=>{let r;let n=(e&&e[Symbol.iterator]).call(e);for(;(r=n.next())&&!r.done;){let n=r.value;t.call(e,n[0],n[1])}},matchAll:(e,t)=>{let r;let n=[];for(;null!==(r=e.exec(t));)n.push(r);return n},isHTMLForm:D,hasOwnProperty:q,hasOwnProp:q,reduceDescriptors:M,freezeMethods:e=>{M(e,(t,r)=>{if(E(e)&&-1!==["arguments","caller","callee"].indexOf(r))return!1;if(E(e[r])){if(t.enumerable=!1,"writable"in t){t.writable=!1;return}!t.set&&(t.set=()=>{throw Error("Can not rewrite read-only method '"+r+"'")})}})},toObjectSet:(e,t)=>{let r={},n=e=>{e.forEach(e=>{r[e]=!0})};return n(y(e)?e:String(e).split(t)),r},toCamelCase:e=>e.toLowerCase().replace(/[-_\s]([a-z\d])(\w*)/g,function(e,t,r){return t.toUpperCase()+r}),noop:()=>{},toFiniteNumber:(e,t)=>null!=e&&Number.isFinite(e=+e)?e:t,findKey:U,global:F,isContextDefined:B,ALPHABET:J,generateString:(e=16,t=J.ALPHA_DIGIT)=>{let r="",{length:n}=t;for(;e--;)r+=t[Math.random()*n|0];return r},isSpecCompliantForm:function(e){return!!(e&&E(e.append)&&"FormData"===e[Symbol.toStringTag]&&e[Symbol.iterator])},toJSONObject:e=>{let t=Array(10),r=(e,n)=>{if(O(e)){if(t.indexOf(e)>=0)return;if(!("toJSON"in e)){t[n]=e;let o=y(e)?[]:{};return L(e,(e,t)=>{let i=r(e,n+1);b(i)||(o[t]=i)}),t[n]=void 0,o}}return e};return r(e,0)},isAsyncFn:W,isThenable:e=>e&&(O(e)||E(e))&&E(e.then)&&E(e.catch),setImmediate:K,asap:V};function G(e,t,r,n,o){Error.call(this),Error.captureStackTrace?Error.captureStackTrace(this,this.constructor):this.stack=Error().stack,this.message=e,this.name="AxiosError",t&&(this.code=t),r&&(this.config=r),n&&(this.request=n),o&&(this.response=o,this.status=o.status?o.status:null)}$.inherits(G,Error,{toJSON:function(){return{message:this.message,name:this.name,description:this.description,number:this.number,fileName:this.fileName,lineNumber:this.lineNumber,columnNumber:this.columnNumber,stack:this.stack,config:$.toJSONObject(this.config),code:this.code,status:this.status}}});let X=G.prototype,Q={};["ERR_BAD_OPTION_VALUE","ERR_BAD_OPTION","ECONNABORTED","ETIMEDOUT","ERR_NETWORK","ERR_FR_TOO_MANY_REDIRECTS","ERR_DEPRECATED","ERR_BAD_RESPONSE","ERR_BAD_REQUEST","ERR_CANCELED","ERR_NOT_SUPPORT","ERR_INVALID_URL"].forEach(e=>{Q[e]={value:e}}),Object.defineProperties(G,Q),Object.defineProperty(X,"isAxiosError",{value:!0}),G.from=(e,t,r,n,o,i)=>{let s=Object.create(X);return $.toFlatObject(e,s,function(e){return e!==Error.prototype},e=>"isAxiosError"!==e),G.call(s,e.message,t,r,n,o),s.cause=e,s.name=e.name,i&&Object.assign(s,i),s};function Z(e){return $.isPlainObject(e)||$.isArray(e)}function Y(e){return $.endsWith(e,"[]")?e.slice(0,-2):e}function ee(e,t,r){return e?e.concat(t).map(function(e,t){return e=Y(e),!r&&t?"["+e+"]":e}).join(r?".":""):t}let et=$.toFlatObject($,{},null,function(e){return/^is[A-Z]/.test(e)}),er=function(e,t,r){if(!$.isObject(e))throw TypeError("target must be an object");t=t||new FormData;let n=(r=$.toFlatObject(r,{metaTokens:!0,dots:!1,indexes:!1},!1,function(e,t){return!$.isUndefined(t[e])})).metaTokens,o=r.visitor||u,i=r.dots,s=r.indexes,a=(r.Blob||"undefined"!=typeof Blob&&Blob)&&$.isSpecCompliantForm(t);if(!$.isFunction(o))throw TypeError("visitor must be a function");function l(e){if(null===e)return"";if($.isDate(e))return e.toISOString();if(!a&&$.isBlob(e))throw new G("Blob is not supported. Use a Buffer instead.");return $.isArrayBuffer(e)||$.isTypedArray(e)?a&&"function"==typeof Blob?new Blob([e]):Buffer.from(e):e}function u(e,r,o){let a=e;if(e&&!o&&"object"==typeof e){if($.endsWith(r,"{}"))r=n?r:r.slice(0,-2),e=JSON.stringify(e);else{var u;if($.isArray(e)&&(u=e,$.isArray(u)&&!u.some(Z))||($.isFileList(e)||$.endsWith(r,"[]"))&&(a=$.toArray(e)))return r=Y(r),a.forEach(function(e,n){$.isUndefined(e)||null===e||t.append(!0===s?ee([r],n,i):null===s?r:r+"[]",l(e))}),!1}}return!!Z(e)||(t.append(ee(o,r,i),l(e)),!1)}let c=[],f=Object.assign(et,{defaultVisitor:u,convertValue:l,isVisitable:Z});if(!$.isObject(e))throw TypeError("data must be an object");return!function e(r,n){if(!$.isUndefined(r)){if(-1!==c.indexOf(r))throw Error("Circular reference detected in "+n.join("."));c.push(r),$.forEach(r,function(r,i){!0===(!($.isUndefined(r)||null===r)&&o.call(t,r,$.isString(i)?i.trim():i,n,f))&&e(r,n?n.concat(i):[i])}),c.pop()}}(e),t};function en(e){let t={"!":"%21","'":"%27","(":"%28",")":"%29","~":"%7E","%20":"+","%00":"\0"};return encodeURIComponent(e).replace(/[!'()~]|%20|%00/g,function(e){return t[e]})}function eo(e,t){this._pairs=[],e&&er(e,this,t)}let ei=eo.prototype;ei.append=function(e,t){this._pairs.push([e,t])},ei.toString=function(e){let t=e?function(t){return e.call(this,t,en)}:en;return this._pairs.map(function(e){return t(e[0])+"="+t(e[1])},"").join("&")};function es(e){return encodeURIComponent(e).replace(/%3A/gi,":").replace(/%24/g,"$").replace(/%2C/gi,",").replace(/%20/g,"+").replace(/%5B/gi,"[").replace(/%5D/gi,"]")}function ea(e,t,r){let n;if(!t)return e;let o=r&&r.encode||es;$.isFunction(r)&&(r={serialize:r});let i=r&&r.serialize;if(n=i?i(t,r):$.isURLSearchParams(t)?t.toString():new eo(t,r).toString(o)){let t=e.indexOf("#");-1!==t&&(e=e.slice(0,t)),e+=(-1===e.indexOf("?")?"?":"&")+n}return e}let el=class e{constructor(){this.handlers=[]}use(e,t,r){return this.handlers.push({fulfilled:e,rejected:t,synchronous:!!r&&r.synchronous,runWhen:r?r.runWhen:null}),this.handlers.length-1}eject(e){this.handlers[e]&&(this.handlers[e]=null)}clear(){this.handlers&&(this.handlers=[])}forEach(e){$.forEach(this.handlers,function(t){null!==t&&e(t)})}},eu={silentJSONParsing:!0,forcedJSONParsing:!0,clarifyTimeoutError:!1},ec="undefined"!=typeof URLSearchParams?URLSearchParams:eo,ef="undefined"!=typeof FormData?FormData:null,ed="undefined"!=typeof Blob?Blob:null,ep="undefined"!=typeof window&&"undefined"!=typeof document,eh="object"==typeof navigator&&navigator||void 0,em=ep&&(!eh||0>["ReactNative","NativeScript","NS"].indexOf(eh.product)),ey="undefined"!=typeof WorkerGlobalScope&&self instanceof WorkerGlobalScope&&"function"==typeof self.importScripts,eb=ep&&window.location.href||"http://localhost",eg={...u,isBrowser:!0,classes:{URLSearchParams:ec,FormData:ef,Blob:ed},protocols:["http","https","file","blob","url","data"]},ew=function(e){if($.isFormData(e)&&$.isFunction(e.entries)){let t={};return $.forEachEntry(e,(e,r)=>{var n;!function e(t,r,n,o){let i=t[o++];if("__proto__"===i)return!0;let s=Number.isFinite(+i),a=o>=t.length;return(i=!i&&$.isArray(n)?n.length:i,a)?($.hasOwnProp(n,i)?n[i]=[n[i],r]:n[i]=r,!s):((!n[i]||!$.isObject(n[i]))&&(n[i]=[]),e(t,r,n[i],o)&&$.isArray(n[i])&&(n[i]=function(e){let t,r;let n={},o=Object.keys(e),i=o.length;for(t=0;t<i;t++)n[r=o[t]]=e[r];return n}(n[i])),!s)}((n=e,$.matchAll(/\w+|\[(\w*)]/g,n).map(e=>"[]"===e[0]?"":e[1]||e[0])),r,t,0)}),t}return null},eE={transitional:eu,adapter:["xhr","http","fetch"],transformRequest:[function(e,t){let r;let n=t.getContentType()||"",o=n.indexOf("application/json")>-1,i=$.isObject(e);if(i&&$.isHTMLForm(e)&&(e=new FormData(e)),$.isFormData(e))return o?JSON.stringify(ew(e)):e;if($.isArrayBuffer(e)||$.isBuffer(e)||$.isStream(e)||$.isFile(e)||$.isBlob(e)||$.isReadableStream(e))return e;if($.isArrayBufferView(e))return e.buffer;if($.isURLSearchParams(e))return t.setContentType("application/x-www-form-urlencoded;charset=utf-8",!1),e.toString();if(i){if(n.indexOf("application/x-www-form-urlencoded")>-1){var s,a;return(s=e,a=this.formSerializer,er(s,new eg.classes.URLSearchParams,Object.assign({visitor:function(e,t,r,n){return eg.isNode&&$.isBuffer(e)?(this.append(t,e.toString("base64")),!1):n.defaultVisitor.apply(this,arguments)}},a))).toString()}if((r=$.isFileList(e))||n.indexOf("multipart/form-data")>-1){let t=this.env&&this.env.FormData;return er(r?{"files[]":e}:e,t&&new t,this.formSerializer)}}return i||o?(t.setContentType("application/json",!1),function(e,t,r){if($.isString(e))try{return(0,JSON.parse)(e),$.trim(e)}catch(e){if("SyntaxError"!==e.name)throw e}return(0,JSON.stringify)(e)}(e)):e}],transformResponse:[function(e){let t=this.transitional||eE.transitional,r=t&&t.forcedJSONParsing,n="json"===this.responseType;if($.isResponse(e)||$.isReadableStream(e))return e;if(e&&$.isString(e)&&(r&&!this.responseType||n)){let r=t&&t.silentJSONParsing;try{return JSON.parse(e)}catch(e){if(!r&&n){if("SyntaxError"===e.name)throw G.from(e,G.ERR_BAD_RESPONSE,this,null,this.response);throw e}}}return e}],timeout:0,xsrfCookieName:"XSRF-TOKEN",xsrfHeaderName:"X-XSRF-TOKEN",maxContentLength:-1,maxBodyLength:-1,env:{FormData:eg.classes.FormData,Blob:eg.classes.Blob},validateStatus:function(e){return e>=200&&e<300},headers:{common:{Accept:"application/json, text/plain, */*","Content-Type":void 0}}};$.forEach(["delete","get","head","post","put","patch"],e=>{eE.headers[e]={}});let eR=$.toObjectSet(["age","authorization","content-length","content-type","etag","expires","from","host","if-modified-since","if-unmodified-since","last-modified","location","max-forwards","proxy-authorization","referer","retry-after","user-agent"]),eO=e=>{let t,r,n;let o={};return e&&e.split("\n").forEach(function(e){if(n=e.indexOf(":"),t=e.substring(0,n).trim().toLowerCase(),r=e.substring(n+1).trim(),!!t&&(!o[t]||!eR[t]))"set-cookie"===t?o[t]?o[t].push(r):o[t]=[r]:o[t]=o[t]?o[t]+", "+r:r}),o},eS=Symbol("internals");function eT(e){return e&&String(e).trim().toLowerCase()}function eA(e){return!1===e||null==e?e:$.isArray(e)?e.map(eA):String(e)}let ev=e=>/^[-_a-zA-Z0-9^`|~,!#$%&'*+.]+$/.test(e.trim());function ex(e,t,r,n,o){if($.isFunction(n))return n.call(this,t,r);if(o&&(t=r),$.isString(t)){if($.isString(n))return -1!==t.indexOf(n);if($.isRegExp(n))return n.test(t)}}class eC{constructor(e){e&&this.set(e)}set(e,t,r){let n=this;function o(e,t,r){let o=eT(t);if(!o)throw Error("header name must be a non-empty string");let i=$.findKey(n,o);(!i||void 0===n[i]||!0===r||void 0===r&&!1!==n[i])&&(n[i||t]=eA(e))}let i=(e,t)=>$.forEach(e,(e,r)=>o(e,r,t));if($.isPlainObject(e)||e instanceof this.constructor)i(e,t);else if($.isString(e)&&(e=e.trim())&&!ev(e))i(eO(e),t);else if($.isHeaders(e))for(let[t,n]of e.entries())o(n,t,r);else null!=e&&o(t,e,r);return this}get(e,t){if(e=eT(e)){let r=$.findKey(this,e);if(r){let e=this[r];if(!t)return e;if(!0===t)return function(e){let t;let r=Object.create(null),n=/([^\s,;=]+)\s*(?:=\s*([^,;]+))?/g;for(;t=n.exec(e);)r[t[1]]=t[2];return r}(e);if($.isFunction(t))return t.call(this,e,r);if($.isRegExp(t))return t.exec(e);throw TypeError("parser must be boolean|regexp|function")}}}has(e,t){if(e=eT(e)){let r=$.findKey(this,e);return!!(r&&void 0!==this[r]&&(!t||ex(this,this[r],r,t)))}return!1}delete(e,t){let r=this,n=!1;function o(e){if(e=eT(e)){let o=$.findKey(r,e);o&&(!t||ex(r,r[o],o,t))&&(delete r[o],n=!0)}}return $.isArray(e)?e.forEach(o):o(e),n}clear(e){let t=Object.keys(this),r=t.length,n=!1;for(;r--;){let o=t[r];(!e||ex(this,this[o],o,e,!0))&&(delete this[o],n=!0)}return n}normalize(e){let t=this,r={};return $.forEach(this,(n,o)=>{let i=$.findKey(r,o);if(i){t[i]=eA(n),delete t[o];return}let s=e?o.trim().toLowerCase().replace(/([a-z\d])(\w*)/g,(e,t,r)=>t.toUpperCase()+r):String(o).trim();s!==o&&delete t[o],t[s]=eA(n),r[s]=!0}),this}concat(...e){return this.constructor.concat(this,...e)}toJSON(e){let t=Object.create(null);return $.forEach(this,(r,n)=>{null!=r&&!1!==r&&(t[n]=e&&$.isArray(r)?r.join(", "):r)}),t}[Symbol.iterator](){return Object.entries(this.toJSON())[Symbol.iterator]()}toString(){return Object.entries(this.toJSON()).map(([e,t])=>e+": "+t).join("\n")}get[Symbol.toStringTag](){return"AxiosHeaders"}static from(e){return e instanceof this?e:new this(e)}static concat(e,...t){let r=new this(e);return t.forEach(e=>r.set(e)),r}static accessor(e){let t=(this[eS]=this[eS]={accessors:{}}).accessors,r=this.prototype;function n(e){let n=eT(e);!t[n]&&(!function(e,t){let r=$.toCamelCase(" "+t);["get","set","has"].forEach(n=>{Object.defineProperty(e,n+r,{value:function(e,r,o){return this[n].call(this,t,e,r,o)},configurable:!0})})}(r,e),t[n]=!0)}return $.isArray(e)?e.forEach(n):n(e),this}}eC.accessor(["Content-Type","Content-Length","Accept","Accept-Encoding","User-Agent","Authorization"]),$.reduceDescriptors(eC.prototype,({value:e},t)=>{let r=t[0].toUpperCase()+t.slice(1);return{get:()=>e,set(e){this[r]=e}}}),$.freezeMethods(eC);function ej(e,t){let r=this||eE,n=t||r,o=eC.from(n.headers),i=n.data;return $.forEach(e,function(e){i=e.call(r,i,o.normalize(),t?t.status:void 0)}),o.normalize(),i}function eN(e){return!!(e&&e.__CANCEL__)}function eP(e,t,r){G.call(this,null==e?"canceled":e,G.ERR_CANCELED,t,r),this.name="CanceledError"}$.inherits(eP,G,{__CANCEL__:!0});function e_(e,t,r){let n=r.config.validateStatus;!r.status||!n||n(r.status)?e(r):t(new G("Request failed with status code "+r.status,[G.ERR_BAD_REQUEST,G.ERR_BAD_RESPONSE][Math.floor(r.status/100)-4],r.config,r.request,r))}let eL=function(e,t){let r;let n=Array(e=e||10),o=Array(e),i=0,s=0;return t=void 0!==t?t:1e3,function(a){let l=Date.now(),u=o[s];!r&&(r=l),n[i]=a,o[i]=l;let c=s,f=0;for(;c!==i;)f+=n[c++],c%=e;if((i=(i+1)%e)===s&&(s=(s+1)%e),l-r<t)return;let d=u&&l-u;return d?Math.round(1e3*f/d):void 0}},eU=function(e,t){let r,n,o=0,i=1e3/t,s=(t,i=Date.now())=>{o=i,r=null,n&&(clearTimeout(n),n=null),e.apply(null,t)};return[(...e)=>{let t=Date.now(),a=t-o;a>=i?s(e,t):(r=e,!n&&(n=setTimeout(()=>{n=null,s(r)},i-a)))},()=>r&&s(r)]},eF=(e,t,r=3)=>{let n=0,o=eL(50,250);return eU(r=>{let i=r.loaded,s=r.lengthComputable?r.total:void 0,a=i-n,l=o(a);n=i;e({loaded:i,total:s,progress:s?i/s:void 0,bytes:a,rate:l||void 0,estimated:l&&s&&i<=s?(s-i)/l:void 0,event:r,lengthComputable:null!=s,[t?"download":"upload"]:!0})},r)},eB=(e,t)=>{let r=null!=e;return[n=>t[0]({lengthComputable:r,total:e,loaded:n}),t[1]]},ek=e=>(...t)=>$.asap(()=>e(...t));let eD=eg.hasStandardBrowserEnv?(i=new URL(eg.origin),s=eg.navigator&&/(msie|trident)/i.test(eg.navigator.userAgent),e=>(e=new URL(e,eg.origin),i.protocol===e.protocol&&i.host===e.host&&(s||i.port===e.port))):()=>!0,eq=eg.hasStandardBrowserEnv?{write(e,t,r,n,o,i){let s=[e+"="+encodeURIComponent(t)];$.isNumber(r)&&s.push("expires="+new Date(r).toGMTString()),$.isString(n)&&s.push("path="+n),$.isString(o)&&s.push("domain="+o),!0===i&&s.push("secure"),document.cookie=s.join("; ")},read(e){let t=document.cookie.match(RegExp("(^|;\\s*)("+e+")=([^;]*)"));return t?decodeURIComponent(t[3]):null},remove(e){this.write(e,"",Date.now()-864e5)}}:{write(){},read:()=>null,remove(){}};function eI(e,t){var r,n,o;if(e&&(r=t,!/^([a-z][a-z\d+\-.]*:)?\/\//i.test(r))){;return n=e,(o=t)?n.replace(/\/?\/$/,"")+"/"+o.replace(/^\/+/,""):n}return t}let eM=e=>e instanceof eC?{...e}:e;function ez(e,t){t=t||{};let r={};function n(e,t,r,n){if($.isPlainObject(e)&&$.isPlainObject(t))return $.merge.call({caseless:n},e,t);if($.isPlainObject(t))return $.merge({},t);if($.isArray(t))return t.slice();return t}function o(e,t,r,o){return $.isUndefined(t)?$.isUndefined(e)?void 0:n(void 0,e,r,o):n(e,t,r,o)}function i(e,t){if(!$.isUndefined(t))return n(void 0,t)}function s(e,t){return $.isUndefined(t)?$.isUndefined(e)?void 0:n(void 0,e):n(void 0,t)}function a(r,o,i){return i in t?n(r,o):i in e?n(void 0,r):void 0}let l={url:i,method:i,data:i,baseURL:s,transformRequest:s,transformResponse:s,paramsSerializer:s,timeout:s,timeoutMessage:s,withCredentials:s,withXSRFToken:s,adapter:s,responseType:s,xsrfCookieName:s,xsrfHeaderName:s,onUploadProgress:s,onDownloadProgress:s,decompress:s,maxContentLength:s,maxBodyLength:s,beforeRedirect:s,transport:s,httpAgent:s,httpsAgent:s,cancelToken:s,socketPath:s,responseEncoding:s,validateStatus:a,headers:(e,t,r)=>o(eM(e),eM(t),r,!0)};return $.forEach(Object.keys(Object.assign({},e,t)),function(n){let i=l[n]||o,s=i(e[n],t[n],n);$.isUndefined(s)&&i!==a||(r[n]=s)}),r}let eH=e=>{let t;let r=ez({},e),{data:n,withXSRFToken:o,xsrfHeaderName:i,xsrfCookieName:s,headers:a,auth:l}=r;if(r.headers=a=eC.from(a),r.url=ea(eI(r.baseURL,r.url),e.params,e.paramsSerializer),l&&a.set("Authorization","Basic "+btoa((l.username||"")+":"+(l.password?unescape(encodeURIComponent(l.password)):""))),$.isFormData(n)){if(eg.hasStandardBrowserEnv||eg.hasStandardBrowserWebWorkerEnv)a.setContentType(void 0);else if(!1!==(t=a.getContentType())){let[e,...r]=t?t.split(";").map(e=>e.trim()).filter(Boolean):[];a.setContentType([e||"multipart/form-data",...r].join("; "))}}if(eg.hasStandardBrowserEnv&&(o&&$.isFunction(o)&&(o=o(r)),o||!1!==o&&eD(r.url))){let e=i&&s&&eq.read(s);e&&a.set(i,e)}return r},eJ="undefined"!=typeof XMLHttpRequest&&function(e){return new Promise(function(t,r){let n,o,i,s,a;let l=eH(e),u=l.data,c=eC.from(l.headers).normalize(),{responseType:f,onUploadProgress:d,onDownloadProgress:p}=l;function h(){s&&s(),a&&a(),l.cancelToken&&l.cancelToken.unsubscribe(n),l.signal&&l.signal.removeEventListener("abort",n)}let m=new XMLHttpRequest;function y(){if(!m)return;let n=eC.from("getAllResponseHeaders"in m&&m.getAllResponseHeaders());e_(function(e){t(e),h()},function(e){r(e),h()},{data:f&&"text"!==f&&"json"!==f?m.response:m.responseText,status:m.status,statusText:m.statusText,headers:n,config:e,request:m}),m=null}m.open(l.method.toUpperCase(),l.url,!0),m.timeout=l.timeout,"onloadend"in m?m.onloadend=y:m.onreadystatechange=function(){if(!!m&&4===m.readyState&&(0!==m.status||!!(m.responseURL&&0===m.responseURL.indexOf("file:"))))setTimeout(y)},m.onabort=function(){if(!!m)r(new G("Request aborted",G.ECONNABORTED,e,m)),m=null},m.onerror=function(){r(new G("Network Error",G.ERR_NETWORK,e,m)),m=null},m.ontimeout=function(){let t=l.timeout?"timeout of "+l.timeout+"ms exceeded":"timeout exceeded",n=l.transitional||eu;l.timeoutErrorMessage&&(t=l.timeoutErrorMessage),r(new G(t,n.clarifyTimeoutError?G.ETIMEDOUT:G.ECONNABORTED,e,m)),m=null},void 0===u&&c.setContentType(null),"setRequestHeader"in m&&$.forEach(c.toJSON(),function(e,t){m.setRequestHeader(t,e)}),!$.isUndefined(l.withCredentials)&&(m.withCredentials=!!l.withCredentials),f&&"json"!==f&&(m.responseType=l.responseType),p&&([i,a]=eF(p,!0),m.addEventListener("progress",i)),d&&m.upload&&([o,s]=eF(d),m.upload.addEventListener("progress",o),m.upload.addEventListener("loadend",s)),(l.cancelToken||l.signal)&&(n=t=>{if(!!m)r(!t||t.type?new eP(null,e,m):t),m.abort(),m=null},l.cancelToken&&l.cancelToken.subscribe(n),l.signal&&(l.signal.aborted?n():l.signal.addEventListener("abort",n)));let b=function(e){let t=/^([-+\w]{1,25})(:?\/\/|:)/.exec(e);return t&&t[1]||""}(l.url);if(b&&-1===eg.protocols.indexOf(b)){r(new G("Unsupported protocol "+b+":",G.ERR_BAD_REQUEST,e));return}m.send(u||null)})},eW=(e,t)=>{let{length:r}=e=e?e.filter(Boolean):[];if(t||r){let r,n=new AbortController,o=function(e){if(!r){r=!0,s();let t=e instanceof Error?e:this.reason;n.abort(t instanceof G?t:new eP(t instanceof Error?t.message:t))}},i=t&&setTimeout(()=>{i=null,o(new G(`timeout ${t} of ms exceeded`,G.ETIMEDOUT))},t),s=()=>{e&&(i&&clearTimeout(i),i=null,e.forEach(e=>{e.unsubscribe?e.unsubscribe(o):e.removeEventListener("abort",o)}),e=null)};e.forEach(e=>e.addEventListener("abort",o));let{signal:a}=n;return a.unsubscribe=()=>$.asap(s),a}},eK=function*(e,t){let r,n=e.byteLength;if(!t||n<t){yield e;return}let o=0;for(;o<n;)r=o+t,yield e.slice(o,r),o=r},eV=async function*(e,t){for await(let r of e$(e))yield*eK(r,t)},e$=async function*(e){if(e[Symbol.asyncIterator]){yield*e;return}let t=e.getReader();try{for(;;){let{done:e,value:r}=await t.read();if(e)break;yield r}}finally{await t.cancel()}},eG=(e,t,r,n)=>{let o;let i=eV(e,t),s=0,a=e=>{!o&&(o=!0,n&&n(e))};return new ReadableStream({async pull(e){try{let{done:t,value:n}=await i.next();if(t){a(),e.close();return}let o=n.byteLength;if(r){let e=s+=o;r(e)}e.enqueue(new Uint8Array(n))}catch(e){throw a(e),e}},cancel:e=>(a(e),i.return())},{highWaterMark:2})},eX="function"==typeof fetch&&"function"==typeof Request&&"function"==typeof Response,eQ=eX&&"function"==typeof ReadableStream;let eZ=eX&&("function"==typeof TextEncoder?(a=new TextEncoder,e=>a.encode(e)):async e=>new Uint8Array(await new Response(e).arrayBuffer())),eY=(e,...t)=>{try{return!!e(...t)}catch(e){return!1}},e0=eQ&&eY(()=>{let e=!1,t=new Request(eg.origin,{body:new ReadableStream,method:"POST",get duplex(){return e=!0,"half"}}).headers.has("Content-Type");return e&&!t}),e1=eQ&&eY(()=>$.isReadableStream(new Response("").body)),e2={stream:e1&&(e=>e.body)};eX&&(l=new Response,["text","arrayBuffer","blob","formData","stream"].forEach(e=>{e2[e]||(e2[e]=$.isFunction(l[e])?t=>t[e]():(t,r)=>{throw new G(`Response type '${e}' is not supported`,G.ERR_NOT_SUPPORT,r)})}));let e4=async e=>{if(null==e)return 0;if($.isBlob(e))return e.size;if($.isSpecCompliantForm(e)){let t=new Request(eg.origin,{method:"POST",body:e});return(await t.arrayBuffer()).byteLength}return $.isArrayBufferView(e)||$.isArrayBuffer(e)?e.byteLength:($.isURLSearchParams(e)&&(e+=""),$.isString(e))?(await eZ(e)).byteLength:void 0},e5=async(e,t)=>{let r=$.toFiniteNumber(e.getContentLength());return null==r?e4(t):r},e3={http:null,xhr:eJ,fetch:eX&&(async e=>{let t,r,{url:n,method:o,data:i,signal:s,cancelToken:a,timeout:l,onDownloadProgress:u,onUploadProgress:c,responseType:f,headers:d,withCredentials:p="same-origin",fetchOptions:h}=eH(e);f=f?(f+"").toLowerCase():"text";let m=eW([s,a&&a.toAbortSignal()],l),y=m&&m.unsubscribe&&(()=>{m.unsubscribe()});try{if(c&&e0&&"get"!==o&&"head"!==o&&0!==(r=await e5(d,i))){let e,t=new Request(n,{method:"POST",body:i,duplex:"half"});if($.isFormData(i)&&(e=t.headers.get("content-type"))&&d.setContentType(e),t.body){let[e,n]=eB(r,eF(ek(c)));i=eG(t.body,65536,e,n)}}!$.isString(p)&&(p=p?"include":"omit");let s="credentials"in Request.prototype;t=new Request(n,{...h,signal:m,method:o.toUpperCase(),headers:d.normalize().toJSON(),body:i,duplex:"half",credentials:s?p:void 0});let a=await fetch(t),l=e1&&("stream"===f||"response"===f);if(e1&&(u||l&&y)){let e={};["status","statusText","headers"].forEach(t=>{e[t]=a[t]});let t=$.toFiniteNumber(a.headers.get("content-length")),[r,n]=u&&eB(t,eF(ek(u),!0))||[];a=new Response(eG(a.body,65536,r,()=>{n&&n(),y&&y()}),e)}f=f||"text";let b=await e2[$.findKey(e2,f)||"text"](a,e);return!l&&y&&y(),await new Promise((r,n)=>{e_(r,n,{data:b,headers:eC.from(a.headers),status:a.status,statusText:a.statusText,config:e,request:t})})}catch(r){if(y&&y(),r&&"TypeError"===r.name&&/fetch/i.test(r.message))throw Object.assign(new G("Network Error",G.ERR_NETWORK,e,t),{cause:r.cause||r});throw G.from(r,r&&r.code,e,t)}})};$.forEach(e3,(e,t)=>{if(e){try{Object.defineProperty(e,"name",{value:t})}catch(e){}Object.defineProperty(e,"adapterName",{value:t})}});let e6=e=>`- ${e}`,e8=e=>$.isFunction(e)||null===e||!1===e,e7=e=>{let t,r;let{length:n}=e=$.isArray(e)?e:[e],o={};for(let i=0;i<n;i++){let n;if(r=t=e[i],!e8(t)&&void 0===(r=e3[(n=String(t)).toLowerCase()]))throw new G(`Unknown adapter '${n}'`);if(r)break;o[n||"#"+i]=r}if(!r){let e=Object.entries(o).map(([e,t])=>`adapter ${e} `+(!1===t?"is not supported by the environment":"is not available in the build"));throw new G("There is no suitable adapter to dispatch the request "+(n?e.length>1?"since :\n"+e.map(e6).join("\n"):" "+e6(e[0]):"as no adapter specified"),"ERR_NOT_SUPPORT")}return r};function e9(e){if(e.cancelToken&&e.cancelToken.throwIfRequested(),e.signal&&e.signal.aborted)throw new eP(null,e)}function te(e){return e9(e),e.headers=eC.from(e.headers),e.data=ej.call(e,e.transformRequest),-1!==["post","put","patch"].indexOf(e.method)&&e.headers.setContentType("application/x-www-form-urlencoded",!1),e7(e.adapter||eE.adapter)(e).then(function(t){return e9(e),t.data=ej.call(e,e.transformResponse,t),t.headers=eC.from(t.headers),t},function(t){return!eN(t)&&(e9(e),t&&t.response&&(t.response.data=ej.call(e,e.transformResponse,t.response),t.response.headers=eC.from(t.response.headers))),Promise.reject(t)})}let tt="1.7.9",tr={};["object","boolean","number","function","string","symbol"].forEach((e,t)=>{tr[e]=function(r){return typeof r===e||"a"+(t<1?"n ":" ")+e}});let tn={};tr.transitional=function(e,t,r){function n(e,t){return"[Axios v"+tt+"] Transitional option '"+e+"'"+t+(r?". "+r:"")}return(r,o,i)=>{if(!1===e)throw new G(n(o," has been removed"+(t?" in "+t:"")),G.ERR_DEPRECATED);return t&&!tn[o]&&(tn[o]=!0,console.warn(n(o," has been deprecated since v"+t+" and will be removed in the near future"))),!e||e(r,o,i)}},tr.spelling=function(e){return(t,r)=>(console.warn(`${r} is likely a misspelling of ${e}`),!0)};let to={assertOptions:function(e,t,r){if("object"!=typeof e)throw new G("options must be an object",G.ERR_BAD_OPTION_VALUE);let n=Object.keys(e),o=n.length;for(;o-- >0;){let i=n[o],s=t[i];if(s){let t=e[i],r=void 0===t||s(t,i,e);if(!0!==r)throw new G("option "+i+" must be "+r,G.ERR_BAD_OPTION_VALUE);continue}if(!0!==r)throw new G("Unknown option "+i,G.ERR_BAD_OPTION)}},validators:tr},ti=to.validators;class ts{constructor(e){this.defaults=e,this.interceptors={request:new el,response:new el}}async request(e,t){try{return await this._request(e,t)}catch(e){if(e instanceof Error){let t={};Error.captureStackTrace?Error.captureStackTrace(t):t=Error();let r=t.stack?t.stack.replace(/^.+\n/,""):"";try{e.stack?r&&!String(e.stack).endsWith(r.replace(/^.+\n.+\n/,""))&&(e.stack+="\n"+r):e.stack=r}catch(e){}}throw e}}_request(e,t){let r,n;"string"==typeof e?(t=t||{}).url=e:t=e||{};let{transitional:o,paramsSerializer:i,headers:s}=t=ez(this.defaults,t);void 0!==o&&to.assertOptions(o,{silentJSONParsing:ti.transitional(ti.boolean),forcedJSONParsing:ti.transitional(ti.boolean),clarifyTimeoutError:ti.transitional(ti.boolean)},!1),null!=i&&($.isFunction(i)?t.paramsSerializer={serialize:i}:to.assertOptions(i,{encode:ti.function,serialize:ti.function},!0)),to.assertOptions(t,{baseUrl:ti.spelling("baseURL"),withXsrfToken:ti.spelling("withXSRFToken")},!0),t.method=(t.method||this.defaults.method||"get").toLowerCase();let a=s&&$.merge(s.common,s[t.method]);s&&$.forEach(["delete","get","head","post","put","patch","common"],e=>{delete s[e]}),t.headers=eC.concat(a,s);let l=[],u=!0;this.interceptors.request.forEach(function(e){if("function"!=typeof e.runWhen||!1!==e.runWhen(t))u=u&&e.synchronous,l.unshift(e.fulfilled,e.rejected)});let c=[];this.interceptors.response.forEach(function(e){c.push(e.fulfilled,e.rejected)});let f=0;if(!u){let e=[te.bind(this),void 0];for(e.unshift.apply(e,l),e.push.apply(e,c),n=e.length,r=Promise.resolve(t);f<n;)r=r.then(e[f++],e[f++]);return r}n=l.length;let d=t;for(f=0;f<n;){let e=l[f++],t=l[f++];try{d=e(d)}catch(e){t.call(this,e);break}}try{r=te.call(this,d)}catch(e){return Promise.reject(e)}for(f=0,n=c.length;f<n;)r=r.then(c[f++],c[f++]);return r}getUri(e){return ea(eI((e=ez(this.defaults,e)).baseURL,e.url),e.params,e.paramsSerializer)}}$.forEach(["delete","get","head","options"],function(e){ts.prototype[e]=function(t,r){return this.request(ez(r||{},{method:e,url:t,data:(r||{}).data}))}}),$.forEach(["post","put","patch"],function(e){function t(t){return function(r,n,o){return this.request(ez(o||{},{method:e,headers:t?{"Content-Type":"multipart/form-data"}:{},url:r,data:n}))}}ts.prototype[e]=t(),ts.prototype[e+"Form"]=t(!0)});class ta{constructor(e){let t;if("function"!=typeof e)throw TypeError("executor must be a function.");this.promise=new Promise(function(e){t=e});let r=this;this.promise.then(e=>{if(!r._listeners)return;let t=r._listeners.length;for(;t-- >0;)r._listeners[t](e);r._listeners=null}),this.promise.then=e=>{let t;let n=new Promise(e=>{r.subscribe(e),t=e}).then(e);return n.cancel=function(){r.unsubscribe(t)},n},e(function(e,n,o){if(!r.reason)r.reason=new eP(e,n,o),t(r.reason)})}throwIfRequested(){if(this.reason)throw this.reason}subscribe(e){if(this.reason){e(this.reason);return}this._listeners?this._listeners.push(e):this._listeners=[e]}unsubscribe(e){if(!this._listeners)return;let t=this._listeners.indexOf(e);-1!==t&&this._listeners.splice(t,1)}toAbortSignal(){let e=new AbortController,t=t=>{e.abort(t)};return this.subscribe(t),e.signal.unsubscribe=()=>this.unsubscribe(t),e.signal}static source(){let e;return{token:new ta(function(t){e=t}),cancel:e}}}let tl={Continue:100,SwitchingProtocols:101,Processing:102,EarlyHints:103,Ok:200,Created:201,Accepted:202,NonAuthoritativeInformation:203,NoContent:204,ResetContent:205,PartialContent:206,MultiStatus:207,AlreadyReported:208,ImUsed:226,MultipleChoices:300,MovedPermanently:301,Found:302,SeeOther:303,NotModified:304,UseProxy:305,Unused:306,TemporaryRedirect:307,PermanentRedirect:308,BadRequest:400,Unauthorized:401,PaymentRequired:402,Forbidden:403,NotFound:404,MethodNotAllowed:405,NotAcceptable:406,ProxyAuthenticationRequired:407,RequestTimeout:408,Conflict:409,Gone:410,LengthRequired:411,PreconditionFailed:412,PayloadTooLarge:413,UriTooLong:414,UnsupportedMediaType:415,RangeNotSatisfiable:416,ExpectationFailed:417,ImATeapot:418,MisdirectedRequest:421,UnprocessableEntity:422,Locked:423,FailedDependency:424,TooEarly:425,UpgradeRequired:426,PreconditionRequired:428,TooManyRequests:429,RequestHeaderFieldsTooLarge:431,UnavailableForLegalReasons:451,InternalServerError:500,NotImplemented:501,BadGateway:502,ServiceUnavailable:503,GatewayTimeout:504,HttpVersionNotSupported:505,VariantAlsoNegotiates:506,InsufficientStorage:507,LoopDetected:508,NotExtended:510,NetworkAuthenticationRequired:511};Object.entries(tl).forEach(([e,t])=>{tl[t]=e});let tu=function e(t){let r=new ts(t),n=c(ts.prototype.request,r);return $.extend(n,ts.prototype,r,{allOwnKeys:!0}),$.extend(n,r,null,{allOwnKeys:!0}),n.create=function(r){return e(ez(t,r))},n}(eE);tu.Axios=ts,tu.CanceledError=eP,tu.CancelToken=ta,tu.isCancel=eN,tu.VERSION=tt,tu.toFormData=er,tu.AxiosError=G,tu.Cancel=tu.CanceledError,tu.all=function(e){return Promise.all(e)},tu.spread=function(e){return function(t){return e.apply(null,t)}},tu.isAxiosError=function(e){return $.isObject(e)&&!0===e.isAxiosError},tu.mergeConfig=ez,tu.AxiosHeaders=eC,tu.formToJSON=e=>ew($.isHTMLForm(e)?new FormData(e):e),tu.getAdapter=e7,tu.HttpStatusCode=tl,tu.default=tu;let tc=tu}}]);