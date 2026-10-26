import '../../providers/locale_provider.dart';

/// Static UI copy — one language at a time (no EN+MR brackets).
class S {
  final LocaleProvider locale;
  S(this.locale);

  String get appName => locale.t('MahaTicket', 'महाटिकिट');
  String get explore => locale.t('Explore', 'एक्सप्लोर');
  String get myTickets => locale.t('My Tickets', 'माझी तिकिटे');
  String get profile => locale.t('Profile', 'प्रोफाइल');
  String get partner => locale.t('Partner', 'पार्टनर');
  String get adminHub => locale.t('Admin Hub', 'अॅडमिन हब');
  String get producerHub => locale.t('Producer Hub', 'निर्माते हब');
  String get searchHint => locale.t('Search events, artists…', 'कार्यक्रम, कलाकार शोधा…');
  String get selectCity => locale.t('Select city', 'शहर निवडा');
  String get bookNow => locale.t('Book Now', 'आता बुक करा');
  String get from => locale.t('From', 'पासून');
  String get allShows => locale.t('All Shows', 'सर्व प्रयोग');
  String get selectSeats => locale.t('Select Seats', 'जागा निवडा');
  String get continueBtn => locale.t('Continue', 'पुढे चला');
  String get checkout => locale.t('Checkout', 'चेकआउट');
  String get payNow => locale.t('Pay Securely', 'सुरक्षित पेमेंट');
  String get digitalPass => locale.t('Digital Pass', 'डिजिटल पास');
  String get bookingConfirmed => locale.t('Booking confirmed', 'बुकिंग निश्चित');
  String get backHome => locale.t('Back to Home', 'होमवर परत');
  String get sharePass => locale.t('Share Pass', 'पास शेअर करा');
  String get viewPass => locale.t('View Pass', 'पास उघडा');
  String get upcoming => locale.t('Upcoming', 'येणारे');
  String get past => locale.t('Past', 'मागील');
  String get aboutShow => locale.t('About the Show', 'कथानक व माहिती');
  String get castCrew => locale.t('Cast & Crew', 'कलाकार व दिग्दर्शक');
  String get gallery => locale.t('Gallery', 'गॅलरी');
  String get reviews => locale.t('Audience Reviews', 'प्रेक्षक प्रतिक्रिया');
  String get entryPolicy => locale.t('Entry Policy', 'प्रवेश नियम');
  String get readMore => locale.t('Read more', 'अधिक वाचा');
  String get readLess => locale.t('Read less', 'कमी वाचा');
  String get submitReview => locale.t('Submit Review', 'समीक्षा पाठवा');
  String get language => locale.t('Language', 'भाषा');
  String get stageThisWay => locale.t('STAGE THIS WAY', 'रंगमंच या बाजूस');
  String get available => locale.t('Available', 'उपलब्ध');
  String get selected => locale.t('Selected', 'निवडलेले');
  String get reserved => locale.t('Reserved', 'आरक्षित');
  String get booked => locale.t('Booked', 'बुक');
  String get loadingSeats => locale.t('Loading seat map…', 'आसन व्यवस्था लोड होत आहे…');
  String get holdExpired =>
      locale.t('Seat hold expired. Select seats again.', 'आसन आरक्षण संपले. पुन्हा आसने निवडा.');
  String get maxSeats =>
      locale.t('Maximum 5 seats per booking.', 'एका वेळी जास्तीत जास्त ५ आसने.');
  String seatHeld(String code) => locale.t(
        'Seat $code is held by another customer. Choose different seats.',
        'आसन $code दुसऱ्या ग्राहकाकडे आरक्षित आहे. इतर आसन निवडा.',
      );
  String get seatConflict => locale.t(
        'Selected seats are held by another customer. Choose different seats.',
        'निवडलेले आसन दुसऱ्या ग्राहकाकडे आरक्षित आहे. इतर आसन निवडा.',
      );
  String get noEvents => locale.t('No events found', 'कार्यक्रम सापडले नाहीत');
  String get resetFilters => locale.t('Reset filters', 'फिल्टर रीसेट');
  String get homeSections => locale.t('Home Sections', 'होम स्क्रीन सेक्शन्स');
  String get gateScanner => locale.t('Gate Scanner', 'गेट स्कॅनर');
  String get verify => locale.t('Verify', 'पडताळा');
  String get accessGranted => locale.t('ACCESS GRANTED', 'प्रवेश मंजूर');
  String get entryRejected => locale.t('ENTRY REJECTED', 'प्रवेश नाकारला');
  String get signIn => locale.t('Sign In', 'प्रवेश करा');
  String get createAccount => locale.t('Create Account', 'खाते तयार करा');
  String get useOtp => locale.t('Sign in with email OTP', 'ईमेल OTP ने प्रवेश');
  String get usePassword => locale.t('Use password instead', 'पासवर्डने प्रवेश');
  String hits(int n) => locale.t('$n Hits', '$n हिट्स');
  String showsCount(int n) => locale.t('$n Shows', '$n प्रयोग');
}
