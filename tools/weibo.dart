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

  // fetchWeibo();
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

  final sourceDir = Directory('source/_weibo');
  if (!sourceDir.existsSync()) {
    sourceDir.create(recursive: true);
  }

  final files = dir.list(recursive: false, followLinks: false,);
  await for (final f in files) {
    try {
      final file = File(f.path);
      if (!file.existsSync()) {
        print("'${file.path}' not exists!");
        continue;
      }
      final str = await file.readAsString();
      _writePost(json.decode(str));
    } catch (e) {
      print("Error: $e !!");
      break;
    }
  }
  // final ss = Stream<int>.periodic(Duration(seconds: 3), (x) => x + 1).take(1);
  // await for (final i in ss) {
  //   try {
  //     _fromFile('weibo_page_$i.json');
  //   } catch (e) {
  //     print("Error========> $e");
  //     break;
  //   }
  // }
}

extension _IntExt on int {
  String get padZero => toString().padLeft(2, '0');
}

String _formatTime(DateTime time, {String ymd = ' ', String hms = ':'}) {
  return "${time.year}-${time.month.padZero}-${time.day.padZero}$ymd"
      "${time.hour.padZero}$hms${time.minute.padZero}$hms${time.second.padZero}";
}

void _writePost(Map<String, dynamic> body) async {
  final cards = body['cards'] as List;
  final info = body['cardlistInfo'];
  final total = info['total'] ?? 0;
  int i = 0;
  for (final card in cards) {
    final type = card['card_type'];
    final entity = card['mblog'];
    final text = entity['text'];
    final at = (entity['created_at'] as String?)?.replaceFirst('+0800', '') ?? '';
    final source = entity['source'];
    final time = HttpDate.parse(at);

    final f = File("source/_weibo/${_formatTime(time, ymd: '-', hms: '')}.md");
    final sink = f.openWrite();
    sink.writeln('layout: weibo');
    sink.writeln('date: ${_formatTime(time)}');
    sink.writeln('---');
    sink.writeln(source);
    sink.writeln(text);

    final retweet = entity['retweeted_status'];
    final page = entity['page_info'];
    final pic = entity['pic_infos'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    if (retweet != null) {
      final text = retweet['text'];
      if (text != null) {
        final owner = retweet['user'];
        final ownerName = owner?['screen_name'] as String?;
        sink.writeln(">  ${ownerName == null ? '' : '@$ownerName: '}$text");
      }
      final picInfo = retweet['pic_infos'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      if (picInfo.isNotEmpty) {
        picInfo.forEach((key, value) {
          final url = (((value as Map<String, dynamic>)['largest']) as Map<String, dynamic>)['url'];
          sink.writeln(">  ![图片]($url)");
        });
      }
    } else if (page != null) {
      sink.writeln(">  ${page?['user']?['screen_name']}回答了:");
      sink.writeln(">  ${page?['content1']}");
      sink.writeln(">  ${page?['content2_html']}");
    } else if (pic.isNotEmpty) {
      pic.forEach((key, value) {
        final url = (((value as Map<String, dynamic>)['largest']) as Map<String, dynamic>)['url'];
        sink.writeln("![图片]($url)");
      });
    }

    await sink.close();
    print("${i++ + 1}/$total: -------------------------- $type");
  }
}

int fetchNum = 0;
void fetchWeibo({int page = 1}) async {
  final url = Uri.parse('http://api.weibo.cn/2/cardlist?networktype=wifi&uicode=10000197&moduleID=708&featurecode=10000085&wb_version=3342&c=android&i=b7cd3c5&s=af220cf7&ua=Google-Pixel__weibo__7.3.0__android__android10&wm=44904_0001&aid=&fid=1076031831493635_-_WEIBO_SECOND_PROFILE_WEIBO&uid=1831493635&v_f=2&v_p=45&from=1073095010&gsid=_2A25NxPnrDeRxGedG6FMV-S3KyDmIHXVs0AojrDV6PUJbkdAKLXjkkWpNUVL2flBB4SmV3nFF8CpOMiBjvhO52v1u&lang=zh_CN&lfid=2735327001&page=$page&skin=default&count=20&oldwm=44904_0001&sflag=1&containerid=1076031831493635_-_WEIBO_SECOND_PROFILE_WEIBO&luicode=10000073&need_head_cards=0');
  final response = await http.post(url);

  print("<<<<<< status: ${response.statusCode}, headers=${response.headers}");
  if (response.statusCode == 200) {
    final filename = 'weibo_page_$page.json';
    final file = File(filename);
    await file.writeAsString(response.body);
    fetchNum += 20;
    page++;
  }
  print(">>>>>> num=$fetchNum");
  if (fetchNum < 2854) {
    Future.delayed(Duration(seconds: 2), () {
      fetchWeibo(page: page);
    });
  }
}
