import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk/talk.dart';

import '../helper.dart';
import '../mock_adapter.dart';

void main() {
  MockAdapter _adapter;
  TalkApi _api;
  Dio _dio;

  setUp(() {
    _dio = Dio();
    _adapter = MockAdapter();
    _dio.httpClientAdapter = _adapter;
    _api = TalkApi(_dio);
  });

  test("/v1/api/talk/profile 200", () async {
    String body = await loadJson("talk/profile/profile.json");
    Map<String, dynamic> map = jsonDecode(body);
    _adapter.setResponseString(body, 200);

    TalkProfile profile = await _api.profile();
    expect(profile.nickname, map["nickName"]);
    expect(profile.profileImageUrl.toString(), map["profileImageURL"]);
    expect(profile.thumbnailUrl.toString(), map["thumbnailURL"]);
    expect(map["countryISO"], profile.countryISO);
    expect(true, profile.toJson() != null);
  });

  bool compareFriend(Map<String, dynamic> element, Friend friend) {
    return friend.userId == element["id"] &&
        friend.profileNickname == element["profile_nickname"] &&
        friend.profileThumbnailImage.toString() ==
            element["profile_thumbnail_image"];
  }

  test('/v1/friends 200', () async {
    String body = await loadJson("talk/friends/friends.json");
    Map<String, dynamic> map = jsonDecode(body);
    _adapter.setResponseString(body, 200);

    FriendsResponse res = await _api.friends();
    expect(map["total_count"], res.totalCount);
    expect(res.beforeUrl.toString(), map["before_url"].toString());
    expect(res.afterUrl.toString(), map["after_url"].toString());

    List<dynamic> elements = map["elements"];
    List<Friend> friends = res.friends;
    friends.asMap().forEach(
        (idx, friend) => expect(true, compareFriend(elements[idx], friend)));
    expect(true, res.toJson() != null);
  });

  group("/v2/api/talk/memo", () {
    setUp(() async {
      _adapter.setResponseString("", 200);
    });

    tearDown(() async {});
    test("/custom without args", () async {
      _adapter.requestAssertions = (RequestOptions options) {
        expect(options.method, "POST");
        Map<String, dynamic> params = options.data;
        expect(params["template_id"], 1234);
        expect(false, params.containsKey("template_args"));
      };
      await _api.customMemo(1234);
    });

    test("/custom with args", () async {
      var args = {"key1": "value1", "key2": "value2"};
      _adapter.requestAssertions = (RequestOptions options) {
        expect(options.method, "POST");
        var params = options.data;
        expect(params["template_id"], 1234);
        expect(params["template_args"], jsonEncode(args));
      };
      await _api.customMemo(1234, args);
    });

    group("/default", () {
      test("feed", () async {
        var template = FeedTemplate(
            Content("title", Uri.parse("https://example.com/image.png"),
                Link(webUrl: Uri.parse("https://example.com"))),
            social: Social(
                likeCount: 1,
                commentCount: 2,
                sharedCount: 3,
                viewCount: 4,
                subscriberCount: 10));
        _adapter.requestAssertions = (RequestOptions options) {
          expect(options.method, "POST");
          Map<String, dynamic> params = options.data;
          expect(true, params.containsKey("template_object"));
          expect(params["template_object"], jsonEncode(template));
        };

        await _api.defaultMemo(template);
      });

      test("commerce", () async {
        var template = CommerceTemplate(
            Content(
                "title",
                Uri.parse("https://developers.kakao.com/image.png"),
                Link(webUrl: Uri.parse("https://developers.kakao.com"))),
            Commerce(15000));

        _adapter.requestAssertions = (RequestOptions options) {
          expect(options.data["template_object"], jsonEncode(template));
        };
        await _api.defaultMemo(template);
      });
    });

    group("/scrap", () {
      test("without args", () async {
        var url = "https://developers.kakao.com";
        _adapter.requestAssertions = (RequestOptions options) {
          expect(options.method, "POST");
          Map<String, dynamic> params = options.data;
          expect(params["request_url"], url);
        };
        await _api.scrapMemo(url);
      });

      test("with args", () async {
        var url = "https://developers.kakao.com";
        var templateId = 1234;
        var args = {"key1": "value1", "key2": "value2"};
        _adapter.requestAssertions = (RequestOptions options) {
          expect(options.method, "POST");
          Map<String, dynamic> params = options.data;
          expect(params["request_url"], url);
          expect(params["template_id"], templateId);
          expect(params["template_args"], jsonEncode(args));
        };
        await _api.scrapMemo(url, templateId: 1234, templateArgs: args);
      });
    });
  });

  group("/v1/api/talk/plusfriends", () {
    var map;
    PlusFriendsResponse res;
    setUp(() async {
      var body = await loadJson("talk/plusfriends/plus_friends.json");
      map = jsonDecode(body);
      _adapter.setResponseString(body, 200);
    });

    tearDown(() async {
      expect(res.userId, map["user_id"]);
      var elements = map["plus_friends"];
      var friends = res.plusFriends;
      friends.asMap().forEach((index, friend) {
        var element = elements[index];
        expect(friend.uuid, element["plus_friend_uuid"]);
        expect(friend.publicId, element["plus_friend_public_id"]);
        expect(friend.relation, element["relation"]);
        expect(Util.dateTimeWithoutMillis(friend.updatedAt),
            element["updated_at"]);
      });
      expect(true, res.toJson() != null);
    });

    test("with no parameter", () async {
      res = await _api.plusFriends();
    });

    test("with public ids", () async {
      var publicId = "_frxjem";
      _adapter.requestAssertions = (RequestOptions options) {
        var params = options.queryParameters;
        expect(params["plus_friend_public_ids"], jsonEncode([publicId]));
      };
      res = await _api.plusFriends([publicId]);
    });
  });
}
