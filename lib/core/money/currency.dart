import 'package:meta/meta.dart';
/// ISO 4217 currency metadata bundled with the app (no network).
@immutable
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.digits,
    required this.name,
    this.symbolBefore = true,
  });

  /// ISO 4217 alphabetic code, e.g. `MAD`.
  final String code;

  /// Display symbol, e.g. `$` or `MAD`.
  final String symbol;

  /// Number of minor-unit digits (0, 2 or 3).
  final int digits;

  /// English display name used for search.
  final String name;

  /// Whether the symbol is placed before the number.
  final bool symbolBefore;

  /// 10^digits.
  int get factor => _pow10(digits);

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

/// Lookup table of supported currencies.
abstract final class Currencies {
  /// Currencies pinned at the top of pickers (APP_PROMPT §6.1).
  static const pinned = ['MAD', 'EUR', 'USD', 'GBP', 'SAR', 'AED', 'CAD', 'CHF'];

  // code|symbol|digits|before(1/0)|name
  static const _raw = '''
AED|AED|2|0|UAE Dirham
AFN|؋|2|1|Afghan Afghani
ALL|L|2|0|Albanian Lek
AMD|֏|2|0|Armenian Dram
ANG|ƒ|2|1|Netherlands Antillean Guilder
AOA|Kz|2|1|Angolan Kwanza
ARS|\$|2|1|Argentine Peso
AUD|A\$|2|1|Australian Dollar
AWG|ƒ|2|1|Aruban Florin
AZN|₼|2|0|Azerbaijani Manat
BAM|KM|2|0|Bosnia-Herzegovina Mark
BBD|\$|2|1|Barbadian Dollar
BDT|৳|2|1|Bangladeshi Taka
BGN|лв|2|0|Bulgarian Lev
BHD|BHD|3|0|Bahraini Dinar
BIF|FBu|0|0|Burundian Franc
BMD|\$|2|1|Bermudan Dollar
BND|\$|2|1|Brunei Dollar
BOB|Bs|2|1|Bolivian Boliviano
BRL|R\$|2|1|Brazilian Real
BSD|\$|2|1|Bahamian Dollar
BTN|Nu|2|1|Bhutanese Ngultrum
BWP|P|2|1|Botswanan Pula
BYN|Br|2|0|Belarusian Ruble
BZD|\$|2|1|Belize Dollar
CAD|CA\$|2|1|Canadian Dollar
CDF|FC|2|0|Congolese Franc
CHF|CHF|2|1|Swiss Franc
CLP|\$|0|1|Chilean Peso
CNY|¥|2|1|Chinese Yuan
COP|\$|2|1|Colombian Peso
CRC|₡|2|1|Costa Rican Colón
CUP|\$|2|1|Cuban Peso
CVE|\$|2|1|Cape Verdean Escudo
CZK|Kč|2|0|Czech Koruna
DJF|Fdj|0|0|Djiboutian Franc
DKK|kr|2|0|Danish Krone
DOP|RD\$|2|1|Dominican Peso
DZD|DZD|2|0|Algerian Dinar
EGP|E£|2|1|Egyptian Pound
ERN|Nfk|2|1|Eritrean Nakfa
ETB|Br|2|1|Ethiopian Birr
EUR|€|2|1|Euro
FJD|\$|2|1|Fijian Dollar
GBP|£|2|1|British Pound
GEL|₾|2|0|Georgian Lari
GHS|GH₵|2|1|Ghanaian Cedi
GMD|D|2|0|Gambian Dalasi
GNF|FG|0|0|Guinean Franc
GTQ|Q|2|1|Guatemalan Quetzal
GYD|\$|2|1|Guyanaese Dollar
HKD|HK\$|2|1|Hong Kong Dollar
HNL|L|2|1|Honduran Lempira
HTG|G|2|1|Haitian Gourde
HUF|Ft|2|0|Hungarian Forint
IDR|Rp|2|1|Indonesian Rupiah
ILS|₪|2|1|Israeli New Shekel
INR|₹|2|1|Indian Rupee
IQD|IQD|3|0|Iraqi Dinar
IRR|﷼|2|0|Iranian Rial
ISK|kr|0|0|Icelandic Króna
JMD|\$|2|1|Jamaican Dollar
JOD|JOD|3|0|Jordanian Dinar
JPY|¥|0|1|Japanese Yen
KES|KSh|2|1|Kenyan Shilling
KGS|сом|2|0|Kyrgystani Som
KHR|៛|2|0|Cambodian Riel
KMF|CF|0|0|Comorian Franc
KRW|₩|0|1|South Korean Won
KWD|KWD|3|0|Kuwaiti Dinar
KYD|\$|2|1|Cayman Islands Dollar
KZT|₸|2|0|Kazakhstani Tenge
LAK|₭|2|0|Laotian Kip
LBP|L£|2|1|Lebanese Pound
LKR|Rs|2|1|Sri Lankan Rupee
LRD|\$|2|1|Liberian Dollar
LSL|L|2|1|Lesotho Loti
LYD|LYD|3|0|Libyan Dinar
MAD|MAD|2|0|Moroccan Dirham
MDL|L|2|0|Moldovan Leu
MGA|Ar|2|0|Malagasy Ariary
MKD|ден|2|0|Macedonian Denar
MMK|K|2|0|Myanmar Kyat
MNT|₮|2|0|Mongolian Tugrik
MOP|MOP\$|2|1|Macanese Pataca
MRU|UM|2|0|Mauritanian Ouguiya
MUR|Rs|2|1|Mauritian Rupee
MVR|Rf|2|1|Maldivian Rufiyaa
MWK|MK|2|1|Malawian Kwacha
MXN|MX\$|2|1|Mexican Peso
MYR|RM|2|1|Malaysian Ringgit
MZN|MT|2|0|Mozambican Metical
NAD|\$|2|1|Namibian Dollar
NGN|₦|2|1|Nigerian Naira
NIO|C\$|2|1|Nicaraguan Córdoba
NOK|kr|2|0|Norwegian Krone
NPR|Rs|2|1|Nepalese Rupee
NZD|NZ\$|2|1|New Zealand Dollar
OMR|OMR|3|0|Omani Rial
PAB|B/.|2|1|Panamanian Balboa
PEN|S/|2|1|Peruvian Sol
PGK|K|2|1|Papua New Guinean Kina
PHP|₱|2|1|Philippine Peso
PKR|Rs|2|1|Pakistani Rupee
PLN|zł|2|0|Polish Zloty
PYG|₲|0|1|Paraguayan Guarani
QAR|QAR|2|0|Qatari Riyal
RON|lei|2|0|Romanian Leu
RSD|din|2|0|Serbian Dinar
RUB|₽|2|0|Russian Ruble
RWF|RF|0|0|Rwandan Franc
SAR|SAR|2|0|Saudi Riyal
SBD|\$|2|1|Solomon Islands Dollar
SCR|Rs|2|1|Seychellois Rupee
SDG|SDG|2|0|Sudanese Pound
SEK|kr|2|0|Swedish Krona
SGD|S\$|2|1|Singapore Dollar
SLE|Le|2|1|Sierra Leonean Leone
SOS|Sh|2|1|Somali Shilling
SRD|\$|2|1|Surinamese Dollar
SSP|£|2|1|South Sudanese Pound
STN|Db|2|0|São Tomé Dobra
SYP|£S|2|1|Syrian Pound
SZL|E|2|1|Swazi Lilangeni
THB|฿|2|1|Thai Baht
TJS|SM|2|0|Tajikistani Somoni
TMT|m|2|0|Turkmenistani Manat
TND|TND|3|0|Tunisian Dinar
TOP|T\$|2|1|Tongan Paʻanga
TRY|₺|2|1|Turkish Lira
TTD|\$|2|1|Trinidad & Tobago Dollar
TWD|NT\$|2|1|New Taiwan Dollar
TZS|TSh|2|1|Tanzanian Shilling
UAH|₴|2|0|Ukrainian Hryvnia
UGX|USh|0|1|Ugandan Shilling
USD|\$|2|1|US Dollar
UYU|\$U|2|1|Uruguayan Peso
UZS|soʻm|2|0|Uzbekistani Som
VES|Bs.S|2|1|Venezuelan Bolívar
VND|₫|0|0|Vietnamese Dong
VUV|VT|0|0|Vanuatu Vatu
WST|WS\$|2|1|Samoan Tala
XAF|FCFA|0|0|Central African CFA Franc
XCD|EC\$|2|1|East Caribbean Dollar
XOF|CFA|0|0|West African CFA Franc
XPF|CFPF|0|0|CFP Franc
YER|YER|2|0|Yemeni Rial
ZAR|R|2|1|South African Rand
ZMW|ZK|2|1|Zambian Kwacha
ZWL|\$|2|1|Zimbabwean Dollar''';

  static final Map<String, Currency> _byCode = {
    for (final line in _raw.trim().split('\n'))
      line.split('|')[0]: _parse(line),
  };

  static Currency _parse(String line) {
    final p = line.split('|');
    return Currency(
      code: p[0],
      symbol: p[1],
      digits: int.parse(p[2]),
      symbolBefore: p[3] == '1',
      name: p[4],
    );
  }

  /// All currencies sorted by code.
  static List<Currency> get all =>
      _byCode.values.toList()..sort((a, b) => a.code.compareTo(b.code));

  /// Returns the currency for [code]; unknown codes get a 2-digit fallback.
  static Currency of(String code) =>
      _byCode[code] ??
      Currency(code: code, symbol: code, digits: 2, name: code, symbolBefore: false);

  static bool isKnown(String code) => _byCode.containsKey(code);

  /// Pinned first, then the rest; optionally filtered by [query].
  static List<Currency> ordered({String query = ''}) {
    final q = query.trim().toLowerCase();
    bool match(Currency c) =>
        q.isEmpty ||
        c.code.toLowerCase().contains(q) ||
        c.name.toLowerCase().contains(q);
    final pinnedList = pinned.map(of).where(match).toList();
    final rest = all.where((c) => !pinned.contains(c.code) && match(c));
    return [...pinnedList, ...rest];
  }
}
