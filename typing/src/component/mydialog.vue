<template>
  <nut-overlay
      :visible="visible"
      :close-on-click-overlay="false"
      :z-index="2000"
  >
    <div class="my-dialog-wrapper">
      <div class="my-dialog-container">
        <div v-if="title" class="my-dialog-header">{{ title }}</div>

        <div class="my-dialog-content">
          <slot>
            <div class="html-wrapper" v-html="content"></div>
          </slot>
        </div>

        <div class="my-dialog-footer">
          <div class="my-dialog-btn" @click="onOkClick">
            {{ okText || 'OK' }}
          </div>
        </div>
      </div>
    </div>
  </nut-overlay>
</template>

<script setup lang="ts">
// 使用 interface 定义 Props，确保编译器能正确识别类型
interface Props {
  visible: boolean;
  title?: string;
  content?: string;
  okText?: string;
}

const props = defineProps<Props>();
const emit = defineEmits(['update:visible', 'ok']);

const onOkClick = () => {
  // 手动触发关闭逻辑
  emit('update:visible', false);
  emit('ok');
};
</script>

<style scoped>
/* 1. 强制垂直水平居中 */
.my-dialog-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100vw;
  height: 100vh;
  position: fixed;
  top: 0;
  left: 0;
  pointer-events: none; /* 确保不挡住下层的点击，但 container 内部会恢复 */
}

.my-dialog-container {
  pointer-events: auto; /* 恢复点击 */
  background-color: #ffffff; /* 亮色背景 */
  width: 85%;
  max-width: 320px;
  border-radius: 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.1);
}

/* 2. 精准适配 .nut-theme-dark */
.nut-theme-dark .my-dialog-container {
  background-color: #1d1d1d !important; /* 纯正深色背景 */
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.5);
}

/* 标题颜色 */
.my-dialog-header {
  padding: 24px 20px 8px;
  text-align: center;
  font-weight: 600;
  font-size: 18px;
  color: #1a1a1a;
}
.nut-theme-dark .my-dialog-header {
  color: #f5f5f5 !important;
}

/* 内容颜色与居中 */
.my-dialog-content {
  padding: 12px 24px 24px;
  text-align: center;
  white-space: normal !important; /* 彻底根治 pre-wrap 的高度问题 */
  font-size: 15px;
  line-height: 1.6;
  color: #666666;
}
.nut-theme-dark .my-dialog-content {
  color: #aaaaaa !important;
}

/* 底部按钮与分割线 */
.my-dialog-footer {
  border-top: 1px solid #f0f0f0;
}
.nut-theme-dark .my-dialog-footer {
  border-top: 1px solid #333333 !important;
}

.my-dialog-btn {
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fa2c19; /* NutUI 品牌红 */
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

.my-dialog-btn:active {
  background-color: rgba(0, 0, 0, 0.05);
}
.nut-theme-dark .my-dialog-btn:active {
  background-color: rgba(255, 255, 255, 0.05);
}
</style>