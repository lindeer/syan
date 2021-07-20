import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _feedList = [
  '21616894817',
  '21427002649',
  '20569680510',
  '20454316385',
  '20421648174',
  '20320312808',
  '20215509468',
  '19935000902',
  '19635335553',
  '19605268797',
  '19573043956',
  '19543028823',
  '19485487362',
  '19365939164',
  '19209562086',
  '19093878704',
  '18977159851',
  '18917722728',
  '18839814441',
  '18726622573',
  '18726539179',
  '18659886920',
  '18619477136',
  '18606436708',
  '18466636821',
  '18357916023',
  '18245033787',
  '17895218305',
  '17748516448',
  '17708290420',
  '17595989323',
  '17573939887',
  '17566494620',
  '17566347690',
  '17547276162',
  '17477256373',
  '17463808215',
  '17420946474',
  '14844641396',
  '14813552925',
  '14813552931',
  '14813552935',
  '14813553003',
  '14813552884',
  '14813553007',
  '14813553009',
  '14813552953',
  '14813552958',
  '14813553020',
  '14813552792',
  '14813552968',
  '14813552975',
  '14813552977',
  '14813552986',
  '14813552869',
  '14813552695',
  '14813552996',
  '14813553064',
  '14813553005',
  '14813552948',
  '14813553017',
  '14813553018',
  '14813553024',
  '14813552849',
  '14813553031',
  '14813553092',
  '14813553096',
  '14813552982',
  '14813553105',
  '14813552872',
  '14813553052',
  '14813553115',
  '14813553063',
  '14813553065',
  '14813553012',
  '14813553074',
  '14813553139',
  '14813553081',
  '14813553147',
  '14813553084',
  '14813553157',
  '14813553038',
  '14813552805',
  '14926358880',
  '14813553103',
  '14813553168',
  '14813552997',
  '14813553178',
  '14813553186',
  '14813552938',
  '14813553120',
  '14813553124',
  '14813553190',
  '14813552896',
  '14813553132',
  '14813553078',
  '14813553140',
  '14813553023',
  '14813553142',
  '14813553207',
  '14813553029',
  '14813553213',
  '14813553091',
  '14813553036',
  '14813552984',
  '14813553166',
  '14813553051',
  '14813553110',
  '14813553177',
  '14813553236',
  '14813553059',
  '14813553250',
  '14813552791',
  '14813553129',
  '14813553202',
  '14813553022',
  '14813552914',
  '14813553262',
  '14813553211',
  '14813553045',
  '14813553283',
  '14813553231',
  '14813553114',
  '14813553182',
  '14813553237',
  '14813553185',
  '14813553251',
  '14813553255',
  '14813553134',
  '14813553148',
  '14813553156',
  '14813553158',
  '14813553219',
  '14813553265',
  '14813553271',
  '14813553317',
  '14926358948',
  '14926358994',
  '14813553279',
  '14813553053',
  '14813553288',
  '14813553184',
  '14926359036',
  '14813553117',
  '14813553295',
  '14813553302',
  '14926359230',
  '14813553263',
  '14813553264',
  '14813553266',
  '14813553305',
  '14813553316',
  '14813553276',
  '14813553225',
  '14813553226',
  '14813553253',
  '14813553260',
  '14813553347',
  '14813553351',
];

void main(List<String> argv) {
  if (argv.length > 0) {
    Directory.current = argv[0];
  }
  // _feedList.forEach(_saveFeed);
  _createSource();
}

final reg = RegExp(r'__INITIAL_STATE__=({.*})');

void _saveFeed(String feedId) async {
  final url = Uri.parse('http://renren.com/feed/$feedId/42526317');
  final response = await http.get(url, headers: {"Cookie": 'taihe_bi_sdk_uid=449bda8e2dda262917ce859d17c16c60; taihe_bi_sdk_session=63a87ef63c5936d65b70dd52ac2e3683; Hm_lvt_ad6b0fd84f08dc70750c5ee6ba650172=1626404623; anonymid=kr5rgxfs-mqoo4w; LOCAL_STORAGE_KEY_RENREN_USER_BASIC_INFO=%7B%22userName%22%3A%22%u6797%u9E7F%22%2C%22userId%22%3A42526317%2C%22headUrl%22%3A%22http%3A//hdn.xnimg.cn/photos/hdn321/20120614/1645/h_head_XGmE_0c4e000002b81375.jpg%22%2C%22secretKey%22%3A%2295e5a633c5dc7173fabab0b7497dda1b%22%2C%22sessionKey%22%3A%22F2C6GPSsWiKBL5v%22%7D; Hm_lpvt_ad6b0fd84f08dc70750c5ee6ba650172=1626663781'});
  if (response.statusCode != 200) {
    Future.delayed(Duration(seconds: 2), () {
      _saveFeed(feedId);
    });
    return;
  }
  final match = reg.firstMatch(response.body);
  final str = match?[1];
  if (str == null) {
    print("feed: '$feedId' json content error!");
    return;
  }
  final body = json.decode(str);
  final detail = body['feedDetail']['detail'] as Map<String, dynamic>;

  final id = '${detail['id']}';
  final filename = 'data/renren/renren_feed_$id.json';
  final file = File(filename);
  file.writeAsStringSync(json.encode(detail), flush: true);
  if (id != feedId) {
    print("????????????? '$feedId' is not fetched id '$id' !!");
  }
  print("save feed $feedId!!");
}

extension _IntExt on int {
  String get padZero => toString().padLeft(2, '0');
}

String _formatTime(DateTime time, {String ymd = ' ', String hms = ':'}) {
  return "${time.year}-${time.month.padZero}-${time.day.padZero}$ymd"
      "${time.hour.padZero}$hms${time.minute.padZero}$hms${time.second.padZero}";
}

void _createSource() async {
  final dir = Directory('data/renren');
  if (!dir.existsSync()) {
    print("No renren data found in 'data/renren'!");
    exit(-1);
  }
  final sourceDir = Directory('source/_posts');
  if (!sourceDir.existsSync()) {
    sourceDir.create(recursive: true);
  }
  final files = dir.listSync(recursive: false, followLinks: false,).where((f) => f.path.contains('renren_feed_'));
  int count = 0;
  for (final f in files) {
    final feed = json.decode(File(f.path).readAsStringSync());
    _writeFeed(feed);
    count++;
  }
  print("finish writing $count post!");
}

void _writeFeed(Map<String, dynamic> feed) {
  final content = feed['body'];
  final text = content['content'];
  final time = DateTime.fromMillisecondsSinceEpoch(feed['publish_time'] as int);
  final f = File("source/_posts/renren_${_formatTime(time, ymd: '-', hms: '')}.md");
  final sink = f.openWrite();
  sink.writeln('layout: weibo');
  sink.writeln('date: ${_formatTime(time)}');
  sink.writeln('---');
  sink.writeln('<meta name="referrer" content="no-referrer" />\n');
  sink.writeln('<img src="/images/renren.ico" style="float: left;"/>${_formatTime(time)}\n');
  sink.writeln(text);
  sink.writeln();

  final images = content['images'] as List?;
  images?.forEach((img) {
    sink.writeln('![content](${img['url']})');
  });
  if ((images?.length ?? 0) > 1) {
    print("!!!! ${feed['id']} more than one pic!");
  }

  sink.close();
}
