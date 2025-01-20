"use strict";(self.webpackChunktyping=self.webpackChunktyping||[]).push([["614"],{702:function(e,t,l){l.d(t,{Z:()=>v});var i=l("881"),a=l("94"),u=l("894"),n=l("755"),o=l("238"),s=l("575"),r=l("462"),p=l("480"),c=l("834");let d=(0,i.aZ)({__name:"editor",props:{type:{type:String,required:!0},save:{type:Function,required:!0}},setup(e,t){let{expose:l}=t,d=(0,a.oR)(),v=null,w=(0,i.iH)(null);return s.KD.defineEx("w","w",function(){var t;console.log("test: w"),null===(t=e.save)||void 0===t||t.call(e)}),s.KD.defineEx("x","x",function(){var t;console.log("test: x"),null===(t=e.save)||void 0===t||t.call(e)}),s.KD.defineEx("wq","wq",function(){var t;console.log("test: wq"),null===(t=e.save)||void 0===t||t.call(e)}),(0,i.bv)(()=>{if(w.value){let t=[u.Xy,(0,p._)()];"json"===e.type&&t.push((0,r.AV)()),"dark"===d.getters.currentTheme&&t.push(o.vk),d.getters.currentEnableVim&&(t.push((0,s.dV)()),t.push(c.Q)),(v=new n.tk({doc:"",extensions:t,parent:w.value})).focus()}}),l({getEditorView:()=>v,focus:()=>null==v?void 0:v.focus()}),(e,t)=>((0,i.wg)(),(0,i.iD)("div",{ref_key:"codemirrorParent",ref:w},null,512))}}),v=d},323:function(e,t,l){l.r(t),l.d(t,{default:()=>D});var i=l("881"),a=l("13"),u=l("151"),n=l("702"),o=l("494"),s=l("987"),r=l("946"),p=l("687"),c=l("200"),d=l("556");let v={class:"container"},w={key:0,class:"input-hit"},f={key:1,class:"input-error"},y={key:2,class:"input"},g={key:3,class:"output-finish"},h={key:4,class:"output"},m={key:5,class:"output-error"},k={class:"container"},_={class:"overlay-body"},b={class:"overlay-content"},x=(0,i.aZ)({__name:"game",setup(e){let t;let l=(0,i.iH)(null),x=(0,i.iH)([]),D=(0,i.iH)(!1),H=(0,i.iH)(!1),{t:E}=(0,r.QT)(),q=0,C=(0,i.iH)([]),S=(0,d.yj)(),W=(0,d.tv)();(0,i.bv)(async()=>{t=a.km.from(S.query),await U(t),await z(),(0,a.$x)().on(a.B_.RefreshGame,e=>{t=e,U(e)}),(0,a.$x)().on(a.B_.WsStatus,e=>{e===p.wJ.CONNECT_FINISH&&W.push("/loading")})}),(0,i.Jd)(()=>{(0,a.$x)().off(a.B_.RefreshGame),(0,a.$x)().off(a.B_.WsStatus)});let z=async()=>{try{H.value=!0;let e=new p.cf({path:u.y$.getEditStatus}),t=await p.Lp.node.send(e);D.value=t.data}catch(e){console.error("Failed to refreshEnableEdit:",e)}finally{H.value=!1}},U=async e=>{try{H.value=!0;let t={gameId:e.id,time:e.time},l=new p.cf({path:u.y$.gameUserHistory,data:t}),i=await p.Lp.node.send(l),a=u.ot.from(i.data);x.value=a.list.map(e=>({input:e.input,output:e.output})),q=a.list.length?a.list[a.list.length-1].id:0,C.value=a.list.length?a.list[a.list.length-1].output:[],await W.replace({query:{id:e.id,time:e.time}})}catch(e){console.error("Failed to refresh game:",e)}finally{H.value=!1}},$=()=>{console.log("event cancel")},B=()=>{W.push("/home")},I=async()=>{let e,a="";l.value&&(e=l.value.getEditorView())&&(a=e.state.doc.toString()),H.value=!0;let n=new u.bY;n.gameId=t.id,n.prevId=q,n.input=a;let o=await p.Lp.node.send(new p.cf({path:u.y$.submit,data:n}));if(o.error){(0,c.vC)({title:E("tips"),content:E(o.error),noCancelBtn:!0,okText:E("confirm"),onCancel:$,onOk:B});return}let s=o.data;q=s.id,x.value.push({input:s.input,output:s.output}),C.value=s.output,await (0,i.Y3)(()=>{window.scrollTo(0,document.body.scrollHeight)}),null==e||e.dispatch({changes:{from:0,to:null==e?void 0:e.state.doc.length,insert:""}}),H.value=!1},K=(0,i.Fl)(()=>{let e=C.value.join("");return 0===e.length||-1!==e.indexOf("•")}),Y=e=>{for(let t of e)if("•"===t)return!1;return!0},j=()=>history.back(),F=async()=>{await W.push({path:"/game-editor",query:{id:t.id,time:t.time}})};return(e,t)=>{let a=(0,i.up)("router-link"),u=(0,i.up)("nut-navbar"),r=(0,i.up)("nut-button"),p=(0,i.up)("dev"),c=(0,i.up)("nut-overlay");return(0,i.wg)(),(0,i.iD)(i.HY,null,[(0,i.Wm)(u,{"left-show":"",onClickBack:j},{right:(0,i.w5)(()=>[D.value?((0,i.wg)(),(0,i.j4)((0,i.SU)(s.I8),{key:0,class:"nav-bar",width:"16px",onClick:F})):(0,i.kq)("",!0),(0,i.Wm)(a,{to:"/settings"},{default:(0,i.w5)(()=>[(0,i.Wm)((0,i.SU)(s.pE),{width:"16px"})]),_:1})]),_:1}),(0,i.Wm)(o.Z),(0,i._)("div",v,[((0,i.wg)(!0),(0,i.iD)(i.HY,null,(0,i.Ko)(x.value,(e,t)=>((0,i.wg)(),(0,i.iD)("div",{key:t,class:"history-item"},[((0,i.wg)(!0),(0,i.iD)(i.HY,null,(0,i.Ko)(e.input,(t,l)=>((0,i.wg)(),(0,i.iD)("div",{key:l,class:"history-word"},[((0,i.wg)(!0),(0,i.iD)(i.HY,null,(0,i.Ko)(t,(t,a)=>((0,i.wg)(),(0,i.iD)("div",{key:a,class:"history-char"},["•"!==t&&e.output[l]&&e.output[l][a]&&e.output[l][a]===t?((0,i.wg)(),(0,i.iD)("span",w,(0,i.zw)(t),1)):"•"!==t?((0,i.wg)(),(0,i.iD)("span",f,(0,i.zw)(t),1)):((0,i.wg)(),(0,i.iD)("span",y,(0,i.zw)(t),1)),e.output[l]&&e.output[l][a]&&Y(e.output[l])?((0,i.wg)(),(0,i.iD)("span",g,(0,i.zw)(e.output[l][a]),1)):e.output[l]&&e.output[l][a]?((0,i.wg)(),(0,i.iD)("span",h,(0,i.zw)(e.output[l][a]),1)):((0,i.wg)(),(0,i.iD)("span",m,(0,i.zw)("\xd7")))]))),128))]))),128))]))),128))]),K.value?((0,i.wg)(),(0,i.j4)(p,{key:0},{default:(0,i.w5)(()=>[(0,i.Wm)(n.Z,{type:"txt",save:I,ref_key:"editorComponent",ref:l},null,512),(0,i._)("div",k,[(0,i.Wm)(r,{size:"large",type:"info",onClick:I},{default:(0,i.w5)(()=>[(0,i.Uk)((0,i.zw)((0,i.SU)(E)("confirm")),1)]),_:1})])]),_:1})):(0,i.kq)("",!0),(0,i.Wm)(c,{visible:H.value,"onUpdate:visible":t[0]||(t[0]=e=>H.value=e)},{default:(0,i.w5)(()=>[(0,i._)("div",_,[(0,i._)("div",b,[(0,i.Wm)((0,i.SU)(s.vG))])])]),_:1},8,["visible"])],64)}}}),D=x}}]);