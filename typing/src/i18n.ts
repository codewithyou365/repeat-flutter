import {createI18n} from 'vue-i18n';

const messages = {
    en: {
        dartMode: 'Dart Mode',
        settings: 'Settings',
    },
    zh: {
        dartMode: '深色模式',
        settings: '设置',
    },
};

export const i18n = createI18n({
    legacy: false,
    locale: 'en',
    messages,
});