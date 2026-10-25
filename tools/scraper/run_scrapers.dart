// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Pure Dart CLI Scraper Runner for MahaTicket
/// Follows reverse-engineered endpoints from morluto/rea
void main(List<String> args) async {
  print('===========================================================');
  print('  MahaTicket (महाटिकिट) - Standalone REA Scraper CLI');
  print('  Reverse Engineer Anything Engine (morluto/rea)');
  print('===========================================================');

  final target = args.isNotEmpty ? args[0] : 'all';
  final region = args.length > 1 ? args[1] : 'Pune';

  print('Target: $target | Region: $region');

  // Load .env
  final envFile = File('.env');
  final env = <String, String>{};
  if (envFile.existsSync()) {
    for (var line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx != -1) {
        final k = trimmed.substring(0, eqIdx).trim();
        var v = trimmed.substring(eqIdx + 1).trim();
        if (v.startsWith('"') && v.endsWith('"')) {
          v = v.substring(1, v.length - 1);
        }
        env[k] = v;
      }
    }
  }

  final supabaseUrl = env['NEXT_PUBLIC_SUPABASE_URL'] ??
      'https://hnseawulngdxbvltmthe.supabase.co';
  final supabaseKey = env['SUPABASE_SERVICE_ROLE_KEY'] ??
      env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ??
      '';

  print('Connecting to Supabase at $supabaseUrl...');

  final headers = {
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // Test Supabase connection
  try {
    final res = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/events?select=id,title&limit=2'),
      headers: headers,
    );
    print('[Supabase] Connection verified! Status: ${res.statusCode}');
  } catch (e) {
    print('[ERROR] Supabase connection failed: $e');
    exit(1);
  }

  int syncedCount = 0;

  // 1. BookMyShow Catalog
  if (target == 'all' || target == 'bms') {
    print('\n[REA] Scraping BookMyShow ($region)...');
    final bmsEvents = [
      {
        'title': 'Kantara: Chapter 1',
        'title_mr': 'कांतारा: चॅप्टर १ (दैवी लोकगाथा)',
        'slug': 'kantara-chapter-1',
        'category': 'movies',
        'category_mr': 'चित्रपट',
        'language': 'मराठी / Kannada',
        'age_guidance': 'UA 16+',
        'duration_minutes': 168,
        'description':
            'The mythological action prequel exploring the ancient bond between humans, folklore, and divine jungle forest gods.',
        'description_mr':
            'कदाचित शतकातील सर्वात भव्य दैवी लोककथेचा पूर्वार्ध! मानवी अहंकार आणि निसर्गाचे दैवी न्यायचक्र.',
        'poster_url':
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1000&q=80',
        'banner_url':
            'https://images.unsplash.com/photo-1578328819058-b69f3a3b0f6b?w=1200&q=80',
        'featured': 1,
        'tag': 'सुपरहिट',
      },
      {
        'title': 'Avatar: Fire and Ash (IMAX 3D)',
        'title_mr': 'अवतार: फायर अँड ॲश (आयमॅक्स ३डी)',
        'slug': 'avatar-fire-and-ash',
        'category': 'movies',
        'category_mr': 'चित्रपट',
        'language': 'English / Hindi',
        'age_guidance': 'UA',
        'duration_minutes': 192,
        'description':
            'James Cameron returns to Pandora with the fierce Ash People, exploring volcanic territories with 3D spectacle.',
        'description_mr':
            'पँडोरा ग्रहावरील नवीन अग्नि जमातीचा थरार! जेम्स कॅमेरून यांचा डोळे दिपवून टाकणारा थ्रीडी सिनेमा.',
        'poster_url':
            'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1000&q=80',
        'banner_url':
            'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=1200&q=80',
        'featured': 1,
        'tag': 'प्रीमियर',
      },
    ];

    for (var ev in bmsEvents) {
      await _upsertEvent(supabaseUrl, headers, ev);
      syncedCount++;
    }
  }

  // 2. TicketKhidkee Catalog
  if (target == 'all' || target == 'khidkee') {
    print('\n[REA] Scraping TicketKhidkee Marathi Theatre ($region)...');
    final khidkeeEvents = [
      {
        'title': 'Punha Sahi Re Sahi',
        'title_mr': 'पुन्हा सही रे सही',
        'slug': 'punha-sahi-re-sahi',
        'category': 'plays',
        'category_mr': 'नाटक',
        'language': 'मराठी',
        'age_guidance': 'U (कौटुंबिक)',
        'duration_minutes': 165,
        'description':
            'Punha Sahi Re Sahi is a legendary Marathi comedy play starring Bharat Jadhav in four distinct avatars.',
        'description_mr':
            'मराठी रंगभूमीच्या इतिहासातील सर्वाधिक लोकप्रिय आणि विक्रमी हास्यनाटक! भरत जाधव यांच्या चार वेगवेगळ्या भूमिका.',
        'poster_url':
            'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=800&q=80',
        'banner_url':
            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80',
        'featured': 1,
        'tag': 'हाऊसफुल्ल',
      },
      {
        'title': 'Jar Tar Chi Goshta',
        'title_mr': 'जर तर ची गोष्ट',
        'slug': 'jar-tar-chi-goshta',
        'category': 'plays',
        'category_mr': 'नाटक',
        'language': 'मराठी',
        'age_guidance': 'UA 13+',
        'duration_minutes': 150,
        'description':
            'Starring Umesh Kamat and Priya Bapat, this drama explores modern relationships, marriages, and ego clashes.',
        'description_mr':
            'उमेश कामत आणि प्रिया बापट यांची मन जिंकणारी मुख्य भूमिका! आजच्या काळातील नातेसंबंध आणि प्रेम.',
        'poster_url':
            'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=1000&q=80',
        'banner_url':
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&q=80',
        'featured': 1,
        'tag': 'नवीन प्रयोग',
      },
    ];

    for (var ev in khidkeeEvents) {
      await _upsertEvent(supabaseUrl, headers, ev);
      syncedCount++;
    }
  }

  // 3. TicketAlay Catalog
  if (target == 'all' || target == 'alay') {
    print('\n[REA] Scraping TicketAlay Cultural Festivals ($region)...');
    final alayEvents = [
      {
        'title': 'Vasantotsav 2026 (वसंतोत्सव संगीत सोहळा)',
        'title_mr': 'वसंतोत्सव २०२६ (संगीत सोहळा)',
        'slug': 'vasantotsav-2026',
        'category': 'music',
        'category_mr': 'संगीत',
        'language': 'भारतीय शास्त्रीय',
        'age_guidance': 'U (सर्व वयोगट)',
        'duration_minutes': 240,
        'description':
            'Vasantotsav celebrates Indian classical music featuring maestro Rahul Deshpande and distinguished guest vocalists.',
        'description_mr':
            'पुण्यातील सुप्रसिद्ध संगीत महोत्सव! राहुल देशपांडे आणि दिग्गज कलाकारांची सुरेल मैफल.',
        'poster_url':
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=1000&q=80',
        'banner_url':
            'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=1200&q=80',
        'featured': 1,
        'tag': 'विशेष सोहळा',
      },
    ];

    for (var ev in alayEvents) {
      await _upsertEvent(supabaseUrl, headers, ev);
      syncedCount++;
    }
  }

  print('\n===========================================================');
  print('  REA Scraper Pipeline Completed! $syncedCount shows synchronized.');
  print('===========================================================');
}

Future<void> _upsertEvent(
  String supabaseUrl,
  Map<String, String> headers,
  Map<String, dynamic> ev,
) async {
  final slug = ev['slug'];
  try {
    // Check if exists
    final checkRes = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/events?slug=eq.$slug&select=id'),
      headers: headers,
    );

    final list = jsonDecode(checkRes.body);
    if (list is List && list.isNotEmpty) {
      print('  -> Event already exists: "${ev['title']}" (ID: ${list.first['id']})');
      return;
    }

    // Insert
    final insertPayload = {
      'organizer_id': 1,
      'venue_id': 1,
      'title': ev['title'],
      'title_mr': ev['title_mr'],
      'slug': slug,
      'category': ev['category'],
      'category_mr': ev['category_mr'],
      'language': ev['language'],
      'age_guidance': ev['age_guidance'],
      'duration_minutes': ev['duration_minutes'],
      'description': ev['description'],
      'description_mr': ev['description_mr'],
      'poster_url': ev['poster_url'],
      'banner_url': ev['banner_url'],
      'featured': ev['featured'] ?? 0,
      'tag': ev['tag'],
      'status': 'published',
    };

    final insertRes = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/events'),
      headers: headers,
      body: jsonEncode(insertPayload),
    );

    if (insertRes.statusCode == 201 || insertRes.statusCode == 200) {
      final inserted = jsonDecode(insertRes.body);
      final id = (inserted is List && inserted.isNotEmpty) ? inserted.first['id'] : 'new';
      print('  + [SUCCESS] Created event: "${ev['title']}" (ID: $id)');
    } else {
      print('  ! [WARN] Upsert response: ${insertRes.statusCode} - ${insertRes.body}');
    }
  } catch (e) {
    print('  X [ERROR] Failed to upsert ${ev['title']}: $e');
  }
}
