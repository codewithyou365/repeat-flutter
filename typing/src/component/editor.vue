<template>
  <div ref="codemirrorParent"></div>
</template>

<script setup lang="ts">
import {onMounted, ref, defineProps, defineExpose} from 'vue';
import {useStore} from 'vuex';
import {basicSetup, EditorView} from "codemirror";
import {oneDark} from "@codemirror/theme-one-dark";
import {Vim, vim} from "@replit/codemirror-vim";
import {json} from "@codemirror/lang-json"
import {indentWrappedLines} from 'codemirror-indent-wrapped-line'
import {lineNumbersRelative} from '@uiw/codemirror-extensions-line-numbers-relative';

const props = defineProps({
  type: {
    type: String,
    required: true,
  },
  save: {
    type: Function,
    required: false,
  }
});
const store = useStore();
let editorView: EditorView | null = null;

const codemirrorParent = ref<HTMLDivElement | null>(null);
Vim.defineEx('w', 'w', function () {
  console.log("test: w");
  props.save?.();
});
Vim.defineEx('x', 'x', function () {
  console.log("test: x");
  props.save?.();
});
Vim.defineEx('wq', 'wq', function () {
  console.log("test: wq");
  props.save?.();
});
onMounted(() => {
  if (codemirrorParent.value) {
    const extensions = [basicSetup, indentWrappedLines()];
    if (props.type === 'json') {
      extensions.push(json());
    }
    if (store.getters.currentTheme === 'dark') {
      extensions.push(oneDark);
    }

    if (store.getters.currentEnableVim) {
      extensions.push(vim());
      extensions.push(lineNumbersRelative);
    }

    editorView = new EditorView({
      doc: "",
      extensions: extensions,
      parent: codemirrorParent.value,
    });
    editorView.focus();
  }
});

// Expose the editorView getter function
defineExpose({
  getEditorView: () => editorView,
  focus: () => editorView?.focus(),
});
</script>