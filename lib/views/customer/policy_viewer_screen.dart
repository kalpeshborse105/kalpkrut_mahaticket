import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PolicyViewerScreen extends StatefulWidget {
  final String initialPolicy; // 'terms', 'privacy', 'refund'

  const PolicyViewerScreen({super.key, this.initialPolicy = 'terms'});

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initIndex = 0;
    if (widget.initialPolicy == 'privacy') initIndex = 1;
    if (widget.initialPolicy == 'refund') initIndex = 2;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('कायदेशीर अटी व धोरणे (Policies)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'अटी (Terms)'),
            Tab(text: 'गोपनीयता (Privacy)'),
            Tab(text: 'परतावा (Refund)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsContent(),
          _buildPrivacyContent(),
          _buildRefundContent(),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('१. सेवा अटी (Terms of Service)'),
          _paragraph(
            'महाटिकिट (MahaTicket) हे कल्पकृत इन्फोटेक द्वारे संचलित अधिकृत तिकीट बुकिंग व इव्हेंट व्यवस्थापन व्यासपीठ आहे. या अ‍ॅपचा अथवा संकेतस्थळाचा वापर करून तुम्ही या अटींचे पालन करण्यास संमती दर्शवता.',
          ),
          _sectionTitle('२. तिकीट खरेदी व प्रवेश नियम'),
          _paragraph(
            '• डिजिटल एम-तिकीट (M-Ticket) व त्यावर असलेला अधिकृत QR कोड प्रवेशद्वारावर स्कॅन करणे बंधनकारक आहे.\n'
            '• एका QR कोडचा वापर फक्त एकदाच प्रवेशासाठी केला जाऊ शकतो.\n'
            '• तिकीट स्क्रीनशॉट सोशल मीडियावर सार्वजनिक करू नका, जेणेकरून फसवणूक टाळता येईल.\n'
            '• नाट्यगृहात प्रेक्षकांनी प्रयोगाच्या वेळेच्या किमान २० मिनिटे आधी उपस्थित राहावे.',
          ),
          _sectionTitle('३. आसन आरक्षण व राखीव जागा'),
          _paragraph(
            '• महाटिकिट रिअल-टाइम ५ मिनिटांचे आसन लॉक (Concurrency Hold) प्रदान करते. ५ मिनिटांत पेमेंट पूर्ण न झाल्यास जागा पुन्हा सर्वांसाठी उपलब्ध होते.\n'
            '• नाट्यगृह व्यवस्थापनाकडे सुरक्षा व आपत्कालीन परिस्थितीत आसन व्यवस्था बदलण्याचा अंतिम अधिकार आहे.',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('१. गोपनीयता धोरण (Privacy Policy)'),
          _paragraph(
            'आम्ही आपल्या गोपनीयतेचा आदर करतो. महाटिकिट आपल्या वैयक्तिक डेटाची (नाव, मोबाईल नंबर, ईमेल) सुरक्षितता सर्वोच्च प्राधान्याने जपते.',
          ),
          _sectionTitle('२. माहितीचा वापर'),
          _paragraph(
            '• आपले नाव, फोन व ईमेलचा वापर केवळ डिजिटल तिकीट व्हॉट्सअ‍ॅप व ईमेलवर पाठवण्यासाठी केला जातो.\n'
            '• पेमेंट प्रक्रिया Razorpay या PCI-DSS मान्यताप्राप्त गेटवेमार्फत पूर्णतः एनक्रिप्टेड पद्धतीने होते. आम्ही तुमचे कार्ड किंवा बँक तपशील साठवत नाही.\n'
            '• आपली वैयक्तिक माहिती कोणत्याही तृतीय पक्षाला विकली किंवा वितरित केली जात नाही.',
          ),
        ],
      ),
    );
  }

  Widget _buildRefundContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('१. रद्द करणे व परतावा धोरण (Cancellation & Refund)'),
          _paragraph(
            'नाट्यप्रयोग व लाइव्ह इव्हेंट्सच्या स्वरूपामुळे एकदा आरक्षित केलेले तिकीट रद्द करता येत नाही किंवा बदलून दिले जात नाही, जोपर्यंत कार्यक्रम अधिकृतपणे रद्द होत नाही.',
          ),
          _sectionTitle('२. कार्यक्रम रद्द झाल्यास परतावा'),
          _paragraph(
            '• जर निर्माता अथवा आयोजकांकडून कार्यक्रम तांत्रिक कारणामुळे अथवा अपरिहार्य परिस्थितीमुळे रद्द झाल्यास, तिकीटाची १००% रक्कम (प्लॅटफॉर्म इंटरनेट फी सोडून) मूळ पेमेंट स्त्रोतामध्ये ५ ते ७ बँक कामकाजाच्या दिवसांत जमा केली जाईल.\n'
            '• कोणत्याही तक्रारीसाठी help@mahaticket.com वर संपर्क साधावा.',
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
    );
  }
}
