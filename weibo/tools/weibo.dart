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
  // _createSource();
  _fetchAllComments();
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
    final size = await _writeToFile(f.path);
    total += size;
    final warning = size != 20 ? 'have only $size tweets!' : '';
    print("'${f.path}' $warning total: $total");
  }
}

Future<int> _writeToFile(String path) async {
  try {
    final file = File(path);
    if (!file.existsSync()) {
      print("'${file.path}' not exists!");
      return 0;
    }
    final str = await file.readAsString();
    final size = await _writePost(json.decode(str));
    return size;
  } catch (e) {
    print("Error: $e !!");
    return 0;
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

String _formatTime2(DateTime time) => "${time.year % 100}-${time.month}-${time.day} "
    "${time.hour.padZero}:${time.minute.padZero}";

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
    sink.writeln('<meta name="referrer" content="no-referrer" />\n');
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

    final tags = entity['tag_struct'] as List? ?? const [];
    tags.forEach((tag) {
      sink.writeln('<img src="${tag['url_type_pic']}" width="32" height="32" style="float: left;"/>  '
          '${tag['tag_name']}');
    });

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

Future<void> _fetchAllComments() async {
  final dir = Directory('data/weibo');
  final files = dir.list(recursive: false, followLinks: false,).where((f) => f.path.contains('weibo_page_'));
  await for (final f in files) {
    print("++++++ start downloading all comments in '${f.path}'...");
    int num = await _fetchPageComments(f.path);
    print("------ finish downloading comments${num > 0 ? ' and saved' : ''}");
  }

}

Future<int> _fetchPageComments(String path) async {
  final input = File(path);
  final body = json.decode(await input.readAsString());
  final cards = body['cards'] as List;
  final comments = <Map<String, dynamic>>[];
  for (final card in cards) {
    final entity = card['mblog'];
    final count = entity['comments_count'] as int? ?? 0;
    if (count > 0) {
      final itemId = card['itemid'];
      final id = entity['idstr'] as String;
      final comment = (await _fetchComments({"itemId":itemId, "blogId":id, "text":entity['text']}));
      if (comment != null) {
        comments.add(comment);
      }
    }
  }
  if (comments.length > 0) {
    final output = File(path.replaceAll('weibo_page_', 'weibo_comment_'));
    await output.writeAsString(json.encode(comments));
  }
  return comments.length;
}

Future<Map<String, dynamic>?> _fetchComments(Map<String, String> item) async {
  final itemId = item['itemId'];
  final blogId = item['blogId'];
  print("<<<<<< itemId=$itemId, blog=$blogId");
  final url = Uri.parse('http://api.weibo.cn/2/comments/build_comments?networktype=wifi&max_id=0&is_show_bulletin=2&uicode=10000002&moduleID=700&trim_user=0&is_reload=1&wb_version=3342&is_encoded=0&lcardid=$itemId&c=android&i=c7f35ce&s=af220cf7&id=$blogId&ua=LGE-Nexus%205__weibo__7.3.0__android__android5.1.1&wm=44904_0001&aid=01A8V-NuwmveGeUbKVCeikNEsaeahxV5iJMRgD3fjwt_pz_Is.&v_f=2&v_p=45&from=1073095010&gsid=_2A25N1ertDeRxGedG6FMV-S3KyDmIHXVsw3klrDV6PUJbkdAKLW79kWpNUVL2fnRiMtjf3Bj5mUdwaVH-7vUflRy0&lang=zh_CN&lfid=2302831831493635&skin=default&count=20&oldwm=44904_0001&sflag=1&luicode=10000197&fetch_level=0&max_id_type=0');
  final response = await http.post(url);
  final success = response.statusCode == 200;
  if (success) {
    final body = json.decode(response.body) as Map<String, dynamic>;
    final roots = body['root_comments'] as List? ?? const [];
    final total = await Future.wait<int>(roots.map((root) async {
      final more = root['more_info'] as Map<String, dynamic>?;
      final old = root['comments'] as List;
      int size = old.length;
      if (more != null && more.isNotEmpty) {
        final id = root['rootidstr'];
        print("    <<<<<< detail commentId=$id");
        final u = Uri.parse('http://api.weibo.cn/2/comments/build_comments?networktype=wifi&max_id=0&is_show_bulletin=2&uicode=10000408&moduleID=700&trim_user=0&is_reload=1&wb_version=3342&is_encoded=0&c=android&i=c7f35ce&s=af220cf7&id=$id&ua=LGE-Nexus%205__weibo__7.3.0__android__android5.1.1&wm=44904_0001&aid=01A8V-NuwmveGeUbKVCeikNEsaeahxV5iJMRgD3fjwt_pz_Is.&v_f=2&v_p=45&from=1073095010&gsid=_2A25N1ertDeRxGedG6FMV-S3KyDmIHXVsw3klrDV6PUJbkdAKLW79kWpNUVL2fnRiMtjf3Bj5mUdwaVH-7vUflRy0&lang=zh_CN&skin=default&count=20&oldwm=44904_0001&sflag=1&luicode=10000002&fetch_level=1&max_id_type=0');
        final res = await http.post(u);
        final detail = json.decode(res.body);
        final list = detail['comments'] as List;
        print("    >>>>>> old=${old.length}, new=${list.length}");
        root['comments'] = list;
        size = list.length ;
      }
      return size + 1;
    }));
    print(">>>>>> ${item['text']}: total=$total");
    return total.isEmpty ? null : body;
  } else {
    print("!!!!!!! error: url=$url");
  }
}

Future<int> _writeComment(int page) async {
  int size = 0;
  final sink = File('').openWrite();
    final body = json.decode(await File('weibo_comment_$page.json').readAsString());
    final roots = body['root_comments'] as List? ?? const [];
    size = roots.length;
    roots.forEach((root) {
      final user = root['user'] as Map<String, dynamic>;
      final name = user['screen_name'];
      final time = HttpDate.parse((root['created_at'] as String?)?.replaceFirst('+0800', '') ?? '');
      final text = root['text'];

      final more = root['more_info'] as Map<String, dynamic>?;

      final comments = root['comments'] as List? ?? const [];
      comments.forEach((comment) {
        final c = comment as Map<String, dynamic>;
        _writeOneComment(sink, c);
      });

    });
  return size;
}

void _writeOneComment(IOSink sink, Map<String, dynamic> comment) {
  final user = comment['user'];
  final colon = comment['shouldShowColon'] as int? ?? 0;
  final name = user['screen_name'];
  final time = HttpDate.parse((comment['created_at'] as String?)?.replaceFirst('+0800', '') ?? '');

  sink.writeln(name);
  sink.writeln(_formatTime2(time));
  sink.writeln('${colon == 0 ? '' : ': '}${comment['text']}');
}
