"use strict";(self.webpackChunktyping=self.webpackChunktyping||[]).push([["242"],{350:function(e,l,t){t.r(l),t.d(l,{default:()=>b});var a=t("881"),n=t("494"),u=t("987"),i=t("946"),o=t("687"),r=t("200"),v=t("556"),m=t("151");let c={style:{margin:"8px"}},s={class:"overlay-body"},p={class:"overlay-content"},d=(0,a.aZ)({__name:"home",setup(e){let l=(0,v.tv)(),t=(0,a.iH)(""),d=(0,a.iH)(!1),b=(0,a.iH)(!1),{t:g}=(0,i.QT)();(0,a.bv)(()=>{});let y=()=>{console.log("event cancel")},f=()=>{console.log("event ok")},w=()=>{d.value=!1},k=async()=>{b.value=!0,console.log("Game Number:",t.value);let e=new o.cf({path:m.y$.entryGame,data:parseInt(t.value)}),a=await o.Lp.node.send(e);if(b.value=!1,d.value=!1,a.error)(0,r.vC)({title:g("tips"),content:g("gameEntryCodeError"),noCancelBtn:!0,okText:g("confirm"),onCancel:y,onOk:f});else{let e=a.data;await l.push({path:"/game",query:e})}},U=()=>{d.value=!0};return(e,l)=>{let i=(0,a.up)("router-link"),o=(0,a.up)("nut-navbar"),r=(0,a.up)("nut-grid-item"),v=(0,a.up)("nut-grid"),m=(0,a.up)("nut-input"),y=(0,a.up)("nut-dialog"),f=(0,a.up)("nut-overlay");return(0,a.wg)(),(0,a.iD)(a.HY,null,[(0,a.Wm)(o,{title:(0,a.SU)(g)("home")},{right:(0,a.w5)(()=>[(0,a.Wm)(i,{to:"/settings"},{default:(0,a.w5)(()=>[(0,a.Wm)((0,a.SU)(u.pE),{width:"16px"})]),_:1})]),_:1},8,["title"]),(0,a.Wm)(n.Z),(0,a._)("div",c,[(0,a.Wm)(v,{"column-num":1,square:""},{default:(0,a.w5)(()=>[(0,a.Wm)(r,{text:"entry game",clickable:"",onClick:U},{default:(0,a.w5)(()=>[(0,a.Wm)((0,a.SU)(u.UD))]),_:1})]),_:1})]),(0,a.Wm)(y,{visible:d.value,"onUpdate:visible":l[1]||(l[1]=e=>d.value=e),title:(0,a.SU)(g)("pleaseInputGameNumber"),okText:(0,a.SU)(g)("confirm"),cancelText:(0,a.SU)(g)("cancel"),onOk:k,onCancel:w},{default:(0,a.w5)(()=>[(0,a.Wm)(m,{clearable:"",type:"number",modelValue:t.value,"onUpdate:modelValue":l[0]||(l[0]=e=>t.value=e)},null,8,["modelValue"])]),_:1},8,["visible","title","okText","cancelText"]),(0,a.Wm)(f,{visible:b.value,"onUpdate:visible":l[2]||(l[2]=e=>b.value=e)},{default:(0,a.w5)(()=>[(0,a._)("div",s,[(0,a._)("div",p,[(0,a.Wm)((0,a.SU)(u.vG))])])]),_:1},8,["visible"])],64)}}}),b=d}}]);