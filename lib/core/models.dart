import 'helpers.dart';

enum Presence { online, away, busy, dnd, invisible, offline }

const presenceOptions = [
  Presence.online,
  Presence.away,
  Presence.busy,
  Presence.dnd,
  Presence.invisible,
];

Presence presenceFrom(Object? value) {
  switch (value?.toString()) {
    case 'away':
      return Presence.away;
    case 'busy':
      return Presence.busy;
    case 'dnd':
      return Presence.dnd;
    case 'invisible':
      return Presence.invisible;
    case 'offline':
      return Presence.offline;
    default:
      return Presence.online;
  }
}

String presenceValue(Presence p) => p.name;

bool presenceAvailable(Presence p) =>
    p != Presence.offline && p != Presence.invisible;

String presenceLabelKey(Presence p) {
  switch (p) {
    case Presence.online:
      return '在线';
    case Presence.away:
      return '离开';
    case Presence.busy:
      return '忙碌';
    case Presence.dnd:
      return '请勿打扰';
    case Presence.invisible:
      return '隐身';
    case Presence.offline:
      return '离线';
  }
}

class Peer {
  String id;
  String name;
  String signature;
  String avatar;
  Presence status;
  String ip;
  int port;
  int transferPort;
  String version;
  String platform;
  DateTime? lastSeen;
  bool connected;
  String alias;
  bool manual;

  Peer({
    required this.id,
    this.name = '',
    this.signature = '',
    this.avatar = '',
    this.status = Presence.offline,
    this.ip = '',
    this.port = 0,
    this.transferPort = 0,
    this.version = '',
    this.platform = '',
    this.lastSeen,
    this.connected = false,
    this.alias = '',
    this.manual = false,
  });

  String get displayName {
    if (alias.trim().isNotEmpty) return alias;
    if (name.trim().isNotEmpty) return name;
    if (ip.isNotEmpty) return ip;
    return '未知设备';
  }

  String get addr => port == 0 ? ip : '$ip:$port';
  String get transferAddr =>
      (ip.isEmpty || transferPort == 0) ? '' : '$ip:$transferPort';

  bool get available =>
      connected && presenceAvailable(status) && ip.isNotEmpty;

  Map<String, dynamic> toJson({bool runtime = false}) {
    final m = <String, dynamic>{
      'id': id,
      'name': name,
      'status': presenceValue(status),
      'lastSeen': lastSeen == null ? rfc3339(DateTime.now()) : rfc3339(lastSeen!),
    };
    if (signature.isNotEmpty) m['signature'] = signature;
    if (avatar.isNotEmpty) m['avatar'] = avatar;
    if (ip.isNotEmpty) m['ip'] = ip;
    if (port != 0) m['port'] = port;
    if (transferPort != 0) m['transferPort'] = transferPort;
    if (version.isNotEmpty) m['version'] = version;
    if (platform.isNotEmpty) m['platform'] = platform;
    if (alias.isNotEmpty) m['alias'] = alias;
    if (manual) m['manual'] = true;
    if (runtime) m['connected'] = connected;
    return m;
  }

  factory Peer.fromJson(Map<String, dynamic> m) {
    return Peer(
      id: asString(m['id']),
      name: asString(m['name']),
      signature: asString(m['signature']),
      avatar: asString(m['avatar']),
      status: presenceFrom(m['status']),
      ip: asString(m['ip']),
      port: asInt(m['port']),
      transferPort: asInt(m['transferPort']),
      version: asString(m['version']),
      platform: asString(m['platform']),
      lastSeen: parseTime(m['lastSeen']),
      connected: asBool(m['connected']),
      alias: asString(m['alias']),
      manual: asBool(m['manual']),
    );
  }
}

class Profile {
  String id;
  String name;
  String signature;
  String avatar;
  Presence status;

  Profile({
    required this.id,
    this.name = '',
    this.signature = '',
    this.avatar = '',
    this.status = Presence.online,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (signature.isNotEmpty) 'signature': signature,
        if (avatar.isNotEmpty) 'avatar': avatar,
        'status': presenceValue(status),
      };

  factory Profile.fromJson(Map<String, dynamic> m) => Profile(
        id: asString(m['id']),
        name: asString(m['name']),
        signature: asString(m['signature']),
        avatar: asString(m['avatar']),
        status: presenceFrom(m['status']),
      );

  Peer asPeer(String ip, int port, int transferPort) => Peer(
        id: id,
        name: name,
        signature: signature,
        avatar: avatar,
        status: status,
        ip: ip,
        port: port,
        transferPort: transferPort,
        lastSeen: DateTime.now(),
        connected: true,
      );
}

enum ConvKind { direct, group }

class Conversation {
  String id;
  ConvKind kind;
  String peerId;
  String title;
  String owner;
  List<String> members;
  DateTime createdAt;
  DateTime updatedAt;
  int unread;
  bool pinned;
  bool muted;
  String draft;

  Message? last;

  Conversation({
    required this.id,
    required this.kind,
    this.peerId = '',
    this.title = '',
    this.owner = '',
    List<String>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.unread = 0,
    this.pinned = false,
    this.muted = false,
    this.draft = '',
    this.last,
  })  : members = members ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool includeRuntime = false}) => {
        'id': id,
        'kind': kind.name,
        if (peerId.isNotEmpty) 'peerId': peerId,
        if (title.isNotEmpty) 'title': title,
        if (owner.isNotEmpty) 'owner': owner,
        if (members.isNotEmpty) 'members': members,
        'createdAt': rfc3339(createdAt),
        'updatedAt': rfc3339(updatedAt),
        'unread': unread,
        if (pinned) 'pinned': true,
        if (muted) 'muted': true,
        if (draft.isNotEmpty) 'draft': draft,
        if (includeRuntime && last != null) 'last': last!.toJson(),
      };

  factory Conversation.fromJson(Map<String, dynamic> m) {
    final kind = m['kind']?.toString() == 'group' ? ConvKind.group : ConvKind.direct;
    return Conversation(
      id: asString(m['id']),
      kind: kind,
      peerId: asString(m['peerId']),
      title: asString(m['title']),
      owner: asString(m['owner']),
      members: (m['members'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: parseTime(m['createdAt']) ?? DateTime.now(),
      updatedAt: parseTime(m['updatedAt']) ?? DateTime.now(),
      unread: asInt(m['unread']),
      pinned: asBool(m['pinned']),
      muted: asBool(m['muted']),
      draft: asString(m['draft']),
      last: m['last'] is Map
          ? Message.fromJson(Map<String, dynamic>.from(m['last'] as Map))
          : null,
    );
  }
}

class Group {
  String id;
  String name;
  String owner;
  List<String> members;
  DateTime createdAt;
  DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.owner,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  bool hasMember(String id) => members.contains(id);

  Conversation conversation() => Conversation(
        id: id,
        kind: ConvKind.group,
        title: name,
        owner: owner,
        members: List<String>.from(members),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner': owner,
        'members': members,
        'createdAt': rfc3339(createdAt),
        'updatedAt': rfc3339(updatedAt),
      };

  factory Group.fromJson(Map<String, dynamic> m) => Group(
        id: asString(m['id']),
        name: asString(m['name']),
        owner: asString(m['owner']),
        members:
            (m['members'] as List?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: parseTime(m['createdAt']) ?? DateTime.now(),
        updatedAt: parseTime(m['updatedAt']) ?? DateTime.now(),
      );
}

class FileMeta {
  String name;
  int size;
  String mime;
  String url;
  String token;
  String path;
  int width;
  int height;

  FileMeta({
    required this.name,
    required this.size,
    this.mime = '',
    this.url = '',
    this.token = '',
    this.path = '',
    this.width = 0,
    this.height = 0,
  });

  Map<String, dynamic> toJson({bool includePath = false}) => {
        'name': name,
        'size': size,
        if (mime.isNotEmpty) 'mime': mime,
        if (url.isNotEmpty) 'url': url,
        if (token.isNotEmpty) 'token': token,
        if (includePath && path.isNotEmpty) 'path': path,
        if (width > 0) 'width': width,
        if (height > 0) 'height': height,
      };

  factory FileMeta.fromJson(Map<String, dynamic> m) => FileMeta(
        name: asString(m['name']),
        size: asInt(m['size']),
        mime: asString(m['mime']),
        url: asString(m['url']),
        token: asString(m['token']),
        path: asString(m['path']),
        width: asInt(m['width']),
        height: asInt(m['height']),
      );
}

enum MessageKind { text, image, file, system }

class Message {
  String id;
  String convId;
  String senderId;
  String senderName;
  MessageKind kind;
  String text;
  FileMeta? file;
  DateTime sentAt;
  DateTime? editedAt;
  String status;
  bool delivered;
  bool read;
  bool recalled;
  bool mine;

  Message({
    required this.id,
    required this.convId,
    required this.senderId,
    this.senderName = '',
    this.kind = MessageKind.text,
    this.text = '',
    this.file,
    required this.sentAt,
    this.editedAt,
    this.status = '',
    this.delivered = false,
    this.read = false,
    this.recalled = false,
    this.mine = false,
  });

  String get preview => chatPreview(kind.name, text, file?.name ?? '', recalled);

  Map<String, dynamic> toJson({bool includePath = false}) {
    final m = <String, dynamic>{
      'id': id,
      'convId': convId,
      'senderId': senderId,
      if (senderName.isNotEmpty) 'senderName': senderName,
      'kind': kind.name,
      if (text.isNotEmpty) 'text': text,
      if (file != null) 'file': file!.toJson(includePath: includePath),
      'sentAt': rfc3339(sentAt),
      if (editedAt != null) 'editedAt': rfc3339(editedAt!),
      if (status.isNotEmpty) 'status': status,
      if (delivered) 'delivered': true,
      if (read) 'read': true,
      if (recalled) 'recalled': true,
    };
    return m;
  }

  Map<String, dynamic> wireJson() => toJson(includePath: false);

  factory Message.fromJson(Map<String, dynamic> m) {
    MessageKind kind;
    switch (m['kind']?.toString()) {
      case 'image':
        kind = MessageKind.image;
        break;
      case 'file':
        kind = MessageKind.file;
        break;
      case 'system':
        kind = MessageKind.system;
        break;
      default:
        kind = MessageKind.text;
    }
    return Message(
      id: asString(m['id']),
      convId: asString(m['convId']),
      senderId: asString(m['senderId']),
      senderName: asString(m['senderName']),
      kind: kind,
      text: asString(m['text']),
      file: m['file'] is Map
          ? FileMeta.fromJson(Map<String, dynamic>.from(m['file'] as Map))
          : null,
      sentAt: parseTime(m['sentAt']) ?? DateTime.now(),
      editedAt: parseTime(m['editedAt']),
      status: asString(m['status']),
      delivered: asBool(m['delivered']),
      read: asBool(m['read']),
      recalled: asBool(m['recalled']),
    );
  }
}

class TypingState {
  final String convId;
  final String peerId;
  final DateTime updatedAt;

  TypingState(this.convId, this.peerId, this.updatedAt);
}

class SendProgress {
  int sent;
  int total;
  double speed;
  String error;
  bool working;
  bool done;
  String transport;
  DateTime lastAt;
  int lastSent;

  SendProgress({
    this.sent = 0,
    this.total = 0,
    this.speed = 0,
    this.error = '',
    this.working = false,
    this.done = false,
    this.transport = '',
    DateTime? lastAt,
    this.lastSent = 0,
  }) : lastAt = lastAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  double get value => total <= 0 ? (done ? 1 : 0) : (sent / total).clamp(0, 1);
}

class DownloadState {
  final String convId;
  final String messageId;
  double value;
  int total;
  bool working;
  String error;
  String transport;
  DateTime updatedAt;

  DownloadState({
    required this.convId,
    required this.messageId,
    this.value = 0,
    this.total = 0,
    this.working = false,
    this.error = '',
    this.transport = '',
  }) : updatedAt = DateTime.now();
}

class IncomingFile {
  final String token;
  final String peerId;
  final String convId;
  final Message message;
  double value;
  int total;
  DateTime updatedAt;
  bool done;
  String? error;

  IncomingFile({
    required this.token,
    required this.peerId,
    required this.convId,
    required this.message,
    this.value = 0,
    this.total = 0,
  })  : updatedAt = DateTime.now(),
        done = false;
}
