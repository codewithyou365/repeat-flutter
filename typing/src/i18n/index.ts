import {createI18n} from 'vue-i18n';

import en from './en';
import zh from './zh';
import ja from './ja';
import ko from './ko';
import es from './es';
import fr from './fr';
import de from './de';
import ru from './ru';
import pt from './pt';
import it from './it';
import id from './id';
import vi from './vi';

const messages = {en, zh, ja, ko, es, fr, de, ru, pt, it, id, vi};

export type LocaleCode = keyof typeof messages;

/**
 * 语言选择器上的选项。名字一律写母语写法：选语言的时候用户看不懂当前界面语言，
 * 只能靠认出自己那一行。顺序跟 Dart 端 I18nLocal 保持一致。
 */
export const LOCALES: { code: LocaleCode; name: string }[] = [
    {code: 'en', name: 'English'},
    {code: 'zh', name: '中文'},
    {code: 'ja', name: '日本語'},
    {code: 'ko', name: '한국어'},
    {code: 'es', name: 'Español'},
    {code: 'fr', name: 'Français'},
    {code: 'de', name: 'Deutsch'},
    {code: 'ru', name: 'Русский'},
    {code: 'pt', name: 'Português (BR)'},
    {code: 'it', name: 'Italiano'},
    {code: 'id', name: 'Bahasa Indonesia'},
    {code: 'vi', name: 'Tiếng Việt'},
];

export const i18n = createI18n({
    legacy: false,
    locale: 'en',
    // 少了哪条就退回英文。没有这行的话 t() 会把 key 名原样甩到界面上，
    // 而且 t(res.error) 这种动态 key 天生就可能撞上没翻译的错误码。
    fallbackLocale: 'en',
    // 退回英文是预期行为，不用每次都往控制台刷一条警告
    fallbackWarn: false,
    missingWarn: false,
    messages,
});
