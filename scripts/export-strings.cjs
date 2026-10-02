#!/usr/bin/env node
/**
 * Exports the Fire TV app's UI string table (src/i18n/strings.ts) and the
 * ALLERGEN_NAMES map to JSON resources bundled by the iOS app.
 *
 * Usage (from this repo root):
 *   TV_REPO=../fifirecipes-amazonfire node scripts/export-strings.cjs
 *
 * The TV repo's own copy of jiti does the TypeScript evaluation, so this
 * script stays dependency-free in this repo.
 */
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const tvRepo = path.resolve(process.env.TV_REPO || '../fifirecipes-amazonfire');
const jiti = require(path.join(tvRepo, 'node_modules/jiti/lib/jiti.cjs'))(__filename);

const stringsPath = path.join(tvRepo, 'src/i18n/strings.ts');
const mod = jiti(stringsPath);
const { STRINGS, EN } = mod;

if (!STRINGS || !EN) throw new Error('STRINGS/EN exports not found in strings.ts');
if (Object.keys(STRINGS).length !== 25) {
  throw new Error(`expected 25 languages, got ${Object.keys(STRINGS).length}`);
}

// iPadOS wording overrides — the TV table references a remote control / OK
// button / "big screen"; on iPad we say tap/type and name the device "iPad".
const OVERRIDES = {
  en: {
    searchHint: 'Type a word — tasty matches appear below.',
    tickHint: 'Tap to tick what you have',
    aboutText: 'FiFi Recipes brings Dr. Fatma’s beloved Egyptian home cooking to your iPad — browse, pick a recipe, and cook together. Recipe data is served fresh from fifi.cooking.',
    errorBody: 'We couldn’t fetch your recipes. Check the internet connection, then tap Retry.',
  },
  ar: {
    searchHint: 'اكتبي كلمة — الوصفات الحلوة هتظهر تحت.',
    tickHint: 'دوسي على اللي عندك عشان تعلميه',
    aboutText: 'وصفات فيفي بتجيبلك أكلات د. فاطمة المصرية المحبوبة على الآيباد بتاعك — اتفرجي، اختاري، واطبخي. البيانات تازة من fifi.cooking.',
  },
  fr: {
    searchHint: 'Tapez un mot — les recettes apparaissent en bas.',
    tickHint: 'Touchez pour cocher ce que vous avez',
    aboutText: 'FiFi Recipes apporte la cuisine familiale égyptienne du Dr Fatma sur votre iPad — parcourez, choisissez, cuisinez. Données : fifi.cooking.',
  },
  es: {
    searchHint: 'Escribe una palabra — las recetas aparecen abajo.',
    tickHint: 'Toca para marcar lo que tienes',
    aboutText: 'FiFi Recipes lleva la querida cocina casera egipcia de la Dra. Fatma a tu iPad — explora, elige y cocina. Datos: fifi.cooking.',
  },
  de: {
    searchHint: 'Tippe ein Wort ein — leckere Treffer erscheinen unten.',
    tickHint: 'Tippe, um abzuhaken, was du hast',
    aboutText: 'FiFi Recipes bringt Dr. Fatmas beliebte ägyptische Hausmannskost auf dein iPad — stöbern, wählen, kochen. Daten: fifi.cooking.',
  },
  it: {
    searchHint: 'Digita una parola — le ricette compaiono sotto.',
    tickHint: 'Tocca per spuntare ciò che hai',
    aboutText: 'FiFi Recipes porta l’amata cucina casalinga egiziana della Dott.ssa Fatma sul tuo iPad — sfoglia, scegli, cucina. Dati: fifi.cooking.',
  },
  pt: {
    searchHint: 'Digite uma palavra — as receitas aparecem abaixo.',
    tickHint: 'Toque para marcar o que você tem',
    aboutText: 'FiFi Recipes leva a querida culinária caseira egípcia da Dra. Fatma ao seu iPad — navegue, escolha e cozinhe. Dados: fifi.cooking.',
  },
  ru: {
    searchHint: 'Введите слово — подходящие рецепты появятся ниже.',
    tickHint: 'Нажмите, чтобы отметить, что уже есть',
    aboutText: 'FiFi Recipes переносит любимую египетскую домашнюю кухню доктора Фатмы на ваш iPad — выбирайте и готовьте. Данные: fifi.cooking.',
  },
  zh: {
    searchHint: '输入关键词——美味的菜谱会出现在下方。',
    tickHint: '点按即可勾选已有的材料',
    aboutText: 'FiFi Recipes 把法特玛博士心爱的埃及家常菜带到你的 iPad——浏览、挑选、一起做。数据来源：fifi.cooking。',
  },
  ja: {
    searchHint: '文字を入力してね — おいしいレシピが下に出ます。',
    tickHint: 'タップして持っているものにチェック',
    aboutText: 'FiFi Recipes はファトマ博士の愛するエジプト家庭料理をあなたの iPad へお届けします。データ提供: fifi.cooking。',
  },
  ko: {
    searchHint: '단어를 입력해 보세요 — 맛있는 레시피가 아래에 나타나요.',
    tickHint: '탭해서 가지고 있는 재료를 체크해요',
    aboutText: 'FiFi Recipes는 파트마 박사의 사랑받는 이집트 가정요리를 iPad 앱으로 제공합니다. 데이터: fifi.cooking.',
  },
  tr: {
    searchHint: 'Bir kelime yazın — lezzetli tarifler aşağıda belirir.',
    tickHint: 'Elinde olanları işaretlemek için dokun',
    aboutText: 'FiFi Recipes, Dr. Fatma’nın sevilen Mısır ev yemeklerini iPad’inize taşır — göz atın, seçin, pişirin. Veri: fifi.cooking.',
  },
  hi: {
    searchHint: 'शब्द टाइप करें — स्वादिष्ट रेसिपी नीचे दिखेंगी।',
    tickHint: 'जो चीज़ें हैं उन्हें टैप करके टिक करें',
    aboutText: 'FiFi Recipes डॉ. फातमा के पसंदीदा मिस्री घर के खाने को आपके iPad पर लाता है — देखिए, चुनिए, पकाइए। डेटा: fifi.cooking.',
  },
  ur: {
    searchHint: 'لفظ ٹائپ کریں — مزیدار ریسپیاں نیچے آ جائیں گی۔',
    tickHint: 'جو چیزیں ہیں انہیں ٹیپ کر کے ٹک کریں',
    aboutText: 'فیفی ریسپیز ڈاکٹر فاطمہ کے پیارے مصری گھریلو کھانے آپ کے iPad پر لاتا ہے — دیکھیں، چنیں، پکائیں۔ ڈیٹا: fifi.cooking.',
  },
  fa: {
    searchHint: 'یه کلمه تایپ کنید — دستورهای خوشمزه پایین میاد.',
    tickHint: 'هر چی داری رو با لمس تیک بزن',
    aboutText: 'دستورهای فیفی آشپزی خانگی محبوب دکتر فاطما رو به آیپد شما میاره — ببینید، انتخاب کنید، بپزید. داده‌ها: fifi.cooking.',
  },
  el: {
    searchHint: 'Πληκτρολογήστε μια λέξη — νόστιμες συνταγές εμφανίζονται παρακάτω.',
    tickHint: 'Πάτα για να σημειώσεις όσα έχεις',
    aboutText: 'Το FiFi Recipes φέρνει την αγαπημένη αιγυπτιακή σπιτική κουζίνα της Δρ Φάτμα στο iPad σας — δείτε, διαλέξτε, μαγειρέψτε. Δεδομένα: fifi.cooking.',
  },
  ku: {
    searchHint: 'Peyveke binivîse — reçeteyên xweş li jêr derdikevin.',
    tickHint: 'Li ya ku te heye bike da ku nîşan bikeri',
    aboutText: 'FiFi Recipes xwarinên malê yên Misrî yên hezkirî yên Dr. Fatma tîne ser iPad’a we — temaşe bike, hilbijêre, bişîne. Daneyên ji fifi.cooking.',
  },
  id: {
    searchHint: 'Ketik satu kata — resep lezat muncul di bawah.',
    tickHint: 'Ketuk untuk menandai yang kamu punya',
    aboutText: 'FiFi Recipes menghadirkan masakan rumahan Mesir kesukaan Dr. Fatma ke iPad kamu — jelajahi, pilih, masak. Data: fifi.cooking.',
  },
  sw: {
    searchHint: 'Andika neno — mapishi ya kitamu yataonekana chini.',
    tickHint: 'Gusa kuweka alama unachonacho',
    aboutText: 'FiFi Recipes huleta mapishi maarufu ya nyumbani ya Misri ya Dkt. Fatma kwenye iPad yako — vinjari, chagua, pika. Data: fifi.cooking.',
  },
  nl: {
    searchHint: 'Typ een woord — lekkere recepten verschijnen hieronder.',
    tickHint: 'Tik om af te vinken wat je hebt',
    aboutText: 'FiFi Recipes brengt dr. Fatma’s geliefde Egyptische thuiskeuken naar je iPad — blader, kies, kook. Data: fifi.cooking.',
  },
  ps: {
    searchHint: 'يوه کلمه ولیکئ — خوندور ترکیبونه به لاندې ښکاري.',
    tickHint: 'هغه څه چې لرې ټک کړه',
    aboutText: 'فیفي ترکیبونه د ډاکټرې فاطمه ګران مصري کورنی پخلنځي ستاسو iPad ته راوړي — وګورئ، وټاکئ، وپخئ. معلومات: fifi.cooking.',
  },
  he: {
    searchHint: 'הקלידו מילה — מתכונים טעימים יופיעו למטה.',
    tickHint: 'הקישו כדי לסמן מה יש לכם',
    aboutText: 'FiFi Recipes מביא את הבישול המצרי הביתי האהוב של ד״ר פאטמה ל-iPad שלכם — עיינו, בחרו, בשלו. נתונים: fifi.cooking.',
  },
  pl: {
    searchHint: 'Wpisz słowo — pyszne przepisy pojawią się poniżej.',
    tickHint: 'Dotknij, by odhaczyć, co masz',
    aboutText: 'FiFi Recipes przenosi ukochaną egipską kuchnię domową dr Fatmy na Twój iPad — przeglądaj, wybieraj, gotuj. Dane: fifi.cooking.',
  },
  sv: {
    searchHint: 'Skriv ett ord — goda recept visas nedan.',
    tickHint: 'Tryck för att bocka av det du har',
    aboutText: 'FiFi Recipes tar dr Fatmas älskade egyptiska hemköksrecept till din iPad — bläddra, välj, laga. Data: fifi.cooking.',
  },
  te: {
    searchHint: 'ఒక పదం టైప్ చేయండి — రుచికరమైన వంటకాలు కింద కనిపిస్తాయి.',
    tickHint: 'మీ దగ్గర ఉన్నవి టిక్ చేయడానికి ట్యాప్ చేయండి',
    aboutText: 'FiFi Recipes డాక్టర్ ఫాతిమా ప్రియమైన ఈజిప్టు ఇంటి వంటకాలను మీ iPadకి తెస్తుంది — చూడండి, ఎంచుకోండి, వండండి. డేటా: fifi.cooking.',
    errorBody: 'మీ వంటకాలు తేలేకపోయాం. ఇంటర్నెట్ కనెక్షన్ చూసి, మళ్లీ ప్రయత్నించండి ట్యాప్ చేయండి.',
  },
};

for (const [lang, t] of Object.entries(STRINGS)) {
  Object.assign(t, OVERRIDES[lang] ?? OVERRIDES.en);
}

// ALLERGEN_NAMES is module-private; strings.ts exposes allergenName().
// Rebuild the per-language map through the public function so the JSON
// carries the same fallback-resolved values.
const fsSrc = fs.readFileSync(stringsPath, 'utf8');
const am = fsSrc.match(/const ALLERGEN_NAMES[^=]*=\s*(\{[\s\S]*?\n\});/);
if (!am) throw new Error('ALLERGEN_NAMES literal not found');
const ALLERGEN_NAMES = new Function(`return (${am[1]})`)();

const outDir = path.join(repoRoot, 'FifiRecipesPad', 'Resources');
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(
  path.join(outDir, 'ui-strings.json'),
  JSON.stringify({ strings: STRINGS, allergens: ALLERGEN_NAMES }, null, 0) + '\n',
);
console.log(`wrote ui-strings.json: ${Object.keys(STRINGS).length} languages, ` +
  `${Object.keys(ALLERGEN_NAMES).length} allergen tables`);
