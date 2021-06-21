import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

Duration _calTimezone(String timezone) {
  final isPositive = timezone.codeUnits[0] == 0x2B;
  final hour = timezone.substring(1,3);
  final minute = timezone.substring(3);
  final d = Duration(hours: int.tryParse(hour) ?? 0, minutes: int.tryParse(minute) ?? 0);
  return isPositive ? d : -d;
}

void main(List<String> argv) async {
  // final t = 'Tue Oct 01 09:21:59 -0300 2019';
  // final reg = RegExp(r'[+-]\d+');
  // final m = reg.firstMatch(t);
  // final s = m != null ? t.replaceFirst(m[0] ?? '', '') : t;
  // final curZone = DateTime.now().timeZoneOffset;
  //
  // final time = HttpDate.parse(s);
  // final timezone =m==null?curZone:_calTimezone(m[0] ?? '');
  //
  // print("cur = $curZone, zone=$timezone, diff=${curZone - timezone}");
  // final showTime = time.add(curZone - timezone);
  // print("$timezone - ${DateFormat('yyyy-MM-dd hh:mm:ss').format(showTime)}, show=$showTime");

  // fetchWeibo(page: 124, increase: false);
  if (argv.length > 0) {
    Directory.current = argv[0];
  }
  _createSource();
}

void _createSource() async {
  final dir = Directory('data/weibo');
  if (!dir.existsSync()) {
    print("No weibo data found in 'data/weibo'!");
    exit(-1);
  }

  final sourceDir = Directory('source/_posts');
  if (!sourceDir.existsSync()) {
    sourceDir.create(recursive: true);
  }

  final files = dir.list(recursive: false, followLinks: false,);
  int total = 0;
  await for (final f in files) {
    try {
      final file = File(f.path);
      if (!file.existsSync()) {
        print("'${file.path}' not exists!");
        continue;
      }
      final str = await file.readAsString();
      final size = await _writePost(json.decode(str));
      total += size;
      final warning = size != 20 ? 'have only $size tweets!' : '';
      print("'${f.path}' $warning total: $total");
    } catch (e) {
      print("Error: $e !!");
      break;
    }
  }
}

extension _IntExt on int {
  String get padZero => toString().padLeft(2, '0');
}

extension _TExt<T> on T {
  R let<R>(R op(T it)) => op(this);
}

String _formatTime(DateTime time, {String ymd = ' ', String hms = ':'}) {
  return "${time.year}-${time.month.padZero}-${time.day.padZero}$ymd"
      "${time.hour.padZero}$hms${time.minute.padZero}$hms${time.second.padZero}";
}

bool _isUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.startsWith('https://') || url.startsWith('http://');
}

Future<int> _writePost(Map<String, dynamic> body) async {
  final cards = body['cards'] as List;
  final info = body['cardlistInfo'];
  final total = info['total'] ?? 0;
  final size = cards.length;
  for (final card in cards) {
    final entity = card['mblog'];
    final text = entity['text'];
    final at = (entity['created_at'] as String?)?.replaceFirst('+0800', '') ?? '';
    final source = entity['source'];
    final time = HttpDate.parse(at);

    final f = File("source/_posts/${_formatTime(time, ymd: '-', hms: '')}.md");
    final sink = f.openWrite();
    sink.writeln('layout: weibo');
    sink.writeln('date: ${_formatTime(time)}');
    sink.writeln('---');
    sink.writeln("${_formatTime(time)}  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 来自 $source");

    sink.writeln(text);

    final retweet = entity['retweeted_status'];
    final page = entity['page_info'];
    final title = page?['page_title'];
    final pic = entity['pic_infos'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    if (retweet != null) {
      final text = retweet['text'] as String?;
      if (text != null) {
        final owner = retweet['user'];
        final ownerName = owner?['screen_name'] as String?;
        final content = _isUrl(text) && title != null ? '[$title]($text)': text;
        sink.writeln(">  ${ownerName == null ? '' : '@$ownerName: '}$content");
      }
      final picInfo = retweet['pic_infos'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      if (picInfo.isNotEmpty) {
        picInfo.forEach((key, value) {
          final url = (((value as Map<String, dynamic>)['largest']) as Map<String, dynamic>)['url'];
          sink.writeln(">  ![图片]($url)");
        });
      }
    }
    if (page != null) {
      final pageType = page['type'];
      final type = pageType is num ? pageType : int.tryParse(pageType.toString()) ?? 0;
      final pic = page['page_pic'];
      if (type == 0) {
        final url = Uri.parse(page['page_url']);
        final link = url.isScheme('http') || url.isScheme('https') ? url : url.queryParameters['url'];
        final content = '<img style="float: left;" src="$pic"/>'
            '${page['page_title']}\n${page['page_desc']}';
        sink.writeln('[$content]($link)');
        sink.writeln();

      } else if (type == 24) {
        sink.writeln('> <img src="${page['page_pic']}" />');
        sink.writeln(">  ${page['user']?['screen_name']}回答了:");
        sink.writeln(">  ${page['content1']}");
        (page['content2_html'] as String?)?.let((it) => sink.writeln(">  $it"));
      }
    } else if (pic.isNotEmpty) {
      pic.forEach((key, value) {
        final url = (((value as Map<String, dynamic>)['largest']) as Map<String, dynamic>)['url'];
        sink.writeln("![图片]($url)");
      });
    }

    await sink.close();
  }
  return size;
}

int fetchNum = 0;
void fetchWeibo({int page = 1, bool increase = true}) async {
  final url = Uri.parse('http://api.weibo.cn/2/cardlist?networktype=wifi&uicode=10000197&moduleID=708&featurecode=10000085&wb_version=3342&c=android&i=b7cd3c5&s=af220cf7&ua=Google-Pixel__weibo__7.3.0__android__android10&wm=44904_0001&aid=&fid=1076031831493635_-_WEIBO_SECOND_PROFILE_WEIBO&uid=1831493635&v_f=2&v_p=45&from=1073095010&gsid=_2A25NxPnrDeRxGedG6FMV-S3KyDmIHXVs0AojrDV6PUJbkdAKLXjkkWpNUVL2flBB4SmV3nFF8CpOMiBjvhO52v1u&lang=zh_CN&lfid=2735327001&page=$page&skin=default&count=20&oldwm=44904_0001&sflag=1&containerid=1076031831493635_-_WEIBO_SECOND_PROFILE_WEIBO&luicode=10000073&need_head_cards=0');
  final response = await http.post(url);

  print("<<<<<< status: ${response.statusCode}, headers=${response.headers}");
  int num = 0;
  final success = response.statusCode == 200;
  if (success) {
    final filename = 'weibo_page_$page.json';
    final file = File(filename);
    final body = response.body;
    await file.writeAsString(body);
    final obj = json.decode(body);
    final cards = obj['cards'] as List;
    num = cards.length;
    page++;
  }
  fetchNum += num;
  print(">>>>>> num=$num, total=$fetchNum");
  if (!success || increase && fetchNum < 2854) {
    Future.delayed(Duration(seconds: 2), () {
      fetchWeibo(page: page);
    });
  }
}
